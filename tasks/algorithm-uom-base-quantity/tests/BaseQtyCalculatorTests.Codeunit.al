codeunit 50900 "Base Qty Calculator Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WholeUnitsConvertWithoutRounding()
    var
        BaseQtyCalculator: Codeunit "Base Qty Calculator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 7 boxes of 6 pieces are exactly 42 pieces
        Assert.AreEqual(42, BaseQtyCalculator.CalcBaseQty(7, 6, 0),
            'Expected 7 units at 6 base units each to convert to exactly 42 base units');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LongProductRoundsToFiveDecimals()
    var
        BaseQtyCalculator: Codeunit "Base Qty Calculator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 0.12345 x 0.12345 = 0.0152399025 must come back with five decimals
        Assert.AreEqual(0.01524, BaseQtyCalculator.CalcBaseQty(0.12345, 0.12345, 0),
            'Expected the product 0.12345 x 0.12345 rounded to the nearest 0.00001 — a base quantity never keeps more than five decimals');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HalfwayProductRoundsAwayFromZero()
    var
        BaseQtyCalculator: Codeunit "Base Qty Calculator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 0.33333 x 0.5 = 0.166665, exactly halfway between two steps
        Assert.AreEqual(0.16667, BaseQtyCalculator.CalcBaseQty(0.33333, 0.5, 0),
            'Expected the halfway product 0.166665 to round away from zero to 0.16667, not down to 0.16666');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ProductBelowTheMidpointRoundsDown()
    var
        BaseQtyCalculator: Codeunit "Base Qty Calculator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 0.11111 x 0.2 = 0.022222, below the midpoint of the 0.00001 step
        Assert.AreEqual(0.02222, BaseQtyCalculator.CalcBaseQty(0.11111, 0.2, 0),
            'Expected the product 0.022222 to round down to the nearest 0.00001 multiple, 0.02222 — rounding every product up would give 0.02223');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroQuantityYieldsZeroBaseQty()
    var
        BaseQtyCalculator: Codeunit "Base Qty Calculator";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(0, BaseQtyCalculator.CalcBaseQty(0, 6, 1),
            'Expected a zero quantity to convert to a zero base quantity');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoundingPrecisionSnapsFivePiecesOfASixPieceBox()
    var
        BaseQtyCalculator: Codeunit "Base Qty Calculator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 0.83333 BOX x 6 = 4.99998, snapped to whole pieces by precision 1
        Assert.AreEqual(5, BaseQtyCalculator.CalcBaseQty(0.83333, 6, 1),
            'Expected 0.83333 of a six-piece box with Quantity Rounding Precision 1 to convert to exactly 5 pieces, not 4.99998');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TenthPrecisionSnapsToTenths()
    var
        BaseQtyCalculator: Codeunit "Base Qty Calculator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 0.33333 x 6 = 1.99998, snapped to tenths by precision 0.1
        Assert.AreEqual(2.0, BaseQtyCalculator.CalcBaseQty(0.33333, 6, 0.1),
            'Expected 0.33333 units at 6 base units each with Quantity Rounding Precision 0.1 to snap to exactly 2.0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChainedConversionsUseTheRoundedIntermediate()
    var
        BaseQtyCalculator: Codeunit "Base Qty Calculator";
        Assert: Codeunit Assert;
        IntermediateQty: Decimal;
    begin
        // [SCENARIO] bottle -> litre -> glass: the second conversion must start from the
        // first conversion's rounded result (0.16667), not the raw product (0.166665)
        IntermediateQty := BaseQtyCalculator.CalcBaseQty(0.33333, 0.5, 0);

        Assert.AreEqual(0.50001, BaseQtyCalculator.CalcBaseQty(IntermediateQty, 3, 0),
            StrSubstNo('Expected the chained conversion to yield 0.16667 x 3 = 0.50001 — the first step returned %1, and every step must return an already-rounded base quantity', IntermediateQty));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomQuantityFollowsTheDocumentedRounding()
    var
        BaseQtyCalculator: Codeunit "Base Qty Calculator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Qty: Decimal;
        QtyPerUnitOfMeasure: Decimal;
    begin
        Qty := Any.IntegerInRange(1, 999999) / 100000;
        QtyPerUnitOfMeasure := Any.IntegerInRange(1, 99999) / 100000;

        Assert.AreEqual(Round(Qty * QtyPerUnitOfMeasure, 0.00001), BaseQtyCalculator.CalcBaseQty(Qty, QtyPerUnitOfMeasure, 0),
            StrSubstNo('Expected %1 x %2 rounded to the nearest 0.00001, halves away from zero', Qty, QtyPerUnitOfMeasure));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FirstPostingOfFivePiecesLeavesWholeBaseQty()
    var
        BaseQtyCalculator: Codeunit "Base Qty Calculator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] ship 5 pieces of an ordered six-piece box: 0.83333 BOX, nothing posted yet
        Assert.AreEqual(5, BaseQtyCalculator.CalcBaseQtyToPost(0.83333, 0, 6, 1),
            'Expected the first posting of 0.83333 of a six-piece box (precision 1) to post exactly 5 pieces');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FinalPostingClosesTheBoxToSixPieces()
    var
        BaseQtyCalculator: Codeunit "Base Qty Calculator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] the closing posting of the box order: 0.16667 BOX after 0.83333 posted
        Assert.AreEqual(1, BaseQtyCalculator.CalcBaseQtyToPost(0.16667, 0.83333, 6, 1),
            'Expected the closing posting of 0.16667 BOX after 0.83333 BOX to post exactly the 1 remaining piece, closing the order at 6');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FirstPostingBelowTheMidpointRoundsDown()
    var
        BaseQtyCalculator: Codeunit "Base Qty Calculator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] first posting, cumulative product 0.11111 x 0.2 = 0.022222 rounds down
        Assert.AreEqual(0.02222, BaseQtyCalculator.CalcBaseQtyToPost(0.11111, 0, 0.2, 0),
            'Expected the first posting of 0.11111 units at 0.2 base units each to post 0.02222 — the exact product 0.022222 rounds down to the nearest 0.00001 step, not up to 0.02223');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SecondSplitAbsorbsTheFirstSplitsRounding()
    var
        BaseQtyCalculator: Codeunit "Base Qty Calculator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 1 CAN = 0.33333 KG; the first 0.5 CAN posted 0.16667 KG (rounded up
        // from 0.166665), so the second 0.5 CAN must post 0.16666 KG to land on 0.33333
        Assert.AreEqual(0.16666, BaseQtyCalculator.CalcBaseQtyToPost(0.5, 0.5, 0.33333, 0),
            'Expected the second 0.5 CAN posting to absorb the first posting''s rounding and post 0.16666 KG — converting it on its own gives 0.16667 and the splits drift');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SixCanSplitsSumToTheOrderedBaseQty()
    var
        BaseQtyCalculator: Codeunit "Base Qty Calculator";
        Assert: Codeunit Assert;
        QtyPostedSoFar: Decimal;
        PostedBaseQty: Decimal;
        TotalBaseQty: Decimal;
        i: Integer;
    begin
        // [SCENARIO] posting 0.5 CAN (1 CAN = 0.33333 KG) six times must close on 0.99999 KG
        for i := 1 to 6 do begin
            PostedBaseQty := BaseQtyCalculator.CalcBaseQtyToPost(0.5, QtyPostedSoFar, 0.33333, 0);

            Assert.AreEqual(Round(PostedBaseQty, 0.00001), PostedBaseQty,
                StrSubstNo('Expected posting %1 to be a multiple of the 0.00001 step, got %2', i, PostedBaseQty));
            Assert.IsTrue(Abs(PostedBaseQty - 0.166665) < 0.00001,
                StrSubstNo('Expected posting %1 to stay strictly within one 0.00001 step of its exact share 0.166665, got %2 — the correction must not pile up on one posting', i, PostedBaseQty));

            QtyPostedSoFar += 0.5;
            TotalBaseQty += PostedBaseQty;
        end;

        Assert.AreEqual(0.99999, TotalBaseQty,
            'Expected six postings of 0.5 CAN at 0.33333 KG per CAN to sum to exactly 0.99999 KG — rounding each posting on its own hands out 1.00002');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomSplitSequenceClosesAfterEveryPosting()
    var
        BaseQtyCalculator: Codeunit "Base Qty Calculator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        QtyPerUnitOfMeasure: Decimal;
        SplitQty: Decimal;
        QtyPostedSoFar: Decimal;
        PostedBaseQty: Decimal;
        RunningBaseQty: Decimal;
        i: Integer;
    begin
        QtyPerUnitOfMeasure := Any.IntegerInRange(10000, 99999) / 100000;

        for i := 1 to 5 do begin
            SplitQty := Any.IntegerInRange(1, 99999) / 100000;
            PostedBaseQty := BaseQtyCalculator.CalcBaseQtyToPost(SplitQty, QtyPostedSoFar, QtyPerUnitOfMeasure, 0);

            Assert.AreEqual(Round(PostedBaseQty, 0.00001), PostedBaseQty,
                StrSubstNo('Expected posting %1 (%2 units at %3 per unit) to be a multiple of the 0.00001 step, got %4', i, SplitQty, QtyPerUnitOfMeasure, PostedBaseQty));
            Assert.IsTrue(Abs(PostedBaseQty - SplitQty * QtyPerUnitOfMeasure) < 0.00001,
                StrSubstNo('Expected posting %1 to stay strictly within one 0.00001 step of its exact share %2, got %3', i, SplitQty * QtyPerUnitOfMeasure, PostedBaseQty));

            QtyPostedSoFar += SplitQty;
            RunningBaseQty += PostedBaseQty;
            Assert.AreEqual(Round(QtyPostedSoFar * QtyPerUnitOfMeasure, 0.00001), RunningBaseQty,
                StrSubstNo('Expected the base quantities posted so far to sum to the base quantity of the total %1 units after posting %2 — split postings must never drift, even mid-sequence', QtyPostedSoFar, i));
        end;
    end;
}
