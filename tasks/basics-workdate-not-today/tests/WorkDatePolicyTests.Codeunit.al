codeunit 50900 "Work Date Policy Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DefaultPostingDateIsTheWorkDate()
    var
        WorkDatePolicy: Codeunit "Work Date Policy";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The default posting date is the session work date
        // [GIVEN] the work date set to 15 January 2024
        WorkDate(20240115D);

        // [WHEN] asking for the default posting date
        // [THEN] it is 15 January 2024
        Assert.AreEqual(20240115D, WorkDatePolicy.DefaultPostingDate(),
            'Expected DefaultPostingDate to return the session work date (15 January 2024) — reading the calendar clock returns the grading day instead');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DefaultPostingDateFollowsAMovedWorkDate()
    var
        WorkDatePolicy: Codeunit "Work Date Policy";
        Assert: Codeunit Assert;
        MovedWorkDate: Date;
    begin
        // [SCENARIO] Moving the work date moves the default posting date with it
        // [GIVEN] the work date moved to a random day in 2019-2021
        MovedWorkDate := RandomPastWorkDate();
        WorkDate(MovedWorkDate);

        // [WHEN] asking for the default posting date
        // [THEN] it equals the moved work date
        Assert.AreEqual(MovedWorkDate, WorkDatePolicy.DefaultPostingDate(),
            StrSubstNo('Expected DefaultPostingDate to follow the work date after it moved to %1 — the answer must come from the session work date, not from the clock or a fixed date', MovedWorkDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingDateBeforeTheWorkDateIsBackdated()
    var
        WorkDatePolicy: Codeunit "Work Date Policy";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The day before the work date is backdated
        // [GIVEN] the work date set to 15 January 2024
        WorkDate(20240115D);

        // [WHEN] checking 14 January 2024
        // [THEN] it is backdated
        Assert.IsTrue(WorkDatePolicy.IsBackdated(20240114D),
            'Expected 14 January 2024 to be backdated when the work date is 15 January 2024');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingDateInThePreviousYearIsBackdated()
    var
        WorkDatePolicy: Codeunit "Work Date Policy";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A posting date in the previous year is backdated
        // [GIVEN] the work date set to 15 January 2024
        WorkDate(20240115D);

        // [WHEN] checking 31 December 2023
        // [THEN] it is backdated
        Assert.IsTrue(WorkDatePolicy.IsBackdated(20231231D),
            'Expected 31 December 2023 to be backdated when the work date is 15 January 2024 — the comparison must work across a year boundary');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingDateOnTheWorkDateIsNotBackdated()
    var
        WorkDatePolicy: Codeunit "Work Date Policy";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The work date itself is not backdated
        // [GIVEN] the work date set to 15 January 2024
        WorkDate(20240115D);

        // [WHEN] checking 15 January 2024
        // [THEN] it is not backdated
        Assert.IsFalse(WorkDatePolicy.IsBackdated(20240115D),
            'Expected 15 January 2024 not to be backdated when the work date is 15 January 2024 — backdated means strictly before the work date, and a clock-based check calls every 2024 date backdated');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingDateAfterTheWorkDateIsNotBackdated()
    var
        WorkDatePolicy: Codeunit "Work Date Policy";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The day after the work date is not backdated
        // [GIVEN] the work date set to 15 January 2024
        WorkDate(20240115D);

        // [WHEN] checking 16 January 2024
        // [THEN] it is not backdated
        Assert.IsFalse(WorkDatePolicy.IsBackdated(20240116D),
            'Expected 16 January 2024 not to be backdated when the work date is 15 January 2024');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankPostingDateIsNotBackdated()
    var
        WorkDatePolicy: Codeunit "Work Date Policy";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A blank posting date is never backdated
        // [GIVEN] the work date set to 15 January 2024
        WorkDate(20240115D);

        // [WHEN] checking a blank posting date
        // [THEN] it is not backdated
        Assert.IsFalse(WorkDatePolicy.IsBackdated(0D),
            'Expected a blank posting date (0D) not to be backdated — 0D sorts before every real date, so a plain comparison flags it; decide the blank case first');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostingDateAfterAMovedWorkDateIsNotBackdated()
    var
        WorkDatePolicy: Codeunit "Work Date Policy";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        MovedWorkDate: Date;
        PostingDate: Date;
    begin
        // [SCENARIO] After the work date moves, a date just after it is not backdated
        // [GIVEN] the work date moved to a random day in 2019-2021 and a posting date 1-300 days later
        MovedWorkDate := RandomPastWorkDate();
        WorkDate(MovedWorkDate);
        PostingDate := MovedWorkDate + Any.IntegerInRange(1, 300);

        // [WHEN] checking that posting date
        // [THEN] it is not backdated
        Assert.IsFalse(WorkDatePolicy.IsBackdated(PostingDate),
            StrSubstNo('Expected %1 not to be backdated when the work date is %2 — the check must compare against the session work date, not the clock or a fixed date', PostingDate, MovedWorkDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DaysOverdueCountsTheDaysPastTheDueDate()
    var
        WorkDatePolicy: Codeunit "Work Date Policy";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A due date ten days before the work date is 10 days overdue
        // [GIVEN] the work date set to 15 January 2024
        WorkDate(20240115D);

        // [WHEN] asking how overdue 5 January 2024 is
        // [THEN] it is 10 days
        Assert.AreEqual(10, WorkDatePolicy.DaysOverdue(20240105D),
            'Expected a due date of 5 January 2024 to be 10 days overdue when the work date is 15 January 2024');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DaysOverdueCountsAcrossTheYearEnd()
    var
        WorkDatePolicy: Codeunit "Work Date Policy";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Days overdue are counted correctly across a year boundary
        // [GIVEN] the work date set to 15 January 2024
        WorkDate(20240115D);

        // [WHEN] asking how overdue 20 December 2023 is
        // [THEN] it is 26 days
        Assert.AreEqual(26, WorkDatePolicy.DaysOverdue(20231220D),
            'Expected a due date of 20 December 2023 to be 26 days overdue when the work date is 15 January 2024 — 11 days left in December plus 15 in January');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DaysOverdueIsZeroOnTheDueDate()
    var
        WorkDatePolicy: Codeunit "Work Date Policy";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A due date equal to the work date is not overdue
        // [GIVEN] the work date set to 15 January 2024
        WorkDate(20240115D);

        // [WHEN] asking how overdue 15 January 2024 is
        // [THEN] it is 0 days
        Assert.AreEqual(0, WorkDatePolicy.DaysOverdue(20240115D),
            'Expected a due date equal to the work date (15 January 2024) to be 0 days overdue');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DaysOverdueIsZeroForAFutureDueDate()
    var
        WorkDatePolicy: Codeunit "Work Date Policy";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        DueDate: Date;
    begin
        // [SCENARIO] A due date after the work date is never negative days overdue
        // [GIVEN] the work date set to 15 January 2024 and a due date 1-400 days later
        WorkDate(20240115D);
        DueDate := 20240115D + Any.IntegerInRange(1, 400);

        // [WHEN] asking how overdue that due date is
        // [THEN] it is 0 days
        Assert.AreEqual(0, WorkDatePolicy.DaysOverdue(DueDate),
            StrSubstNo('Expected a future due date (%1) to be 0 days overdue when the work date is 15 January 2024 — the result must never be negative', DueDate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DaysOverdueIsZeroForABlankDueDate()
    var
        WorkDatePolicy: Codeunit "Work Date Policy";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A blank due date is not overdue
        // [GIVEN] the work date set to 15 January 2024
        WorkDate(20240115D);

        // [WHEN] asking how overdue a blank due date is
        // [THEN] it is 0 days
        Assert.AreEqual(0, WorkDatePolicy.DaysOverdue(0D),
            'Expected a blank due date (0D) to be 0 days overdue — subtracting 0D from a real date yields centuries, so decide the blank case first');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DaysOverdueFollowsAMovedWorkDate()
    var
        WorkDatePolicy: Codeunit "Work Date Policy";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        MovedWorkDate: Date;
        Offset: Integer;
    begin
        // [SCENARIO] Moving the work date moves the overdue count with it
        // [GIVEN] the work date moved to a random day in 2019-2021 and a due date a random 1-400 days earlier
        MovedWorkDate := RandomPastWorkDate();
        WorkDate(MovedWorkDate);
        Offset := Any.IntegerInRange(1, 400);

        // [WHEN] asking how overdue that due date is
        // [THEN] it is exactly the offset
        Assert.AreEqual(Offset, WorkDatePolicy.DaysOverdue(MovedWorkDate - Offset),
            StrSubstNo('Expected a due date %1 days before the moved work date %2 to be %1 days overdue — counting from the clock or a fixed date gives a different number', Offset, MovedWorkDate));
    end;

    // Any day in 2019-2021: never the calendar date of a grading run, so a
    // clock-based answer always differs from the work date set here.
    local procedure RandomPastWorkDate(): Date
    var
        Any: Codeunit Any;
    begin
        exit(Any.DateInRange(20190101D, 1, 1000));
    end;
}
