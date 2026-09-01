codeunit 50900 "Ticket Resolution Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResolvingAFreshTicketAppliesOnlyTheServiceFields()
    var
        SupportTicket: Record "Support Ticket";
        StaleTicket: Record "Support Ticket";
        TicketResolutionService: Codeunit "Ticket Resolution Service";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SeededDescription: Text[100];
        SeededPriority: Integer;
        Note: Text[100];
    begin
        // [SCENARIO] Resolving an untouched ticket lands the two service fields and nothing else
        SeededDescription := CopyStr(Any.AlphabeticText(40), 1, 100);
        SeededPriority := Any.IntegerInRange(1, 9);
        SeedTicket('TRYAL-T01', SeededDescription, SeededPriority);
        StaleTicket.Get('TRYAL-T01');
        Note := CopyStr(Any.AlphabeticText(40), 1, 100);

        Assert.IsTrue(TicketResolutionService.ResolveTicket(StaleTicket, Note),
            'Expected ResolveTicket to return true for a ticket that still exists');

        SupportTicket.Get('TRYAL-T01');
        Assert.IsTrue(SupportTicket.Resolved,
            'Expected the ticket''s Resolved flag to be true and saved after ResolveTicket');
        Assert.AreEqual(Note, SupportTicket."Resolution Note",
            'Expected the exact note passed to ResolveTicket to be saved in "Resolution Note"');
        Assert.AreEqual(SeededDescription, SupportTicket.Description,
            'Expected Description to be untouched — the service owns only Resolved and "Resolution Note"');
        Assert.AreEqual(SeededPriority, SupportTicket.Priority,
            'Expected Priority to be untouched — the service owns only Resolved and "Resolution Note"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AStaleCopyIsResolvedWithoutARuntimeError()
    var
        SupportTicket: Record "Support Ticket";
        StaleTicket: Record "Support Ticket";
        CurrentTicket: Record "Support Ticket";
        TicketResolutionService: Codeunit "Ticket Resolution Service";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Note: Text[100];
    begin
        // [SCENARIO] The ticket changes after the copy was read; resolving through the old copy still succeeds
        SeedTicket('TRYAL-T02', CopyStr(Any.AlphabeticText(40), 1, 100), Any.IntegerInRange(1, 9));
        StaleTicket.Get('TRYAL-T02');
        // [GIVEN] another user moves the ticket's Priority after the copy was read
        CurrentTicket.Get('TRYAL-T02');
        CurrentTicket.Priority := CurrentTicket.Priority + Any.IntegerInRange(1, 50);
        CurrentTicket.Modify();
        Note := CopyStr(Any.AlphabeticText(40), 1, 100);

        // [WHEN] the service is handed the old copy
        // [THEN] the call succeeds — a service that writes through the copy dies on the platform's version check instead
        Assert.IsTrue(TicketResolutionService.ResolveTicket(StaleTicket, Note),
            'Expected ResolveTicket to succeed on a stale copy — writing through the copy it was handed raises "Unable to change an earlier version of the Support Ticket record"');

        SupportTicket.Get('TRYAL-T02');
        Assert.IsTrue(SupportTicket.Resolved,
            'Expected Resolved to be true on the ticket even though the copy handed in was stale');
        Assert.AreEqual(Note, SupportTicket."Resolution Note",
            'Expected the exact resolution note to land on the ticket even though the copy handed in was stale');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AConcurrentPriorityChangeSurvivesTheResolution()
    var
        SupportTicket: Record "Support Ticket";
        StaleTicket: Record "Support Ticket";
        CurrentTicket: Record "Support Ticket";
        TicketResolutionService: Codeunit "Ticket Resolution Service";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NewPriority: Integer;
    begin
        // [SCENARIO] A Priority set by another user after the copy was read is still there after resolving
        SeedTicket('TRYAL-T03', CopyStr(Any.AlphabeticText(40), 1, 100), Any.IntegerInRange(1, 9));
        StaleTicket.Get('TRYAL-T03');
        // [GIVEN] another user moves the ticket's Priority after the copy was read
        CurrentTicket.Get('TRYAL-T03');
        NewPriority := CurrentTicket.Priority + Any.IntegerInRange(1, 50);
        CurrentTicket.Priority := NewPriority;
        CurrentTicket.Modify();

        // [WHEN] the service resolves the ticket through the old copy
        TicketResolutionService.ResolveTicket(StaleTicket, CopyStr(Any.AlphabeticText(40), 1, 100));

        // [THEN] the other user's Priority is still on the row
        SupportTicket.Get('TRYAL-T03');
        Assert.AreEqual(NewPriority, SupportTicket.Priority,
            'Expected the Priority set by another user after the copy was read to survive the resolution — writing the copy''s fields back silently undoes their change (the lost update)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AConcurrentDescriptionChangeSurvivesTheResolution()
    var
        SupportTicket: Record "Support Ticket";
        StaleTicket: Record "Support Ticket";
        CurrentTicket: Record "Support Ticket";
        TicketResolutionService: Codeunit "Ticket Resolution Service";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NewDescription: Text[100];
        Note: Text[100];
    begin
        // [SCENARIO] A Description rewritten by another user after the copy was read is still there after resolving
        SeedTicket('TRYAL-T04', CopyStr(Any.AlphabeticText(40), 1, 100), Any.IntegerInRange(1, 9));
        StaleTicket.Get('TRYAL-T04');
        // [GIVEN] another user rewrites the ticket's Description after the copy was read
        CurrentTicket.Get('TRYAL-T04');
        NewDescription := CopyStr(Any.AlphabeticText(60), 1, 100);
        CurrentTicket.Description := NewDescription;
        CurrentTicket.Modify();
        Note := CopyStr(Any.AlphabeticText(40), 1, 100);

        // [WHEN] the service resolves the ticket through the old copy
        TicketResolutionService.ResolveTicket(StaleTicket, Note);

        // [THEN] the other user's Description and the service's note coexist on the row
        SupportTicket.Get('TRYAL-T04');
        Assert.AreEqual(NewDescription, SupportTicket.Description,
            'Expected the Description rewritten by another user after the copy was read to survive the resolution — writing the copy''s fields back silently undoes their change (the lost update)');
        Assert.AreEqual(Note, SupportTicket."Resolution Note",
            'Expected the resolution note to land on the same row that keeps the other user''s Description — both changes must coexist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AVanishedTicketIsReportedAsFalseAndStaysDeleted()
    var
        SupportTicket: Record "Support Ticket";
        StaleTicket: Record "Support Ticket";
        CurrentTicket: Record "Support Ticket";
        TicketResolutionService: Codeunit "Ticket Resolution Service";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] The ticket is deleted after the copy was read; the service reports it instead of erroring
        SeedTicket('TRYAL-T05', CopyStr(Any.AlphabeticText(40), 1, 100), Any.IntegerInRange(1, 9));
        StaleTicket.Get('TRYAL-T05');
        // [GIVEN] another user deletes the ticket after the copy was read
        CurrentTicket.Get('TRYAL-T05');
        CurrentTicket.Delete();

        // [WHEN] the service is handed the copy of the now-deleted ticket
        // [THEN] it returns false — it must not raise "does not exist" and must not resurrect the row
        Assert.IsFalse(TicketResolutionService.ResolveTicket(StaleTicket, CopyStr(Any.AlphabeticText(40), 1, 100)),
            'Expected ResolveTicket to report a vanished ticket by returning false, not by raising a runtime error');
        Assert.IsFalse(SupportTicket.Get('TRYAL-T05'),
            'Expected the vanished ticket to stay deleted — the service must not recreate the row from the stale copy');
    end;

    local procedure SeedTicket(TicketNo: Code[20]; TicketDescription: Text[100]; TicketPriority: Integer)
    var
        SupportTicket: Record "Support Ticket";
    begin
        SupportTicket.Init();
        SupportTicket."Ticket No." := TicketNo;
        SupportTicket.Description := TicketDescription;
        SupportTicket.Priority := TicketPriority;
        SupportTicket.Insert();
    end;
}
