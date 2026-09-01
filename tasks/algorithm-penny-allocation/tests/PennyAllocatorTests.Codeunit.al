codeunit 50900 "Penny Allocator Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleLineReceivesTheWholeTotal()
    var
        PennyAllocator: Codeunit "Penny Allocator";
        Assert: Codeunit Assert;
        Weights: List of [Decimal];
        Amounts: List of [Decimal];
    begin
        Weights.Add(7.5);

        Amounts := PennyAllocator.Allocate(123.45, Weights);

        Assert.AreEqual(1, Amounts.Count(), 'Expected exactly one amount for a one-line invoice');
        Assert.AreEqual(123.45, Amounts.Get(1), 'Expected a single line to receive the entire total');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EvenlyDivisibleSharesComeBackExactAndInOrder()
    var
        PennyAllocator: Codeunit "Penny Allocator";
        Assert: Codeunit Assert;
        Weights: List of [Decimal];
        Amounts: List of [Decimal];
    begin
        Weights.Add(70);
        Weights.Add(20);
        Weights.Add(10);

        Amounts := PennyAllocator.Allocate(100.00, Weights);

        Assert.AreEqual(3, Amounts.Count(), 'Expected one amount per weight');
        Assert.AreEqual(70.00, Amounts.Get(1), 'Expected the line with weight 70 to get exactly 70.00 of 100.00 — a share that is already a whole number of cents must come back unchanged, in the position of its weight');
        Assert.AreEqual(20.00, Amounts.Get(2), 'Expected the line with weight 20 to get exactly 20.00 of 100.00, in the position of its weight');
        Assert.AreEqual(10.00, Amounts.Get(3), 'Expected the line with weight 10 to get exactly 10.00 of 100.00, in the position of its weight');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ThreeWaySplitLosesNoPenny()
    var
        PennyAllocator: Codeunit "Penny Allocator";
        Weights: List of [Decimal];
        Amounts: List of [Decimal];
    begin
        Weights.Add(1);
        Weights.Add(1);
        Weights.Add(1);

        Amounts := PennyAllocator.Allocate(100.00, Weights);

        VerifyAllocation(100.00, Weights, Amounts);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HalfCentSharesStillSumToTheTotal()
    var
        PennyAllocator: Codeunit "Penny Allocator";
        Weights: List of [Decimal];
        Amounts: List of [Decimal];
    begin
        Weights.Add(1);
        Weights.Add(1);

        Amounts := PennyAllocator.Allocate(0.03, Weights);

        VerifyAllocation(0.03, Weights, Amounts);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResidualIsSpreadAcrossLinesNotDumpedOnOne()
    var
        PennyAllocator: Codeunit "Penny Allocator";
        Weights: List of [Decimal];
        Amounts: List of [Decimal];
        i: Integer;
    begin
        // 0.99 / 6 = 0.165 per line: every exact share ends in half a cent,
        // so per-line rounding drifts by 3 cents in total — an implementation
        // that parks the whole correction on one line breaks guarantee 4 here.
        for i := 1 to 6 do
            Weights.Add(1);

        Amounts := PennyAllocator.Allocate(0.99, Weights);

        VerifyAllocation(0.99, Weights, Amounts);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroWeightLineGetsExactlyZero()
    var
        PennyAllocator: Codeunit "Penny Allocator";
        Assert: Codeunit Assert;
        Weights: List of [Decimal];
        Amounts: List of [Decimal];
    begin
        Weights.Add(5);
        Weights.Add(0);
        Weights.Add(3);

        Amounts := PennyAllocator.Allocate(99.99, Weights);

        Assert.AreEqual(0.0, Amounts.Get(2), 'Expected the line with weight 0 to be allocated exactly 0.00 — it has no share of the total to absorb');
        VerifyAllocation(99.99, Weights, Amounts);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreditMemoNegativeTotalBalancesToTheCent()
    var
        PennyAllocator: Codeunit "Penny Allocator";
        Weights: List of [Decimal];
        Amounts: List of [Decimal];
    begin
        Weights.Add(2);
        Weights.Add(1);

        Amounts := PennyAllocator.Allocate(-100.01, Weights);

        VerifyAllocation(-100.01, Weights, Amounts);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomInvoiceKeepsEveryGuarantee()
    var
        PennyAllocator: Codeunit "Penny Allocator";
        Any: Codeunit Any;
        Weights: List of [Decimal];
        Amounts: List of [Decimal];
        TotalAmount: Decimal;
        i: Integer;
    begin
        for i := 1 to 8 do
            Weights.Add(Any.DecimalInRange(1, 500, 2));
        TotalAmount := Any.IntegerInRange(100000, 999999) / 100;

        Amounts := PennyAllocator.Allocate(TotalAmount, Weights);

        VerifyAllocation(TotalAmount, Weights, Amounts);
    end;

    local procedure VerifyAllocation(TotalAmount: Decimal; Weights: List of [Decimal]; Amounts: List of [Decimal])
    var
        Assert: Codeunit Assert;
        WeightSum: Decimal;
        Weight: Decimal;
        LineAmount: Decimal;
        ExactShare: Decimal;
        i: Integer;
    begin
        Assert.AreEqual(Weights.Count(), Amounts.Count(), 'Expected exactly one amount per weight, in the same order');
        Assert.AreEqual(TotalAmount, SumOf(Amounts), StrSubstNo('Expected the allocated amounts to sum to exactly the total %1 — rounding must neither invent nor lose a cent', TotalAmount));
        foreach Weight in Weights do
            WeightSum += Weight;
        for i := 1 to Amounts.Count() do begin
            LineAmount := Amounts.Get(i);
            Assert.AreEqual(Round(LineAmount, 0.01), LineAmount, StrSubstNo('Expected the amount on line %1 to be a whole number of cents', i));
            ExactShare := TotalAmount * Weights.Get(i) / WeightSum;
            Assert.IsTrue(Abs(LineAmount - ExactShare) < 0.01, StrSubstNo('Expected line %1 to stay strictly within one cent of its exact share %2, got %3 — the rounding correction must be spread across lines, not parked on one', i, ExactShare, LineAmount));
        end;
    end;

    local procedure SumOf(Amounts: List of [Decimal]): Decimal
    var
        LineAmount: Decimal;
        Total: Decimal;
    begin
        foreach LineAmount in Amounts do
            Total += LineAmount;
        exit(Total);
    end;
}
