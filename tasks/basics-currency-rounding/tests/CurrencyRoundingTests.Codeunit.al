codeunit 50900 "Currency Rounding Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryERM: Codeunit "Library - ERM";

    // [FEATURE] [Currency Rounding]

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvoiceTotalRoundsUpToTheCurrencyPrecision()
    var
        CurrencyRounding: Codeunit "Currency Rounding";
        Assert: Codeunit Assert;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] An invoice total in a currency that rounds up to 0.05 is lifted to the next 0.05 step
        // [GIVEN] a currency with Invoice Rounding Precision 0.05 and Invoice Rounding Type Up
        CurrencyCode := CreateFiveCentUpCurrency();

        // [WHEN] rounding an invoice total of 10.01
        // [THEN] the total is 10.05
        Assert.AreEqual(10.05, CurrencyRounding.RoundInvoiceTotal(10.01, CurrencyCode),
            'Expected 10.01 to round UP to the next 0.05 step in a currency whose Invoice Rounding Precision is 0.05 and Invoice Rounding Type is Up');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvoiceTotalRoundsDownToTheCurrencyPrecision()
    var
        CurrencyRounding: Codeunit "Currency Rounding";
        Assert: Codeunit Assert;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] An invoice total in a currency that rounds down to whole units drops to the unit below
        // [GIVEN] a currency with Invoice Rounding Precision 1.00 and Invoice Rounding Type Down
        CurrencyCode := CreateWholeUnitDownCurrency();

        // [WHEN] rounding an invoice total of 10.99
        // [THEN] the total is 10
        Assert.AreEqual(10.0, CurrencyRounding.RoundInvoiceTotal(10.99, CurrencyCode),
            'Expected 10.99 to round DOWN to 10 in a currency whose Invoice Rounding Precision is 1.00 and Invoice Rounding Type is Down');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvoiceTotalRoundsToNearestBelowHalfStep()
    var
        CurrencyRounding: Codeunit "Currency Rounding";
        Assert: Codeunit Assert;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] An invoice total in a Nearest currency that sits below the half step drops to the step below, not up
        // [GIVEN] a currency with Invoice Rounding Precision 0.05 and Invoice Rounding Type Nearest
        CurrencyCode := CreateFiveCentNearestCurrency();

        // [WHEN] rounding an invoice total of 10.02
        // [THEN] the total is 10.00
        Assert.AreEqual(10.0, CurrencyRounding.RoundInvoiceTotal(10.02, CurrencyCode),
            'Expected 10.02 to round to the NEAREST 0.05 step (10.00) in a currency whose Invoice Rounding Type is Nearest — Nearest must not be treated as Up');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvoiceTotalRoundsToNearestAboveHalfStep()
    var
        CurrencyRounding: Codeunit "Currency Rounding";
        Assert: Codeunit Assert;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] An invoice total in a Nearest currency that sits above the half step lifts to the step above, not down
        // [GIVEN] a currency with Invoice Rounding Precision 0.05 and Invoice Rounding Type Nearest
        CurrencyCode := CreateFiveCentNearestCurrency();

        // [WHEN] rounding an invoice total of 10.03
        // [THEN] the total is 10.05
        Assert.AreEqual(10.05, CurrencyRounding.RoundInvoiceTotal(10.03, CurrencyCode),
            'Expected 10.03 to round to the NEAREST 0.05 step (10.05) in a currency whose Invoice Rounding Type is Nearest — Nearest must not be treated as Down');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeInvoiceTotalRoundsUpAwayFromZero()
    var
        CurrencyRounding: Codeunit "Currency Rounding";
        Assert: Codeunit Assert;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] A credit memo total in an Up currency moves away from zero, not toward the mathematically bigger value
        // [GIVEN] a currency with Invoice Rounding Precision 0.05 and Invoice Rounding Type Up
        CurrencyCode := CreateFiveCentUpCurrency();

        // [WHEN] rounding a credit memo total of -10.01
        // [THEN] the total is -10.05
        Assert.AreEqual(-10.05, CurrencyRounding.RoundInvoiceTotal(-10.01, CurrencyCode),
            'Expected -10.01 to round UP to -10.05: Round''s ''>'' direction moves a negative amount away from zero, not toward -10.00');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeInvoiceTotalRoundsDownTowardZero()
    var
        CurrencyRounding: Codeunit "Currency Rounding";
        Assert: Codeunit Assert;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] A credit memo total in a Down currency moves toward zero, not to the mathematically smaller value
        // [GIVEN] a currency with Invoice Rounding Precision 1.00 and Invoice Rounding Type Down
        CurrencyCode := CreateWholeUnitDownCurrency();

        // [WHEN] rounding a credit memo total of -10.99
        // [THEN] the total is -10
        Assert.AreEqual(-10.0, CurrencyRounding.RoundInvoiceTotal(-10.99, CurrencyCode),
            'Expected -10.99 to round DOWN to -10: Round''s ''<'' direction moves a negative amount toward zero, not to -11');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvoiceTotalAlreadyOnThePrecisionIsUnchanged()
    var
        CurrencyRounding: Codeunit "Currency Rounding";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // [SCENARIO] An amount that already sits on a 0.05 step is not pushed to the next step by an Up currency
        // [GIVEN] a currency with Invoice Rounding Precision 0.05 and Invoice Rounding Type Up, and a random multiple of 0.05
        CurrencyCode := CreateFiveCentUpCurrency();
        Amount := Any.IntegerInRange(1, 400) * 0.05;

        // [WHEN] rounding that amount
        // [THEN] it comes back unchanged
        Assert.AreEqual(Amount, CurrencyRounding.RoundInvoiceTotal(Amount, CurrencyCode),
            StrSubstNo('Expected %1, which already is a multiple of 0.05, to come back unchanged even though the currency rounds up', Amount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvoiceTotalRoundsAGeneratedAmount()
    var
        CurrencyRounding: Codeunit "Currency Rounding";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // [SCENARIO] A random invoice total in a whole-unit Down currency drops to the whole unit below
        // [GIVEN] a currency with Invoice Rounding Precision 1.00 and Invoice Rounding Type Down, and a random amount with cents
        CurrencyCode := CreateWholeUnitDownCurrency();
        Amount := Any.DecimalInRange(100, 999, 2);

        // [WHEN] rounding that amount
        // [THEN] the result is the amount rounded down to a whole unit
        Assert.AreEqual(Round(Amount, 1, '<'), CurrencyRounding.RoundInvoiceTotal(Amount, CurrencyCode),
            StrSubstNo('Expected %1 to round DOWN to the whole unit below in a currency whose Invoice Rounding Precision is 1.00 and type is Down', Amount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvoiceTotalWithoutCurrencyUsesGeneralLedgerSetup()
    var
        CurrencyRounding: Codeunit "Currency Rounding";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A blank currency code rounds with the LCY invoice rounding from General Ledger Setup
        // [GIVEN] General Ledger Setup with Inv. Rounding Precision (LCY) 0.25 and Inv. Rounding Type (LCY) Up
        ConfigureLcyRounding();

        // [WHEN] rounding an invoice total of 10.01 with a blank currency code
        // [THEN] the total is 10.25
        Assert.AreEqual(10.25, CurrencyRounding.RoundInvoiceTotal(10.01, ''),
            'Expected a blank currency code to round 10.01 UP to 10.25 using General Ledger Setup''s Inv. Rounding Precision (LCY) of 0.25 and Inv. Rounding Type (LCY) of Up');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnitPriceRoundsToTheCurrencyUnitAmountPrecision()
    var
        CurrencyRounding: Codeunit "Currency Rounding";
        Assert: Codeunit Assert;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] A unit price is rounded to the nearest multiple of the currency's Unit-Amount Rounding Precision
        // [GIVEN] a currency with Unit-Amount Rounding Precision 0.001
        CurrencyCode := CreateFiveCentUpCurrency();

        // [WHEN] rounding a unit price of 12.3456
        // [THEN] the price is 12.346
        Assert.AreEqual(12.346, CurrencyRounding.RoundUnitPrice(12.3456, CurrencyCode),
            'Expected 12.3456 to round to 12.346 in a currency whose Unit-Amount Rounding Precision is 0.001 (the Amount Rounding Precision of 0.01 is the wrong field)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnitPriceIgnoresAnUpInvoiceRoundingType()
    var
        CurrencyRounding: Codeunit "Currency Rounding";
        Assert: Codeunit Assert;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] A currency that rounds invoices up still rounds unit prices to the nearest
        // [GIVEN] a currency with Invoice Rounding Type Up and Unit-Amount Rounding Precision 0.001
        CurrencyCode := CreateFiveCentUpCurrency();

        // [WHEN] rounding a unit price of 12.3451
        // [THEN] the price is 12.345, not 12.346
        Assert.AreEqual(12.345, CurrencyRounding.RoundUnitPrice(12.3451, CurrencyCode),
            'Expected 12.3451 to round to the NEAREST 0.001 (12.345) — the Invoice Rounding Type Up must not apply to unit prices');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnitPriceIgnoresADownInvoiceRoundingType()
    var
        CurrencyRounding: Codeunit "Currency Rounding";
        Assert: Codeunit Assert;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] A currency that rounds invoices down still rounds unit prices to the nearest
        // [GIVEN] a currency with Invoice Rounding Type Down and Unit-Amount Rounding Precision 0.1
        CurrencyCode := CreateWholeUnitDownCurrency();

        // [WHEN] rounding a unit price of 7.46
        // [THEN] the price is 7.5, not 7.4
        Assert.AreEqual(7.5, CurrencyRounding.RoundUnitPrice(7.46, CurrencyCode),
            'Expected 7.46 to round to the NEAREST 0.1 (7.5) — the Invoice Rounding Type Down must not apply to unit prices');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeUnitPriceRoundsToNearest()
    var
        CurrencyRounding: Codeunit "Currency Rounding";
        Assert: Codeunit Assert;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] A negative unit price rounds to the nearest step like a positive one
        // [GIVEN] a currency with Unit-Amount Rounding Precision 0.001
        CurrencyCode := CreateFiveCentUpCurrency();

        // [WHEN] rounding a unit price of -12.3456
        // [THEN] the price is -12.346
        Assert.AreEqual(-12.346, CurrencyRounding.RoundUnitPrice(-12.3456, CurrencyCode),
            'Expected -12.3456 to round to the nearest 0.001, which is -12.346');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnitPriceAlreadyOnThePrecisionIsUnchanged()
    var
        CurrencyRounding: Codeunit "Currency Rounding";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // [SCENARIO] A unit price that already sits on a 0.001 step comes back as it is
        // [GIVEN] a currency with Unit-Amount Rounding Precision 0.001 and a random multiple of 0.001
        CurrencyCode := CreateFiveCentUpCurrency();
        Amount := Any.IntegerInRange(1, 50000) * 0.001;

        // [WHEN] rounding that unit price
        // [THEN] it comes back unchanged
        Assert.AreEqual(Amount, CurrencyRounding.RoundUnitPrice(Amount, CurrencyCode),
            StrSubstNo('Expected %1, which already is a multiple of 0.001, to come back unchanged from RoundUnitPrice', Amount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnitPriceRoundsAGeneratedAmount()
    var
        CurrencyRounding: Codeunit "Currency Rounding";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // [SCENARIO] A random five-decimal unit price is rounded to the nearest 0.001
        // [GIVEN] a currency with Unit-Amount Rounding Precision 0.001 and a random amount with five decimals
        CurrencyCode := CreateFiveCentUpCurrency();
        Amount := Any.DecimalInRange(1, 500, 5);

        // [WHEN] rounding that amount
        // [THEN] the result is the amount rounded to the nearest 0.001
        Assert.AreEqual(Round(Amount, 0.001), CurrencyRounding.RoundUnitPrice(Amount, CurrencyCode),
            StrSubstNo('Expected %1 to round to the nearest 0.001 in a currency whose Unit-Amount Rounding Precision is 0.001', Amount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnitPriceWithoutCurrencyUsesGeneralLedgerSetup()
    var
        CurrencyRounding: Codeunit "Currency Rounding";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A blank currency code rounds unit prices with General Ledger Setup's Unit-Amount Rounding Precision
        // [GIVEN] General Ledger Setup with Unit-Amount Rounding Precision 0.001 and Amount Rounding Precision 0.01
        ConfigureLcyRounding();

        // [WHEN] rounding a unit price of 12.3456 with a blank currency code
        // [THEN] the price is 12.346
        Assert.AreEqual(12.346, CurrencyRounding.RoundUnitPrice(12.3456, ''),
            'Expected a blank currency code to round 12.3456 to 12.346 using General Ledger Setup''s Unit-Amount Rounding Precision of 0.001');
    end;

    local procedure CreateFiveCentUpCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency."Amount Rounding Precision" := 0.01;
        Currency."Invoice Rounding Precision" := 0.05;
        Currency."Invoice Rounding Type" := Currency."Invoice Rounding Type"::Up;
        Currency."Unit-Amount Rounding Precision" := 0.001;
        Currency.Modify();
        exit(Currency.Code);
    end;

    local procedure CreateWholeUnitDownCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency."Amount Rounding Precision" := 0.01;
        Currency."Invoice Rounding Precision" := 1;
        Currency."Invoice Rounding Type" := Currency."Invoice Rounding Type"::Down;
        Currency."Unit-Amount Rounding Precision" := 0.1;
        Currency.Modify();
        exit(Currency.Code);
    end;

    local procedure CreateFiveCentNearestCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency."Amount Rounding Precision" := 0.01;
        Currency."Invoice Rounding Precision" := 0.05;
        Currency."Invoice Rounding Type" := Currency."Invoice Rounding Type"::Nearest;
        Currency."Unit-Amount Rounding Precision" := 0.001;
        Currency.Modify();
        exit(Currency.Code);
    end;

    local procedure ConfigureLcyRounding()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Amount Rounding Precision" := 0.01;
        GeneralLedgerSetup."Inv. Rounding Precision (LCY)" := 0.25;
        GeneralLedgerSetup."Inv. Rounding Type (LCY)" := GeneralLedgerSetup."Inv. Rounding Type (LCY)"::Up;
        GeneralLedgerSetup."Unit-Amount Rounding Precision" := 0.001;
        GeneralLedgerSetup.Modify();
    end;
}
