codeunit 50900 "VAT Period Totals Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountsInvoicePostedInJanuaryByItsDecemberVatDate()
    var
        VatPeriodTotals: Codeunit "VAT Period Totals";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        BusGroup: Code[20];
        ProdGroup: Code[20];
        BaseAmount: Decimal;
        VatAmount: Decimal;
        TotalBase: Decimal;
        TotalAmount: Decimal;
    begin
        CreateGroupPair(BusGroup, ProdGroup);
        BaseAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        VatAmount := LibraryRandom.RandDecInRange(100, 300, 2);
        InsertVatEntry(BusGroup, ProdGroup, 20251215D, 20260110D, 20260110D, BaseAmount, VatAmount);

        VatPeriodTotals.VatTotalsForPeriod(BusGroup, ProdGroup, 20251201D, 20251231D, TotalBase, TotalAmount);

        Assert.AreEqual(BaseAmount, TotalBase,
            'Expected the base of the entry VAT-dated 15.12. to count in December even though it was posted on 10.01. — the VAT date decides the period, not the posting date');
        Assert.AreEqual(VatAmount, TotalAmount,
            'Expected the VAT amount of the entry VAT-dated 15.12. to count in December even though it was posted on 10.01. — the VAT date decides the period, not the posting date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExcludesInvoicePostedInDecemberWithJanuaryVatDate()
    var
        VatPeriodTotals: Codeunit "VAT Period Totals";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        BusGroup: Code[20];
        ProdGroup: Code[20];
        TotalBase: Decimal;
        TotalAmount: Decimal;
    begin
        CreateGroupPair(BusGroup, ProdGroup);
        InsertVatEntry(BusGroup, ProdGroup, 20260105D, 20251228D, 20251228D,
            LibraryRandom.RandDecInRange(1000, 2000, 2), LibraryRandom.RandDecInRange(100, 300, 2));

        VatPeriodTotals.VatTotalsForPeriod(BusGroup, ProdGroup, 20251201D, 20251231D, TotalBase, TotalAmount);

        Assert.AreEqual(0.0, TotalBase,
            'Expected a base of 0 for December: the entry posted on 28.12. carries a January VAT date, so it belongs to the January return');
        Assert.AreEqual(0.0, TotalAmount,
            'Expected a VAT amount of 0 for December: the entry posted on 28.12. carries a January VAT date, so it belongs to the January return');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SumsBaseAndAmountAcrossEntriesInThePeriod()
    var
        VatPeriodTotals: Codeunit "VAT Period Totals";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        BusGroup: Code[20];
        ProdGroup: Code[20];
        FirstBase: Decimal;
        SecondBase: Decimal;
        CreditBase: Decimal;
        FirstAmount: Decimal;
        SecondAmount: Decimal;
        CreditAmount: Decimal;
        TotalBase: Decimal;
        TotalAmount: Decimal;
    begin
        CreateGroupPair(BusGroup, ProdGroup);
        FirstBase := LibraryRandom.RandDecInRange(1000, 2000, 2);
        SecondBase := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CreditBase := LibraryRandom.RandDecInRange(100, 500, 2);
        FirstAmount := LibraryRandom.RandDecInRange(100, 300, 2);
        SecondAmount := LibraryRandom.RandDecInRange(100, 300, 2);
        CreditAmount := LibraryRandom.RandDecInRange(10, 90, 2);
        InsertVatEntry(BusGroup, ProdGroup, 20251203D, 20260102D, 20260102D, FirstBase, FirstAmount);
        InsertVatEntry(BusGroup, ProdGroup, 20251210D, 20260105D, 20260105D, SecondBase, SecondAmount);
        InsertVatEntry(BusGroup, ProdGroup, 20251224D, 20260108D, 20260108D, -CreditBase, -CreditAmount);

        VatPeriodTotals.VatTotalsForPeriod(BusGroup, ProdGroup, 20251201D, 20251231D, TotalBase, TotalAmount);

        Assert.AreEqual(FirstBase + SecondBase - CreditBase, TotalBase,
            'Expected the signed sum of all three December VAT-dated entries in TotalBase — the credit memo''s negative base must reduce it, and none of the entries may be dropped for being posted in January');
        Assert.AreEqual(FirstAmount + SecondAmount - CreditAmount, TotalAmount,
            'Expected the signed sum of all three December VAT-dated entries in TotalAmount — the credit memo''s negative amount must reduce it, and none of the entries may be dropped for being posted in January');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IncludesBothBoundaryDaysOfThePeriod()
    var
        VatPeriodTotals: Codeunit "VAT Period Totals";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        BusGroup: Code[20];
        ProdGroup: Code[20];
        FirstDayBase: Decimal;
        LastDayBase: Decimal;
        FirstDayAmount: Decimal;
        LastDayAmount: Decimal;
        TotalBase: Decimal;
        TotalAmount: Decimal;
    begin
        CreateGroupPair(BusGroup, ProdGroup);
        FirstDayBase := LibraryRandom.RandDecInRange(1000, 2000, 2);
        LastDayBase := LibraryRandom.RandDecInRange(1000, 2000, 2);
        FirstDayAmount := LibraryRandom.RandDecInRange(100, 300, 2);
        LastDayAmount := LibraryRandom.RandDecInRange(100, 300, 2);
        InsertVatEntry(BusGroup, ProdGroup, 20251130D, 20251130D, 20251130D,
            LibraryRandom.RandDecInRange(1000, 2000, 2), LibraryRandom.RandDecInRange(100, 300, 2));
        InsertVatEntry(BusGroup, ProdGroup, 20251201D, 20251201D, 20251201D, FirstDayBase, FirstDayAmount);
        InsertVatEntry(BusGroup, ProdGroup, 20251231D, 20251231D, 20251231D, LastDayBase, LastDayAmount);
        InsertVatEntry(BusGroup, ProdGroup, 20260101D, 20260101D, 20260101D,
            LibraryRandom.RandDecInRange(1000, 2000, 2), LibraryRandom.RandDecInRange(100, 300, 2));

        VatPeriodTotals.VatTotalsForPeriod(BusGroup, ProdGroup, 20251201D, 20251231D, TotalBase, TotalAmount);

        Assert.AreEqual(FirstDayBase + LastDayBase, TotalBase,
            'Expected the entries VAT-dated exactly on FromDate and exactly on ToDate to count in TotalBase, and the entries one day outside each boundary not to');
        Assert.AreEqual(FirstDayAmount + LastDayAmount, TotalAmount,
            'Expected the entries VAT-dated exactly on FromDate and exactly on ToDate to count in TotalAmount, and the entries one day outside each boundary not to');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountsOnlyTheRequestedPostingGroupPair()
    var
        VatPeriodTotals: Codeunit "VAT Period Totals";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        BusGroup: Code[20];
        ProdGroup: Code[20];
        OtherBusGroup: Code[20];
        OtherProdGroup: Code[20];
        OwnBase: Decimal;
        OwnAmount: Decimal;
        TotalBase: Decimal;
        TotalAmount: Decimal;
    begin
        CreateGroupPair(BusGroup, ProdGroup);
        CreateGroupPair(OtherBusGroup, OtherProdGroup);
        OwnBase := LibraryRandom.RandDecInRange(1000, 2000, 2);
        OwnAmount := LibraryRandom.RandDecInRange(100, 300, 2);
        InsertVatEntry(BusGroup, ProdGroup, 20251210D, 20251210D, 20251210D, OwnBase, OwnAmount);
        InsertVatEntry(BusGroup, OtherProdGroup, 20251212D, 20251212D, 20251212D,
            LibraryRandom.RandDecInRange(1000, 2000, 2), LibraryRandom.RandDecInRange(100, 300, 2));
        InsertVatEntry(OtherBusGroup, ProdGroup, 20251214D, 20251214D, 20251214D,
            LibraryRandom.RandDecInRange(1000, 2000, 2), LibraryRandom.RandDecInRange(100, 300, 2));

        VatPeriodTotals.VatTotalsForPeriod(BusGroup, ProdGroup, 20251201D, 20251231D, TotalBase, TotalAmount);

        Assert.AreEqual(OwnBase, TotalBase,
            'Expected only the entry matching BOTH posting groups in TotalBase — entries sharing just the business group or just the product group must not count');
        Assert.AreEqual(OwnAmount, TotalAmount,
            'Expected only the entry matching BOTH posting groups in TotalAmount — entries sharing just the business group or just the product group must not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankVatDateFallsBackToThePostingDateDefault()
    var
        VatPeriodTotals: Codeunit "VAT Period Totals";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        BusGroup: Code[20];
        ProdGroup: Code[20];
        OtherBusGroup: Code[20];
        OtherProdGroup: Code[20];
        InsideBase: Decimal;
        InsideAmount: Decimal;
        TotalBase: Decimal;
        TotalAmount: Decimal;
    begin
        SetDefaultVatDate("VAT Reporting Date"::"Posting Date");
        CreateGroupPair(BusGroup, ProdGroup);
        CreateGroupPair(OtherBusGroup, OtherProdGroup);
        InsideBase := LibraryRandom.RandDecInRange(1000, 2000, 2);
        InsideAmount := LibraryRandom.RandDecInRange(100, 300, 2);
        InsertVatEntry(BusGroup, ProdGroup, 0D, 20251210D, 20260115D, InsideBase, InsideAmount);
        InsertVatEntry(BusGroup, ProdGroup, 0D, 20260110D, 20251215D,
            LibraryRandom.RandDecInRange(1000, 2000, 2), LibraryRandom.RandDecInRange(100, 300, 2));
        // Blank-dated decoy under a foreign group pair with an in-window posting
        // date: it fails any solution whose blank-date pass forgets the group filters.
        InsertVatEntry(OtherBusGroup, OtherProdGroup, 0D, 20251208D, 20251208D,
            LibraryRandom.RandDecInRange(1000, 2000, 2), LibraryRandom.RandDecInRange(100, 300, 2));

        VatPeriodTotals.VatTotalsForPeriod(BusGroup, ProdGroup, 20251201D, 20251231D, TotalBase, TotalAmount);

        Assert.AreEqual(InsideBase, TotalBase,
            'With Default VAT Date = Posting Date, expected the blank-VAT-date entry posted 10.12. in TotalBase and the one posted 10.01. excluded — blank dates fall back to the posting date, not the document date');
        Assert.AreEqual(InsideAmount, TotalAmount,
            'With Default VAT Date = Posting Date, expected the blank-VAT-date entry posted 10.12. in TotalAmount and the one posted 10.01. excluded — blank dates fall back to the posting date, not the document date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankVatDateFallsBackToTheDocumentDateDefault()
    var
        VatPeriodTotals: Codeunit "VAT Period Totals";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        BusGroup: Code[20];
        ProdGroup: Code[20];
        OtherBusGroup: Code[20];
        OtherProdGroup: Code[20];
        InsideBase: Decimal;
        InsideAmount: Decimal;
        TotalBase: Decimal;
        TotalAmount: Decimal;
    begin
        SetDefaultVatDate("VAT Reporting Date"::"Document Date");
        CreateGroupPair(BusGroup, ProdGroup);
        CreateGroupPair(OtherBusGroup, OtherProdGroup);
        InsideBase := LibraryRandom.RandDecInRange(1000, 2000, 2);
        InsideAmount := LibraryRandom.RandDecInRange(100, 300, 2);
        InsertVatEntry(BusGroup, ProdGroup, 0D, 20260109D, 20251212D, InsideBase, InsideAmount);
        InsertVatEntry(BusGroup, ProdGroup, 0D, 20251218D, 20260112D,
            LibraryRandom.RandDecInRange(1000, 2000, 2), LibraryRandom.RandDecInRange(100, 300, 2));
        // Blank-dated decoy under a foreign group pair with an in-window document
        // date: it fails any solution whose blank-date pass forgets the group filters.
        InsertVatEntry(OtherBusGroup, OtherProdGroup, 0D, 20260114D, 20251216D,
            LibraryRandom.RandDecInRange(1000, 2000, 2), LibraryRandom.RandDecInRange(100, 300, 2));

        VatPeriodTotals.VatTotalsForPeriod(BusGroup, ProdGroup, 20251201D, 20251231D, TotalBase, TotalAmount);

        Assert.AreEqual(InsideBase, TotalBase,
            'With Default VAT Date = Document Date, expected the blank-VAT-date entry document-dated 12.12. in TotalBase and the one document-dated 12.01. excluded — the fallback must follow the configured default, not always the posting date');
        Assert.AreEqual(InsideAmount, TotalAmount,
            'With Default VAT Date = Document Date, expected the blank-VAT-date entry document-dated 12.12. in TotalAmount and the one document-dated 12.01. excluded — the fallback must follow the configured default, not always the posting date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PeriodWithNoEntriesReturnsZeroInBothOutputs()
    var
        VatPeriodTotals: Codeunit "VAT Period Totals";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        BusGroup: Code[20];
        ProdGroup: Code[20];
        TotalBase: Decimal;
        TotalAmount: Decimal;
    begin
        CreateGroupPair(BusGroup, ProdGroup);
        TotalBase := LibraryRandom.RandDecInRange(1000, 2000, 2);
        TotalAmount := LibraryRandom.RandDecInRange(100, 300, 2);

        VatPeriodTotals.VatTotalsForPeriod(BusGroup, ProdGroup, 20251201D, 20251231D, TotalBase, TotalAmount);

        Assert.AreEqual(0.0, TotalBase,
            'Expected TotalBase = 0 for a period with no matching entries — the procedure must set the output, not add to whatever value the caller passed in');
        Assert.AreEqual(0.0, TotalAmount,
            'Expected TotalAmount = 0 for a period with no matching entries — the procedure must set the output, not add to whatever value the caller passed in');
    end;

    local procedure CreateGroupPair(var BusGroup: Code[20]; var ProdGroup: Code[20])
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        // Fresh, unique group codes isolate each test's fixtures from every other
        // VAT entry in the (possibly shared) grading company.
        BusGroup := LibraryUtility.GenerateGUID();
        ProdGroup := LibraryUtility.GenerateGUID();
    end;

    local procedure InsertVatEntry(BusGroup: Code[20]; ProdGroup: Code[20]; VatDate: Date; PostingDate: Date; DocumentDate: Date; BaseAmount: Decimal; VatAmount: Decimal)
    var
        VatEntry: Record "VAT Entry";
    begin
        VatEntry.Init();
        VatEntry."Entry No." := NextVatEntryNo();
        VatEntry."VAT Bus. Posting Group" := BusGroup;
        VatEntry."VAT Prod. Posting Group" := ProdGroup;
        VatEntry."VAT Reporting Date" := VatDate;
        VatEntry."Posting Date" := PostingDate;
        VatEntry."Document Date" := DocumentDate;
        VatEntry.Type := VatEntry.Type::Sale;
        VatEntry.Base := BaseAmount;
        VatEntry.Amount := VatAmount;
        VatEntry.Insert();
    end;

    local procedure NextVatEntryNo(): Integer
    var
        VatEntry: Record "VAT Entry";
    begin
        if VatEntry.FindLast() then
            exit(VatEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure SetDefaultVatDate(DefaultDate: Enum "VAT Reporting Date")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."VAT Reporting Date" := DefaultDate;
        GeneralLedgerSetup.Modify();
    end;
}
