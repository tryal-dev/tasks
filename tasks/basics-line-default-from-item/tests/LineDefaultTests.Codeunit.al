codeunit 50900 "Line Default Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidatingTheItemNoPullsItsGradeOntoTheLine()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        Any: Codeunit Any;
        Grade: Code[10];
    begin
        // [SCENARIO] Choosing an item on a sales line stamps the item's quality grade onto the line
        // [GIVEN] an item carrying a generated quality grade
        Grade := CopyStr(Any.AlphabeticText(MaxStrLen(Grade)), 1, MaxStrLen(Grade));
        CreateItemWithGrade(Item, Grade);

        // [WHEN] adding a sales order line for that item (which validates "No.")
        CreateOrderLineForItem(SalesLine, Item."No.");

        // [THEN] the line carries the item's grade
        Assert.AreEqual(Grade, GradeOnLine(SalesLine),
            StrSubstNo('Expected validating "No." with item %1 to copy the item''s "Quality Grade" onto the sales line', Item."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ItemWithoutAGradeLeavesTheLineBlank()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] An item that carries no grade produces a line with a blank grade
        // [GIVEN] an item whose "Quality Grade" is blank
        LibraryInventory.CreateItem(Item);

        // [WHEN] adding a sales order line for that item
        CreateOrderLineForItem(SalesLine, Item."No.");

        // [THEN] the line's grade is blank
        Assert.AreEqual('', GradeOnLine(SalesLine),
            StrSubstNo('Expected a blank "Quality Grade" on the line when item %1 has none', Item."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RevalidatingToAnotherItemOverwritesTheGrade()
    var
        FirstItem: Record Item;
        SecondItem: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Switching the line to another item replaces the grade with the new item's grade
        // [GIVEN] a line for an item graded GRADE-A, and a second item graded GRADE-B
        CreateItemWithGrade(FirstItem, 'GRADE-A');
        CreateItemWithGrade(SecondItem, 'GRADE-B');
        CreateOrderLineForItem(SalesLine, FirstItem."No.");

        // [WHEN] re-validating "No." to the second item
        SalesLine.Validate("No.", SecondItem."No.");

        // [THEN] the line now carries the second item's grade
        Assert.AreEqual('GRADE-B', GradeOnLine(SalesLine),
            'Expected re-validating "No." to another item to overwrite the line''s "Quality Grade" with the new item''s grade');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RevalidatingToAGradelessItemClearsTheLine()
    var
        GradedItem: Record Item;
        GradelessItem: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] The line mirrors the item that is on it — switching to a gradeless item clears the grade
        // [GIVEN] a line for a graded item, and a second item without a grade
        CreateItemWithGrade(GradedItem, 'GRADE-A');
        LibraryInventory.CreateItem(GradelessItem);
        CreateOrderLineForItem(SalesLine, GradedItem."No.");

        // [WHEN] re-validating "No." to the gradeless item
        SalesLine.Validate("No.", GradelessItem."No.");

        // [THEN] the line's grade is blank again
        Assert.AreEqual('', GradeOnLine(SalesLine),
            StrSubstNo('Expected the line''s "Quality Grade" to be cleared when "No." is re-validated to item %1, which has no grade — the line must always mirror its item', GradelessItem."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GradeFieldsAreDeclaredAsCodeTen()
    begin
        // [SCENARIO] Both "Quality Grade" fields are declared exactly as promised
        VerifyGradeFieldIsCodeTen(Database::Item);
        VerifyGradeFieldIsCodeTen(Database::"Sales Line");
    end;

    local procedure VerifyGradeFieldIsCodeTen(TableNo: Integer)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(TableNo);
        FldRef := FieldByName(RecRef, 'Quality Grade');
        Assert.AreEqual(Format(FieldType::Code), Format(FldRef.Type()),
            StrSubstNo('Expected the %1 field "Quality Grade" to be declared as Code[10], not %2[10]', RecRef.Name(), FldRef.Type()));
        Assert.AreEqual(10, FldRef.Length(),
            StrSubstNo('Expected the %1 field "Quality Grade" to be declared as Code[10] — its maximum length must be exactly 10', RecRef.Name()));
    end;

    local procedure CreateItemWithGrade(var Item: Record Item; Grade: Code[10])
    var
        RecRef: RecordRef;
    begin
        LibraryInventory.CreateItem(Item);
        RecRef.GetTable(Item);
        FieldByName(RecRef, 'Quality Grade').Value := Grade;
        RecRef.Modify();
        RecRef.SetTable(Item);
    end;

    local procedure GradeOnLine(var SalesLine: Record "Sales Line"): Code[10]
    var
        RecRef: RecordRef;
        Grade: Code[10];
    begin
        RecRef.GetTable(SalesLine);
        Grade := FieldByName(RecRef, 'Quality Grade').Value();
        exit(Grade);
    end;

    local procedure CreateOrderLineForItem(var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
    end;

    // Both "Quality Grade" fields are the user's to add, so the tests reach them by name
    // at run time instead of binding to them at compile time.
    local procedure FieldByName(var RecRef: RecordRef; FieldName: Text): FieldRef
    var
        FldRef: FieldRef;
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            if FldRef.Name() = FieldName then
                exit(FldRef);
        end;
        Assert.Fail(StrSubstNo('Expected table %1 to have a field named "%2"', RecRef.Name(), FieldName));
    end;
}
