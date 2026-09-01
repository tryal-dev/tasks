codeunit 50900 "Record Note Manager Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddNoteCreatesASingleNoteLinkOnTheCustomer()
    var
        Customer: Record Customer;
        RecordLink: Record "Record Link";
        RecordNoteManager: Codeunit "Record Note Manager";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] AddNote attaches exactly one Note-type record link to the customer
        CreateCustomer(Customer);

        RecordNoteManager.AddNote(Customer, 'Called them on Monday');

        RecordLink.SetRange("Record ID", Customer.RecordId());
        Assert.AreEqual(1, RecordLink.Count(), 'Expected AddNote to insert exactly one "Record Link" row attached to the customer via "Record ID"');
        RecordLink.FindFirst();
        Assert.IsTrue(RecordLink.Type = RecordLink.Type::Note, StrSubstNo('Expected the inserted link to have Type = Note, got %1', RecordLink.Type));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddNoteReturnsTheAssignedLinkId()
    var
        Customer: Record Customer;
        RecordLink: Record "Record Link";
        RecordNoteManager: Codeunit "Record Note Manager";
        Assert: Codeunit Assert;
        LinkID: BigInteger;
    begin
        // [SCENARIO] AddNote returns the auto-assigned "Link ID" of the row it inserted
        CreateCustomer(Customer);

        LinkID := RecordNoteManager.AddNote(Customer, 'Prefers e-mail over phone');

        Assert.IsTrue(RecordLink.Get(LinkID), StrSubstNo('Expected AddNote to return the "Link ID" of the inserted row — no "Record Link" row has ID %1', LinkID));
        Assert.AreEqual(Format(Customer.RecordId()), Format(RecordLink."Record ID"), 'Expected the link behind the returned "Link ID" to be attached to the customer the note was added to');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddNoteStoresSpecialCharactersInTheStandardFormat()
    var
        Customer: Record Customer;
        RecordLink: Record "Record Link";
        RecordNoteManager: Codeunit "Record Note Manager";
        RecordLinkManagement: Codeunit "Record Link Management";
        Assert: Codeunit Assert;
        NoteText: Text;
    begin
        // [SCENARIO] a note with special characters decodes through the standard reader
        CreateCustomer(Customer);
        NoteText := 'Zürich Café — O''Brien & Søns, 100% Ærlig';

        RecordNoteManager.AddNote(Customer, NoteText);

        RecordLink.SetRange("Record ID", Customer.RecordId());
        RecordLink.FindFirst();
        RecordLink.CalcFields(Note);
        Assert.AreEqual(NoteText, RecordLinkManagement.ReadNote(RecordLink), 'Expected the note to decode through the standard "Record Link Management" reader — a hand-written OutStream blob is not the format the platform stores notes in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddNoteRoundTripsGeneratedText()
    var
        Customer: Record Customer;
        RecordLink: Record "Record Link";
        RecordNoteManager: Codeunit "Record Note Manager";
        RecordLinkManagement: Codeunit "Record Link Management";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NoteText: Text;
    begin
        // [SCENARIO] a freshly generated note text survives the round-trip through the standard reader
        CreateCustomer(Customer);
        NoteText := 'TRYAL-N4 ' + Any.AlphanumericText(120);

        RecordNoteManager.AddNote(Customer, NoteText);

        RecordLink.SetRange("Record ID", Customer.RecordId());
        RecordLink.FindFirst();
        RecordLink.CalcFields(Note);
        Assert.AreEqual(NoteText, RecordLinkManagement.ReadNote(RecordLink), 'Expected the generated note text to come back unchanged through the standard "Record Link Management" reader');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReadNoteDecodesAStandardNote()
    var
        Customer: Record Customer;
        RecordNoteManager: Codeunit "Record Note Manager";
        Assert: Codeunit Assert;
        LinkID: BigInteger;
        NoteText: Text;
    begin
        // [SCENARIO] ReadNote decodes a note written by the standard writer
        CreateCustomer(Customer);
        NoteText := 'Første kvartal — O''Malley & Co';
        LinkID := SeedNote(Customer.RecordId(), NoteText, CompanyName());

        Assert.AreEqual(NoteText, RecordNoteManager.ReadNote(LinkID), 'Expected ReadNote to decode a note written by the standard "Record Link Management" writer (is the Note BLOB loaded with CalcFields before decoding?)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReadNoteReturnsEmptyTextWhenTheLinkDoesNotExist()
    var
        RecordLink: Record "Record Link";
        RecordNoteManager: Codeunit "Record Note Manager";
        Assert: Codeunit Assert;
        MissingId: BigInteger;
    begin
        // [SCENARIO] ReadNote on an unknown Link ID returns an empty text instead of failing
        if RecordLink.FindLast() then
            MissingId := RecordLink."Link ID" + 1000000
        else
            MissingId := 1000000;

        Assert.AreEqual('', RecordNoteManager.ReadNote(MissingId), 'Expected an empty text for a "Link ID" no record link carries — not an error and not leftover content');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountNotesCountsOnlyTheCustomersNoteLinks()
    var
        Customer: Record Customer;
        OtherCustomer: Record Customer;
        RecordNoteManager: Codeunit "Record Note Manager";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SeededNotes: Integer;
        i: Integer;
    begin
        // [SCENARIO] CountNotes sees the customer's notes but not its web links or other customers' notes
        CreateCustomer(Customer);
        CreateCustomer(OtherCustomer);
        SeededNotes := Any.IntegerInRange(2, 5);
        for i := 1 to SeededNotes do
            SeedNote(Customer.RecordId(), StrSubstNo('Note no. %1', i), CompanyName());
        Customer.AddLink('https://tryal.example.com/docs', 'Supplier docs');
        SeedNote(OtherCustomer.RecordId(), 'Someone else''s note', CompanyName());

        Assert.AreEqual(SeededNotes, RecordNoteManager.CountNotes(Customer), 'Expected exactly the seeded Note-type links of this customer to count — its web link and the other customer''s note must be ignored');
        Assert.AreEqual(1, RecordNoteManager.CountNotes(OtherCustomer), 'Expected the other customer to count exactly its own single note');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CopyLinksGivesTheTargetReadableCopies()
    var
        FromCustomer: Record Customer;
        ToCustomer: Record Customer;
        RecordLink: Record "Record Link";
        RecordNoteManager: Codeunit "Record Note Manager";
        RecordLinkManagement: Codeunit "Record Link Management";
        Assert: Codeunit Assert;
        NoteText: Text;
    begin
        // [SCENARIO] copying links gives the target its own note and web link, note text intact
        CreateCustomer(FromCustomer);
        CreateCustomer(ToCustomer);
        NoteText := 'Delivery gate 4 — ring twice';
        SeedNote(FromCustomer.RecordId(), NoteText, CompanyName());
        FromCustomer.AddLink('https://tryal.example.com/contract', 'Contract');

        RecordNoteManager.CopyLinks(FromCustomer, ToCustomer);

        RecordLink.SetRange("Record ID", ToCustomer.RecordId());
        Assert.AreEqual(2, RecordLink.Count(), 'Expected both the note and the web link to be copied onto the target customer');
        RecordLink.SetRange(Type, RecordLink.Type::Note);
        RecordLink.FindFirst();
        RecordLink.CalcFields(Note);
        Assert.AreEqual(NoteText, RecordLinkManagement.ReadNote(RecordLink), 'Expected the copied note to keep its text in the standard format on the target customer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CopyLinksLeavesTheSourceUntouched()
    var
        FromCustomer: Record Customer;
        ToCustomer: Record Customer;
        RecordLink: Record "Record Link";
        RecordNoteManager: Codeunit "Record Note Manager";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] copying links does not move or delete the source customer's links
        CreateCustomer(FromCustomer);
        CreateCustomer(ToCustomer);
        SeedNote(FromCustomer.RecordId(), 'Keep me here', CompanyName());
        SeedNote(FromCustomer.RecordId(), 'Me too', CompanyName());

        RecordNoteManager.CopyLinks(FromCustomer, ToCustomer);

        RecordLink.SetRange("Record ID", FromCustomer.RecordId());
        Assert.AreEqual(2, RecordLink.Count(), 'Expected the source customer to keep its own two links after the copy — copying must not move or delete them');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteDanglingLinksRemovesLinksOfDeletedRecords()
    var
        DoomedCustomer: Record Customer;
        DoomedItem: Record Item;
        RecordLink: Record "Record Link";
        RecordNoteManager: Codeunit "Record Note Manager";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        DoomedCustomerRecordId: RecordId;
        DoomedItemRecordId: RecordId;
    begin
        // [SCENARIO] after the sweep, no link of a deleted record is left, whatever table it lived in
        CreateCustomer(DoomedCustomer);
        DoomedCustomerRecordId := DoomedCustomer.RecordId();
        SeedNote(DoomedCustomerRecordId, 'Company-stamped note', CompanyName());
        SeedNote(DoomedCustomerRecordId, 'Company-less note', '');
        LibraryInventory.CreateItem(DoomedItem);
        DoomedItemRecordId := DoomedItem.RecordId();
        SeedNote(DoomedItemRecordId, 'Note on an item', CompanyName());
        DoomedCustomer.Delete();
        DoomedItem.Delete();

        RecordNoteManager.DeleteDanglingLinks();

        RecordLink.SetRange("Record ID", DoomedCustomerRecordId);
        Assert.AreEqual(0, RecordLink.Count(), 'Expected every link of the deleted customer to be swept — both the row stamped with the current company and the row with an empty Company');
        RecordLink.SetRange("Record ID", DoomedItemRecordId);
        Assert.AreEqual(0, RecordLink.Count(), 'Expected the deleted item''s link to be swept too — the sweep must work for any table a "Record ID" points at, not just customers');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteDanglingLinksKeepsLinksOfLiveRecords()
    var
        LiveCustomer: Record Customer;
        DoomedCustomer: Record Customer;
        RecordLink: Record "Record Link";
        RecordNoteManager: Codeunit "Record Note Manager";
        RecordLinkManagement: Codeunit "Record Link Management";
        Assert: Codeunit Assert;
        LiveLinkID: BigInteger;
        NoteText: Text;
    begin
        // [SCENARIO] the sweep only removes dangling links, not those of existing records
        CreateCustomer(LiveCustomer);
        CreateCustomer(DoomedCustomer);
        NoteText := 'Still alive and readable';
        LiveLinkID := SeedNote(LiveCustomer.RecordId(), NoteText, CompanyName());
        SeedNote(DoomedCustomer.RecordId(), 'About to dangle', CompanyName());
        DoomedCustomer.Delete();

        RecordNoteManager.DeleteDanglingLinks();

        Assert.IsTrue(RecordLink.Get(LiveLinkID), 'Expected the live customer''s note to survive the sweep — only links whose record is gone may be deleted');
        RecordLink.CalcFields(Note);
        Assert.AreEqual(NoteText, RecordLinkManagement.ReadNote(RecordLink), 'Expected the surviving note to still decode to its original text');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteDanglingLinksLeavesOtherCompaniesLinksAlone()
    var
        DoomedCustomer: Record Customer;
        RecordLink: Record "Record Link";
        RecordNoteManager: Codeunit "Record Note Manager";
        Assert: Codeunit Assert;
        ForeignLinkID: BigInteger;
    begin
        // [SCENARIO] a link stamped with another company's name is out of the sweep's scope
        CreateCustomer(DoomedCustomer);
        ForeignLinkID := SeedNote(DoomedCustomer.RecordId(), 'Belongs to another company', 'TRYAL-OTHER');
        DoomedCustomer.Delete();

        RecordNoteManager.DeleteDanglingLinks();

        Assert.IsTrue(RecordLink.Get(ForeignLinkID), 'Expected the link stamped with another company''s name to be left alone — the sweep may only touch links whose Company is empty or the current company');
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
    end;

    local procedure SeedNote(AttachTo: RecordId; NoteText: Text; CompanyValue: Text): BigInteger
    var
        RecordLink: Record "Record Link";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        RecordLink.Init();
        RecordLink."Record ID" := AttachTo;
        RecordLink.Type := RecordLink.Type::Note;
        RecordLink.Company := CopyStr(CompanyValue, 1, MaxStrLen(RecordLink.Company));
        RecordLinkManagement.WriteNote(RecordLink, NoteText);
        RecordLink.Insert();
        exit(RecordLink."Link ID");
    end;
}
