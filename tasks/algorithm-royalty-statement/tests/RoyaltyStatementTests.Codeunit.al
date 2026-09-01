codeunit 50900 "Royalty Statement Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TragedyChargesFlatFeeBelowThreshold()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Audience: Integer;
    begin
        // [SCENARIO] A tragedy with fewer than 30 attendees costs the flat base fee, regardless of audience size
        Audience := Any.IntegerInRange(1, 29);
        Assert.AreEqual(400.0, RoyaltyStatement.LineAmount('TRAGEDY', Audience), StrSubstNo('Expected the flat tragedy base fee for an audience of %1 — below 31 attendees no surcharge applies', Audience));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TragedyChargesFlatFeeAtExactlyThirty()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Exactly 30 attendees is NOT above the threshold — base fee only
        Assert.AreEqual(400.0, RoyaltyStatement.LineAmount('TRAGEDY', 30), 'Expected the flat tragedy base fee at exactly 30 attendees — the surcharge starts only ABOVE 30');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TragedyAddsSurchargeJustAboveThirty()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 31 attendees is one attendee above the threshold — one 10.00 step
        Assert.AreEqual(410.0, RoyaltyStatement.LineAmount('TRAGEDY', 31), 'Expected the tragedy base fee plus one 10.00 surcharge step at 31 attendees');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TragedyFeeGrowsWithGeneratedAudience()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Audience: Integer;
    begin
        // [SCENARIO] A generated large audience pays 400.00 plus 10.00 per attendee above 30 — hardcoded answers fail here
        Audience := Any.IntegerInRange(35, 200);
        Assert.AreEqual(400.0 + 10 * (Audience - 30), RoyaltyStatement.LineAmount('TRAGEDY', Audience), StrSubstNo('Expected 400.00 plus 10.00 per attendee above 30 for a tragedy audience of %1', Audience));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ComedyChargesPerAttendeeBelowThreshold()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Audience: Integer;
    begin
        // [SCENARIO] Below the bonus threshold a comedy still charges its per-attendee fee on every attendee
        Audience := Any.IntegerInRange(1, 19);
        Assert.AreEqual(300.0 + 3 * Audience, RoyaltyStatement.LineAmount('COMEDY', Audience), StrSubstNo('Expected the comedy base fee plus 3.00 per attendee for an audience of %1 — the per-attendee fee applies at any size', Audience));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ComedyEarnsNoBonusAtExactlyTwenty()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Exactly 20 attendees is NOT above the threshold — no bonus yet
        Assert.AreEqual(360.0, RoyaltyStatement.LineAmount('COMEDY', 20), 'Expected 300.00 plus 3.00 x 20 with no bonus at exactly 20 attendees — the bonus starts only ABOVE 20');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ComedyAddsBonusJustAboveTwenty()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 21 attendees triggers the 100.00 bonus plus one 5.00 step
        Assert.AreEqual(468.0, RoyaltyStatement.LineAmount('COMEDY', 21), 'Expected 300.00 + 3.00 x 21 + 100.00 + 5.00 x 1 at 21 attendees — the bonus and its first step both apply');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ComedyBonusGrowsWithGeneratedAudience()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Audience: Integer;
    begin
        // [SCENARIO] A generated large comedy audience pays base, per-attendee fee, bonus and per-attendee bonus steps
        Audience := Any.IntegerInRange(25, 150);
        Assert.AreEqual(300.0 + 3 * Audience + 100 + 5 * (Audience - 20), RoyaltyStatement.LineAmount('COMEDY', Audience), StrSubstNo('Expected 300.00 + 3.00 per attendee + 100.00 + 5.00 per attendee above 20 for a comedy audience of %1', Audience));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoCreditsAtExactlyThirtyAttendees()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Exactly 30 attendees earns no credits — credits count only attendees ABOVE 30
        Assert.AreEqual(0, RoyaltyStatement.LineCredits('TRAGEDY', 30), 'Expected zero credits for a tragedy at exactly 30 attendees — credits start only above 30');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OneCreditAtThirtyOneAttendees()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 31 attendees is one above the threshold — exactly one credit
        Assert.AreEqual(1, RoyaltyStatement.LineCredits('TRAGEDY', 31), 'Expected exactly one credit for a tragedy at 31 attendees');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TragedyCreditsGrowWithGeneratedAudience()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Audience: Integer;
    begin
        // [SCENARIO] A generated tragedy audience earns one credit per attendee above 30 — hardcoded answers fail here
        Audience := Any.IntegerInRange(40, 150);
        Assert.AreEqual(Audience - 30, RoyaltyStatement.LineCredits('TRAGEDY', Audience), StrSubstNo('Expected one credit per attendee above 30 for a tragedy audience of %1', Audience));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ComedyAddsCreditPerFullGroupOfFive()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A comedy at 34 attendees earns 4 threshold credits plus 6 group-of-five credits
        Assert.AreEqual(10, RoyaltyStatement.LineCredits('COMEDY', 34), 'Expected 4 credits for the attendees above 30 plus 6 for the full groups of five in a comedy audience of 34');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ComedyCreditsDropGroupFractions()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A comedy at 9 attendees has one full group of five — the remaining 4 attendees earn nothing
        Assert.AreEqual(1, RoyaltyStatement.LineCredits('COMEDY', 9), 'Expected exactly one group-of-five credit for a comedy audience of 9 — fractions of a group are dropped');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownCategoryFailsLineAmount()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A category outside TRAGEDY/COMEDY makes LineAmount error, naming the category
        asserterror RoyaltyStatement.LineAmount('HISTORY', 25);
        Assert.ExpectedError('HISTORY');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownCategoryFailsLineCredits()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] LineCredits rejects unknown categories the same way as LineAmount
        asserterror RoyaltyStatement.LineCredits('HISTORY', 25);
        Assert.ExpectedError('HISTORY');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedUnknownCategoryFailsWithItsCode()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        UnknownCategory: Code[20];
    begin
        // [SCENARIO] Any generated category code errors and the message carries that exact code — pattern-matching 'HISTORY' fails here
        UnknownCategory := CopyStr(UpperCase(Any.AlphabeticText(12)), 1, 20);
        asserterror RoyaltyStatement.LineAmount(UnknownCategory, 25);
        Assert.ExpectedError(UnknownCategory);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedUnknownCategoryFailsLineCredits()
    var
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        UnknownCategory: Code[20];
    begin
        // [SCENARIO] LineCredits also errors on any generated category code, carrying that exact code — pattern-matching 'HISTORY' fails here
        UnknownCategory := CopyStr(UpperCase(Any.AlphabeticText(12)), 1, 20);
        asserterror RoyaltyStatement.LineCredits(UnknownCategory, 25);
        Assert.ExpectedError(UnknownCategory);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BuildStatementListsAgreementPerformancesInOrder()
    var
        TempRoyaltyStatementLine: Record "Royalty Statement Line" temporary;
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
        TotalAmount: Decimal;
        TotalCredits: Integer;
    begin
        // [SCENARIO] The worked example: three performances become three ordered lines with exact amounts, credits and totals
        // [GIVEN] three performances for the agreement and one for a different agreement
        SeedPerformance(1701, 'TRYAL-RS17', 'Hamlet', 'TRAGEDY', 55);
        SeedPerformance(1702, 'TRYAL-RS17', 'As You Like It', 'COMEDY', 35);
        SeedPerformance(1703, 'TRYAL-RS17', 'Othello', 'TRAGEDY', 15);
        SeedPerformance(1704, 'TRYAL-RS17X', 'The Tempest', 'COMEDY', 40);

        // [WHEN] building the statement for the agreement
        RoyaltyStatement.BuildStatement('TRYAL-RS17', TempRoyaltyStatementLine, TotalAmount, TotalCredits);

        // [THEN] one line per performance, in entry order, everything copied and computed
        TempRoyaltyStatementLine.Reset();
        Assert.AreEqual(3, TempRoyaltyStatementLine.Count(), 'Expected exactly one statement line per performance of the agreement — performances of other agreements are excluded');
        VerifyLine(TempRoyaltyStatementLine, 1, 'Hamlet', 'TRAGEDY', 55, 650.0, 25);
        VerifyLine(TempRoyaltyStatementLine, 2, 'As You Like It', 'COMEDY', 35, 580.0, 12);
        VerifyLine(TempRoyaltyStatementLine, 3, 'Othello', 'TRAGEDY', 15, 400.0, 0);
        Assert.AreEqual(1630.0, TotalAmount, 'Expected TotalAmount to be the sum of the three line amounts');
        Assert.AreEqual(37, TotalCredits, 'Expected TotalCredits to be the sum of the three line credits');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BuildStatementClearsBufferAndTotalsFromPreviousBuild()
    var
        TempRoyaltyStatementLine: Record "Royalty Statement Line" temporary;
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
        TotalAmount: Decimal;
        TotalCredits: Integer;
    begin
        // [SCENARIO] A rebuild starts clean: stale buffer lines and old totals must not survive
        // [GIVEN] one performance, a stale line already in the buffer, and non-zero totals from a previous build
        SeedPerformance(1801, 'TRYAL-RS18', 'King Lear', 'TRAGEDY', 40);
        TempRoyaltyStatementLine.Init();
        TempRoyaltyStatementLine."Line No." := 999;
        TempRoyaltyStatementLine.Insert();
        TotalAmount := 123.45;
        TotalCredits := 77;

        // [WHEN] building the statement into the dirty buffer
        RoyaltyStatement.BuildStatement('TRYAL-RS18', TempRoyaltyStatementLine, TotalAmount, TotalCredits);

        // [THEN] only the agreement's own line remains and the totals are recomputed from scratch
        TempRoyaltyStatementLine.Reset();
        Assert.AreEqual(1, TempRoyaltyStatementLine.Count(), 'Expected the buffer to hold only the fresh statement — lines from a previous build must be removed first');
        Assert.IsFalse(TempRoyaltyStatementLine.Get(999), 'Expected the stale line 999 from before the build to be gone');
        VerifyLine(TempRoyaltyStatementLine, 1, 'King Lear', 'TRAGEDY', 40, 500.0, 10);
        Assert.AreEqual(500.0, TotalAmount, 'Expected TotalAmount to be recomputed from scratch, not accumulated onto the old value');
        Assert.AreEqual(10, TotalCredits, 'Expected TotalCredits to be recomputed from scratch, not accumulated onto the old value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BuildStatementYieldsEmptyStatementWithoutPerformances()
    var
        TempRoyaltyStatementLine: Record "Royalty Statement Line" temporary;
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
        TotalAmount: Decimal;
        TotalCredits: Integer;
    begin
        // [SCENARIO] An agreement with no performances yields an empty buffer and zero totals even when the outputs start dirty
        // [GIVEN] a stale buffer line and non-zero totals, and no performances for the agreement
        TempRoyaltyStatementLine.Init();
        TempRoyaltyStatementLine."Line No." := 999;
        TempRoyaltyStatementLine.Insert();
        TotalAmount := 999.99;
        TotalCredits := 99;

        // [WHEN] building the statement for an agreement that played nothing
        RoyaltyStatement.BuildStatement('TRYAL-RS19', TempRoyaltyStatementLine, TotalAmount, TotalCredits);

        // [THEN] the buffer is empty and both totals are zero
        TempRoyaltyStatementLine.Reset();
        Assert.AreEqual(0, TempRoyaltyStatementLine.Count(), 'Expected an empty statement for an agreement with no performances');
        Assert.AreEqual(0.0, TotalAmount, 'Expected TotalAmount to be reset to zero for an agreement with no performances');
        Assert.AreEqual(0, TotalCredits, 'Expected TotalCredits to be reset to zero for an agreement with no performances');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BuildStatementFailsWhenAPerformanceHasUnknownCategory()
    var
        TempRoyaltyStatementLine: Record "Royalty Statement Line" temporary;
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
        TotalAmount: Decimal;
        TotalCredits: Integer;
    begin
        // [SCENARIO] One unknown category anywhere in the agreement fails the whole build with the category in the message
        SeedPerformance(2001, 'TRYAL-RS20', 'Hamlet', 'TRAGEDY', 30);
        SeedPerformance(2002, 'TRYAL-RS20', 'Henry V', 'HISTORY', 25);

        asserterror RoyaltyStatement.BuildStatement('TRYAL-RS20', TempRoyaltyStatementLine, TotalAmount, TotalCredits);
        Assert.ExpectedError('HISTORY');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomAgreementTotalsMatchIndependentComputation()
    var
        TempRoyaltyStatementLine: Record "Royalty Statement Line" temporary;
        RoyaltyStatement: Codeunit "Royalty Statement";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Category: Code[20];
        Audience: Integer;
        i: Integer;
        ExpectedAmount: Decimal;
        ExpectedCredits: Integer;
        TotalAmount: Decimal;
        TotalCredits: Integer;
    begin
        // [SCENARIO] A generated agreement of tragedies and comedies totals exactly what the formulas say — hardcoding the worked example fails here
        // [GIVEN] five performances with generated audiences, expected totals computed independently
        for i := 1 to 5 do begin
            if i mod 2 = 1 then
                Category := 'TRAGEDY'
            else
                Category := 'COMEDY';
            Audience := Any.IntegerInRange(1, 150);
            SeedPerformance(2100 + i, 'TRYAL-RS21', StrSubstNo('Play %1', i), Category, Audience);
            ExpectedAmount += IndependentAmount(Category, Audience);
            ExpectedCredits += IndependentCredits(Category, Audience);
        end;

        // [WHEN] building the statement
        RoyaltyStatement.BuildStatement('TRYAL-RS21', TempRoyaltyStatementLine, TotalAmount, TotalCredits);

        // [THEN] one line per performance and both totals match the independent computation
        TempRoyaltyStatementLine.Reset();
        Assert.AreEqual(5, TempRoyaltyStatementLine.Count(), 'Expected one statement line per generated performance');
        Assert.AreEqual(ExpectedAmount, TotalAmount, 'Expected TotalAmount to match the independently computed sum of the generated fees');
        Assert.AreEqual(ExpectedCredits, TotalCredits, 'Expected TotalCredits to match the independently computed sum of the generated credits');
    end;

    local procedure SeedPerformance(EntryNo: Integer; AgreementNo: Code[20]; PlayName: Text[50]; Category: Code[20]; Audience: Integer)
    var
        RoyaltyPerformance: Record "Royalty Performance";
    begin
        RoyaltyPerformance.Init();
        RoyaltyPerformance."Entry No." := EntryNo;
        RoyaltyPerformance."Agreement No." := AgreementNo;
        RoyaltyPerformance."Play Name" := PlayName;
        RoyaltyPerformance.Category := Category;
        RoyaltyPerformance.Audience := Audience;
        RoyaltyPerformance.Insert();
    end;

    local procedure VerifyLine(var TempRoyaltyStatementLine: Record "Royalty Statement Line" temporary; LineNo: Integer; PlayName: Text[50]; Category: Code[20]; Audience: Integer; Amount: Decimal; Credits: Integer)
    var
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(TempRoyaltyStatementLine.Get(LineNo), StrSubstNo('Expected the statement to contain line %1 — lines are numbered 1, 2, 3, ... in ascending Entry No. order', LineNo));
        Assert.AreEqual(PlayName, TempRoyaltyStatementLine."Play Name", StrSubstNo('Expected the play name copied from the performance onto line %1', LineNo));
        Assert.AreEqual(Category, TempRoyaltyStatementLine.Category, StrSubstNo('Expected the category copied from the performance onto line %1', LineNo));
        Assert.AreEqual(Audience, TempRoyaltyStatementLine.Audience, StrSubstNo('Expected the audience copied from the performance onto line %1', LineNo));
        Assert.AreEqual(Amount, TempRoyaltyStatementLine.Amount, StrSubstNo('Expected the fee computed by the category formula on line %1 (%2, audience %3)', LineNo, Category, Audience));
        Assert.AreEqual(Credits, TempRoyaltyStatementLine.Credits, StrSubstNo('Expected the loyalty credits computed by the credit rule on line %1 (%2, audience %3)', LineNo, Category, Audience));
    end;

    local procedure IndependentAmount(Category: Code[20]; Audience: Integer): Decimal
    begin
        if Category = 'TRAGEDY' then begin
            if Audience > 30 then
                exit(400.0 + 10 * (Audience - 30));
            exit(400.0);
        end;
        if Audience > 20 then
            exit(300.0 + 3 * Audience + 100 + 5 * (Audience - 20));
        exit(300.0 + 3 * Audience);
    end;

    local procedure IndependentCredits(Category: Code[20]; Audience: Integer): Integer
    var
        Credits: Integer;
    begin
        if Audience > 30 then
            Credits := Audience - 30;
        if Category = 'COMEDY' then
            Credits += Audience div 5;
        exit(Credits);
    end;
}
