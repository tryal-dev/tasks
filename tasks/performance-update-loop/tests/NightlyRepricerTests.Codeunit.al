codeunit 50900 "Nightly Repricer Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        // seeded inputs by entry number: expectations must come from what the test
        // wrote, never from values read back after the code under test ran — a wrong
        // solution could rewrite cost or markup to make the stored price look right
        SeededCost: Dictionary of [Integer, Decimal];
        SeededMarkup: Dictionary of [Integer, Decimal];

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RepricesStaleRowsToTheComputedPrice()
    var
        PriceReviewLine: Record "Price Review Line";
        NightlyRepricer: Codeunit "Nightly Repricer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        StaleCount: Integer;
        CorrectCount: Integer;
        Updated: Integer;
        i: Integer;
        UnitCost: Decimal;
        MarkupPct: Decimal;
    begin
        // [SCENARIO] Rows whose stored price differs from the computed one get exactly the computed price; the return value counts exactly them
        PriceReviewLine.DeleteAll();
        StaleCount := Any.IntegerInRange(4, 7);
        for i := 1 to StaleCount do begin
            UnitCost := Any.DecimalInRange(10, 500, 2);
            MarkupPct := Any.DecimalInRange(5, 90, 2);
            SeedRow(1000 + i, UnitCost, MarkupPct, ExpectedPrice(UnitCost, MarkupPct) + Any.DecimalInRange(1, 9, 2));
        end;
        // a markdown row: negative markup must go through the same formula
        SeedRow(1500, 199.99, -15, 200);
        CorrectCount := Any.IntegerInRange(3, 5);
        for i := 1 to CorrectCount do begin
            UnitCost := Any.DecimalInRange(10, 500, 2);
            MarkupPct := Any.DecimalInRange(5, 90, 2);
            SeedRow(1600 + i, UnitCost, MarkupPct, ExpectedPrice(UnitCost, MarkupPct));
        end;

        Updated := NightlyRepricer.RunRepricing();

        Assert.AreEqual(StaleCount + 1, Updated,
            'Expected the return value to count exactly the rows whose stored price differed from the computed one');
        for i := 1 to StaleCount do
            AssertRepriced(1000 + i, 'a stale row must end up holding cost times (1 + markup/100), rounded to the nearest 0.01');
        AssertRepriced(1500, 'a negative markup is a markdown and follows the same formula');
        for i := 1 to CorrectCount do
            AssertRepriced(1600 + i, 'a row that already held the computed price must still hold it');
        Assert.AreEqual(StaleCount + 1 + CorrectCount, PriceReviewLine.Count(),
            'Expected the repricing pass to neither insert nor delete rows');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesUpToDateRowsUntouched()
    var
        PriceReviewLine: Record "Price Review Line";
        NightlyRepricer: Codeunit "Nightly Repricer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        StampBefore: Dictionary of [Integer, DateTime];
        CorrectCount: Integer;
        i: Integer;
        UnitCost: Decimal;
        MarkupPct: Decimal;
    begin
        // [SCENARIO] A row already holding the computed price is never written — its SystemModifiedAt keeps the exact value it had before the call
        PriceReviewLine.DeleteAll();
        CorrectCount := Any.IntegerInRange(3, 5);
        for i := 1 to CorrectCount do begin
            UnitCost := Any.DecimalInRange(10, 500, 2);
            MarkupPct := Any.DecimalInRange(5, 90, 2);
            SeedRow(2000 + i, UnitCost, MarkupPct, ExpectedPrice(UnitCost, MarkupPct));
            PriceReviewLine.Get(2000 + i);
            StampBefore.Add(2000 + i, PriceReviewLine.SystemModifiedAt);
        end;
        for i := 1 to 2 do begin
            UnitCost := Any.DecimalInRange(10, 500, 2);
            MarkupPct := Any.DecimalInRange(5, 90, 2);
            SeedRow(2100 + i, UnitCost, MarkupPct, ExpectedPrice(UnitCost, MarkupPct) + Any.DecimalInRange(1, 9, 2));
        end;
        // let the clock tick past the seeding, so any write during the run gets a visibly newer stamp
        Sleep(30);

        NightlyRepricer.RunRepricing();

        for i := 1 to CorrectCount do begin
            PriceReviewLine.Get(2000 + i);
            Assert.AreEqual(StampBefore.Get(2000 + i), PriceReviewLine.SystemModifiedAt,
                StrSubstNo('Expected row %1, already at the computed price, to come out of the run never written — a Modify that stores the very same values still stamps SystemModifiedAt', 2000 + i));
        end;
        for i := 1 to 2 do
            AssertRepriced(2100 + i, 'the stale rows next to the untouched ones must still be repriced');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AllRowsUpToDateReturnsZero()
    var
        PriceReviewLine: Record "Price Review Line";
        NightlyRepricer: Codeunit "Nightly Repricer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        RowCount: Integer;
        Updated: Integer;
        i: Integer;
        UnitCost: Decimal;
        MarkupPct: Decimal;
    begin
        // [SCENARIO] A worksheet where every price is already right reports zero changed rows and raises no error
        PriceReviewLine.DeleteAll();
        RowCount := Any.IntegerInRange(3, 5);
        for i := 1 to RowCount do begin
            UnitCost := Any.DecimalInRange(10, 500, 2);
            MarkupPct := Any.DecimalInRange(5, 90, 2);
            SeedRow(3000 + i, UnitCost, MarkupPct, ExpectedPrice(UnitCost, MarkupPct));
        end;

        Updated := NightlyRepricer.RunRepricing();

        Assert.AreEqual(0, Updated,
            'Expected zero changed rows — and no error — when every row already holds its computed price');
        for i := 1 to RowCount do
            AssertRepriced(3000 + i, 'an already-correct row must still hold its computed price after the run');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyWorksheetReturnsZeroWithoutError()
    var
        PriceReviewLine: Record "Price Review Line";
        NightlyRepricer: Codeunit "Nightly Repricer";
        Assert: Codeunit Assert;
        Updated: Integer;
    begin
        // [SCENARIO] An empty worksheet is a normal input: zero changed rows, no error
        PriceReviewLine.DeleteAll();

        Updated := NightlyRepricer.RunRepricing();

        Assert.AreEqual(0, Updated, 'Expected an empty worksheet to report zero changed rows without an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StaysWithinTheSqlStatementBudget()
    var
        PriceReviewLine: Record "Price Review Line";
        NightlyRepricer: Codeunit "Nightly Repricer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TotalRows: Integer;
        ChangedCount: Integer;
        MaxStatements: Integer;
        Updated: Integer;
        i: Integer;
        UnitCost: Decimal;
        MarkupPct: Decimal;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
    begin
        // [SCENARIO] One pass over 350-450 rows where every fifth row is stale fits in (stale rows + 40) SQL statements
        PriceReviewLine.DeleteAll();
        TotalRows := Any.IntegerInRange(70, 90) * 5;
        ChangedCount := TotalRows div 5;
        MaxStatements := ChangedCount + 40;
        for i := 1 to TotalRows do begin
            UnitCost := Any.DecimalInRange(10, 500, 2);
            MarkupPct := Any.DecimalInRange(5, 90, 2);
            if i mod 5 = 0 then
                SeedRow(i, UnitCost, MarkupPct, ExpectedPrice(UnitCost, MarkupPct) + 1)
            else
                SeedRow(i, UnitCost, MarkupPct, ExpectedPrice(UnitCost, MarkupPct));
        end;

        // warm-up: the first call pays one-time metadata statements; grade the steady state
        Updated := NightlyRepricer.RunRepricing();
        Assert.AreEqual(ChangedCount, Updated,
            StrSubstNo('Expected the warm-up call to reprice exactly the %1 stale rows before the budget is judged', ChangedCount));
        // restore the stale prices for the graded call; these writes also bump the table
        // version, so nothing the warm-up left in the server data cache can hide the
        // graded call's own read — and its writes always hit SQL regardless
        for i := 1 to TotalRows do
            if i mod 5 = 0 then begin
                PriceReviewLine.Get(i);
                PriceReviewLine."Unit Price" := ExpectedPrice(SeededCost.Get(i), SeededMarkup.Get(i)) + 1;
                PriceReviewLine.Modify();
            end;
        // measure the codeunit cold: state remembered from the warm-up call must not
        // subsidize the graded call
        Clear(NightlyRepricer);

        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        Updated := NightlyRepricer.RunRepricing();
        StatementsUsed := SessionInformation.SqlStatementsExecuted() - StatementsBefore;

        if DebugBudgets() then
            Assert.Fail(StrSubstNo('DEBUG: the graded call executed %1 SQL statements for %2 stale rows out of %3', StatementsUsed, ChangedCount, TotalRows));
        Assert.AreEqual(ChangedCount, Updated,
            StrSubstNo('Expected the graded call to reprice exactly the %1 stale rows before judging the budget', ChangedCount));
        AssertRepriced(5, 'the budget-friendly pass must still write the computed price to the first stale row');
        AssertRepriced(TotalRows, 'the budget-friendly pass must still write the computed price to the last stale row');
        Assert.AreEqual(TotalRows, PriceReviewLine.Count(),
            'Expected the graded pass to neither insert nor delete rows');
        Assert.IsTrue(StatementsUsed <= MaxStatements,
            StrSubstNo('Expected the whole pass to cost at most %1 SQL statements, but this call executed %2 for %3 stale rows out of %4 — writing rows whose price is already right spends a statement per row for nothing, and even a loop that writes only the stale rows pays a hidden second statement per write when the rows were read without update intent or modified through a copy', MaxStatements, StatementsUsed, ChangedCount, TotalRows));
    end;

    local procedure ExpectedPrice(UnitCost: Decimal; MarkupPct: Decimal): Decimal
    begin
        exit(Round(UnitCost * (1 + MarkupPct / 100), 0.01));
    end;

    local procedure SeedRow(EntryNo: Integer; UnitCost: Decimal; MarkupPct: Decimal; UnitPrice: Decimal)
    var
        PriceReviewLine: Record "Price Review Line";
    begin
        PriceReviewLine.Init();
        PriceReviewLine."Entry No." := EntryNo;
        PriceReviewLine."Unit Cost" := UnitCost;
        PriceReviewLine."Markup %" := MarkupPct;
        PriceReviewLine."Unit Price" := UnitPrice;
        PriceReviewLine.Insert();
        SeededCost.Set(EntryNo, UnitCost);
        SeededMarkup.Set(EntryNo, MarkupPct);
    end;

    local procedure AssertRepriced(EntryNo: Integer; Because: Text)
    var
        PriceReviewLine: Record "Price Review Line";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(PriceReviewLine.Get(EntryNo),
            StrSubstNo('Expected a Price Review Line row with entry number %1 — %2', EntryNo, Because));
        Assert.AreEqual(SeededCost.Get(EntryNo), PriceReviewLine."Unit Cost",
            StrSubstNo('Expected the unit cost of row %1 to still hold its seeded value — the pass writes only the unit price, never its inputs', EntryNo));
        Assert.AreEqual(SeededMarkup.Get(EntryNo), PriceReviewLine."Markup %",
            StrSubstNo('Expected the markup of row %1 to still hold its seeded value — the pass writes only the unit price, never its inputs', EntryNo));
        Assert.AreEqual(ExpectedPrice(SeededCost.Get(EntryNo), SeededMarkup.Get(EntryNo)), PriceReviewLine."Unit Price",
            StrSubstNo('Expected the unit price of row %1 to equal the price computed from its seeded cost and markup — %2', EntryNo, Because));
    end;

    local procedure DebugBudgets(): Boolean
    begin
        // flip to true to fail right after measuring with the raw counter in the message —
        // the calibration channel for re-baselining MaxStatements on a new BC version
        exit(false);
    end;
}
