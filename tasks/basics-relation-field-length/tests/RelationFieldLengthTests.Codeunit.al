codeunit 50900 "Relation Field Length Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Table Relation] [Field Length]

    var
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoteIsStoredForAnOrdinaryCustomerNumber()
    var
        Customer: Record Customer;
        CustomerNote: Record "Customer Note";
        CustomerNoteMgt: Codeunit "Customer Note Mgt.";
        NoteText: Text[250];
    begin
        // [SCENARIO] A note for a customer with a short, number-series style number is stored as given
        // [GIVEN] an ordinary customer and a generated note text
        LibrarySales.CreateCustomer(Customer);
        NoteText := GeneratedNote();

        // [WHEN] adding the note
        CustomerNoteMgt.AddNote(Customer."No.", NoteText);

        // [THEN] one "Customer Note" row carries that customer number and that text
        CustomerNote.SetRange("Customer No.", Customer."No.");
        Assert.AreEqual(1, CustomerNote.Count(),
            StrSubstNo('Expected exactly one note stored for customer %1 after a single AddNote call', Customer."No."));
        CustomerNote.FindFirst();
        Assert.AreEqual(NoteText, CustomerNote.Note,
            'Expected the note text to be stored on the row exactly as passed to AddNote');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoteIsStoredForATwentyCharacterCustomerNumber()
    var
        Customer: Record Customer;
        CustomerNote: Record "Customer Note";
        CustomerNoteMgt: Codeunit "Customer Note Mgt.";
        NoteText: Text[250];
    begin
        // [SCENARIO] A customer number that uses all 20 characters of Customer."No." is stored on the note in full
        // [GIVEN] a customer whose number is exactly 20 characters long, and a generated note text
        CreateCustomerWithTwentyCharacterNo(Customer);
        NoteText := GeneratedNote();

        // [WHEN] adding a note for that customer
        CustomerNoteMgt.AddNote(Customer."No.", NoteText);

        // [THEN] the row exists and carries the whole 20-character number, not a shortened one
        CustomerNote.SetRange(Note, NoteText);
        Assert.IsTrue(CustomerNote.FindFirst(),
            StrSubstNo('Expected AddNote to insert a "Customer Note" row for customer %1', Customer."No."));
        Assert.AreEqual(Customer."No.", CustomerNote."Customer No.",
            'Expected "Customer No." on the note to hold the full 20-character customer number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StoredCustomerNumberResolvesToItsCustomer()
    var
        Customer: Record Customer;
        FoundCustomer: Record Customer;
        CustomerNote: Record "Customer Note";
        CustomerNoteMgt: Codeunit "Customer Note Mgt.";
        NoteText: Text[250];
    begin
        // [SCENARIO] The customer number a note stores still points at an existing customer
        // [GIVEN] a customer whose number is exactly 20 characters long, and a generated note text
        CreateCustomerWithTwentyCharacterNo(Customer);
        NoteText := GeneratedNote();

        // [WHEN] adding a note for that customer
        CustomerNoteMgt.AddNote(Customer."No.", NoteText);

        // [THEN] Customer.Get with the number read back from the note finds that very customer
        CustomerNote.SetRange(Note, NoteText);
        Assert.IsTrue(CustomerNote.FindFirst(),
            StrSubstNo('Expected AddNote to insert a "Customer Note" row for customer %1', Customer."No."));
        Assert.IsTrue(FoundCustomer.Get(CustomerNote."Customer No."),
            StrSubstNo('Expected the customer number stored on the note (%1) to resolve to an existing customer', CustomerNote."Customer No."));
        Assert.AreEqual(Customer.Name, FoundCustomer.Name,
            'Expected the number stored on the note to lead back to the customer the note was added for');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoteTextOfMaximumLengthRoundTrips()
    var
        Customer: Record Customer;
        CustomerNote: Record "Customer Note";
        CustomerNoteMgt: Codeunit "Customer Note Mgt.";
        Any: Codeunit Any;
        LongNote: Text[250];
    begin
        // [SCENARIO] A 250-character note is stored without loss
        // [GIVEN] an ordinary customer and a generated 250-character note
        LibrarySales.CreateCustomer(Customer);
        LongNote := CopyStr(Any.AlphabeticText(250), 1, 250);

        // [WHEN] adding the note
        CustomerNoteMgt.AddNote(Customer."No.", LongNote);

        // [THEN] the stored text equals all 250 characters
        CustomerNote.SetRange("Customer No.", Customer."No.");
        Assert.IsTrue(CustomerNote.FindFirst(),
            StrSubstNo('Expected AddNote to insert a "Customer Note" row for customer %1', Customer."No."));
        Assert.AreEqual(LongNote, CustomerNote.Note,
            'Expected a 250-character note to be stored in full - Note is declared as Text[250]');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerNoIsDeclaredWithTheLengthOfTheCustomerKey()
    var
        Customer: Record Customer;
        FldRef: FieldRef;
    begin
        // [SCENARIO] The relation field is declared as Code with exactly the length of Customer."No."
        // [GIVEN] the "Customer Note" table
        // [WHEN] reading the declaration of "Customer No."
        FldRef := CustomerNoField();

        // [THEN] it is a Code field of length 20 - no shorter (overflows), no longer (accepts numbers no customer can have)
        Assert.AreEqual(Format(FieldType::Code), Format(FldRef.Type),
            StrSubstNo('Expected "Customer No." on "Customer Note" to stay a Code field, like the Customer."No." it relates to, not %1', FldRef.Type));
        Assert.AreEqual(MaxStrLen(Customer."No."), FldRef.Length,
            'Expected "Customer No." on "Customer Note" to be declared with exactly the length of Customer."No." (Code[20]) - the key it relates to');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerNoStillRelatesToTheCustomerTable()
    var
        FldRef: FieldRef;
    begin
        // [SCENARIO] Fixing the length does not mean dropping the relation
        // [GIVEN] the "Customer Note" table
        // [WHEN] reading the declaration of "Customer No."
        FldRef := CustomerNoField();

        // [THEN] the field still relates to the Customer table
        Assert.AreEqual(Database::Customer, FldRef.Relation(),
            'Expected "Customer No." on "Customer Note" to keep its TableRelation to the Customer table');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddNoteRefusesANumberNoCustomerCarries()
    var
        CustomerNoteMgt: Codeunit "Customer Note Mgt.";
    begin
        // [SCENARIO] The relation is validated: a note cannot point at a customer that does not exist
        // [GIVEN] a generated customer number that no customer carries
        // [WHEN] adding a note for it
        asserterror CustomerNoteMgt.AddNote(UnusedCustomerNo(), GeneratedNote());

        // [THEN] the relation check itself refuses the number, naming the related table
        Assert.ExpectedError('cannot be found in the related table');
        Assert.ExpectedError('Customer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EveryCallAddsItsOwnNote()
    var
        Customer: Record Customer;
        CustomerNote: Record "Customer Note";
        CustomerNoteMgt: Codeunit "Customer Note Mgt.";
        FirstNote: Text[250];
        SecondNote: Text[250];
    begin
        // [SCENARIO] A customer can carry any number of notes; each AddNote call adds one more row
        // [GIVEN] an ordinary customer and two different generated note texts
        LibrarySales.CreateCustomer(Customer);
        FirstNote := GeneratedNote();
        SecondNote := GeneratedNote();

        // [WHEN] adding both notes for the same customer
        CustomerNoteMgt.AddNote(Customer."No.", FirstNote);
        CustomerNoteMgt.AddNote(Customer."No.", SecondNote);

        // [THEN] the customer has two notes, one per text
        CustomerNote.SetRange("Customer No.", Customer."No.");
        Assert.AreEqual(2, CustomerNote.Count(),
            StrSubstNo('Expected two notes for customer %1 after two AddNote calls - every call must insert its own row', Customer."No."));
        CustomerNote.SetRange(Note, FirstNote);
        Assert.IsFalse(CustomerNote.IsEmpty(),
            StrSubstNo('Expected the first note (%1) to still be stored for customer %2 after the second AddNote call', FirstNote, Customer."No."));
        CustomerNote.SetRange(Note, SecondNote);
        Assert.IsFalse(CustomerNote.IsEmpty(),
            StrSubstNo('Expected the second note (%1) to be stored for customer %2 as its own row', SecondNote, Customer."No."));
    end;

    local procedure CreateCustomerWithTwentyCharacterNo(var Customer: Record Customer)
    var
        Any: Codeunit Any;
    begin
        Customer.Init();
        Customer."No." := CopyStr('TRYAL-' + UpperCase(Any.AlphanumericText(20)), 1, MaxStrLen(Customer."No."));
        Customer.Name := CopyStr('TRYAL long-numbered ' + Any.AlphabeticText(20), 1, MaxStrLen(Customer.Name));
        Customer.Insert();
    end;

    // Ten characters fit the starter's Code[10] as well, so this test fails only when the relation itself is gone.
    local procedure UnusedCustomerNo(): Code[20]
    var
        Any: Codeunit Any;
    begin
        exit(CopyStr('TRYAL' + UpperCase(Any.AlphabeticText(5)), 1, 10));
    end;

    local procedure GeneratedNote(): Text[250]
    var
        Any: Codeunit Any;
    begin
        exit(CopyStr('TRYAL note ' + Any.AlphabeticText(30), 1, 250));
    end;

    local procedure CustomerNoField(): FieldRef
    var
        CustomerNote: Record "Customer Note";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CustomerNote);
        exit(RecRef.Field(CustomerNote.FieldNo("Customer No.")));
    end;
}
