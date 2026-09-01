codeunit 50900 "Shelf Totals Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShelfTotalAddsEveryMovementOnTheShelf()
    var
        ShelfTotals: Codeunit "Shelf Totals";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Qty1: Decimal;
        Qty2: Decimal;
        Qty3: Decimal;
    begin
        // [SCENARIO] The shelf total spans every item on the shelf
        Qty1 := Any.DecimalInRange(10, 900, 2);
        Qty2 := Any.DecimalInRange(10, 900, 2);
        Qty3 := Any.DecimalInRange(10, 900, 2);
        InsertMovement('TRYAL-S1', 'TRYAL-ITEM-A', Qty1);
        InsertMovement('TRYAL-S1', 'TRYAL-ITEM-A', Qty2);
        InsertMovement('TRYAL-S1', 'TRYAL-ITEM-B', Qty3);

        Assert.AreEqual(Qty1 + Qty2 + Qty3, ShelfTotals.QuantityOnShelf('TRYAL-S1'),
            'Expected the shelf total to add up every movement of every item on the shelf');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShelvesAreKeptSeparate()
    var
        ShelfTotals: Codeunit "Shelf Totals";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        QtyA: Decimal;
        QtyB: Decimal;
    begin
        // [SCENARIO] A shelf's total contains only its own movements
        QtyA := Any.DecimalInRange(10, 900, 2);
        QtyB := Any.DecimalInRange(1000, 2000, 2);
        InsertMovement('TRYAL-S2A', 'TRYAL-ITEM-A', QtyA);
        InsertMovement('TRYAL-S2B', 'TRYAL-ITEM-A', QtyB);

        Assert.AreEqual(QtyA, ShelfTotals.QuantityOnShelf('TRYAL-S2A'),
            'Expected shelf A''s total to contain only shelf A''s movements');
        Assert.AreEqual(QtyB, ShelfTotals.QuantityOnShelf('TRYAL-S2B'),
            'Expected shelf B''s total to contain only shelf B''s movements');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PicksReduceTheShelfTotal()
    var
        ShelfTotals: Codeunit "Shelf Totals";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        PutAwayQty: Decimal;
        PickQty: Decimal;
    begin
        // [SCENARIO] Negative movements (picks) reduce the total
        PutAwayQty := Any.DecimalInRange(500, 900, 2);
        PickQty := Any.DecimalInRange(100, 400, 2);
        InsertMovement('TRYAL-S3', 'TRYAL-ITEM-A', PutAwayQty);
        InsertMovement('TRYAL-S3', 'TRYAL-ITEM-A', -PickQty);

        Assert.AreEqual(PutAwayQty - PickQty, ShelfTotals.QuantityOnShelf('TRYAL-S3'),
            'Expected the negative movement (a pick) to reduce the shelf total, not to be skipped');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ItemTotalCountsOnlyThatItemOnThatShelf()
    var
        ShelfTotals: Codeunit "Shelf Totals";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TargetQty: Decimal;
        PickQty: Decimal;
    begin
        // [SCENARIO] The item total ignores other items and the same item on other shelves,
        // and negative movements (picks) of the item reduce it
        TargetQty := Any.DecimalInRange(500, 900, 2);
        PickQty := Any.DecimalInRange(100, 400, 2);
        InsertMovement('TRYAL-S4', 'TRYAL-ITEM-T', TargetQty);
        InsertMovement('TRYAL-S4', 'TRYAL-ITEM-T', -PickQty);
        InsertMovement('TRYAL-S4', 'TRYAL-ITEM-O', Any.DecimalInRange(10, 900, 2));
        InsertMovement('TRYAL-S4B', 'TRYAL-ITEM-T', Any.DecimalInRange(10, 900, 2));

        Assert.AreEqual(TargetQty - PickQty, ShelfTotals.QuantityOnShelfForItem('TRYAL-S4', 'TRYAL-ITEM-T'),
            'Expected the item total to count only that item on that shelf — a pick of the item reduces it, while the neighbouring item and the same item on another shelf must stay out');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyShelfTotalsZero()
    var
        ShelfTotals: Codeunit "Shelf Totals";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A shelf without a single movement totals exactly 0 without erroring
        Assert.AreEqual(0.0, ShelfTotals.QuantityOnShelf('TRYAL-S5'),
            'Expected a shelf with no movements at all to total exactly 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ItemWithNoMovementsOnTheShelfTotalsZero()
    var
        ShelfTotals: Codeunit "Shelf Totals";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] An item absent from the shelf totals 0 even though the shelf holds other items
        InsertMovement('TRYAL-S6', 'TRYAL-ITEM-O', Any.DecimalInRange(10, 900, 2));

        Assert.AreEqual(0.0, ShelfTotals.QuantityOnShelfForItem('TRYAL-S6', 'TRYAL-ITEM-N'),
            'Expected 0 for an item with no movements on the shelf, even though the shelf holds other items');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeclaresAMaintainedSiftKeyOnShelfAndItem()
    var
        TableKey: Record "Key";
        Assert: Codeunit Assert;
        DeclaredKeys: Text;
    begin
        // [SCENARIO] The table carries the promised SIFT key: field list starting with
        // Shelf Code, Item No., Quantity among the SumIndexFields, enabled and maintained
        TableKey.SetRange(TableNo, Database::"Shelf Movement Entry");
        if TableKey.FindSet() then
            repeat
                if IsContractSiftKey(TableKey) then
                    exit;
                DeclaredKeys += StrSubstNo('[%1; SumIndexFields: %2; Enabled: %3; MaintainSiftIndex: %4] ',
                    TableKey."Key", TableKey.SumIndexFields, TableKey.Enabled, TableKey.MaintainSIFTIndex);
            until TableKey.Next() = 0;
        Assert.Fail(StrSubstNo('Expected an enabled, SIFT-maintained key whose field list starts with "Shelf Code", "Item No." and whose SumIndexFields include Quantity — without it the totals are re-computed from the rows on every ask. Keys found on the table: %1', DeclaredKeys));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShelfTotalStaysWithinTheRowBudget()
    var
        ShelfTotals: Codeunit "Shelf Totals";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemCount: Integer;
        EntriesPerItem: Integer;
        MaxRows: Integer;
        i: Integer;
        j: Integer;
        Qty: Decimal;
        ExpectedTotal: Decimal;
        Total: Decimal;
        RowsBefore: BigInteger;
        RowsUsed: BigInteger;
    begin
        // [SCENARIO] One shelf total reads at most 25 rows however many movements the shelf holds
        MaxRows := 25;
        ItemCount := Any.IntegerInRange(10, 14);
        EntriesPerItem := Any.IntegerInRange(20, 30);
        for i := 1 to ItemCount do
            for j := 1 to EntriesPerItem do begin
                Qty := Any.DecimalInRange(1, 9, 2);
                ExpectedTotal += Qty;
                InsertMovement('TRYAL-S7', StrSubstNo('TRYAL-I%1', i), Qty);
            end;

        // warm-up: the first call may pay one-time metadata reads; grade the steady state
        ShelfTotals.QuantityOnShelf('TRYAL-S7');
        InvalidateDataCache();
        RowsBefore := SessionInformation.SqlRowsRead();
        Total := ShelfTotals.QuantityOnShelf('TRYAL-S7');
        RowsUsed := SessionInformation.SqlRowsRead() - RowsBefore;

        Assert.AreEqual(ExpectedTotal, Total,
            StrSubstNo('Expected the shelf total to stay correct while fitting the budget — %1 movements were seeded on the shelf', ItemCount * EntriesPerItem));
        Assert.IsTrue(RowsUsed <= MaxRows,
            StrSubstNo('Expected one shelf total to read at most %1 rows, but this call read %2 — the shelf holds %3 movement rows, and fetching each one to add it up in AL does not scale; the total is already sitting in the index', MaxRows, RowsUsed, ItemCount * EntriesPerItem));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ItemTotalStaysWithinTheRowBudget()
    var
        ShelfTotals: Codeunit "Shelf Totals";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        HotEntries: Integer;
        MaxRows: Integer;
        i: Integer;
        Qty: Decimal;
        ExpectedTotal: Decimal;
        Total: Decimal;
        RowsBefore: BigInteger;
        RowsUsed: BigInteger;
    begin
        // [SCENARIO] One item total reads at most 25 rows however many movements the item has
        MaxRows := 25;
        HotEntries := Any.IntegerInRange(150, 250);
        for i := 1 to HotEntries do begin
            Qty := Any.DecimalInRange(1, 9, 2);
            ExpectedTotal += Qty;
            InsertMovement('TRYAL-S8', 'TRYAL-HOT', Qty);
        end;
        for i := 1 to 4 do
            InsertMovement('TRYAL-S8', StrSubstNo('TRYAL-COLD%1', i), Any.DecimalInRange(1, 9, 2));
        InsertMovement('TRYAL-S8B', 'TRYAL-HOT', Any.DecimalInRange(1, 9, 2));

        // warm-up: the first call may pay one-time metadata reads; grade the steady state
        ShelfTotals.QuantityOnShelfForItem('TRYAL-S8', 'TRYAL-HOT');
        InvalidateDataCache();
        RowsBefore := SessionInformation.SqlRowsRead();
        Total := ShelfTotals.QuantityOnShelfForItem('TRYAL-S8', 'TRYAL-HOT');
        RowsUsed := SessionInformation.SqlRowsRead() - RowsBefore;

        Assert.AreEqual(ExpectedTotal, Total,
            StrSubstNo('Expected the item total to stay correct while fitting the budget — %1 movements were seeded for the item on the shelf', HotEntries));
        Assert.IsTrue(RowsUsed <= MaxRows,
            StrSubstNo('Expected one item total to read at most %1 rows, but this call read %2 — the item has %3 movement rows on the shelf, and fetching each one to add it up in AL does not scale; the total is already sitting in the index', MaxRows, RowsUsed, HotEntries));
    end;

    local procedure InsertMovement(ShelfCode: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        ShelfMovementEntry: Record "Shelf Movement Entry";
    begin
        if ShelfMovementEntry.FindLast() then;
        ShelfMovementEntry.Init();
        ShelfMovementEntry."Entry No." += 1;
        ShelfMovementEntry."Shelf Code" := ShelfCode;
        ShelfMovementEntry."Item No." := ItemNo;
        ShelfMovementEntry.Quantity := Qty;
        ShelfMovementEntry.Insert();
    end;

    local procedure IsContractSiftKey(TableKey: Record "Key"): Boolean
    var
        KeyFields: Text;
    begin
        if not TableKey.Enabled then
            exit(false);
        if not TableKey.MaintainSIFTIndex then
            exit(false);
        // spaces are stripped so the check doesn't hinge on how the virtual
        // table renders the field list ("A,B" vs "A, B")
        KeyFields := DelChr(UpperCase(TableKey."Key"), '=', ' ');
        if not KeyFields.StartsWith('SHELFCODE,ITEMNO.') then
            exit(false);
        exit(DelChr(UpperCase(TableKey.SumIndexFields), '=', ' ').Contains('QUANTITY'));
    end;

    local procedure InvalidateDataCache()
    begin
        // The warm-up call leaves the table's result sets (and the CalcSums result)
        // in the server data cache, and a cached read costs zero SQL — the graded
        // call would measure nothing. A write bumps the table's version and forces
        // real statements again; SelectLatestVersion alone is not enough for rows
        // this transaction has locked. The decoy shelf is outside every graded filter.
        InsertMovement('TRYAL-DECOY', 'TRYAL-DECOY', 1);
        SelectLatestVersion();
    end;
}
