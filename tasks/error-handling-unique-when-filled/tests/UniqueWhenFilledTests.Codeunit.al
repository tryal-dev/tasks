codeunit 50900 "Unique When Filled Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Customer Document Register]

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankExternalDocumentNosMayRepeatForOneCustomer()
    var
        Register: Record "Customer Document Register";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Blank is not a value the uniqueness rule is about
        // [GIVEN] a customer with nothing registered yet
        CustomerNo := CreateCustomerNo();

        // [WHEN] three documents without an external document no. are registered
        InsertDocument(CustomerNo, 'BLANK-1', '');
        InsertDocument(CustomerNo, 'BLANK-2', '');
        InsertDocument(CustomerNo, 'BLANK-3', '');

        // [THEN] all three documents are in the register
        Register.SetRange("Customer No.", CustomerNo);
        Assert.AreEqual(3, Register.Count(),
            'Expected all three documents with a blank "External Document No." to be registered for this customer — blank is exempt from the uniqueness rule, however often it repeats');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DistinctExternalDocumentNosCoexistForOneCustomer()
    var
        Register: Record "Customer Document Register";
        CustomerNo: Code[20];
        ExternalDocumentNo: Code[35];
    begin
        // [SCENARIO] Two different external document nos. are no conflict at all
        // [GIVEN] a customer with one document carrying an external document no.
        CustomerNo := CreateCustomerNo();
        ExternalDocumentNo := NewExternalDocumentNo();
        InsertDocument(CustomerNo, 'FIRST-1', ExternalDocumentNo);

        // [WHEN] a second document with a different external document no. is inserted
        InsertDocument(CustomerNo, 'SECOND-1', CopyStr(ExternalDocumentNo + '-B', 1, 35));

        // [THEN] both documents are in the register
        Register.SetRange("Customer No.", CustomerNo);
        Assert.AreEqual(2, Register.Count(),
            'Expected both documents to be registered: their external document nos. differ, so the second insert must not be blocked');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TwoCustomersMayShareAnExternalDocumentNo()
    var
        Register: Record "Customer Document Register";
        FirstCustomerNo: Code[20];
        SecondCustomerNo: Code[20];
        ExternalDocumentNo: Code[35];
    begin
        // [SCENARIO] The rule is scoped to one customer, not to the whole register
        // [GIVEN] one customer already using an external document no.
        FirstCustomerNo := CreateCustomerNo();
        SecondCustomerNo := CreateCustomerNo();
        ExternalDocumentNo := NewExternalDocumentNo();
        InsertDocument(FirstCustomerNo, 'SHARED-1', ExternalDocumentNo);

        // [WHEN] another customer registers a document with the same external document no.
        InsertDocument(SecondCustomerNo, 'SHARED-1', ExternalDocumentNo);

        // [THEN] the second customer's document is in the register
        Assert.IsTrue(Register.Get(SecondCustomerNo, 'SHARED-1'),
            StrSubstNo('Expected document SHARED-1 of customer %1 to be registered — external document no. %2 is only taken on customer %3, and customers do not share the rule', SecondCustomerNo, ExternalDocumentNo, FirstCustomerNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertingADuplicateExternalDocumentNoIsRejected()
    var
        CustomerNo: Code[20];
        DecoyDocumentNo: Code[20];
        RivalDocumentNo: Code[20];
        WriterDocumentNo: Code[20];
        ExternalDocumentNo: Code[35];
        ErrorText: Text;
    begin
        // [SCENARIO] A repeated non-blank external document no. is refused, naming the document that owns it
        // [GIVEN] a customer holding one document with the external document no. under test and one with another
        CustomerNo := CreateCustomerNo();
        ExternalDocumentNo := NewExternalDocumentNo();
        DecoyDocumentNo := NewDocumentNo('DECOY-');
        RivalDocumentNo := NewDocumentNo('ORIG-');
        WriterDocumentNo := NewDocumentNo('COPY-');
        InsertDocument(CustomerNo, DecoyDocumentNo, NewExternalDocumentNo());
        InsertDocument(CustomerNo, RivalDocumentNo, ExternalDocumentNo);

        // [WHEN] a second document of the same customer claims that external document no.
        asserterror InsertDocument(CustomerNo, WriterDocumentNo, ExternalDocumentNo);

        // [THEN] the insert fails with your own message, naming the document it collided with
        ErrorText := GetLastErrorText();
        Assert.IsTrue(StrPos(ErrorText, 'already used on document') > 0,
            StrSubstNo('Expected the rejected insert to fail with your own message containing the phrase "already used on document", got: %1', ErrorText));
        Assert.IsTrue(StrPos(ErrorText, RivalDocumentNo) > 0,
            StrSubstNo('Expected the error to name %1, the document that already carries external document no. %2 — not %3, which the customer holds under a different external document no., got: %4', RivalDocumentNo, ExternalDocumentNo, DecoyDocumentNo, ErrorText));
        Assert.IsTrue(StrPos(ErrorText, WriterDocumentNo) = 0,
            StrSubstNo('Expected the error to name the document it collides with, %1, and not %2, the document being written, got: %3', RivalDocumentNo, WriterDocumentNo, ErrorText));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ARejectedInsertLeavesTheRegisterUnchanged()
    var
        Register: Record "Customer Document Register";
        CustomerNo: Code[20];
        KeeperDocumentNo: Code[20];
        BlankKeeperDocumentNo: Code[20];
        RejectedDocumentNo: Code[20];
        ExternalDocumentNo: Code[35];
    begin
        // [SCENARIO] A refused write changes nothing in the register
        // [GIVEN] a customer with one document carrying an external document no. and one without
        CustomerNo := CreateCustomerNo();
        ExternalDocumentNo := NewExternalDocumentNo();
        KeeperDocumentNo := NewDocumentNo('KEEP-');
        BlankKeeperDocumentNo := NewDocumentNo('KEEPBLANK-');
        RejectedDocumentNo := NewDocumentNo('REJ-');
        InsertDocument(CustomerNo, KeeperDocumentNo, ExternalDocumentNo);
        InsertDocument(CustomerNo, BlankKeeperDocumentNo, '');
        // The refused insert rolls the database back to the last commit; without this the
        // two originals would vanish together with the rejected record.
        Commit();

        // [WHEN] a duplicate of the taken external document no. is inserted
        asserterror InsertDocument(CustomerNo, RejectedDocumentNo, ExternalDocumentNo);

        // [THEN] the rejected document is nowhere to be found and the two originals are still there
        Assert.IsFalse(Register.Get(CustomerNo, RejectedDocumentNo),
            StrSubstNo('Expected the rejected document %1 to be absent from the register — a refused insert must not leave the record behind', RejectedDocumentNo));
        Register.SetRange("Customer No.", CustomerNo);
        Assert.AreEqual(2, Register.Count(),
            'Expected the customer to still hold exactly the two documents registered before the rejected insert');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ModifyingARecordIntoADuplicateIsRejected()
    var
        Register: Record "Customer Document Register";
        CustomerNo: Code[20];
        DecoyDocumentNo: Code[20];
        HolderDocumentNo: Code[20];
        MoverDocumentNo: Code[20];
        ExternalDocumentNo: Code[35];
        ErrorText: Text;
    begin
        // [SCENARIO] The rule also guards the modify path, not just the insert path
        // [GIVEN] a customer whose holder document carries an external document no. and whose mover document has none
        CustomerNo := CreateCustomerNo();
        ExternalDocumentNo := NewExternalDocumentNo();
        DecoyDocumentNo := NewDocumentNo('DECOY-');
        HolderDocumentNo := NewDocumentNo('HOLD-');
        MoverDocumentNo := NewDocumentNo('MOVE-');
        InsertDocument(CustomerNo, DecoyDocumentNo, NewExternalDocumentNo());
        InsertDocument(CustomerNo, HolderDocumentNo, ExternalDocumentNo);
        InsertDocument(CustomerNo, MoverDocumentNo, '');

        // [WHEN] the mover document is edited to carry the taken external document no.
        Register.Get(CustomerNo, MoverDocumentNo);
        Register."External Document No." := ExternalDocumentNo;
        asserterror Register.Modify(true);

        // [THEN] the modify fails with your own message, naming the document it collided with
        ErrorText := GetLastErrorText();
        Assert.IsTrue(StrPos(ErrorText, 'already used on document') > 0,
            StrSubstNo('Expected the rejected modify to fail with your own message containing the phrase "already used on document", got: %1', ErrorText));
        Assert.IsTrue(StrPos(ErrorText, HolderDocumentNo) > 0,
            StrSubstNo('Expected the error to name %1, the document that already carries external document no. %2 — not %3, which the customer holds under a different external document no., got: %4', HolderDocumentNo, ExternalDocumentNo, DecoyDocumentNo, ErrorText));
        Assert.IsTrue(StrPos(ErrorText, MoverDocumentNo) = 0,
            StrSubstNo('Expected the error to name the document it collides with, %1, and not %2, the document being written, got: %3', HolderDocumentNo, MoverDocumentNo, ErrorText));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SavingARecordAgainDoesNotCollideWithItself()
    var
        Register: Record "Customer Document Register";
        SavedRegister: Record "Customer Document Register";
        CustomerNo: Code[20];
        ExternalDocumentNo: Code[35];
    begin
        // [SCENARIO] A record is never its own duplicate
        // [GIVEN] a registered document carrying an external document no.
        CustomerNo := CreateCustomerNo();
        ExternalDocumentNo := NewExternalDocumentNo();
        InsertDocument(CustomerNo, 'STABLE-1', ExternalDocumentNo);

        // [WHEN] only its description is changed and the record is saved again
        Register.Get(CustomerNo, 'STABLE-1');
        Register.Description := 'Corrected description';
        Register.Modify(true);

        // [THEN] the new description is stored
        SavedRegister.Get(CustomerNo, 'STABLE-1');
        Assert.AreEqual('Corrected description', SavedRegister.Description,
            'Expected the edited description to be saved: the record kept its own external document no., and a record must never be treated as a duplicate of itself');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClearingAnExternalDocumentNoIsAllowed()
    var
        Register: Record "Customer Document Register";
        SavedRegister: Record "Customer Document Register";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] Emptying an external document no. joins the exempt blanks
        // [GIVEN] a customer with one blank document and one carrying an external document no.
        CustomerNo := CreateCustomerNo();
        InsertDocument(CustomerNo, 'CLEARED-1', '');
        InsertDocument(CustomerNo, 'CLEARED-2', NewExternalDocumentNo());

        // [WHEN] the second document's external document no. is cleared
        Register.Get(CustomerNo, 'CLEARED-2');
        Register."External Document No." := '';
        Register.Modify(true);

        // [THEN] the document is stored with a blank external document no.
        SavedRegister.Get(CustomerNo, 'CLEARED-2');
        Assert.AreEqual('', SavedRegister."External Document No.",
            'Expected the external document no. to be cleared: a second blank must never be refused, not even when another document of the customer is already blank');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RenamingADocumentOntoACollidingCustomerIsRejected()
    var
        Register: Record "Customer Document Register";
        FirstCustomerNo: Code[20];
        SecondCustomerNo: Code[20];
        DecoyDocumentNo: Code[20];
        HostDocumentNo: Code[20];
        TravellerDocumentNo: Code[20];
        ExternalDocumentNo: Code[35];
        ErrorText: Text;
    begin
        // [SCENARIO] Renaming a document to another customer is a write, and the rule applies to it
        // [GIVEN] two customers whose documents carry the same external document no. — legal, so far
        FirstCustomerNo := CreateCustomerNo();
        SecondCustomerNo := CreateCustomerNo();
        ExternalDocumentNo := NewExternalDocumentNo();
        DecoyDocumentNo := NewDocumentNo('DECOY-');
        HostDocumentNo := NewDocumentNo('HOST-');
        TravellerDocumentNo := NewDocumentNo('TRAV-');
        InsertDocument(SecondCustomerNo, DecoyDocumentNo, NewExternalDocumentNo());
        InsertDocument(SecondCustomerNo, HostDocumentNo, ExternalDocumentNo);
        InsertDocument(FirstCustomerNo, TravellerDocumentNo, ExternalDocumentNo);

        // [WHEN] the first customer's document is moved to the second customer
        Register.Get(FirstCustomerNo, TravellerDocumentNo);
        asserterror Register.Rename(SecondCustomerNo, TravellerDocumentNo);

        // [THEN] the rename fails with your own message, naming the document it collided with
        ErrorText := GetLastErrorText();
        Assert.IsTrue(StrPos(ErrorText, 'already used on document') > 0,
            StrSubstNo('Expected the rejected rename to fail with your own message containing the phrase "already used on document", got: %1', ErrorText));
        Assert.IsTrue(StrPos(ErrorText, HostDocumentNo) > 0,
            StrSubstNo('Expected the error to name %1, the document of customer %2 that already carries external document no. %3 — not %4, which that customer holds under a different external document no., got: %5', HostDocumentNo, SecondCustomerNo, ExternalDocumentNo, DecoyDocumentNo, ErrorText));
        Assert.IsTrue(StrPos(ErrorText, TravellerDocumentNo) = 0,
            StrSubstNo('Expected the error to name the document it collides with, %1, and not %2, the document being renamed, got: %3', HostDocumentNo, TravellerDocumentNo, ErrorText));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RenamingADocumentWithinItsCustomerIsAllowed()
    var
        Register: Record "Customer Document Register";
        RenamedRegister: Record "Customer Document Register";
        CustomerNo: Code[20];
        ExternalDocumentNo: Code[35];
    begin
        // [SCENARIO] Renumbering a document must not make it collide with its own old row
        // [GIVEN] a registered document carrying an external document no.
        CustomerNo := CreateCustomerNo();
        ExternalDocumentNo := NewExternalDocumentNo();
        InsertDocument(CustomerNo, 'OLDNUMBER-1', ExternalDocumentNo);

        // [WHEN] the document is renumbered inside the same customer
        Register.Get(CustomerNo, 'OLDNUMBER-1');
        Register.Rename(CustomerNo, 'NEWNUMBER-1');

        // [THEN] the document lives under its new number, external document no. intact
        Assert.IsTrue(RenamedRegister.Get(CustomerNo, 'NEWNUMBER-1'),
            'Expected the renamed document to be registered as NEWNUMBER-1 — during a rename the record is still in the database under its old number, and it must not be mistaken for a rival');
        Assert.AreEqual(ExternalDocumentNo, RenamedRegister."External Document No.",
            'Expected the renamed document to keep its external document no.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheDuplicateCheckStaysWithinTheBudget()
    var
        Register: Record "Customer Document Register";
        Any: Codeunit Any;
        CustomerNo: Code[20];
        DocumentCount: Integer;
        i: Integer;
        StatementsBefore: BigInteger;
        StatementsUsed: BigInteger;
        RowsBefore: BigInteger;
        RowsUsed: BigInteger;
    begin
        // [SCENARIO] The check costs the same on a customer with hundreds of documents
        // [GIVEN] a customer holding a couple of hundred documents, each with its own external document no.
        CustomerNo := CreateCustomerNo();
        DocumentCount := Any.IntegerInRange(180, 220);
        for i := 1 to DocumentCount do
            SeedDocument(CustomerNo, CopyStr(StrSubstNo('SEED-%1', i), 1, 20), CopyStr(StrSubstNo('EXT-SEED-%1', i), 1, 35));

        // warm-up: the first insert may pay one-time metadata statements; grade the steady state
        InsertDocument(CustomerNo, 'WARMUP-1', 'EXT-WARMUP-1');
        InvalidateDataCache();
        StatementsBefore := SessionInformation.SqlStatementsExecuted();
        RowsBefore := SessionInformation.SqlRowsRead();

        // [WHEN] one more document is inserted
        InsertDocument(CustomerNo, 'GRADED-1', 'EXT-GRADED-1');

        // [THEN] the insert went through, and it cost a fixed handful of statements and rows
        StatementsUsed := SessionInformation.SqlStatementsExecuted() - StatementsBefore;
        RowsUsed := SessionInformation.SqlRowsRead() - RowsBefore;
        Assert.IsTrue(Register.Get(CustomerNo, 'GRADED-1'),
            'Expected the graded insert to be registered before judging its budget — cheap must not mean lost');
        Assert.IsTrue(StatementsUsed <= MaxStatements(),
            StrSubstNo('Expected one insert to execute at most %1 SQL statements no matter how many documents the customer has, but it executed %2 against %3 existing documents', MaxStatements(), StatementsUsed, DocumentCount));
        Assert.IsTrue(RowsUsed <= MaxRows(),
            StrSubstNo('Expected one insert to read at most %1 rows, but it read %2 — the customer holds %3 documents, and deciding whether one external document no. is taken must not drag them all into AL', MaxRows(), RowsUsed, DocumentCount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheRegisterFieldsHaveTheDeclaredLengths()
    var
        Register: Record "Customer Document Register";
    begin
        // [SCENARIO] The register's fields are declared with the lengths the statement asks for
        // [WHEN] reading the declared maximum length of each field
        // [THEN] they match the statement
        Assert.AreEqual(20, MaxStrLen(Register."Customer No."),
            'Expected "Customer No." to be declared as Code[20]');
        Assert.AreEqual(20, MaxStrLen(Register."Document No."),
            'Expected "Document No." to be declared as Code[20]');
        Assert.AreEqual(35, MaxStrLen(Register."External Document No."),
            'Expected "External Document No." to be declared as Code[35] — external document nos. are longer than a document no.');
        Assert.AreEqual(100, MaxStrLen(Register.Description),
            'Expected Description to be declared as Text[100]');
    end;

    local procedure MaxStatements(): Integer
    begin
        exit(10);
    end;

    local procedure MaxRows(): Integer
    begin
        exit(25);
    end;

    local procedure CreateCustomerNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        // A customer from the standard number series, not a fixed literal: the graded
        // numbers drift from run to run, so a submission has nothing stable to key on.
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure NewExternalDocumentNo(): Code[35]
    var
        Any: Codeunit Any;
    begin
        exit(CopyStr(UpperCase(Any.AlphanumericText(12)), 1, 35));
    end;

    local procedure NewDocumentNo(Prefix: Text): Code[20]
    var
        Any: Codeunit Any;
    begin
        // Every document no. that a rejected write has to name is drawn fresh here, and the
        // rival's is drawn independently of the writer's: the only place the name of the
        // colliding document exists is the register, so it has to be read from there.
        exit(CopyStr(Prefix + UpperCase(Any.AlphabeticText(6)), 1, 20));
    end;

    local procedure InsertDocument(CustomerNo: Code[20]; DocumentNo: Code[20]; ExternalDocumentNo: Code[35])
    var
        Register: Record "Customer Document Register";
    begin
        Register.Init();
        Register."Customer No." := CustomerNo;
        Register."Document No." := DocumentNo;
        Register."External Document No." := ExternalDocumentNo;
        Register.Insert(true);
    end;

    local procedure SeedDocument(CustomerNo: Code[20]; DocumentNo: Code[20]; ExternalDocumentNo: Code[35])
    var
        Register: Record "Customer Document Register";
    begin
        // Bulk background data, inserted without triggers: the budget test is about what
        // ONE guarded insert costs, not about how long it takes to build the backdrop.
        Register.Init();
        Register."Customer No." := CustomerNo;
        Register."Document No." := DocumentNo;
        Register."External Document No." := ExternalDocumentNo;
        Register.Insert(false);
    end;

    local procedure InvalidateDataCache()
    begin
        // The warm-up insert leaves the register's result sets in the server data cache,
        // and a cached read costs zero SQL — the graded insert would measure nothing.
        // A write bumps the table's version and forces real statements again;
        // SelectLatestVersion alone is not enough for rows this transaction has locked.
        // The decoy belongs to a customer the graded insert never asks about.
        SeedDocument(CreateCustomerNo(), 'DECOY-1', 'EXT-DECOY-1');
        SelectLatestVersion();
    end;
}
