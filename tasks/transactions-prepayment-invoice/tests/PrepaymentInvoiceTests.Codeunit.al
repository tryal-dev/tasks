codeunit 50900 "Prepayment Invoice Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Sales] [Prepayment]

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DepositPercentReachesTheOrderAndEveryLine()
    var
        SalesHeader: Record "Sales Header";
        FirstLine: Record "Sales Line";
        SecondLine: Record "Sales Line";
        SalesDepositManager: Codeunit "Sales Deposit Manager";
        PrepmtAccountNo: Code[20];
        LineAccountNo: Code[20];
        FirstAmount: Decimal;
        SecondAmount: Decimal;
        DepositPct: Decimal;
    begin
        // [SCENARIO] Asking for a deposit stores the percentage on the order and the resulting share on every line
        // [GIVEN] an order with two G/L account lines of different amounts
        Initialize();
        CreateOrder(SalesHeader, PrepmtAccountNo, LineAccountNo);
        FirstAmount := RandomLineAmount();
        SecondAmount := RandomLineAmount();
        AddLine(SalesHeader, FirstLine, LineAccountNo, FirstAmount);
        AddLine(SalesHeader, SecondLine, LineAccountNo, SecondAmount);
        DepositPct := LibraryRandom.RandIntInRange(10, 60);

        // [WHEN] setting the deposit to a generated percentage
        SalesDepositManager.SetDeposit(SalesHeader, DepositPct, true);

        // [THEN] the order header and both lines carry it in the database
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.AreEqual(DepositPct, SalesHeader."Prepayment %",
            'Expected the order header to store the deposit percentage handed to SetDeposit');
        VerifyLineDeposit(FirstLine, DepositPct, FirstAmount);
        VerifyLineDeposit(SecondLine, DepositPct, SecondAmount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TurningCompressionOffIsStoredOnTheOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesDepositManager: Codeunit "Sales Deposit Manager";
        PrepmtAccountNo: Code[20];
        LineAccountNo: Code[20];
    begin
        // [SCENARIO] The CompressLines argument reaches the order's "Compress Prepayment" field
        // [GIVEN] an order with one line - "Compress Prepayment" starts out true, the field's own default
        Initialize();
        CreateOrder(SalesHeader, PrepmtAccountNo, LineAccountNo);
        AddLine(SalesHeader, SalesLine, LineAccountNo, RandomLineAmount());

        // [WHEN] setting a deposit that must not be compressed
        SalesDepositManager.SetDeposit(SalesHeader, 30, false);

        // [THEN] the order says so
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.IsFalse(SalesHeader."Compress Prepayment",
            'Expected "Compress Prepayment" on the order to be false after SetDeposit was called with CompressLines = false');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostDepositReturnsThePostedPrepaymentInvoiceNumber()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesDepositManager: Codeunit "Sales Deposit Manager";
        PrepmtAccountNo: Code[20];
        LineAccountNo: Code[20];
        OrderNo: Code[20];
        DepositInvoiceNo: Code[20];
    begin
        // [SCENARIO] The number PostDeposit returns identifies a posted prepayment invoice for this order
        // [GIVEN] an order with a 30% deposit set on it
        Initialize();
        CreateOrder(SalesHeader, PrepmtAccountNo, LineAccountNo);
        AddLine(SalesHeader, SalesLine, LineAccountNo, RandomLineAmount());
        OrderNo := SalesHeader."No.";
        SalesDepositManager.SetDeposit(SalesHeader, 30, true);

        // [WHEN] posting the deposit
        DepositInvoiceNo := SalesDepositManager.PostDeposit(SalesHeader);

        // [THEN] that number is a posted prepayment invoice raised against the order
        Assert.IsTrue(SalesInvoiceHeader.Get(DepositInvoiceNo),
            StrSubstNo('Expected PostDeposit to return the number of a posted sales invoice, got "%1"', DepositInvoiceNo));
        Assert.IsTrue(SalesInvoiceHeader."Prepayment Invoice",
            StrSubstNo('Expected posted invoice %1 to be flagged as a prepayment invoice - the deposit must be posted as a prepayment, not as an ordinary invoice', DepositInvoiceNo));
        Assert.AreEqual(OrderNo, SalesInvoiceHeader."Prepayment Order No.",
            'Expected the posted prepayment invoice to point back at the order it was raised from');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostedDepositCreditsTheSalesPrepaymentsAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        SalesDepositManager: Codeunit "Sales Deposit Manager";
        PrepmtAccountNo: Code[20];
        LineAccountNo: Code[20];
        LineAmount: Decimal;
        DepositInvoiceNo: Code[20];
    begin
        // [SCENARIO] The deposit lands on the Sales Prepayments Account of the general posting setup, as a credit
        // [GIVEN] an order with one line and a 30% deposit
        Initialize();
        CreateOrder(SalesHeader, PrepmtAccountNo, LineAccountNo);
        LineAmount := RandomLineAmount();
        AddLine(SalesHeader, SalesLine, LineAccountNo, LineAmount);
        SalesDepositManager.SetDeposit(SalesHeader, 30, true);

        // [WHEN] posting the deposit
        DepositInvoiceNo := SalesDepositManager.PostDeposit(SalesHeader);

        // [THEN] the prepayment account carries the deposit excluding VAT, as a credit
        GLEntry.SetRange("Document No.", DepositInvoiceNo);
        GLEntry.SetRange("G/L Account No.", PrepmtAccountNo);
        Assert.RecordIsNotEmpty(GLEntry);
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(-Round(LineAmount * 30 / 100), GLEntry.Amount,
            StrSubstNo('Expected the sales prepayments account %1 to be credited with 30 percent of the line amount %2 by the posted deposit', PrepmtAccountNo, LineAmount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostedDepositLandsOnPrepmtAmtInvOfEveryLine()
    var
        SalesHeader: Record "Sales Header";
        FirstLine: Record "Sales Line";
        SecondLine: Record "Sales Line";
        SalesDepositManager: Codeunit "Sales Deposit Manager";
        PrepmtAccountNo: Code[20];
        LineAccountNo: Code[20];
        FirstAmount: Decimal;
        SecondAmount: Decimal;
    begin
        // [SCENARIO] Every order line records the deposit that was invoiced for it
        // [GIVEN] an order with two lines and a 30% deposit
        Initialize();
        CreateOrder(SalesHeader, PrepmtAccountNo, LineAccountNo);
        FirstAmount := RandomLineAmount();
        SecondAmount := RandomLineAmount();
        AddLine(SalesHeader, FirstLine, LineAccountNo, FirstAmount);
        AddLine(SalesHeader, SecondLine, LineAccountNo, SecondAmount);
        SalesDepositManager.SetDeposit(SalesHeader, 30, true);

        // [WHEN] posting the deposit
        SalesDepositManager.PostDeposit(SalesHeader);

        // [THEN] "Prepmt. Amt. Inv." on each line is that line's share of the deposit
        VerifyLineInvoicedDeposit(FirstLine, Round(FirstAmount * 30 / 100));
        VerifyLineInvoicedDeposit(SecondLine, Round(SecondAmount * 30 / 100));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FinalInvoiceChargesTheOrderTotalMinusTheDeposit()
    var
        SalesHeader: Record "Sales Header";
        FirstLine: Record "Sales Line";
        SecondLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesDepositManager: Codeunit "Sales Deposit Manager";
        PrepmtAccountNo: Code[20];
        LineAccountNo: Code[20];
        TotalInclVAT: Decimal;
        DepositInclVAT: Decimal;
        FinalInvoiceNo: Code[20];
    begin
        // [SCENARIO] The customer is billed the order total including VAT less the deposit already invoiced
        // [GIVEN] an order with two lines whose 30% deposit has been posted
        Initialize();
        CreateOrder(SalesHeader, PrepmtAccountNo, LineAccountNo);
        AddLine(SalesHeader, FirstLine, LineAccountNo, RandomLineAmount());
        AddLine(SalesHeader, SecondLine, LineAccountNo, RandomLineAmount());
        SalesDepositManager.SetDeposit(SalesHeader, 30, true);
        SalesDepositManager.PostDeposit(SalesHeader);
        SumOrder(SalesHeader, TotalInclVAT, DepositInclVAT);
        Assert.AreNotEqual(0, DepositInclVAT,
            'Expected the posted deposit to reach "Prepmt. Amount Inv. Incl. VAT" on the order lines before the final invoice is posted');

        // [WHEN] shipping and invoicing the whole order
        FinalInvoiceNo := SalesDepositManager.PostFinalInvoice(SalesHeader);

        // [THEN] the customer ledger entry behind that invoice is the total minus the deposit
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", FinalInvoiceNo);
        Assert.IsTrue(CustLedgerEntry.FindFirst(),
            StrSubstNo('Expected PostFinalInvoice to return the number of a posted sales invoice with a customer ledger entry, got "%1"', FinalInvoiceNo));
        CustLedgerEntry.CalcFields(Amount);
        Assert.AreNearlyEqual(TotalInclVAT - DepositInclVAT, CustLedgerEntry.Amount, 0.01,
            StrSubstNo('Expected the final invoice to bill the order total incl. VAT %1 less the deposit %2 already invoiced', TotalInclVAT, DepositInclVAT));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CompressedDepositMergesLinesSharingAccountAndDimensions()
    var
        SalesHeader: Record "Sales Header";
        FirstLine: Record "Sales Line";
        SecondLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesDepositManager: Codeunit "Sales Deposit Manager";
        PrepmtAccountNo: Code[20];
        LineAccountNo: Code[20];
        FirstAmount: Decimal;
        SecondAmount: Decimal;
        DepositInvoiceNo: Code[20];
    begin
        // [SCENARIO] Two lines on the same prepayment account with the same dimensions become one prepayment line
        // [GIVEN] an order with two lines on the same G/L account and no dimensions, compressed
        Initialize();
        CreateOrder(SalesHeader, PrepmtAccountNo, LineAccountNo);
        FirstAmount := RandomLineAmount();
        SecondAmount := RandomLineAmount();
        AddLine(SalesHeader, FirstLine, LineAccountNo, FirstAmount);
        AddLine(SalesHeader, SecondLine, LineAccountNo, SecondAmount);
        SalesDepositManager.SetDeposit(SalesHeader, 30, true);

        // [WHEN] posting the deposit
        DepositInvoiceNo := SalesDepositManager.PostDeposit(SalesHeader);

        // [THEN] the posted prepayment invoice carries a single line for both order lines
        FilterPrepaymentLines(SalesInvoiceLine, DepositInvoiceNo, PrepmtAccountNo);
        Assert.AreEqual(1, SalesInvoiceLine.Count(),
            'Expected one compressed prepayment line: both order lines share the sales prepayments account and the same dimensions');
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(Round((FirstAmount + SecondAmount) * 30 / 100), SalesInvoiceLine.Amount,
            'Expected the compressed prepayment line to carry the deposit of both order lines together');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CompressedDepositStillSplitsLinesWithDifferentDimensions()
    var
        SalesHeader: Record "Sales Header";
        FirstLine: Record "Sales Line";
        SecondLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesDepositManager: Codeunit "Sales Deposit Manager";
        PrepmtAccountNo: Code[20];
        LineAccountNo: Code[20];
        DepositInvoiceNo: Code[20];
    begin
        // [SCENARIO] Compression merges lines only when their dimensions match too
        // [GIVEN] an order with two lines on the same G/L account but different dimension values, compressed
        Initialize();
        CreateOrder(SalesHeader, PrepmtAccountNo, LineAccountNo);
        AddLine(SalesHeader, FirstLine, LineAccountNo, RandomLineAmount());
        AddLine(SalesHeader, SecondLine, LineAccountNo, RandomLineAmount());
        GiveLineItsOwnDimension(FirstLine);
        GiveLineItsOwnDimension(SecondLine);
        SalesDepositManager.SetDeposit(SalesHeader, 30, true);

        // [WHEN] posting the deposit
        DepositInvoiceNo := SalesDepositManager.PostDeposit(SalesHeader);

        // [THEN] the posted prepayment invoice keeps them apart
        FilterPrepaymentLines(SalesInvoiceLine, DepositInvoiceNo, PrepmtAccountNo);
        Assert.AreEqual(2, SalesInvoiceLine.Count(),
            'Expected two prepayment lines: compression merges lines that share the prepayment account AND the dimensions, and these two carry different dimension values');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UncompressedDepositKeepsOnePrepaymentLinePerOrderLine()
    var
        SalesHeader: Record "Sales Header";
        FirstLine: Record "Sales Line";
        SecondLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesDepositManager: Codeunit "Sales Deposit Manager";
        PrepmtAccountNo: Code[20];
        LineAccountNo: Code[20];
        DepositInvoiceNo: Code[20];
    begin
        // [SCENARIO] Without compression every order line gets its own prepayment line, dimensions or not
        // [GIVEN] an order with two lines that would otherwise merge, not compressed
        Initialize();
        CreateOrder(SalesHeader, PrepmtAccountNo, LineAccountNo);
        AddLine(SalesHeader, FirstLine, LineAccountNo, RandomLineAmount());
        AddLine(SalesHeader, SecondLine, LineAccountNo, RandomLineAmount());
        SalesDepositManager.SetDeposit(SalesHeader, 30, false);

        // [WHEN] posting the deposit
        DepositInvoiceNo := SalesDepositManager.PostDeposit(SalesHeader);

        // [THEN] the posted prepayment invoice has one line per order line
        FilterPrepaymentLines(SalesInvoiceLine, DepositInvoiceNo, PrepmtAccountNo);
        Assert.AreEqual(2, SalesInvoiceLine.Count(),
            'Expected one prepayment line per order line when the deposit is posted without compression');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure RemovingALineWithAnInvoicedDepositIsRefused()
    var
        SalesHeader: Record "Sales Header";
        FirstLine: Record "Sales Line";
        SecondLine: Record "Sales Line";
        SalesDepositManager: Codeunit "Sales Deposit Manager";
        PrepmtAccountNo: Code[20];
        LineAccountNo: Code[20];
    begin
        // [SCENARIO] A line whose deposit is already invoiced cannot be taken off the order
        // [GIVEN] an order with a posted deposit, reopened so its lines are editable again
        Initialize();
        CreateOrder(SalesHeader, PrepmtAccountNo, LineAccountNo);
        AddLine(SalesHeader, FirstLine, LineAccountNo, RandomLineAmount());
        AddLine(SalesHeader, SecondLine, LineAccountNo, RandomLineAmount());
        SalesDepositManager.SetDeposit(SalesHeader, 30, true);
        SalesDepositManager.PostDeposit(SalesHeader);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.ReopenSalesDocument(SalesHeader);
        FirstLine.Get(FirstLine."Document Type", FirstLine."Document No.", FirstLine."Line No.");
        // The refused call rolls the database back to the last commit; without
        // this the whole order would vanish together with the rejected removal.
        Commit();

        // [WHEN] trying to remove the prepaid line
        asserterror SalesDepositManager.RemoveLine(FirstLine);

        // [THEN] the attempt is refused by name and the line survives
        AssertErrorContains('Prepmt. Amt. Inv.');
        Assert.IsTrue(FirstLine.Get(FirstLine."Document Type", FirstLine."Document No.", FirstLine."Line No."),
            'Expected the prepaid order line to still be there after the refused removal');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemovingALineWithNoInvoicedDepositSucceeds()
    var
        SalesHeader: Record "Sales Header";
        FirstLine: Record "Sales Line";
        SecondLine: Record "Sales Line";
        SalesDepositManager: Codeunit "Sales Deposit Manager";
        PrepmtAccountNo: Code[20];
        LineAccountNo: Code[20];
    begin
        // [SCENARIO] A line is removed normally while nothing has been invoiced on it yet
        // [GIVEN] an order carrying a deposit percentage that has not been posted
        Initialize();
        CreateOrder(SalesHeader, PrepmtAccountNo, LineAccountNo);
        AddLine(SalesHeader, FirstLine, LineAccountNo, RandomLineAmount());
        AddLine(SalesHeader, SecondLine, LineAccountNo, RandomLineAmount());
        SalesDepositManager.SetDeposit(SalesHeader, 30, true);
        SecondLine.Get(SecondLine."Document Type", SecondLine."Document No.", SecondLine."Line No.");

        // [WHEN] removing the second line
        SalesDepositManager.RemoveLine(SecondLine);

        // [THEN] it is gone and the first line is untouched
        Assert.IsFalse(SecondLine.Get(SecondLine."Document Type", SecondLine."Document No.", SecondLine."Line No."),
            'Expected the line to be removed from the order - nothing had been invoiced on it, so the prepayment guard must not fire');
        Assert.IsTrue(FirstLine.Get(FirstLine."Document Type", FirstLine."Document No.", FirstLine."Line No."),
            'Expected removing one line to leave the rest of the order alone');
    end;

    local procedure Initialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // Prepayment posting demands a journal template only where the ledger
        // setup makes them mandatory; the fixture never configures one.
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Journal Templ. Name Mandatory" then begin
            GeneralLedgerSetup."Journal Templ. Name Mandatory" := false;
            GeneralLedgerSetup.Modify();
        end;

        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Posted Prepmt. Inv. Nos." = '' then
            SalesReceivablesSetup."Posted Prepmt. Inv. Nos." := LibraryERM.CreateNoSeriesCode();
        // Keep the fixture arithmetic exact and the posting path unconditional:
        // no invoice rounding line, no invoice discount redistribution, and no
        // block on invoicing an order whose deposit has not been paid yet.
        SalesReceivablesSetup."Invoice Rounding" := false;
        SalesReceivablesSetup."Calc. Inv. Discount" := false;
        SalesReceivablesSetup."Check Prepmt. when Posting" := false;
        SalesReceivablesSetup.Modify();
    end;

    local procedure CreateOrder(var SalesHeader: Record "Sales Header"; var PrepmtAccountNo: Code[20]; var LineAccountNo: Code[20])
    var
        LineGLAccount: Record "G/L Account";
        PrepmtGLAccount: Record "G/L Account";
        Customer: Record Customer;
    begin
        Clear(LineGLAccount);
        LibraryERM.CreatePrepaymentVATSetup(
            LineGLAccount, PrepmtGLAccount, Enum::"General Posting Type"::Sale,
            Enum::"Tax Calculation Type"::"Normal VAT", Enum::"Tax Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, Enum::"Sales Document Type"::Order, Customer."No.");
        PrepmtAccountNo := PrepmtGLAccount."No.";
        LineAccountNo := LineGLAccount."No.";
    end;

    local procedure AddLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; GLAccountNo: Code[20]; LineAmount: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Enum::"Sales Line Type"::"G/L Account", GLAccountNo, 1);
        SalesLine.Validate("Unit Price", LineAmount);
        SalesLine.Modify(true);
    end;

    local procedure GiveLineItsOwnDimension(var SalesLine: Record "Sales Line")
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate(
            "Dimension Set ID",
            LibraryDimension.CreateDimSet(SalesLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        SalesLine.Modify(true);
    end;

    local procedure RandomLineAmount(): Decimal
    begin
        // Whole hundreds keep every percentage share and its VAT exact to the cent.
        exit(100 * LibraryRandom.RandIntInRange(5, 20));
    end;

    local procedure SumOrder(SalesHeader: Record "Sales Header"; var TotalInclVAT: Decimal; var DepositInclVAT: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        TotalInclVAT := 0;
        DepositInclVAT := 0;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                TotalInclVAT += SalesLine."Amount Including VAT";
                DepositInclVAT += SalesLine."Prepmt. Amount Inv. Incl. VAT";
            until SalesLine.Next() = 0;
    end;

    local procedure FilterPrepaymentLines(var SalesInvoiceLine: Record "Sales Invoice Line"; DocumentNo: Code[20]; PrepmtAccountNo: Code[20])
    begin
        SalesInvoiceLine.Reset();
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"G/L Account");
        SalesInvoiceLine.SetRange("No.", PrepmtAccountNo);
    end;

    local procedure VerifyLineDeposit(var SalesLine: Record "Sales Line"; DepositPct: Decimal; LineAmount: Decimal)
    begin
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(DepositPct, SalesLine."Prepayment %",
            StrSubstNo('Expected line %1 to carry the deposit percentage too - storing it on the order header alone leaves the lines behind', SalesLine."Line No."));
        Assert.AreEqual(Round(LineAmount * DepositPct / 100), SalesLine."Prepmt. Line Amount",
            StrSubstNo('Expected "Prepmt. Line Amount" on line %1 to be the deposit share of its line amount %2', SalesLine."Line No.", LineAmount));
    end;

    local procedure VerifyLineInvoicedDeposit(var SalesLine: Record "Sales Line"; ExpectedAmount: Decimal)
    begin
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(ExpectedAmount, SalesLine."Prepmt. Amt. Inv.",
            StrSubstNo('Expected "Prepmt. Amt. Inv." on line %1 to record the deposit invoiced for that line', SalesLine."Line No."));
    end;

    local procedure AssertErrorContains(Fragment: Text)
    var
        ActualError: Text;
    begin
        ActualError := GetLastErrorText();
        Assert.IsTrue(LowerCase(ActualError).Contains(LowerCase(Fragment)),
            StrSubstNo('Expected removing a prepaid line to fail with an error naming "%1", got: %2', Fragment, ActualError));
    end;
}
