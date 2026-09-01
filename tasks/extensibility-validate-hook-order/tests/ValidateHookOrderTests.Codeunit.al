codeunit 50900 "Validate Hook Order Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Sales Line] [Validate hook order]

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        PickLabelFieldTok: Label 'Pick Label', Locked = true;
        PreviousDescriptionFieldTok: Label 'Previous Description', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PuttingAnItemOnALineStampsTheUppercasedDescription()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        Any: Codeunit Any;
    begin
        // [SCENARIO] Validating "No." on a new line stamps the line's description, in upper case, into "Pick Label"
        // [GIVEN] an item whose description is generated lowercase text
        CreateItemWithDescription(Item, Any.AlphabeticText(40));

        // [WHEN] adding a sales order line for that item, which validates "No."
        CreateOrderLineForItem(SalesLine, Item."No.");

        // [THEN] the line carries the description of the item that arrived, in upper case
        Assert.AreEqual(UpperCase(Item.Description), GetPickLabel(SalesLine),
            'Expected "Pick Label" to hold the line''s description in upper case once validating "No." has finished');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ANewLineCarriesNoPreviousDescription()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        Any: Codeunit Any;
    begin
        // [SCENARIO] The first item on a fresh line replaces nothing, so there is no previous description
        // [GIVEN] an item whose description is generated lowercase text
        CreateItemWithDescription(Item, Any.AlphabeticText(40));

        // [WHEN] adding a sales order line for that item, whose description is still blank when "No." is validated
        CreateOrderLineForItem(SalesLine, Item."No.");

        // [THEN] "Previous Description" stays blank
        Assert.AreEqual('', GetPreviousDescription(SalesLine),
            'Expected "Previous Description" to stay blank on a line that carried no description before "No." was validated');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SwitchingTheItemKeepsTheDescriptionItReplaced()
    var
        FirstItem: Record Item;
        SecondItem: Record Item;
        SalesLine: Record "Sales Line";
        Any: Codeunit Any;
    begin
        // [SCENARIO] Re-validating "No." records the description the line carried before that validation
        // [GIVEN] a sales order line for one item, and a second item to switch to
        CreateItemWithDescription(FirstItem, Any.AlphabeticText(40));
        CreateItemWithDescription(SecondItem, Any.AlphabeticText(40));
        CreateOrderLineForItem(SalesLine, FirstItem."No.");

        // [WHEN] re-validating "No." to the second item and saving the line
        SalesLine.Validate("No.", SecondItem."No.");
        SalesLine.Modify(true);

        // [THEN] the stored line keeps the description it replaced
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(FirstItem.Description, GetPreviousDescription(SalesLine),
            'Expected "Previous Description" on the saved line to hold the description the line carried before "No." was re-validated');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SwitchingTheItemRestampsThePickLabel()
    var
        FirstItem: Record Item;
        SecondItem: Record Item;
        SalesLine: Record "Sales Line";
        Any: Codeunit Any;
    begin
        // [SCENARIO] Re-validating "No." stamps the label of the item that just arrived
        // [GIVEN] a sales order line for one item, and a second item to switch to
        CreateItemWithDescription(FirstItem, Any.AlphabeticText(40));
        CreateItemWithDescription(SecondItem, Any.AlphabeticText(40));
        CreateOrderLineForItem(SalesLine, FirstItem."No.");

        // [WHEN] re-validating "No." to the second item
        SalesLine.Validate("No.", SecondItem."No.");

        // [THEN] the label describes the second item, not the first
        Assert.AreEqual(UpperCase(SecondItem.Description), GetPickLabel(SalesLine),
            'Expected "Pick Label" to be restamped with the new item''s description in upper case when "No." is re-validated');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SecondSwitchBeforeSavingKeepsTheDescriptionItJustReplaced()
    var
        FirstItem: Record Item;
        SecondItem: Record Item;
        ThirdItem: Record Item;
        SalesLine: Record "Sales Line";
        Any: Codeunit Any;
    begin
        // [SCENARIO] Two validations in a row, without saving, still record the description of the moment before
        // [GIVEN] a line already switched from the first to the second item, not saved since
        CreateItemWithDescription(FirstItem, Any.AlphabeticText(40));
        CreateItemWithDescription(SecondItem, Any.AlphabeticText(40));
        CreateItemWithDescription(ThirdItem, Any.AlphabeticText(40));
        CreateOrderLineForItem(SalesLine, FirstItem."No.");
        SalesLine.Validate("No.", SecondItem."No.");

        // [WHEN] re-validating "No." a second time, to the third item
        SalesLine.Validate("No.", ThirdItem."No.");

        // [THEN] "Previous Description" holds the second item's description — what the line carried a moment
        // earlier — and not the first item's, which is what the database still stores
        Assert.AreEqual(SecondItem.Description, GetPreviousDescription(SalesLine),
            'Expected "Previous Description" to hold the description the line carried immediately before this validation, not the one last saved to the database');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidatingAnotherFieldLeavesBothFieldsUntouched()
    var
        FirstItem: Record Item;
        SecondItem: Record Item;
        SalesLine: Record "Sales Line";
        Any: Codeunit Any;
    begin
        // [SCENARIO] Only validating "No." maintains the two fields
        // [GIVEN] a line switched from the first to the second item, so both fields carry values
        CreateItemWithDescription(FirstItem, Any.AlphabeticText(40));
        CreateItemWithDescription(SecondItem, Any.AlphabeticText(40));
        CreateOrderLineForItem(SalesLine, FirstItem."No.");
        SalesLine.Validate("No.", SecondItem."No.");

        // [WHEN] validating an unrelated field on the same line
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 500, 2));

        // [THEN] both fields still describe the last validation of "No."
        Assert.AreEqual(FirstItem.Description, GetPreviousDescription(SalesLine),
            'Expected validating a field other than "No." to leave "Previous Description" alone');
        Assert.AreEqual(UpperCase(SecondItem.Description), GetPickLabel(SalesLine),
            'Expected validating a field other than "No." to leave "Pick Label" alone');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssigningTheItemNoWithoutValidatingChangesNothing()
    var
        FirstItem: Record Item;
        SecondItem: Record Item;
        ThirdItem: Record Item;
        SalesLine: Record "Sales Line";
        Any: Codeunit Any;
    begin
        // [SCENARIO] A plain assignment to "No." runs no validation at all, so neither field moves
        // [GIVEN] a line switched from the first to the second item, so both fields carry values
        CreateItemWithDescription(FirstItem, Any.AlphabeticText(40));
        CreateItemWithDescription(SecondItem, Any.AlphabeticText(40));
        CreateItemWithDescription(ThirdItem, Any.AlphabeticText(40));
        CreateOrderLineForItem(SalesLine, FirstItem."No.");
        SalesLine.Validate("No.", SecondItem."No.");

        // [WHEN] assigning "No." directly, without validating
        SalesLine."No." := ThirdItem."No.";

        // [THEN] both fields still describe the last validation of "No."
        Assert.AreEqual(FirstItem.Description, GetPreviousDescription(SalesLine),
            'Expected assigning "No." without validating to leave "Previous Description" alone');
        Assert.AreEqual(UpperCase(SecondItem.Description), GetPickLabel(SalesLine),
            'Expected assigning "No." without validating to leave "Pick Label" alone');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BothFieldsAreDeclaredAsTextHundred()
    var
        RecRef: RecordRef;
    begin
        // [SCENARIO] Both fields are declared exactly as promised
        RecRef.Open(Database::"Sales Line");
        VerifyFieldIsTextHundred(FieldByName(RecRef, PickLabelFieldTok));
        VerifyFieldIsTextHundred(FieldByName(RecRef, PreviousDescriptionFieldTok));
    end;

    local procedure VerifyFieldIsTextHundred(FldRef: FieldRef)
    begin
        Assert.IsTrue(FldRef.Type() = FieldType::Text,
            StrSubstNo('Expected the Sales Line field "%1" to be declared as Text[100], not %2[%3]', FldRef.Name(), FldRef.Type(), FldRef.Length()));
        Assert.AreEqual(100, FldRef.Length(),
            StrSubstNo('Expected "%1" on Sales Line to be declared as Text[100] — its maximum length must be exactly 100', FldRef.Name()));
    end;

    local procedure FieldByName(var RecRef: RecordRef; FieldName: Text): FieldRef
    var
        Index: Integer;
    begin
        // Looked up by name at run time so the tests compile against a starter that
        // has not added the fields yet, and fail with a message that names them.
        for Index := 1 to RecRef.FieldCount() do
            if RecRef.FieldIndex(Index).Name() = FieldName then
                exit(RecRef.FieldIndex(Index));
        Assert.Fail(StrSubstNo('Expected table %1 to have a field named "%2"', RecRef.Name(), FieldName));
    end;

    local procedure GetPickLabel(SalesLine: Record "Sales Line") PickLabel: Text
    var
        RecRef: RecordRef;
    begin
        // GetTable copies the record's in-memory buffer, so this reads the value exactly
        // as the validation left it — nothing is re-read from the database.
        RecRef.GetTable(SalesLine);
        PickLabel := FieldByName(RecRef, PickLabelFieldTok).Value();
    end;

    local procedure GetPreviousDescription(SalesLine: Record "Sales Line") PreviousDescription: Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SalesLine);
        PreviousDescription := FieldByName(RecRef, PreviousDescriptionFieldTok).Value();
    end;

    local procedure CreateItemWithDescription(var Item: Record Item; NewDescription: Text)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Description := CopyStr(NewDescription, 1, MaxStrLen(Item.Description));
        Item.Modify();
    end;

    local procedure CreateOrderLineForItem(var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
    end;
}
