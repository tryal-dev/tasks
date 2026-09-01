codeunit 50900 "Reverse Entry Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReversalEntryNegatesAmountAndQuantity()
    var
        ReversalEntry: Record "Reversible Ledger Entry";
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        EntryAmount: Decimal;
        EntryQuantity: Decimal;
        OriginalNo: Integer;
        ReversalNo: Integer;
    begin
        // [SCENARIO] The reversal of a clean entry carries the opposite amount and quantity
        EntryAmount := Any.DecimalInRange(10, 900, 2);
        EntryQuantity := Any.DecimalInRange(1, 50, 2);
        OriginalNo := SeedEntry('TRE-T01', 'ACC-01', EntryAmount, EntryQuantity);

        ReversalNo := LedgerEntryReversal.ReverseEntry(OriginalNo);

        Assert.IsTrue(ReversalEntry.Get(ReversalNo),
            StrSubstNo('Expected ReverseEntry to write a new ledger entry and return its entry number, got %1', ReversalNo));
        Assert.AreEqual(-EntryAmount, ReversalEntry.Amount,
            'Expected the reversal entry to carry the negated amount of the entry it reverses');
        Assert.AreEqual(-EntryQuantity, ReversalEntry.Quantity,
            'Expected the reversal entry to carry the negated quantity of the entry it reverses');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReversalEntryCopiesDocumentDateAccountAndDescription()
    var
        ReversalEntry: Record "Reversible Ledger Entry";
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        AccountNo: Code[20];
        PostingDate: Date;
        EntryDescription: Text[50];
        OriginalNo: Integer;
        ReversalNo: Integer;
    begin
        // [SCENARIO] Document No., Posting Date, Account No. and Description travel unchanged to the reversal
        AccountNo := CopyStr('T02-' + UpperCase(Any.AlphabeticText(8)), 1, 20);
        PostingDate := Any.DateInRange(120);
        EntryDescription := CopyStr(Any.AlphabeticText(30), 1, 50);
        OriginalNo := SeedEntry('TRE-T02', AccountNo, PostingDate, EntryDescription, Any.DecimalInRange(10, 900, 2), 4);

        ReversalNo := LedgerEntryReversal.ReverseEntry(OriginalNo);

        ReversalEntry.Get(ReversalNo);
        Assert.AreEqual('TRE-T02', ReversalEntry."Document No.",
            'Expected the reversal entry to carry the same document no. as the entry it reverses');
        Assert.AreEqual(PostingDate, ReversalEntry."Posting Date",
            'Expected the reversal entry to carry the same posting date as the entry it reverses');
        Assert.AreEqual(AccountNo, ReversalEntry."Account No.",
            'Expected the reversal entry to carry the same account no. as the entry it reverses');
        Assert.AreEqual(EntryDescription, ReversalEntry.Description,
            'Expected the reversal entry to carry the description of the entry it reverses');
        Assert.AreEqual(0.0, ReversalEntry."Applied Amount",
            'Expected the reversal entry to be written unapplied — "Applied Amount" stays 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReversalEntryNumberContinuesTheLedger()
    var
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        Assert: Codeunit Assert;
        HighestBefore: Integer;
        OriginalNo: Integer;
        ReversalNo: Integer;
    begin
        // [SCENARIO] The reversal gets the highest entry number in the ledger plus one, and that number is returned
        OriginalNo := SeedEntry('TRE-T03', 'ACC-03', 120, 3);
        HighestBefore := LastEntryNo();

        ReversalNo := LedgerEntryReversal.ReverseEntry(OriginalNo);

        Assert.AreEqual(HighestBefore + 1, ReversalNo,
            'Expected ReverseEntry to return a new entry number continuing right after the highest entry already in the ledger');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure BothSidesAreFlaggedReversedAndCrossReferenced()
    var
        OriginalEntry: Record "Reversible Ledger Entry";
        ReversalEntry: Record "Reversible Ledger Entry";
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        Assert: Codeunit Assert;
        OriginalNo: Integer;
        ReversalNo: Integer;
    begin
        // [SCENARIO] Original and reversal both end up Reversed and pointing at each other
        OriginalNo := SeedEntry('TRE-T04', 'ACC-04', 750, 5);

        ReversalNo := LedgerEntryReversal.ReverseEntry(OriginalNo);

        OriginalEntry.Get(OriginalNo);
        ReversalEntry.Get(ReversalNo);
        Assert.IsTrue(OriginalEntry.Reversed,
            'Expected the reversed entry to be flagged Reversed');
        Assert.AreEqual(ReversalNo, OriginalEntry."Reversed by Entry No.",
            'Expected the reversed entry to point at the entry that reversed it through "Reversed by Entry No."');
        Assert.AreEqual(0, OriginalEntry."Reversed Entry No.",
            'Expected the reversed entry to keep an empty "Reversed Entry No." — only a reversal entry has that field set');
        Assert.IsTrue(ReversalEntry.Reversed,
            'Expected the reversal entry itself to be flagged Reversed as well');
        Assert.AreEqual(OriginalNo, ReversalEntry."Reversed Entry No.",
            'Expected the reversal entry to point at the entry it reverses through "Reversed Entry No."');
        Assert.AreEqual(0, ReversalEntry."Reversed by Entry No.",
            'Expected the reversal entry to keep an empty "Reversed by Entry No."');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AnEntryAndItsReversalNetToZero()
    var
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OriginalNo: Integer;
    begin
        // [SCENARIO] After a reversal the document sums to zero on both amount and quantity
        OriginalNo := SeedEntry('TRE-T05', 'ACC-05', Any.DecimalInRange(10, 900, 2), Any.DecimalInRange(1, 50, 2));

        LedgerEntryReversal.ReverseEntry(OriginalNo);

        Assert.AreEqual(2, DocumentEntryCount('TRE-T05'),
            'Expected the ledger to hold the original entry and exactly one reversal for it');
        Assert.AreEqual(0.0, DocumentAmount('TRE-T05'),
            'Expected the amounts of the document to net to zero after the reversal');
        Assert.AreEqual(0.0, DocumentQuantity('TRE-T05'),
            'Expected the quantities of the document to net to zero after the reversal');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReversingAnAlreadyReversedEntryIsRefused()
    var
        OriginalEntry: Record "Reversible Ledger Entry";
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        Assert: Codeunit Assert;
        EntriesBefore: Integer;
        FirstReversalNo: Integer;
        OriginalNo: Integer;
    begin
        // [SCENARIO] A second reversal attempt is refused and leaves the ledger exactly as the first one left it
        OriginalNo := SeedEntry('TRE-T06', 'ACC-06', 400, 2);
        Commit();
        FirstReversalNo := LedgerEntryReversal.ReverseEntry(OriginalNo);
        Commit();
        EntriesBefore := DocumentEntryCount('TRE-T06');

        asserterror LedgerEntryReversal.ReverseEntry(OriginalNo);

        AssertErrorContains('already reversed');
        Assert.AreEqual(EntriesBefore, DocumentEntryCount('TRE-T06'),
            'Expected the refused second attempt to write no entry at all');
        OriginalEntry.Get(OriginalNo);
        Assert.AreEqual(FirstReversalNo, OriginalEntry."Reversed by Entry No.",
            'Expected the refused second attempt to leave the entry pointing at its first reversal');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReversingAReversalEntryIsRefused()
    var
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        Assert: Codeunit Assert;
        EntriesBefore: Integer;
        OriginalNo: Integer;
        ReversalNo: Integer;
    begin
        // [SCENARIO] A reversal entry cannot itself be reversed
        OriginalNo := SeedEntry('TRE-T07', 'ACC-07', 310, 1);
        Commit();
        ReversalNo := LedgerEntryReversal.ReverseEntry(OriginalNo);
        Commit();
        EntriesBefore := DocumentEntryCount('TRE-T07');

        asserterror LedgerEntryReversal.ReverseEntry(ReversalNo);

        AssertErrorContains('is a reversal');
        Assert.AreEqual(EntriesBefore, DocumentEntryCount('TRE-T07'),
            'Expected the refused attempt on a reversal entry to write no entry at all');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReversingAPartlyAppliedEntryIsRefused()
    var
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OriginalNo: Integer;
    begin
        // [SCENARIO] An entry with a non-zero applied amount cannot be reversed
        OriginalNo := SeedAppliedEntry('TRE-T08', 'ACC-08', 500, 5, Any.DecimalInRange(1, 400, 2));
        Commit();

        asserterror LedgerEntryReversal.ReverseEntry(OriginalNo);

        AssertErrorContains('partly applied');
        Assert.AreEqual(1, DocumentEntryCount('TRE-T08'),
            'Expected the refused attempt on a partly applied entry to leave the document with its single entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AnEntryTrippingTwoRefusalsReportsTheEarlierRule()
    var
        ReversibleLedgerEntry: Record "Reversible Ledger Entry";
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        Any: Codeunit Any;
        OriginalNo: Integer;
    begin
        // [SCENARIO] An entry that is both already reversed and partly applied reports the already reversed refusal
        OriginalNo := SeedReversedPair('TRE-T09', 'ACC-09', 480, 4);
        ReversibleLedgerEntry.Get(OriginalNo);
        ReversibleLedgerEntry."Applied Amount" := Any.DecimalInRange(1, 400, 2);
        ReversibleLedgerEntry.Modify();
        Commit();

        asserterror LedgerEntryReversal.ReverseEntry(OriginalNo);

        AssertErrorContains('already reversed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReversingAnEntryThatDoesNotExistIsRefused()
    var
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        MissingEntryNo: Integer;
    begin
        // [SCENARIO] An entry number nothing in the ledger carries is rejected instead of silently doing nothing
        MissingEntryNo := LastEntryNo() + 1000;

        asserterror LedgerEntryReversal.ReverseEntry(MissingEntryNo);

        AssertErrorContains('does not exist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReverseDocumentReversesEveryEntryOfTheDocument()
    var
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ReversedCount: Integer;
    begin
        // [SCENARIO] A clean three-entry document is reversed as a whole
        SeedEntry('TRE-T10', 'ACC-A', Any.DecimalInRange(10, 500, 2), Any.DecimalInRange(1, 20, 2));
        SeedEntry('TRE-T10', 'ACC-B', Any.DecimalInRange(10, 500, 2), Any.DecimalInRange(1, 20, 2));
        SeedEntry('TRE-T10', 'ACC-C', Any.DecimalInRange(10, 500, 2), Any.DecimalInRange(1, 20, 2));

        ReversedCount := LedgerEntryReversal.ReverseDocument('TRE-T10');

        Assert.AreEqual(3, ReversedCount,
            'Expected ReverseDocument to return the number of entries it reversed');
        Assert.AreEqual(6, DocumentEntryCount('TRE-T10'),
            'Expected exactly one reversal entry per entry of the document');
        Assert.AreEqual(0.0, DocumentAmount('TRE-T10'),
            'Expected the amounts of the reversed document to net to zero');
        Assert.AreEqual(0.0, DocumentQuantity('TRE-T10'),
            'Expected the quantities of the reversed document to net to zero');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReverseDocumentNumbersReversalsInOriginalEntryOrder()
    var
        ReversalEntry: Record "Reversible Ledger Entry";
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        Assert: Codeunit Assert;
        FirstNo: Integer;
        SecondNo: Integer;
        ThirdNo: Integer;
    begin
        // [SCENARIO] The lowest new entry number reverses the lowest original entry
        FirstNo := SeedEntry('TRE-T11', 'ACC-A', 100, 1);
        SecondNo := SeedEntry('TRE-T11', 'ACC-B', 200, 2);
        ThirdNo := SeedEntry('TRE-T11', 'ACC-C', 300, 3);

        LedgerEntryReversal.ReverseDocument('TRE-T11');

        ReversalEntry.SetRange("Document No.", 'TRE-T11');
        ReversalEntry.SetFilter("Reversed Entry No.", '<>%1', 0);
        Assert.AreEqual(3, ReversalEntry.Count(),
            'Expected three reversal entries — entries whose "Reversed Entry No." names the entry they reverse');
        ReversalEntry.FindSet();
        Assert.AreEqual(FirstNo, ReversalEntry."Reversed Entry No.",
            'Expected the lowest new entry number to reverse the lowest original entry number');
        ReversalEntry.Next();
        Assert.AreEqual(SecondNo, ReversalEntry."Reversed Entry No.",
            'Expected the middle new entry number to reverse the middle original entry number');
        ReversalEntry.Next();
        Assert.AreEqual(ThirdNo, ReversalEntry."Reversed Entry No.",
            'Expected the highest new entry number to reverse the highest original entry number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReverseDocumentCrossReferencesBothSidesOfEveryEntry()
    var
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        Any: Codeunit Any;
        EntryNo: Integer;
        OriginalEntryNos: List of [Integer];
    begin
        // [SCENARIO] Every entry of a reversed document and its reversal carry the same flags and cross-references a single reversal writes
        OriginalEntryNos.Add(SeedEntry('TRE-T18', 'ACC-A', Any.DecimalInRange(10, 500, 2), Any.DecimalInRange(1, 20, 2)));
        OriginalEntryNos.Add(SeedEntry('TRE-T18', 'ACC-B', Any.DecimalInRange(10, 500, 2), Any.DecimalInRange(1, 20, 2)));
        OriginalEntryNos.Add(SeedEntry('TRE-T18', 'ACC-C', Any.DecimalInRange(10, 500, 2), Any.DecimalInRange(1, 20, 2)));

        LedgerEntryReversal.ReverseDocument('TRE-T18');

        foreach EntryNo in OriginalEntryNos do
            AssertCrossReferencedPair(EntryNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReverseDocumentRunTwiceIsRefused()
    var
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        Assert: Codeunit Assert;
        EntriesBefore: Integer;
    begin
        // [SCENARIO] A second run over an already reversed document is refused for the entries, not for their reversals
        SeedEntry('TRE-T12', 'ACC-A', 140, 1);
        SeedEntry('TRE-T12', 'ACC-B', 260, 2);
        Commit();
        LedgerEntryReversal.ReverseDocument('TRE-T12');
        Commit();
        EntriesBefore := DocumentEntryCount('TRE-T12');

        asserterror LedgerEntryReversal.ReverseDocument('TRE-T12');

        AssertErrorContains('already reversed');
        Assert.AreEqual(EntriesBefore, DocumentEntryCount('TRE-T12'),
            'Expected the second run to write nothing — the reversal entries of the first run are out of scope, and its reversed entries are refused');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReverseDocumentWritesNothingWhenOneEntryIsAlreadyReversed()
    var
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        Assert: Codeunit Assert;
        CleanEntryNos: List of [Integer];
        EntriesBefore: Integer;
    begin
        // [SCENARIO] Entry 3 of 5 is already reversed — the whole call fails and the ledger keeps exactly the entries it had
        SeedDocumentWithAReversedEntry('TRE-T13', CleanEntryNos);
        EntriesBefore := DocumentEntryCount('TRE-T13');

        asserterror LedgerEntryReversal.ReverseDocument('TRE-T13');

        AssertErrorContains('already reversed');
        Assert.AreEqual(EntriesBefore, DocumentEntryCount('TRE-T13'),
            'Expected a refused document to leave the ledger exactly as it was — not one reversal entry may outlive the failed call');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReverseDocumentLeavesTheOtherEntriesUnflaggedWhenItFails()
    var
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        CleanEntryNos: List of [Integer];
        EntryNo: Integer;
    begin
        // [SCENARIO] The four reversible entries of the refused document keep their flags untouched
        SeedDocumentWithAReversedEntry('TRE-T14', CleanEntryNos);

        asserterror LedgerEntryReversal.ReverseDocument('TRE-T14');

        AssertErrorContains('already reversed');
        foreach EntryNo in CleanEntryNos do
            AssertNotFlagged(EntryNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReverseDocumentIsRefusedWhenOneEntryIsPartlyApplied()
    var
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        EntriesBefore: Integer;
    begin
        // [SCENARIO] A partly applied entry refuses the whole document, exactly as a single reversal would
        SeedEntry('TRE-T17', 'ACC-1', Any.DecimalInRange(10, 500, 2), Any.DecimalInRange(1, 20, 2));
        SeedAppliedEntry('TRE-T17', 'ACC-2', 600, 6, Any.DecimalInRange(1, 400, 2));
        SeedEntry('TRE-T17', 'ACC-3', Any.DecimalInRange(10, 500, 2), Any.DecimalInRange(1, 20, 2));
        Commit();
        EntriesBefore := DocumentEntryCount('TRE-T17');

        asserterror LedgerEntryReversal.ReverseDocument('TRE-T17');

        AssertErrorContains('partly applied');
        Assert.AreEqual(EntriesBefore, DocumentEntryCount('TRE-T17'),
            'Expected a document holding a partly applied entry to gain no reversal entry at all');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReverseDocumentWithNothingInScopeIsRefused()
    var
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
    begin
        // [SCENARIO] A document without a single entry to reverse is rejected
        asserterror LedgerEntryReversal.ReverseDocument('TRE-T15');

        AssertErrorContains('nothing to reverse');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ReverseDocumentScopesEverythingToTheGivenDocument()
    var
        LedgerEntryReversal: Codeunit "Ledger Entry Reversal";
        Assert: Codeunit Assert;
        NeighbourEntryNo: Integer;
        ReversedCount: Integer;
    begin
        // [SCENARIO] Reversing one document ignores a neighbouring document entirely
        // [GIVEN] the neighbour is already reversed, so an unscoped run would be refused
        SeedEntry('TRE-T16A', 'ACC-A', 180, 1);
        SeedEntry('TRE-T16A', 'ACC-B', 220, 2);
        NeighbourEntryNo := SeedReversedPair('TRE-T16B', 'ACC-C', 300, 3);

        ReversedCount := LedgerEntryReversal.ReverseDocument('TRE-T16A');

        Assert.AreEqual(2, ReversedCount,
            'Expected both entries of the given document to be reversed');
        Assert.AreEqual(4, DocumentEntryCount('TRE-T16A'),
            'Expected the given document to hold its two entries and their two reversals');
        Assert.AreEqual(2, DocumentEntryCount('TRE-T16B'),
            'Expected the neighbouring document to be untouched — reversing one document must not reach into another');
        Assert.AreEqual(NeighbourEntryNo + 1, NeighbourReversedByEntryNo(NeighbourEntryNo),
            'Expected the neighbouring document''s entry to keep the cross-reference it already had');
    end;

    local procedure SeedEntry(DocumentNo: Code[20]; AccountNo: Code[20]; EntryAmount: Decimal; EntryQuantity: Decimal): Integer
    begin
        exit(SeedEntry(DocumentNo, AccountNo, WorkDate(), '', EntryAmount, EntryQuantity));
    end;

    local procedure SeedEntry(DocumentNo: Code[20]; AccountNo: Code[20]; PostingDate: Date; EntryDescription: Text[50]; EntryAmount: Decimal; EntryQuantity: Decimal): Integer
    var
        ReversibleLedgerEntry: Record "Reversible Ledger Entry";
        NewEntryNo: Integer;
    begin
        NewEntryNo := LastEntryNo() + 1;
        ReversibleLedgerEntry.Init();
        ReversibleLedgerEntry."Entry No." := NewEntryNo;
        ReversibleLedgerEntry."Document No." := DocumentNo;
        ReversibleLedgerEntry."Posting Date" := PostingDate;
        ReversibleLedgerEntry."Account No." := AccountNo;
        ReversibleLedgerEntry.Description := EntryDescription;
        ReversibleLedgerEntry.Amount := EntryAmount;
        ReversibleLedgerEntry.Quantity := EntryQuantity;
        ReversibleLedgerEntry.Insert();
        exit(NewEntryNo);
    end;

    local procedure SeedAppliedEntry(DocumentNo: Code[20]; AccountNo: Code[20]; EntryAmount: Decimal; EntryQuantity: Decimal; AppliedAmount: Decimal): Integer
    var
        ReversibleLedgerEntry: Record "Reversible Ledger Entry";
        NewEntryNo: Integer;
    begin
        NewEntryNo := SeedEntry(DocumentNo, AccountNo, EntryAmount, EntryQuantity);
        ReversibleLedgerEntry.Get(NewEntryNo);
        ReversibleLedgerEntry."Applied Amount" := AppliedAmount;
        ReversibleLedgerEntry.Modify();
        exit(NewEntryNo);
    end;

    local procedure SeedReversedPair(DocumentNo: Code[20]; AccountNo: Code[20]; EntryAmount: Decimal; EntryQuantity: Decimal): Integer
    var
        OriginalEntry: Record "Reversible Ledger Entry";
        ReversalEntry: Record "Reversible Ledger Entry";
        OriginalNo: Integer;
        ReversalNo: Integer;
    begin
        OriginalNo := SeedEntry(DocumentNo, AccountNo, EntryAmount, EntryQuantity);
        ReversalNo := SeedEntry(DocumentNo, AccountNo, -EntryAmount, -EntryQuantity);
        ReversalEntry.Get(ReversalNo);
        ReversalEntry.Reversed := true;
        ReversalEntry."Reversed Entry No." := OriginalNo;
        ReversalEntry.Modify();
        OriginalEntry.Get(OriginalNo);
        OriginalEntry.Reversed := true;
        OriginalEntry."Reversed by Entry No." := ReversalNo;
        OriginalEntry.Modify();
        exit(OriginalNo);
    end;

    local procedure SeedDocumentWithAReversedEntry(DocumentNo: Code[20]; var CleanEntryNos: List of [Integer])
    var
        Any: Codeunit Any;
    begin
        CleanEntryNos.Add(SeedEntry(DocumentNo, 'ACC-1', Any.DecimalInRange(10, 500, 2), Any.DecimalInRange(1, 20, 2)));
        CleanEntryNos.Add(SeedEntry(DocumentNo, 'ACC-2', Any.DecimalInRange(10, 500, 2), Any.DecimalInRange(1, 20, 2)));
        SeedReversedPair(DocumentNo, 'ACC-3', Any.DecimalInRange(10, 500, 2), Any.DecimalInRange(1, 20, 2));
        CleanEntryNos.Add(SeedEntry(DocumentNo, 'ACC-4', Any.DecimalInRange(10, 500, 2), Any.DecimalInRange(1, 20, 2)));
        CleanEntryNos.Add(SeedEntry(DocumentNo, 'ACC-5', Any.DecimalInRange(10, 500, 2), Any.DecimalInRange(1, 20, 2)));
        // Committing the arrangement means the refused call can only roll back
        // its own writes, never the entries this test put in the ledger.
        Commit();
    end;

    local procedure LastEntryNo(): Integer
    var
        ReversibleLedgerEntry: Record "Reversible Ledger Entry";
    begin
        if ReversibleLedgerEntry.FindLast() then
            exit(ReversibleLedgerEntry."Entry No.");
        exit(0);
    end;

    local procedure DocumentEntryCount(DocumentNo: Code[20]): Integer
    var
        ReversibleLedgerEntry: Record "Reversible Ledger Entry";
    begin
        ReversibleLedgerEntry.SetRange("Document No.", DocumentNo);
        exit(ReversibleLedgerEntry.Count());
    end;

    local procedure DocumentAmount(DocumentNo: Code[20]): Decimal
    var
        ReversibleLedgerEntry: Record "Reversible Ledger Entry";
    begin
        ReversibleLedgerEntry.SetRange("Document No.", DocumentNo);
        ReversibleLedgerEntry.CalcSums(Amount);
        exit(ReversibleLedgerEntry.Amount);
    end;

    local procedure DocumentQuantity(DocumentNo: Code[20]): Decimal
    var
        ReversibleLedgerEntry: Record "Reversible Ledger Entry";
    begin
        ReversibleLedgerEntry.SetRange("Document No.", DocumentNo);
        ReversibleLedgerEntry.CalcSums(Quantity);
        exit(ReversibleLedgerEntry.Quantity);
    end;

    local procedure NeighbourReversedByEntryNo(EntryNo: Integer): Integer
    var
        ReversibleLedgerEntry: Record "Reversible Ledger Entry";
    begin
        ReversibleLedgerEntry.Get(EntryNo);
        exit(ReversibleLedgerEntry."Reversed by Entry No.");
    end;

    local procedure AssertCrossReferencedPair(OriginalNo: Integer)
    var
        OriginalEntry: Record "Reversible Ledger Entry";
        ReversalEntry: Record "Reversible Ledger Entry";
        Assert: Codeunit Assert;
    begin
        ReversalEntry.SetRange("Reversed Entry No.", OriginalNo);
        Assert.AreEqual(1, ReversalEntry.Count(),
            StrSubstNo('Expected exactly one reversal entry naming entry %1 in "Reversed Entry No."', OriginalNo));
        ReversalEntry.FindFirst();
        Assert.IsTrue(ReversalEntry.Reversed,
            StrSubstNo('Expected the reversal entry %1 written for entry %2 to be flagged Reversed as well', ReversalEntry."Entry No.", OriginalNo));
        Assert.AreEqual(0, ReversalEntry."Reversed by Entry No.",
            StrSubstNo('Expected the reversal entry %1 to keep an empty "Reversed by Entry No."', ReversalEntry."Entry No."));

        OriginalEntry.Get(OriginalNo);
        Assert.IsTrue(OriginalEntry.Reversed,
            StrSubstNo('Expected entry %1 to be flagged Reversed once the document was reversed', OriginalNo));
        Assert.AreEqual(ReversalEntry."Entry No.", OriginalEntry."Reversed by Entry No.",
            StrSubstNo('Expected entry %1 to point at the reversal that names it through "Reversed by Entry No."', OriginalNo));
        Assert.AreEqual(0, OriginalEntry."Reversed Entry No.",
            StrSubstNo('Expected entry %1 to keep an empty "Reversed Entry No." — only a reversal entry has that field set', OriginalNo));
    end;

    local procedure AssertNotFlagged(EntryNo: Integer)
    var
        ReversibleLedgerEntry: Record "Reversible Ledger Entry";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(ReversibleLedgerEntry.Get(EntryNo),
            StrSubstNo('Expected entry %1 to still be in the ledger after the refused call', EntryNo));
        Assert.IsFalse(ReversibleLedgerEntry.Reversed,
            StrSubstNo('Expected entry %1 to be left unflagged by the refused call — a refused document leaves every entry as it was', EntryNo));
        Assert.AreEqual(0, ReversibleLedgerEntry."Reversed by Entry No.",
            StrSubstNo('Expected entry %1 to keep an empty "Reversed by Entry No." after the refused call', EntryNo));
    end;

    local procedure AssertErrorContains(Fragment: Text)
    var
        Assert: Codeunit Assert;
        ActualError: Text;
    begin
        ActualError := GetLastErrorText();
        Assert.IsTrue(LowerCase(ActualError).Contains(LowerCase(Fragment)),
            StrSubstNo('Expected the error to contain "%1", got: %2', Fragment, ActualError));
    end;
}
