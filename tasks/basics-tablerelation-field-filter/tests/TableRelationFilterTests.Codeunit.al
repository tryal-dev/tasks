codeunit 50900 "TableRelation Filter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Filtered Table Relation]

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OwnVariantIsAcceptedOnTheLine()
    var
        StockCountLine: Record "Stock Count Line";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        // [SCENARIO] A variant that belongs to the line's item passes the relation check
        // [GIVEN] an item with a variant, and a line for that item
        CreateItemWithVariant(Item, ItemVariant);
        CreateLineForItem(StockCountLine, 'TRYAL-TF01', Item."No.");

        // [WHEN] validating "Variant Code" with the item's own variant
        StockCountLine.Validate("Variant Code", ItemVariant.Code);

        // [THEN] the line keeps the variant
        Assert.AreEqual(ItemVariant.Code, StockCountLine."Variant Code",
            'Expected a variant of the line''s own item to be accepted by "Variant Code"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnotherItemsVariantIsRejectedOnTheLine()
    var
        StockCountLine: Record "Stock Count Line";
        Item: Record Item;
        OtherItem: Record Item;
        ItemVariant: Record "Item Variant";
        OtherVariant: Record "Item Variant";
    begin
        // [SCENARIO] A variant code that exists, but under a different item, is refused by the relation itself
        // [GIVEN] two items with a variant each, and a line for the first item
        CreateItemWithVariant(Item, ItemVariant);
        CreateItemWithVariant(OtherItem, OtherVariant);
        CreateLineForItem(StockCountLine, 'TRYAL-TF02', Item."No.");

        // [WHEN] validating "Variant Code" with the other item's variant
        if TryValidateVariantCode(StockCountLine, OtherVariant.Code) then
            Assert.Fail(StrSubstNo('Expected variant %1 to be refused on a line for item %2 — it belongs to item %3, so the relation must be filtered to the line''s own "Item No."',
                OtherVariant.Code, Item."No.", OtherItem."No."));

        // [THEN] the error is the platform's own relation failure, naming the Item Variant table
        Assert.ExpectedError('cannot be found in the related table');
        Assert.ExpectedError('Item Variant');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankVariantIsAcceptedOnTheLine()
    var
        StockCountLine: Record "Stock Count Line";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        // [SCENARIO] A blank variant never reaches the relation check
        // [GIVEN] a line for an item that already carries one of its variants
        CreateItemWithVariant(Item, ItemVariant);
        CreateLineForItem(StockCountLine, 'TRYAL-TF03', Item."No.");
        StockCountLine.Validate("Variant Code", ItemVariant.Code);

        // [WHEN] validating "Variant Code" with a blank value
        StockCountLine.Validate("Variant Code", '');

        // [THEN] the variant is blank and no error was raised
        Assert.AreEqual('', Format(StockCountLine."Variant Code"),
            'Expected a blank "Variant Code" to be accepted without an error — a blank value is never checked against the relation');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChangingTheItemBlanksTheVariant()
    var
        StockCountLine: Record "Stock Count Line";
        Item: Record Item;
        OtherItem: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        // [SCENARIO] A variant must not survive a switch to an item it does not belong to
        // [GIVEN] a stored line carrying an item and one of its variants, and a second item
        CreateItemWithVariant(Item, ItemVariant);
        LibraryInventory.CreateItem(OtherItem);
        CreateStoredLine(StockCountLine, 'TRYAL-TF04', Item."No.", ItemVariant.Code);

        // [WHEN] validating "Item No." with the second item
        StockCountLine.Validate("Item No.", OtherItem."No.");

        // [THEN] the variant is blank
        Assert.AreEqual('', Format(StockCountLine."Variant Code"),
            'Expected validating "Item No." with a different item to blank "Variant Code" — the old variant belongs to the old item');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RevalidatingTheSameItemKeepsTheVariant()
    var
        StockCountLine: Record "Stock Count Line";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        // [SCENARIO] Re-validating "Item No." with the value the line already carries is not a change
        // [GIVEN] a stored line carrying an item and one of its variants
        CreateItemWithVariant(Item, ItemVariant);
        CreateStoredLine(StockCountLine, 'TRYAL-TF05', Item."No.", ItemVariant.Code);

        // [WHEN] validating "Item No." with the same item
        StockCountLine.Validate("Item No.", Item."No.");

        // [THEN] the variant is still there
        Assert.AreEqual(ItemVariant.Code, StockCountLine."Variant Code",
            'Expected validating "Item No." with the value the line already carries to leave "Variant Code" alone — compare with xRec, only a real change may blank it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignedVariantBypassesTheRelationOnModify()
    var
        StockCountLine: Record "Stock Count Line";
        Item: Record Item;
        OtherItem: Record Item;
        ItemVariant: Record "Item Variant";
        OtherVariant: Record "Item Variant";
    begin
        // [SCENARIO] The relation is enforced by Validate only — a plain assignment followed by Modify stores anything
        // [GIVEN] a stored line for one item, and a variant of another item
        CreateItemWithVariant(Item, ItemVariant);
        CreateItemWithVariant(OtherItem, OtherVariant);
        CreateStoredLine(StockCountLine, 'TRYAL-TF06', Item."No.", ItemVariant.Code);

        // [WHEN] assigning the other item's variant and calling Modify with triggers
        StockCountLine."Variant Code" := OtherVariant.Code;
        StockCountLine.Modify(true);

        // [THEN] the foreign variant is stored and no error was raised
        StockCountLine.Get('TRYAL-TF06', 10000);
        Assert.AreEqual(OtherVariant.Code, StockCountLine."Variant Code",
            'Expected a plain assignment plus Modify to store a variant of another item — the table relation is checked by Validate only, and nothing else may refuse the write');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenRegionIsAcceptedOnTheCustomer()
    var
        Customer: Record Customer;
        SalesRegion: Record "Sales Region";
    begin
        // [SCENARIO] A region that is not blocked passes the relation check
        // [GIVEN] an unblocked sales region and a customer
        CreateSalesRegion(SalesRegion, false);
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] validating "Region Code" with that region
        Customer.Validate("Region Code", SalesRegion.Code);

        // [THEN] the customer carries the region
        Assert.AreEqual(SalesRegion.Code, Customer."Region Code",
            'Expected a sales region that is not blocked to be accepted by "Region Code"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlockedRegionIsRejectedOnTheCustomer()
    var
        Customer: Record Customer;
        SalesRegion: Record "Sales Region";
    begin
        // [SCENARIO] A region that exists but is blocked is refused by the relation itself
        // [GIVEN] a blocked sales region and a customer
        CreateSalesRegion(SalesRegion, true);
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] validating "Region Code" with the blocked region
        if TryValidateRegionCode(Customer, SalesRegion.Code) then
            Assert.Fail(StrSubstNo('Expected blocked sales region %1 to be refused by "Region Code" — the relation must be filtered to regions whose Blocked is false', SalesRegion.Code));

        // [THEN] the error is the platform's own relation failure, naming the Sales Region table
        Assert.ExpectedError('cannot be found in the related table');
        Assert.ExpectedError('Sales Region');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownRegionIsRejectedOnTheCustomer()
    var
        Customer: Record Customer;
        FreeCode: Code[10];
    begin
        // [SCENARIO] A code that no sales region carries is refused by the relation itself
        // [GIVEN] a customer and a generated code that belongs to no region
        LibrarySales.CreateCustomer(Customer);
        FreeCode := LibraryUtility.GenerateGUID();

        // [WHEN] validating "Region Code" with that code
        if TryValidateRegionCode(Customer, FreeCode) then
            Assert.Fail(StrSubstNo('Expected code %1, which no sales region carries, to be refused by "Region Code"', FreeCode));

        // [THEN] the error is the platform's own relation failure, naming the Sales Region table
        Assert.ExpectedError('cannot be found in the related table');
        Assert.ExpectedError('Sales Region');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignedRegionBypassesTheRelationOnModify()
    var
        Customer: Record Customer;
        StoredCustomer: Record Customer;
        SalesRegion: Record "Sales Region";
    begin
        // [SCENARIO] The relation is enforced by Validate only — a plain assignment followed by Modify stores a blocked region
        // [GIVEN] a blocked sales region and a customer
        CreateSalesRegion(SalesRegion, true);
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] assigning the blocked region and calling Modify with triggers
        Customer."Region Code" := SalesRegion.Code;
        Customer.Modify(true);

        // [THEN] the blocked region is stored and no error was raised
        StoredCustomer.Get(Customer."No.");
        Assert.AreEqual(SalesRegion.Code, StoredCustomer."Region Code",
            'Expected a plain assignment plus Modify to store a blocked region — the table relation is checked by Validate only, and nothing else may refuse the write');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VariantCodeRelatesToTheCodeOfItemVariant()
    var
        FieldRec: Record Field;
        ItemVariant: Record "Item Variant";
    begin
        // [SCENARIO] The relation is declared on the field, not hand-written in a trigger
        // [GIVEN] the "Stock Count Line" table
        FieldRec.SetRange(TableNo, Database::"Stock Count Line");
        FieldRec.SetRange(FieldName, 'Variant Code');

        // [WHEN] reading the field's metadata
        Assert.IsTrue(FieldRec.FindFirst(),
            'Expected the "Stock Count Line" table to carry a field named exactly "Variant Code"');

        // [THEN] it relates to the Code field of Item Variant
        Assert.AreEqual(Database::"Item Variant", FieldRec.RelationTableNo,
            'Expected "Variant Code" to carry a table relation to "Item Variant" — the relation is what both the lookup and the validation are built on');
        Assert.AreEqual(ItemVariant.FieldNo(Code), FieldRec.RelationFieldNo,
            'Expected "Variant Code" to relate to the Code field of "Item Variant" — name the field the value is matched against, the table alone is not enough');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RegionCodeRelatesToTheSalesRegionTable()
    var
        FieldRec: Record Field;
    begin
        // [SCENARIO] The relation is declared on the extension field, not hand-written in a trigger
        // [GIVEN] the Customer table
        FieldRec.SetRange(TableNo, Database::Customer);
        FieldRec.SetRange(FieldName, 'Region Code');

        // [WHEN] reading the field's metadata
        Assert.IsTrue(FieldRec.FindFirst(),
            'Expected the Customer table to carry a field named exactly "Region Code"');

        // [THEN] it relates to Sales Region
        Assert.AreEqual(Database::"Sales Region", FieldRec.RelationTableNo,
            'Expected "Region Code" to carry a table relation to "Sales Region" — the relation is what both the lookup and the validation are built on');
    end;

    local procedure CreateLineForItem(var StockCountLine: Record "Stock Count Line"; DocumentNo: Code[20]; ItemNo: Code[20])
    begin
        StockCountLine.Init();
        StockCountLine."Document No." := DocumentNo;
        StockCountLine."Line No." := 10000;
        StockCountLine.Validate("Item No.", ItemNo);
        StockCountLine.Insert();
    end;

    // The variant is assigned, not validated, so a broken relation cannot fail
    // the arrangement of the tests that grade the clearing rule.
    local procedure CreateStoredLine(var StockCountLine: Record "Stock Count Line"; DocumentNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        CreateLineForItem(StockCountLine, DocumentNo, ItemNo);
        StockCountLine."Variant Code" := VariantCode;
        StockCountLine.Modify();
        StockCountLine.Get(DocumentNo, 10000);
    end;

    local procedure CreateItemWithVariant(var Item: Record Item; var ItemVariant: Record "Item Variant")
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
    end;

    local procedure CreateSalesRegion(var SalesRegion: Record "Sales Region"; Blocked: Boolean)
    begin
        SalesRegion.Init();
        SalesRegion.Code := LibraryUtility.GenerateGUID();
        SalesRegion.Description := SalesRegion.Code;
        SalesRegion.Blocked := Blocked;
        SalesRegion.Insert();
    end;

    [TryFunction]
    local procedure TryValidateVariantCode(var StockCountLine: Record "Stock Count Line"; VariantCode: Code[10])
    begin
        StockCountLine.Validate("Variant Code", VariantCode);
    end;

    [TryFunction]
    local procedure TryValidateRegionCode(var Customer: Record Customer; RegionCode: Code[10])
    begin
        Customer.Validate("Region Code", RegionCode);
    end;
}
