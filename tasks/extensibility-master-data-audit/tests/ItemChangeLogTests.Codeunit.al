codeunit 50905 "Item Change Log Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Item] [Change Log]

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertWritesOneRowPerAuditedFieldWithABlankOldValue()
    var
        ItemChangeEntry: Record "Item Change Entry";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        UnitPrice: Decimal;
        ItemDescription: Text[100];
    begin
        // [SCENARIO] Inserting an item opens the chain: one row per audited field, old value blank
        UnitPrice := Any.DecimalInRange(10, 500, 2);
        ItemDescription := CopyStr(Any.AlphabeticText(40), 1, MaxStrLen(ItemDescription));

        // [WHEN] inserting an item with that price and description
        CreateItem('TRYAL-M1', UnitPrice, ItemDescription);

        // [THEN] exactly two rows exist for the item — one per audited field, each with a blank old value
        ItemChangeEntry.SetRange("Item No.", 'TRYAL-M1');
        Assert.AreEqual(2, ItemChangeEntry.Count(),
            'Expected exactly two "Item Change Entry" rows after inserting an item — one for "Unit Price" and one for Description');

        ItemChangeEntry.SetRange("Field Name", 'Unit Price');
        Assert.AreEqual(1, ItemChangeEntry.Count(),
            'Expected exactly one "Item Change Entry" row with "Field Name" = ''Unit Price'' after inserting an item');
        ItemChangeEntry.FindFirst();
        VerifyOldAndNew(ItemChangeEntry, '', Format(UnitPrice), 'the "Unit Price" row written on insert');

        ItemChangeEntry.SetRange("Field Name", 'Description');
        Assert.AreEqual(1, ItemChangeEntry.Count(),
            'Expected exactly one "Item Change Entry" row with "Field Name" = ''Description'' after inserting an item');
        ItemChangeEntry.FindFirst();
        VerifyOldAndNew(ItemChangeEntry, '', ItemDescription, 'the Description row written on insert');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TwoPriceChangesChainOldToNewThroughTheLog()
    var
        Item: Record Item;
        ItemChangeEntry: Record "Item Change Entry";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        PriceOnInsert: Decimal;
        FirstNewPrice: Decimal;
        SecondNewPrice: Decimal;
    begin
        // [SCENARIO] Reading the "Unit Price" rows in "Entry No." order tells the price's full history
        // [GIVEN] an item inserted with a starting price
        PriceOnInsert := Any.DecimalInRange(10, 500, 2);
        FirstNewPrice := PriceOnInsert + Any.DecimalInRange(1, 50, 2);
        SecondNewPrice := FirstNewPrice + Any.DecimalInRange(1, 50, 2);
        CreateItem('TRYAL-M2', PriceOnInsert, 'Chain test item');

        // [WHEN] changing the price twice
        Item.Get('TRYAL-M2');
        Item."Unit Price" := FirstNewPrice;
        Item.Modify(true);
        Item.Get('TRYAL-M2');
        Item."Unit Price" := SecondNewPrice;
        Item.Modify(true);

        // [THEN] three "Unit Price" rows chain old to new: blank -> insert price -> first change -> second change
        ItemChangeEntry.SetRange("Item No.", 'TRYAL-M2');
        ItemChangeEntry.SetRange("Field Name", 'Unit Price');
        Assert.AreEqual(3, ItemChangeEntry.Count(),
            'Expected exactly three "Unit Price" rows for the item: the insert row plus one row per price change');
        ItemChangeEntry.FindSet();
        VerifyOldAndNew(ItemChangeEntry, '', Format(PriceOnInsert), 'the first "Unit Price" row (written on insert)');
        ItemChangeEntry.Next();
        VerifyOldAndNew(ItemChangeEntry, Format(PriceOnInsert), Format(FirstNewPrice), 'the second "Unit Price" row (first change) — the old value must be what the database stored before the modify, not what the record instance happens to hold');
        ItemChangeEntry.Next();
        VerifyOldAndNew(ItemChangeEntry, Format(FirstNewPrice), Format(SecondNewPrice), 'the third "Unit Price" row (second change) — the old value must be what the database stored before the modify, not what the record instance happens to hold');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ModifyThatChangesNothingWritesNoRow()
    var
        Item: Record Item;
        Assert: Codeunit Assert;
        RowsBefore: Integer;
    begin
        // [SCENARIO] A modify that leaves both audited fields as they were is not a change
        // [GIVEN] an inserted item
        CreateItem('TRYAL-M3', 100, 'Unchanged item');
        RowsBefore := RowsForItem('TRYAL-M3');

        // [WHEN] modifying it without changing anything
        Item.Get('TRYAL-M3');
        Item.Modify(true);

        // [THEN] no new row appeared
        Assert.AreEqual(RowsBefore, RowsForItem('TRYAL-M3'),
            'Expected no new "Item Change Entry" row for a Modify that changed neither "Unit Price" nor Description — log a field only when its stored value actually changed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ModifyWithRunTriggerFalseStillWritesTheRow()
    var
        Item: Record Item;
        ItemChangeEntry: Record "Item Change Entry";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        PriceOnInsert: Decimal;
        NewPrice: Decimal;
    begin
        // [SCENARIO] Modify(false) skips the table triggers, not the audit
        // [GIVEN] an item inserted with a starting price
        PriceOnInsert := Any.DecimalInRange(10, 500, 2);
        NewPrice := PriceOnInsert + Any.DecimalInRange(1, 50, 2);
        CreateItem('TRYAL-M4', PriceOnInsert, 'Trigger-suppressed item');

        // [WHEN] changing the price with Modify(false)
        Item.Get('TRYAL-M4');
        Item."Unit Price" := NewPrice;
        Item.Modify(false);

        // [THEN] the change row is there all the same — and it is the only change row for the item
        ItemChangeEntry.SetRange("Item No.", 'TRYAL-M4');
        ItemChangeEntry.SetFilter("Old Value", '<>%1', '');
        Assert.AreEqual(1, ItemChangeEntry.Count(),
            'Expected exactly one change row for a Modify that changed only "Unit Price" — a row per audited field is written only when that field''s stored value changed');
        ItemChangeEntry.SetRange("Field Name", 'Unit Price');
        Assert.AreEqual(1, ItemChangeEntry.Count(),
            'Expected exactly one "Unit Price" change row after Modify(false) — the platform reports the write to your audit whether or not the table triggers ran');
        ItemChangeEntry.FindFirst();
        VerifyOldAndNew(ItemChangeEntry, Format(PriceOnInsert), Format(NewPrice), 'the change row written for a Modify(false)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateWithoutModifyWritesNoRow()
    var
        Item: Record Item;
        Assert: Codeunit Assert;
        RowsBefore: Integer;
    begin
        // [SCENARIO] A Validate the database never saw leaves no trace
        // [GIVEN] an inserted item
        CreateItem('TRYAL-M5', 100, 'Validated-only item');
        RowsBefore := RowsForItem('TRYAL-M5');

        // [WHEN] validating a new price without ever calling Modify
        Item.Get('TRYAL-M5');
        Item.Validate("Unit Price", 250);

        // [THEN] no new row appeared
        Assert.AreEqual(RowsBefore, RowsForItem('TRYAL-M5'),
            'Expected no "Item Change Entry" row for a Validate that was never followed by Modify — the database never saw that change, so an audit hooked to field validation logs history that does not exist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DescriptionChangeIsAuditedWithOldAndNewValue()
    var
        Item: Record Item;
        ItemChangeEntry: Record "Item Change Entry";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NewDescription: Text[100];
    begin
        // [SCENARIO] Description is the second audited field, diffed like the price
        // [GIVEN] an item inserted with a known description
        NewDescription := CopyStr(Any.AlphabeticText(40), 1, MaxStrLen(NewDescription));
        CreateItem('TRYAL-M6', 100, 'Original description');

        // [WHEN] changing the description
        Item.Get('TRYAL-M6');
        Item.Description := NewDescription;
        Item.Modify(true);

        // [THEN] one Description change row carries the old and the new text — and it is the only change row for the item
        ItemChangeEntry.SetRange("Item No.", 'TRYAL-M6');
        ItemChangeEntry.SetFilter("Old Value", '<>%1', '');
        Assert.AreEqual(1, ItemChangeEntry.Count(),
            'Expected exactly one change row for a Modify that changed only Description — a row per audited field is written only when that field''s stored value changed');
        ItemChangeEntry.SetRange("Field Name", 'Description');
        Assert.AreEqual(1, ItemChangeEntry.Count(),
            'Expected exactly one Description change row after modifying the description');
        ItemChangeEntry.FindFirst();
        VerifyOldAndNew(ItemChangeEntry, 'Original description', NewDescription, 'the Description change row');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChangingBothFieldsInOneModifyWritesOneRowPerField()
    var
        Item: Record Item;
        ItemChangeEntry: Record "Item Change Entry";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        PriceOnInsert: Decimal;
        NewPrice: Decimal;
        NewDescription: Text[100];
    begin
        // [SCENARIO] One modify touching both audited fields produces one row per field, not one per modify
        // [GIVEN] an inserted item
        PriceOnInsert := Any.DecimalInRange(10, 500, 2);
        NewPrice := PriceOnInsert + Any.DecimalInRange(1, 50, 2);
        NewDescription := CopyStr(Any.AlphabeticText(40), 1, MaxStrLen(NewDescription));
        CreateItem('TRYAL-M7', PriceOnInsert, 'Both-fields item');

        // [WHEN] changing the price and the description in a single Modify
        Item.Get('TRYAL-M7');
        Item."Unit Price" := NewPrice;
        Item.Description := NewDescription;
        Item.Modify(true);

        // [THEN] exactly one change row per audited field, each with its own old and new value
        ItemChangeEntry.SetRange("Item No.", 'TRYAL-M7');
        ItemChangeEntry.SetFilter("Old Value", '<>%1', '');
        Assert.AreEqual(2, ItemChangeEntry.Count(),
            'Expected exactly two change rows for a single Modify that changed both "Unit Price" and Description — one row per changed field');

        ItemChangeEntry.SetRange("Field Name", 'Unit Price');
        Assert.AreEqual(1, ItemChangeEntry.Count(),
            'Expected exactly one "Unit Price" change row for the combined modify');
        ItemChangeEntry.FindFirst();
        VerifyOldAndNew(ItemChangeEntry, Format(PriceOnInsert), Format(NewPrice), 'the "Unit Price" row of the combined modify');

        ItemChangeEntry.SetRange("Field Name", 'Description');
        Assert.AreEqual(1, ItemChangeEntry.Count(),
            'Expected exactly one Description change row for the combined modify');
        ItemChangeEntry.FindFirst();
        VerifyOldAndNew(ItemChangeEntry, 'Both-fields item', NewDescription, 'the Description row of the combined modify');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChangingANonAuditedFieldWritesNoRow()
    var
        Item: Record Item;
        Assert: Codeunit Assert;
        RowsBefore: Integer;
    begin
        // [SCENARIO] Only the two audited fields are logged — other Item fields change silently
        // [GIVEN] an inserted item
        CreateItem('TRYAL-M8', 100, 'Non-audited change item');
        RowsBefore := RowsForItem('TRYAL-M8');

        // [WHEN] changing a field outside the audit
        Item.Get('TRYAL-M8');
        Item."Vendor Item No." := 'TRYAL-VENDOR-REF';
        Item.Modify(true);

        // [THEN] no new row appeared
        Assert.AreEqual(RowsBefore, RowsForItem('TRYAL-M8'),
            'Expected no "Item Change Entry" row for a Modify that changed only "Vendor Item No." — only "Unit Price" and Description are audited');
    end;

    local procedure CreateItem(ItemNo: Code[20]; UnitPrice: Decimal; ItemDescription: Text[100])
    var
        Item: Record Item;
    begin
        Item.Init();
        Item."No." := ItemNo;
        Item."Unit Price" := UnitPrice;
        Item.Description := ItemDescription;
        Item.Insert(false);
    end;

    local procedure RowsForItem(ItemNo: Code[20]): Integer
    var
        ItemChangeEntry: Record "Item Change Entry";
    begin
        ItemChangeEntry.SetRange("Item No.", ItemNo);
        exit(ItemChangeEntry.Count());
    end;

    local procedure VerifyOldAndNew(ItemChangeEntry: Record "Item Change Entry"; ExpectedOldValue: Text; ExpectedNewValue: Text; RowDescription: Text)
    var
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(ExpectedOldValue, ItemChangeEntry."Old Value",
            StrSubstNo('Unexpected "Old Value" on %1', RowDescription));
        Assert.AreEqual(ExpectedNewValue, ItemChangeEntry."New Value",
            StrSubstNo('Unexpected "New Value" on %1', RowDescription));
    end;
}
