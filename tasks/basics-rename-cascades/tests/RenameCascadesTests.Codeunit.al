codeunit 50900 "Rename Cascades Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Table Relation] [Rename]

    var
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddNoteStoresTheNoteUnderTheCustomer()
    var
        Customer: Record Customer;
        CustomerNote: Record "Customer Note";
        CustomerNotes: Codeunit "Customer Notes";
        NoteText: Text[250];
    begin
        // [SCENARIO] AddNote files one row under the customer, with the number snapshotted into the legacy field
        // [GIVEN] a customer and a generated note text
        LibrarySales.CreateCustomer(Customer);
        NoteText := GeneratedNote();

        // [WHEN] adding the note
        CustomerNotes.AddNote(Customer."No.", NoteText);

        // [THEN] the row carries the customer number in both fields and the text as passed
        FindNoteByText(CustomerNote, NoteText);
        Assert.AreEqual(Customer."No.", CustomerNote."Customer No.",
            'Expected AddNote to store the customer number in "Customer No."');
        Assert.AreEqual(Customer."No.", CustomerNote."Legacy Customer No.",
            'Expected AddNote to copy the customer number into "Legacy Customer No." as well');
        Assert.AreEqual(NoteText, CustomerNote.Note,
            'Expected the note text to be stored exactly as passed to AddNote');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddNoteRefusesANumberNoCustomerCarries()
    var
        CustomerNotes: Codeunit "Customer Notes";
        UnknownNo: Code[20];
    begin
        // [SCENARIO] the relation is validated: a note cannot point at a customer that does not exist
        // [GIVEN] a generated customer number that no customer carries
        UnknownNo := UnusedCustomerNo();

        // [WHEN] adding a note for it
        asserterror CustomerNotes.AddNote(UnknownNo, GeneratedNote());

        // [THEN] the relation check itself refuses the number, naming the related table
        Assert.ExpectedError('cannot be found in the related table');
        Assert.ExpectedError('Customer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NotesForCountsEveryNoteOfThatCustomerOnly()
    var
        Customer: Record Customer;
        OtherCustomer: Record Customer;
        CustomerNotes: Codeunit "Customer Notes";
        Any: Codeunit Any;
        NoteCount: Integer;
        i: Integer;
    begin
        // [SCENARIO] NotesFor counts the notes of one customer and ignores everyone else's
        // [GIVEN] a random number of notes for one customer and a single note for another
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(OtherCustomer);
        NoteCount := Any.IntegerInRange(2, 5);
        for i := 1 to NoteCount do
            CustomerNotes.AddNote(Customer."No.", GeneratedNote());
        CustomerNotes.AddNote(OtherCustomer."No.", GeneratedNote());

        // [WHEN] counting the notes of each customer
        // [THEN] each customer gets exactly their own notes
        Assert.AreEqual(NoteCount, CustomerNotes.NotesFor(Customer."No."),
            StrSubstNo('Expected NotesFor to count all %1 notes added for customer %2 and none of the other customer''s', NoteCount, Customer."No."));
        Assert.AreEqual(1, CustomerNotes.NotesFor(OtherCustomer."No."),
            StrSubstNo('Expected NotesFor to count only the single note added for customer %1', OtherCustomer."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NotesForIsZeroForACustomerWithoutNotes()
    var
        Customer: Record Customer;
        OtherCustomer: Record Customer;
        CustomerNotes: Codeunit "Customer Notes";
    begin
        // [SCENARIO] a customer with no notes counts zero even when other customers have notes
        // [GIVEN] a customer without notes, next to a customer that has one
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(OtherCustomer);
        CustomerNotes.AddNote(OtherCustomer."No.", GeneratedNote());

        // [WHEN] counting the notes of the customer without any
        // [THEN] the count is zero
        Assert.AreEqual(0, CustomerNotes.NotesFor(Customer."No."),
            StrSubstNo('Expected NotesFor to return 0 for customer %1, who has no notes - the count must be filtered to that customer', Customer."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NotesFollowTheCustomerToItsNewNumber()
    var
        Customer: Record Customer;
        CustomerNotes: Codeunit "Customer Notes";
        Any: Codeunit Any;
        NoteCount: Integer;
        NewNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO] renaming the customer carries every note along to the new number
        // [GIVEN] a customer with a random number of notes, found under the current number
        LibrarySales.CreateCustomer(Customer);
        NoteCount := Any.IntegerInRange(1, 4);
        for i := 1 to NoteCount do
            CustomerNotes.AddNote(Customer."No.", GeneratedNote());
        AssertNotesFiledUnderCurrentNo(CustomerNotes, Customer."No.", NoteCount);

        // [WHEN] the customer is renamed
        NewNo := RenameCustomer(Customer);

        // [THEN] every note is found under the new number
        Assert.AreEqual(NoteCount, CustomerNotes.NotesFor(NewNo),
            StrSubstNo('Expected NotesFor to find all %1 notes under the customer''s new number %2 after the rename - a field only follows a rename when it declares a TableRelation to the renamed table', NoteCount, NewNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoNotesRemainUnderTheOldNumberAfterTheRename()
    var
        Customer: Record Customer;
        CustomerNotes: Codeunit "Customer Notes";
        OldNo: Code[20];
    begin
        // [SCENARIO] the old number is left with nothing once the customer moved on
        // [GIVEN] a customer with two notes, found under the current number
        LibrarySales.CreateCustomer(Customer);
        OldNo := Customer."No.";
        CustomerNotes.AddNote(OldNo, GeneratedNote());
        CustomerNotes.AddNote(OldNo, GeneratedNote());
        AssertNotesFiledUnderCurrentNo(CustomerNotes, OldNo, 2);

        // [WHEN] the customer is renamed
        RenameCustomer(Customer);

        // [THEN] no note is counted under the old number any more
        Assert.AreEqual(0, CustomerNotes.NotesFor(OldNo),
            StrSubstNo('Expected NotesFor to find no notes under the old number %1 after the rename - the count must go by "Customer No." alone, never by "Legacy Customer No."', OldNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StoredCustomerNoFollowsTheRename()
    var
        Customer: Record Customer;
        CustomerNote: Record "Customer Note";
        CustomerNotes: Codeunit "Customer Notes";
        NoteText: Text[250];
        NewNo: Code[20];
    begin
        // [SCENARIO] the related field on the note row is rewritten by the rename itself
        // [GIVEN] a customer with one note, read back once
        LibrarySales.CreateCustomer(Customer);
        NoteText := GeneratedNote();
        CustomerNotes.AddNote(Customer."No.", NoteText);
        FindNoteByText(CustomerNote, NoteText);

        // [WHEN] the customer is renamed
        NewNo := RenameCustomer(Customer);

        // [THEN] the row's "Customer No." now reads the new number
        FindNoteByText(CustomerNote, NoteText);
        Assert.AreEqual(NewNo, CustomerNote."Customer No.",
            'Expected "Customer No." on the note to read the customer''s new number after the rename - the platform updates every field that declares a TableRelation to Customer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LegacyCustomerNoKeepsTheOldNumberAfterTheRename()
    var
        Customer: Record Customer;
        CustomerNote: Record "Customer Note";
        CustomerNotes: Codeunit "Customer Notes";
        NoteText: Text[250];
        OldNo: Code[20];
    begin
        // [SCENARIO] a field without a relation is just text to the rename and stays as written
        // [GIVEN] a customer with one note, read back once
        LibrarySales.CreateCustomer(Customer);
        OldNo := Customer."No.";
        NoteText := GeneratedNote();
        CustomerNotes.AddNote(OldNo, NoteText);
        FindNoteByText(CustomerNote, NoteText);

        // [WHEN] the customer is renamed
        RenameCustomer(Customer);

        // [THEN] the row's "Legacy Customer No." still reads the old number
        FindNoteByText(CustomerNote, NoteText);
        Assert.AreEqual(OldNo, CustomerNote."Legacy Customer No.",
            'Expected "Legacy Customer No." to keep the number the note was filed under - it must stay a plain Code[20] with no table relation, so the rename leaves it alone');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OtherCustomersNotesAreUntouchedByTheRename()
    var
        Customer: Record Customer;
        OtherCustomer: Record Customer;
        CustomerNote: Record "Customer Note";
        CustomerNotes: Codeunit "Customer Notes";
        OtherNoteText: Text[250];
    begin
        // [SCENARIO] the rename moves only the notes of the renamed customer
        // [GIVEN] two customers, each with a note, read back once
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(OtherCustomer);
        CustomerNotes.AddNote(Customer."No.", GeneratedNote());
        OtherNoteText := GeneratedNote();
        CustomerNotes.AddNote(OtherCustomer."No.", OtherNoteText);
        FindNoteByText(CustomerNote, OtherNoteText);

        // [WHEN] the first customer is renamed
        RenameCustomer(Customer);

        // [THEN] the other customer's note still counts and still points at that customer
        Assert.AreEqual(1, CustomerNotes.NotesFor(OtherCustomer."No."),
            StrSubstNo('Expected the note of customer %1 to still be counted under that number after a different customer was renamed', OtherCustomer."No."));
        FindNoteByText(CustomerNote, OtherNoteText);
        Assert.AreEqual(OtherCustomer."No.", CustomerNote."Customer No.",
            'Expected the rename of one customer to leave the notes of every other customer untouched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerNoIsDeclaredWithARelationToCustomer()
    var
        CustomerNote: Record "Customer Note";
        FldRef: FieldRef;
    begin
        // [SCENARIO] the field that must follow the rename declares a TableRelation to Customer
        // [GIVEN] the "Customer Note" table
        // [WHEN] reading the declaration of "Customer No."
        FldRef := FieldOf(CustomerNote.FieldNo("Customer No."));

        // [THEN] it relates to the Customer table
        Assert.AreEqual(Database::Customer, FldRef.Relation(),
            StrSubstNo('Expected "Customer No." on "Customer Note" to declare a TableRelation to the Customer table - that relation is what makes a rename update the field; got a relation to table %1 (0 means none)', FldRef.Relation()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LegacyCustomerNoIsDeclaredWithoutARelation()
    var
        CustomerNote: Record "Customer Note";
        FldRef: FieldRef;
    begin
        // [SCENARIO] the snapshot field declares no relation, so no rename can ever touch it
        // [GIVEN] the "Customer Note" table
        // [WHEN] reading the declaration of "Legacy Customer No."
        FldRef := FieldOf(CustomerNote.FieldNo("Legacy Customer No."));

        // [THEN] it relates to no table at all
        Assert.AreEqual(0, FldRef.Relation(),
            StrSubstNo('Expected "Legacy Customer No." on "Customer Note" to be declared without any table relation - it is a snapshot that must not move with the customer; got a relation to table %1', FldRef.Relation()));
    end;

    // Reading the table before the rename also flushes any buffered inserts, so the
    // cascade sees every note that was added.
    local procedure AssertNotesFiledUnderCurrentNo(var CustomerNotes: Codeunit "Customer Notes"; CustomerNo: Code[20]; ExpectedCount: Integer)
    begin
        Assert.AreEqual(ExpectedCount, CustomerNotes.NotesFor(CustomerNo),
            StrSubstNo('Expected NotesFor to find the %1 notes just added for customer %2 before the rename - AddNote or NotesFor is not working yet', ExpectedCount, CustomerNo));
    end;

    local procedure RenameCustomer(var Customer: Record Customer): Code[20]
    var
        NewNo: Code[20];
    begin
        NewNo := UnusedCustomerNo();
        Customer.Rename(NewNo);
        exit(NewNo);
    end;

    local procedure UnusedCustomerNo(): Code[20]
    var
        Customer: Record Customer;
        Any: Codeunit Any;
        CandidateNo: Code[20];
    begin
        repeat
            CandidateNo := CopyStr('TRYAL-' + UpperCase(Any.AlphanumericText(12)), 1, MaxStrLen(CandidateNo));
        until not Customer.Get(CandidateNo);
        exit(CandidateNo);
    end;

    // AlphanumericText is GUID-based, so every call yields a distinct text; the seeded
    // AlphabeticText would replay the same string from each fresh Any instance.
    local procedure GeneratedNote(): Text[250]
    var
        Any: Codeunit Any;
    begin
        exit(CopyStr('TRYAL note ' + Any.AlphanumericText(30), 1, 250));
    end;

    local procedure FindNoteByText(var CustomerNote: Record "Customer Note"; NoteText: Text[250])
    begin
        CustomerNote.Reset();
        CustomerNote.SetRange(Note, NoteText);
        Assert.AreEqual(1, CustomerNote.Count(),
            StrSubstNo('Expected AddNote to have inserted exactly one "Customer Note" row with the text "%1"', NoteText));
        CustomerNote.FindFirst();
    end;

    local procedure FieldOf(FieldNo: Integer): FieldRef
    var
        CustomerNote: Record "Customer Note";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CustomerNote);
        exit(RecRef.Field(FieldNo));
    end;
}
