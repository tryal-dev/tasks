codeunit 50900 "Follow-up Filter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TodayBecomesTodaysDateFilter()
    var
        FollowupTask: Record "Follow-up Task";
        TaskFilters: Codeunit "Follow-up Task Filters";
        Assert: Codeunit Assert;
        TodayDate: Date;
    begin
        // [SCENARIO] The token 'today' resolves to today's date before the filter is set
        // Date tokens resolve relative to the session work date; pin it to today so
        // the assertions below hold even if the platform pins the work date elsewhere.
        WorkDate(Today());
        TodayDate := Today();
        AddTask(1101, TodayDate);
        AddTask(1102, TodayDate);
        AddTask(1103, TodayDate + 1);
        AddTask(1104, TodayDate - 1);

        TaskFilters.ApplyDueDateFilter(FollowupTask, 'today');

        Assert.AreEqual(Format(TodayDate), FollowupTask.GetFilter("Due Date"),
            'Expected the input today to reach the "Due Date" filter as today''s actual date');
        Assert.AreEqual(2, FollowupTask.Count(),
            'Expected the today filter to match exactly the two tasks due today — not the ones due tomorrow or yesterday');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TomorrowResolvesWhateverItsCasing()
    var
        FollowupTask: Record "Follow-up Task";
        TaskFilters: Codeunit "Follow-up Task Filters";
        Assert: Codeunit Assert;
        TodayDate: Date;
    begin
        // [SCENARIO] The token 'Tomorrow' (mixed case) resolves to tomorrow's date
        WorkDate(Today());
        TodayDate := Today();
        AddTask(1201, TodayDate);
        AddTask(1202, TodayDate + 1);
        AddTask(1203, TodayDate + 1);

        TaskFilters.ApplyDueDateFilter(FollowupTask, 'Tomorrow');

        Assert.AreEqual(Format(TodayDate + 1), FollowupTask.GetFilter("Due Date"),
            'Expected the input Tomorrow to reach the "Due Date" filter as tomorrow''s actual date — token words are case-insensitive');
        Assert.AreEqual(2, FollowupTask.Count(),
            'Expected the Tomorrow filter to match exactly the two tasks due tomorrow');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WeekBecomesTheCurrentCalendarWeekRange()
    var
        FollowupTask: Record "Follow-up Task";
        TaskFilters: Codeunit "Follow-up Task Filters";
        Assert: Codeunit Assert;
        WeekStart: Date;
        WeekEnd: Date;
    begin
        // [SCENARIO] The token 'week' resolves to a Monday..Sunday range for the current week
        WorkDate(Today());
        WeekStart := CalcDate('<-CW>', Today());
        WeekEnd := CalcDate('<CW>', Today());
        AddTask(1301, WeekStart);
        AddTask(1302, WeekEnd);
        AddTask(1303, Today());
        AddTask(1304, WeekStart - 1);
        AddTask(1305, WeekEnd + 1);

        TaskFilters.ApplyDueDateFilter(FollowupTask, 'week');

        Assert.AreEqual(Format(WeekStart) + '..' + Format(WeekEnd), FollowupTask.GetFilter("Due Date"),
            'Expected the input week to become a range from this week''s Monday through this week''s Sunday');
        Assert.AreEqual(3, FollowupTask.Count(),
            'Expected the week filter to include tasks due on the Monday and Sunday edges of this week and exclude the days just outside');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PipeCombinesTwoResolvedTokens()
    var
        FollowupTask: Record "Follow-up Task";
        TaskFilters: Codeunit "Follow-up Task Filters";
        Assert: Codeunit Assert;
        TodayDate: Date;
    begin
        // [SCENARIO] Each side of a | is resolved on its own, producing an either/or date filter
        WorkDate(Today());
        TodayDate := Today();
        AddTask(1401, TodayDate);
        AddTask(1402, TodayDate + 1);
        AddTask(1403, TodayDate - 1);
        AddTask(1404, TodayDate + 2);

        TaskFilters.ApplyDueDateFilter(FollowupTask, 'today|tomorrow');

        Assert.AreEqual(Format(TodayDate) + '|' + Format(TodayDate + 1), FollowupTask.GetFilter("Due Date"),
            'Expected today|tomorrow to become both resolved dates joined by | — each side of the pipe resolved on its own');
        Assert.AreEqual(2, FollowupTask.Count(),
            'Expected the today|tomorrow filter to match the task due today and the task due tomorrow, and nothing else');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PlainDateInputStillWorks()
    var
        FollowupTask: Record "Follow-up Task";
        TaskFilters: Codeunit "Follow-up Task Filters";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TargetDate: Date;
    begin
        // [SCENARIO] Input that is already a plain date passes through the resolution step intact
        TargetDate := Today() + Any.IntegerInRange(30, 120);
        AddTask(1501, TargetDate);
        AddTask(1502, TargetDate + 1);

        TaskFilters.ApplyDueDateFilter(FollowupTask, Format(TargetDate));

        Assert.AreEqual(Format(TargetDate), FollowupTask.GetFilter("Due Date"),
            'Expected an input that is already a date to be applied as that same date — resolving tokens must not mangle ordinary input');
        Assert.AreEqual(1, FollowupTask.Count(),
            'Expected the plain-date filter to match exactly the one task due on that date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MeBecomesTheCurrentUserId()
    var
        FollowupTask: Record "Follow-up Task";
        TaskFilters: Codeunit "Follow-up Task Filters";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The token 'me' resolves to the current user's id
        AddAssignedTask(1601, CopyStr(UserId(), 1, 50));
        AddAssignedTask(1602, CopyStr(UserId(), 1, 50));
        AddAssignedTask(1603, 'TRYAL-SOMEBODY-ELSE');

        TaskFilters.ApplyAssignedToFilter(FollowupTask, 'me');

        Assert.AreEqual(UserId(), FollowupTask.GetFilter("Assigned To"),
            'Expected the input me to reach the "Assigned To" filter as the current user''s id');
        Assert.AreEqual(2, FollowupTask.Count(),
            'Expected the me filter to match exactly the two tasks assigned to the current user, not the decoy assignee');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UserAlsoBecomesTheCurrentUserId()
    var
        FollowupTask: Record "Follow-up Task";
        TaskFilters: Codeunit "Follow-up Task Filters";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The token 'USER' resolves to the current user's id too
        AddAssignedTask(1701, CopyStr(UserId(), 1, 50));
        AddAssignedTask(1702, 'TRYAL-SOMEBODY-ELSE');

        TaskFilters.ApplyAssignedToFilter(FollowupTask, 'USER');

        Assert.AreEqual(UserId(), FollowupTask.GetFilter("Assigned To"),
            'Expected the input USER to reach the "Assigned To" filter as the current user''s id');
        Assert.AreEqual(1, FollowupTask.Count(),
            'Expected the USER filter to match exactly the one task assigned to the current user');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OrdinaryAssigneePassesThroughUnchanged()
    var
        FollowupTask: Record "Follow-up Task";
        TaskFilters: Codeunit "Follow-up Task Filters";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Input that is not a token filters the field as the literal text
        AddAssignedTask(1801, 'TRYAL-ALEX');
        AddAssignedTask(1802, CopyStr(UserId(), 1, 50));

        TaskFilters.ApplyAssignedToFilter(FollowupTask, 'TRYAL-ALEX');

        Assert.AreEqual('TRYAL-ALEX', FollowupTask.GetFilter("Assigned To"),
            'Expected an ordinary assignee code to be applied to the "Assigned To" filter unchanged — only token words get replaced');
        Assert.AreEqual(1, FollowupTask.Count(),
            'Expected the TRYAL-ALEX filter to match exactly the one task assigned to TRYAL-ALEX, not the current user''s task');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TodayCoversTheWholeDayOnDateTime()
    var
        FollowupTask: Record "Follow-up Task";
        TaskFilters: Codeunit "Follow-up Task Filters";
        Assert: Codeunit Assert;
        TodayDate: Date;
    begin
        // [SCENARIO] On the DateTime field, 'today' resolves to a range spanning all of today
        WorkDate(Today());
        TodayDate := Today();
        AddCreatedTask(1901, CreateDateTime(TodayDate, 080000T));
        AddCreatedTask(1902, CreateDateTime(TodayDate, 235000T));
        AddCreatedTask(1903, CreateDateTime(TodayDate + 1, 010000T));
        AddCreatedTask(1904, CreateDateTime(TodayDate - 1, 230000T));

        TaskFilters.ApplyCreatedAtFilter(FollowupTask, 'today');

        Assert.AreEqual(2, FollowupTask.Count(),
            StrSubstNo('Expected the today filter on "Created At" to cover the whole of today — morning and late-evening tasks in, yesterday and tomorrow out. The filter applied was "%1"',
                FollowupTask.GetFilter("Created At")));
    end;

    local procedure AddTask(EntryNo: Integer; DueDate: Date)
    var
        FollowupTask: Record "Follow-up Task";
    begin
        FollowupTask.Init();
        FollowupTask."Entry No." := EntryNo;
        FollowupTask.Description := StrSubstNo('TRYAL task %1', EntryNo);
        FollowupTask."Due Date" := DueDate;
        FollowupTask.Insert();
    end;

    local procedure AddAssignedTask(EntryNo: Integer; AssignedTo: Text[50])
    var
        FollowupTask: Record "Follow-up Task";
    begin
        FollowupTask.Init();
        FollowupTask."Entry No." := EntryNo;
        FollowupTask.Description := StrSubstNo('TRYAL task %1', EntryNo);
        FollowupTask."Assigned To" := AssignedTo;
        FollowupTask.Insert();
    end;

    local procedure AddCreatedTask(EntryNo: Integer; CreatedAt: DateTime)
    var
        FollowupTask: Record "Follow-up Task";
    begin
        FollowupTask.Init();
        FollowupTask."Entry No." := EntryNo;
        FollowupTask.Description := StrSubstNo('TRYAL task %1', EntryNo);
        FollowupTask."Created At" := CreatedAt;
        FollowupTask.Insert();
    end;
}
