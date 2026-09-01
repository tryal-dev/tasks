codeunit 50900 "Batch Valuation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SumsAllLinesOfOneItem()
    var
        BatchValuation: Codeunit "Batch Valuation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        Price: Decimal;
        Qty1: Decimal;
        Qty2: Decimal;
        Qty3: Decimal;
    begin
        Price := Any.DecimalInRange(10, 90, 2);
        Qty1 := Any.DecimalInRange(1, 9, 2);
        Qty2 := Any.DecimalInRange(1, 9, 2);
        Qty3 := Any.DecimalInRange(1, 9, 2);
        CreateItemWithPrice('TRYAL-I1-A', Price);
        MockJournalLine('TRYAL-T1', 'TRYAL-B1', 'TRYAL-I1-A', Qty1, Price);
        MockJournalLine('TRYAL-T1', 'TRYAL-B1', 'TRYAL-I1-A', Qty2, Price);
        MockJournalLine('TRYAL-T1', 'TRYAL-B1', 'TRYAL-I1-A', Qty3, Price);

        Totals := BatchValuation.ValueByItem('TRYAL-T1', 'TRYAL-B1');

        Assert.AreEqual(Qty1 * Price + Qty2 * Price + Qty3 * Price, GetValue(Totals, 'TRYAL-I1-A'),
            'Expected the item''s value to add up quantity times unit price across every line of the batch');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsEachItemsValueSeparate()
    var
        BatchValuation: Codeunit "Batch Valuation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        PriceA: Decimal;
        PriceB: Decimal;
        QtyA: Decimal;
        QtyB: Decimal;
    begin
        PriceA := Any.DecimalInRange(10, 90, 2);
        PriceB := Any.DecimalInRange(100, 900, 2);
        QtyA := Any.DecimalInRange(1, 9, 2);
        QtyB := Any.DecimalInRange(1, 9, 2);
        CreateItemWithPrice('TRYAL-I2-A', PriceA);
        CreateItemWithPrice('TRYAL-I2-B', PriceB);
        MockJournalLine('TRYAL-T2', 'TRYAL-B2', 'TRYAL-I2-A', QtyA, PriceA);
        MockJournalLine('TRYAL-T2', 'TRYAL-B2', 'TRYAL-I2-B', QtyB, PriceB);

        Totals := BatchValuation.ValueByItem('TRYAL-T2', 'TRYAL-B2');

        Assert.AreEqual(QtyA * PriceA, GetValue(Totals, 'TRYAL-I2-A'),
            'Expected item A''s value to be built only from item A''s own lines and price');
        Assert.AreEqual(QtyB * PriceB, GetValue(Totals, 'TRYAL-I2-B'),
            'Expected item B''s value to be built only from item B''s own lines and price');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeQuantityReducesTheValue()
    var
        BatchValuation: Codeunit "Batch Valuation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        Price: Decimal;
        QtyIn: Decimal;
        QtyOut: Decimal;
    begin
        Price := Any.DecimalInRange(10, 90, 2);
        QtyIn := Any.DecimalInRange(5, 9, 2);
        QtyOut := Any.DecimalInRange(1, 4, 2);
        CreateItemWithPrice('TRYAL-I3-A', Price);
        MockJournalLine('TRYAL-T3', 'TRYAL-B3', 'TRYAL-I3-A', QtyIn, Price);
        MockJournalLine('TRYAL-T3', 'TRYAL-B3', 'TRYAL-I3-A', -QtyOut, Price);

        Totals := BatchValuation.ValueByItem('TRYAL-T3', 'TRYAL-B3');

        Assert.AreEqual(QtyIn * Price - QtyOut * Price, GetValue(Totals, 'TRYAL-I3-A'),
            'Expected the negative quantity (an outbound adjustment) to reduce the item''s value, not to be skipped');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UsesTheItemCardPriceNotTheLineStamp()
    var
        BatchValuation: Codeunit "Batch Valuation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        CardPrice: Decimal;
        StalePrice: Decimal;
        Qty: Decimal;
    begin
        CardPrice := Any.DecimalInRange(100, 900, 2);
        StalePrice := Any.DecimalInRange(10, 90, 2);
        Qty := Any.DecimalInRange(1, 9, 2);
        CreateItemWithPrice('TRYAL-I4-A', CardPrice);
        MockJournalLine('TRYAL-T4', 'TRYAL-B4', 'TRYAL-I4-A', Qty, StalePrice);

        Totals := BatchValuation.ValueByItem('TRYAL-T4', 'TRYAL-B4');

        Assert.AreEqual(Qty * CardPrice, GetValue(Totals, 'TRYAL-I4-A'),
            'Expected the value at the item card''s current Unit Price — the Unit Amount stamped on the line is stale and must be ignored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LinesOutsideTheBatchAreNotCounted()
    var
        BatchValuation: Codeunit "Batch Valuation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        Price: Decimal;
        QtyIn: Decimal;
    begin
        Price := Any.DecimalInRange(10, 90, 2);
        QtyIn := Any.DecimalInRange(1, 9, 2);
        CreateItemWithPrice('TRYAL-I5-A', Price);
        MockJournalLine('TRYAL-T5', 'TRYAL-B5', 'TRYAL-I5-A', QtyIn, Price);
        MockJournalLine('TRYAL-T5', 'TRYAL-B5X', 'TRYAL-I5-A', Any.DecimalInRange(1, 9, 2), Price);
        MockJournalLine('TRYAL-T5X', 'TRYAL-B5', 'TRYAL-I5-A', Any.DecimalInRange(1, 9, 2), Price);

        Totals := BatchValuation.ValueByItem('TRYAL-T5', 'TRYAL-B5');

        Assert.AreEqual(1, Totals.Count(),
            'Expected exactly one item in the valuation — decoy lines live in another batch and under another template with the same batch name');
        Assert.AreEqual(QtyIn * Price, GetValue(Totals, 'TRYAL-I5-A'),
            'Expected the value to be built only from lines matching BOTH the template name and the batch name');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EveryItemAppearsExactlyOnce()
    var
        BatchValuation: Codeunit "Batch Valuation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        ItemNo: Code[20];
        ItemCount: Integer;
        i: Integer;
    begin
        ItemCount := Any.IntegerInRange(5, 9);
        for i := 1 to ItemCount do begin
            ItemNo := CopyStr(StrSubstNo('TRYAL-I6-%1', i), 1, MaxStrLen(ItemNo));
            CreateItemWithPrice(ItemNo, 10);
            MockJournalLine('TRYAL-T6', 'TRYAL-B6', ItemNo, 1, 10);
            MockJournalLine('TRYAL-T6', 'TRYAL-B6', ItemNo, 2, 10);
        end;

        Totals := BatchValuation.ValueByItem('TRYAL-T6', 'TRYAL-B6');

        Assert.AreEqual(ItemCount, Totals.Count(),
            StrSubstNo('Expected exactly one entry per distinct item — %1 items were seeded, each on two lines', ItemCount));
        for i := 1 to ItemCount do begin
            ItemNo := CopyStr(StrSubstNo('TRYAL-I6-%1', i), 1, MaxStrLen(ItemNo));
            Assert.AreEqual(30.0, GetValue(Totals, ItemNo),
                StrSubstNo('Expected item %1 to appear once with both its lines added up', ItemNo));
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ItemWithoutLinesDoesNotAppear()
    var
        BatchValuation: Codeunit "Batch Valuation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        Price: Decimal;
        Qty: Decimal;
    begin
        Price := Any.DecimalInRange(10, 90, 2);
        Qty := Any.DecimalInRange(1, 9, 2);
        CreateItemWithPrice('TRYAL-I7-A', Price);
        CreateItemWithPrice('TRYAL-I7-B', Any.DecimalInRange(10, 90, 2));
        MockJournalLine('TRYAL-T7', 'TRYAL-B7', 'TRYAL-I7-A', Qty, Price);

        Totals := BatchValuation.ValueByItem('TRYAL-T7', 'TRYAL-B7');

        Assert.IsFalse(Totals.ContainsKey('TRYAL-I7-B'),
            'Expected an item that sits on no line of the batch to stay out of the valuation — the master record alone earns no entry');
        Assert.AreEqual(1, Totals.Count(),
            'Expected only the item that actually appears on the batch''s lines');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroPriceItemAppearsWithZeroValue()
    var
        BatchValuation: Codeunit "Batch Valuation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
    begin
        CreateItemWithPrice('TRYAL-I8-A', 0);
        MockJournalLine('TRYAL-T8', 'TRYAL-B8', 'TRYAL-I8-A', Any.DecimalInRange(1, 9, 2), 123.45);

        Totals := BatchValuation.ValueByItem('TRYAL-T8', 'TRYAL-B8');

        Assert.IsTrue(Totals.ContainsKey('TRYAL-I8-A'),
            'Expected the item to stay in the valuation even though its current Unit Price is 0');
        Assert.AreEqual(0.0, Totals.Get('TRYAL-I8-A'),
            'Expected a value of exactly 0 for a zero-price item — the non-zero Unit Amount stamped on the line must not step in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyBatchReturnsEmpty()
    var
        BatchValuation: Codeunit "Batch Valuation";
        Assert: Codeunit Assert;
        Totals: Dictionary of [Code[20], Decimal];
    begin
        CreateItemWithPrice('TRYAL-IE-A', 10);

        Totals := BatchValuation.ValueByItem('TRYAL-TE', 'TRYAL-BE');

        Assert.AreEqual(0, Totals.Count(),
            'Expected an empty dictionary and no error for a batch with no lines at all');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PriceChangedBeforeTheNextCallIsPickedUp()
    var
        BatchValuation: Codeunit "Batch Valuation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Item: Record Item;
        Totals: Dictionary of [Code[20], Decimal];
        OldPrice: Decimal;
        NewPrice: Decimal;
        Qty: Decimal;
    begin
        OldPrice := Any.DecimalInRange(10, 90, 2);
        NewPrice := Any.DecimalInRange(100, 900, 2);
        Qty := Any.DecimalInRange(1, 9, 2);
        CreateItemWithPrice('TRYAL-I10-A', OldPrice);
        MockJournalLine('TRYAL-T10', 'TRYAL-B10', 'TRYAL-I10-A', Qty, OldPrice);
        // first call on the very same codeunit variable primes any cache a submission keeps across calls
        BatchValuation.ValueByItem('TRYAL-T10', 'TRYAL-B10');
        Item.Get('TRYAL-I10-A');
        Item."Unit Price" := NewPrice;
        Item.Modify();

        Totals := BatchValuation.ValueByItem('TRYAL-T10', 'TRYAL-B10');

        Assert.AreEqual(Qty * NewPrice, GetValue(Totals, 'TRYAL-I10-A'),
            'Expected the second call to value the batch at the item card''s NEW Unit Price — the price comes from the card at call time, so a price remembered from an earlier call must not step in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StaysWithinTheSqlStatementBudget()
    var
        BatchValuation: Codeunit "Batch Valuation";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Totals: Dictionary of [Code[20], Decimal];
        ItemNo: Code[20];
        ItemCount: Integer;
        MaxStatements: Integer;
        i: Integer;
        Price: Decimal;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
    begin
        MaxStatements := 6;
        ItemCount := Any.IntegerInRange(12, 18);
        for i := 1 to ItemCount do begin
            ItemNo := CopyStr(StrSubstNo('TRYAL-I9-%1', i), 1, MaxStrLen(ItemNo));
            Price := Any.DecimalInRange(10, 90, 2);
            CreateItemWithPrice(ItemNo, Price);
            MockJournalLine('TRYAL-T9', 'TRYAL-B9', ItemNo, 1, Price);
            MockJournalLine('TRYAL-T9', 'TRYAL-B9', ItemNo, 1, Price);
            MockJournalLine('TRYAL-T9', 'TRYAL-B9', ItemNo, 1, Price);
        end;

        // warm-up: the first call may pay one-time metadata statements; grade the steady state
        BatchValuation.ValueByItem('TRYAL-T9', 'TRYAL-B9');
        // measure the codeunit cold: state the warm-up left in instance variables must not
        // subsidize the graded call, or a per-item memoizer would sneak under the budget
        Clear(BatchValuation);
        InvalidateDataCache();
        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        Totals := BatchValuation.ValueByItem('TRYAL-T9', 'TRYAL-B9');
        StatementsUsed := SessionInformation.SqlStatementsExecuted() - StatementsBefore;

        Assert.AreEqual(ItemCount, Totals.Count(),
            StrSubstNo('Expected every one of the %1 items in the valuation before judging the budget', ItemCount));
        Assert.AreEqual(3 * Price, GetValue(Totals, ItemNo),
            'Expected the budget-friendly valuation to still carry the real numbers');
        Assert.IsTrue(StatementsUsed <= MaxStatements,
            StrSubstNo('Expected the whole valuation to cost at most %1 SQL statements no matter how many items the batch touches, but this call executed %2 for %3 distinct items with three lines each — one round trip per line, or even per distinct item, does not scale', MaxStatements, StatementsUsed, ItemCount));
    end;

    local procedure CreateItemWithPrice(ItemNo: Code[20]; UnitPrice: Decimal)
    var
        Item: Record Item;
    begin
        Item.Init();
        Item."No." := ItemNo;
        Item.Description := ItemNo;
        Item."Unit Price" := UnitPrice;
        Item.Insert();
    end;

    local procedure MockJournalLine(TemplateName: Code[10]; BatchName: Code[10]; ItemNo: Code[20]; Qty: Decimal; StampedUnitAmount: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Template Name", TemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", BatchName);
        if ItemJournalLine.FindLast() then;
        ItemJournalLine.Init();
        ItemJournalLine."Journal Template Name" := TemplateName;
        ItemJournalLine."Journal Batch Name" := BatchName;
        ItemJournalLine."Line No." += 10000;
        ItemJournalLine."Item No." := ItemNo;
        ItemJournalLine.Quantity := Qty;
        ItemJournalLine."Unit Amount" := StampedUnitAmount;
        ItemJournalLine.Insert();
    end;

    local procedure GetValue(Totals: Dictionary of [Code[20], Decimal]; ItemNo: Code[20]): Decimal
    var
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(Totals.ContainsKey(ItemNo),
            StrSubstNo('Expected item %1 to appear in the valuation', ItemNo));
        exit(Totals.Get(ItemNo));
    end;

    local procedure InvalidateDataCache()
    var
        Item: Record Item;
    begin
        // The warm-up call leaves both tables' result sets in the server data cache,
        // and a cached read costs zero SQL — the graded call would measure nothing.
        // A write bumps each table's version and forces real statements again;
        // SelectLatestVersion alone is not enough for rows this transaction has locked.
        // The decoy item sits on a line of a decoy batch, so no TRYAL-T9 filter sees it.
        Item.Init();
        Item."No." := 'TRYAL-DECOY';
        Item.Description := 'TRYAL-DECOY';
        Item.Insert();
        MockJournalLine('TRYAL-DT', 'TRYAL-DB', 'TRYAL-DECOY', 1, 0);
        SelectLatestVersion();
    end;
}
