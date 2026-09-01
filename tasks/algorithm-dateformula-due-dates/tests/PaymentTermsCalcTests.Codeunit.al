codeunit 50900 "Payment Terms Calc Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DayOffsetMovesExactlyThatManyDays()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        DueDate: Date;
    begin
        // [SCENARIO] <14D> from 6 March 2026 falls due 20 March 2026
        DueDate := Calculator.CalcDueDate(DMY2Date(6, 3, 2026), '<14D>');

        Assert.AreEqual(DMY2Date(20, 3, 2026), DueDate, 'Expected <14D> to move the due date exactly 14 days past the document date 06-03-2026');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MonthStepClampsToShorterMonthEnd()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        DueDate: Date;
    begin
        // [SCENARIO] <1M> from 31 January 2026 clamps to 28 February 2026 — day 31 does not exist in February
        DueDate := Calculator.CalcDueDate(DMY2Date(31, 1, 2026), '<1M>');

        Assert.AreEqual(DMY2Date(28, 2, 2026), DueDate, 'Expected <1M> from 31-01-2026 to clamp to the last day of February 2026 because February has no day 31');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MonthStepLandsOnLeapDay()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        DueDate: Date;
    begin
        // [SCENARIO] <1M> from 31 January 2024 clamps to 29 February 2024 — 2024 is a leap year
        DueDate := Calculator.CalcDueDate(DMY2Date(31, 1, 2024), '<1M>');

        Assert.AreEqual(DMY2Date(29, 2, 2024), DueDate, 'Expected <1M> from 31-01-2024 to land on the leap day 29-02-2024, the last day of February in a leap year');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure YearStepOffLeapDayClampsToFeb28()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        DueDate: Date;
    begin
        // [SCENARIO] <1Y> from 29 February 2024 clamps to 28 February 2025 — 2025 has no leap day
        DueDate := Calculator.CalcDueDate(DMY2Date(29, 2, 2024), '<1Y>');

        Assert.AreEqual(DMY2Date(28, 2, 2025), DueDate, 'Expected <1Y> from the leap day 29-02-2024 to clamp to 28-02-2025 because 2025 has no 29 February');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MonthEndFirstThenMonthKeepsTheEndOfMonthDay()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        DueDate: Date;
    begin
        // [SCENARIO] <CM+1M> from 15 February 2024: CM gives 29-02-2024, then +1M gives 29-03-2024 — not the end of March
        DueDate := Calculator.CalcDueDate(DMY2Date(15, 2, 2024), '<CM+1M>');

        Assert.AreEqual(DMY2Date(29, 3, 2024), DueDate, 'Expected <CM+1M> from 15-02-2024 to apply CM first (29-02-2024) and then move one month to 29-03-2024 — terms apply strictly left to right');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MonthFirstThenMonthEndReachesTheNextMonthEnd()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        DueDate: Date;
    begin
        // [SCENARIO] <1M+CM> from 15 February 2024: +1M gives 15-03-2024, then CM gives 31-03-2024
        DueDate := Calculator.CalcDueDate(DMY2Date(15, 2, 2024), '<1M+CM>');

        Assert.AreEqual(DMY2Date(31, 3, 2024), DueDate, 'Expected <1M+CM> from 15-02-2024 to move one month first (15-03-2024) and then jump to the month end 31-03-2024 — terms apply strictly left to right');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeDaysWalkBackFromTheMonthEnd()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        DueDate: Date;
    begin
        // [SCENARIO] <CM-10D> from 18 April 2026: CM gives 30-04-2026, then -10D gives 20-04-2026
        DueDate := Calculator.CalcDueDate(DMY2Date(18, 4, 2026), '<CM-10D>');

        Assert.AreEqual(DMY2Date(20, 4, 2026), DueDate, 'Expected <CM-10D> from 18-04-2026 to reach the month end 30-04-2026 and then walk 10 days back to 20-04-2026');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ThreeTermsApplyLeftToRight()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        DueDate: Date;
    begin
        // [SCENARIO] <CM+1M-10D> from 18 April 2026: CM gives 30-04-2026, +1M gives 30-05-2026, -10D gives 20-05-2026
        DueDate := Calculator.CalcDueDate(DMY2Date(18, 4, 2026), '<CM+1M-10D>');

        Assert.AreEqual(DMY2Date(20, 5, 2026), DueDate, 'Expected <CM+1M-10D> from 18-04-2026 to apply all three terms left to right: month end 30-04-2026, one month to 30-05-2026, then 10 days back to 20-05-2026');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WeekdayTermFindsTheNextTuesday()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        DueDate: Date;
    begin
        // [SCENARIO] <WD2> from Friday 6 March 2026 lands on Tuesday 10 March 2026
        DueDate := Calculator.CalcDueDate(DMY2Date(6, 3, 2026), '<WD2>');

        Assert.AreEqual(DMY2Date(10, 3, 2026), DueDate, 'Expected <WD2> from Friday 06-03-2026 to land on the next Tuesday, 10-03-2026 (weekday 2, Monday = 1)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ForwardWeekdayFromThatWeekdayMovesAFullWeekAhead()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        DueDate: Date;
    begin
        // [SCENARIO] <WD2> from Tuesday 10 March 2026 lands on the next Tuesday, 17 March 2026 — never the start date itself
        DueDate := Calculator.CalcDueDate(DMY2Date(10, 3, 2026), '<WD2>');

        Assert.AreEqual(DMY2Date(17, 3, 2026), DueDate, 'Expected <WD2> from Tuesday 10-03-2026 to move at least one day forward and so land a full week later on 17-03-2026, never on the start date itself');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BackwardWeekdayFromThatWeekdayMovesAFullWeekBack()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        DueDate: Date;
    begin
        // [SCENARIO] <-WD2> from Tuesday 10 March 2026 lands on the previous Tuesday, 3 March 2026
        DueDate := Calculator.CalcDueDate(DMY2Date(10, 3, 2026), '<-WD2>');

        Assert.AreEqual(DMY2Date(3, 3, 2026), DueDate, 'Expected <-WD2> from Tuesday 10-03-2026 to move at least one day back and so land on the previous Tuesday, 03-03-2026');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankFormulaFallsDueOnTheDocumentDate()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        DueDate: Date;
    begin
        // [SCENARIO] blank text means due immediately
        DueDate := Calculator.CalcDueDate(DMY2Date(6, 3, 2026), '');

        Assert.AreEqual(DMY2Date(6, 3, 2026), DueDate, 'Expected a blank formula to mean due immediately: the due date is the document date itself');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvalidFormulaTextRaisesAnErrorNamingIt()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] text that is not a date formula must fail with an error that includes the rejected text
        asserterror Calculator.CalcDueDate(DMY2Date(6, 3, 2026), '<2X>');

        Assert.ExpectedError('2X');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PaymentOnTheDiscountDateStillQualifies()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        Qualifies: Boolean;
    begin
        // [SCENARIO] discount terms <8D> from 10 June 2026 give 18 June 2026; paying exactly then earns the discount
        Qualifies := Calculator.QualifiesForDiscount(DMY2Date(10, 6, 2026), DMY2Date(18, 6, 2026), '<8D>');

        Assert.IsTrue(Qualifies, 'Expected a payment made exactly on the discount date (18-06-2026, from <8D> over 10-06-2026) to still qualify for the discount, got false');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PaymentBeforeTheDiscountDateQualifies()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        Qualifies: Boolean;
    begin
        // [SCENARIO] discount terms <CM> from 10 June 2026 give 30 June 2026; paying mid-month earns the discount
        Qualifies := Calculator.QualifiesForDiscount(DMY2Date(10, 6, 2026), DMY2Date(25, 6, 2026), '<CM>');

        Assert.IsTrue(Qualifies, 'Expected a payment on 25-06-2026 to qualify when the discount terms <CM> over 10-06-2026 allow until 30-06-2026, got false');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PaymentAfterTheDiscountDateDoesNotQualify()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        Qualifies: Boolean;
    begin
        // [SCENARIO] discount terms <8D> from 10 June 2026 give 18 June 2026; paying one day later loses the discount
        Qualifies := Calculator.QualifiesForDiscount(DMY2Date(10, 6, 2026), DMY2Date(19, 6, 2026), '<8D>');

        Assert.IsFalse(Qualifies, 'Expected a payment one day after the discount date (19-06-2026, when <8D> over 10-06-2026 allows until 18-06-2026) to no longer qualify, got true');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomDayOffsetMatchesPlainCalendarArithmetic()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        DocumentDate: Date;
        Days: Integer;
        DueDate: Date;
    begin
        // [SCENARIO] <nD> for a random n and document date is plain date + n — hardcoded example answers fail here
        DocumentDate := DMY2Date(1, 1, 2025) + Any.IntegerInRange(0, 700);
        Days := Any.IntegerInRange(1, 300);

        DueDate := Calculator.CalcDueDate(DocumentDate, StrSubstNo('<%1D>', Days));

        Assert.AreEqual(DocumentDate + Days, DueDate, StrSubstNo('Expected <%1D> applied to %2 to fall due exactly %1 days later', Days, DocumentDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomWeekOffsetMovesWholeWeeks()
    var
        Calculator: Codeunit "Payment Terms Calculator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        DocumentDate: Date;
        Weeks: Integer;
        DueDate: Date;
    begin
        // [SCENARIO] <nW> for a random n and document date is plain date + 7n — hardcoded example answers fail here
        DocumentDate := DMY2Date(1, 1, 2025) + Any.IntegerInRange(0, 700);
        Weeks := Any.IntegerInRange(1, 52);

        DueDate := Calculator.CalcDueDate(DocumentDate, StrSubstNo('<%1W>', Weeks));

        Assert.AreEqual(DocumentDate + Weeks * 7, DueDate, StrSubstNo('Expected <%1W> applied to %2 to fall due exactly %3 days later', Weeks, DocumentDate, Weeks * 7));
    end;
}
