codeunit 50900 "LCY Converter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryERM: Codeunit "Library - ERM";

    // [FEATURE] [Currency] [LCY Converter]

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankCurrencyCodeReturnsTheAmountUnchanged()
    var
        LCYConverter: Codeunit "LCY Converter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Amount: Decimal;
    begin
        // [SCENARIO] An amount without a currency code already is in LCY and comes back as it is
        // [GIVEN] LCY amounts rounding to 0.01 and a random two-decimal amount
        ConfigureLcyPrecision(0.01);
        Amount := Any.DecimalInRange(1, 9999, 2);

        // [WHEN] converting it with a blank currency code
        // [THEN] the amount is returned unchanged
        Assert.AreEqual(Amount, LCYConverter.ToLCY(Amount, '', DMY2Date(15, 3, 2024)),
            StrSubstNo('Expected a blank currency code to return the amount %1 unchanged — a blank code means the amount already is in LCY', Amount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConvertsWithARateStoredPerUnit()
    var
        LCYConverter: Codeunit "LCY Converter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CurrencyCode: Code[10];
        Amount: Decimal;
        Rate: Decimal;
    begin
        // [SCENARIO] A whole-number amount converts with a rate row stored as 1 unit = <rate> LCY
        // [GIVEN] a currency with one rate row of 1 : <random two-decimal rate> and a random whole-number amount
        ConfigureLcyPrecision(0.01);
        CurrencyCode := CreateCurrency();
        Rate := Any.DecimalInRange(5, 9, 2);
        SeedRate(CurrencyCode, DMY2Date(1, 3, 2024), 1, Rate);
        Amount := Any.IntegerInRange(1, 9999);

        // [WHEN] converting the amount on a date after the row started
        // [THEN] the LCY amount is the amount times the rate
        Assert.AreEqual(Amount * Rate, LCYConverter.ToLCY(Amount, CurrencyCode, DMY2Date(15, 3, 2024)),
            StrSubstNo('Expected %1 %2 to convert to %1 x %3 LCY with a rate row of Exchange Rate Amount 1 and Relational Exch. Rate Amount %3', Amount, CurrencyCode, Rate));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConvertsWithARateStoredPerHundredUnits()
    var
        LCYConverter: Codeunit "LCY Converter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CurrencyCode: Code[10];
        Amount: Decimal;
        Rate: Decimal;
    begin
        // [SCENARIO] A rate stored as 100 units = <rate x 100> LCY converts exactly like 1 unit = <rate> LCY
        // [GIVEN] a currency with one rate row of 100 : <random two-decimal rate x 100> and a random whole-number amount
        ConfigureLcyPrecision(0.01);
        CurrencyCode := CreateCurrency();
        Rate := Any.DecimalInRange(5, 9, 2);
        SeedRate(CurrencyCode, DMY2Date(1, 3, 2024), 100, Rate * 100);
        Amount := Any.IntegerInRange(1, 9999);

        // [WHEN] converting the amount on a date after the row started
        // [THEN] the LCY amount is still the amount times the rate
        Assert.AreEqual(Amount * Rate, LCYConverter.ToLCY(Amount, CurrencyCode, DMY2Date(15, 3, 2024)),
            StrSubstNo('Expected %1 %2 to convert to %1 x %3 LCY with a rate row of Exchange Rate Amount 100 and Relational Exch. Rate Amount %4 — the two amounts of a row form a ratio, not a multiplier', Amount, CurrencyCode, Rate, Rate * 100));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoundsDownWhenBelowTheHalfStep()
    var
        LCYConverter: Codeunit "LCY Converter";
        Assert: Codeunit Assert;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] A converted amount of 9197.472 lands on 9197.47 with an LCY precision of 0.01
        // [GIVEN] LCY amounts rounding to 0.01, a currency rounding to 0.001 and a rate row of 1 : 7.45
        ConfigureLcyPrecision(0.01);
        CurrencyCode := CreateCurrency();
        SeedRate(CurrencyCode, DMY2Date(1, 3, 2024), 1, 7.45);

        // [WHEN] converting 1234.56
        // [THEN] the LCY amount is 9197.47
        Assert.AreEqual(9197.47, LCYConverter.ToLCY(1234.56, CurrencyCode, DMY2Date(15, 3, 2024)),
            'Expected 1234.56 x 7.45 = 9197.472 to be rounded to 9197.47 — the nearest multiple of General Ledger Setup''s Amount Rounding Precision (0.01), not of the currency''s own precision (0.001)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoundsUpWhenAboveTheHalfStep()
    var
        LCYConverter: Codeunit "LCY Converter";
        Assert: Codeunit Assert;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] A converted amount of 9197.6955 lands on 9197.70 with an LCY precision of 0.01
        // [GIVEN] LCY amounts rounding to 0.01, a currency rounding to 0.001 and a rate row of 1 : 7.45
        ConfigureLcyPrecision(0.01);
        CurrencyCode := CreateCurrency();
        SeedRate(CurrencyCode, DMY2Date(1, 3, 2024), 1, 7.45);

        // [WHEN] converting 1234.59
        // [THEN] the LCY amount is 9197.70
        Assert.AreEqual(9197.7, LCYConverter.ToLCY(1234.59, CurrencyCode, DMY2Date(15, 3, 2024)),
            'Expected 1234.59 x 7.45 = 9197.6955 to be rounded to 9197.70 — the nearest multiple of General Ledger Setup''s Amount Rounding Precision (0.01); an unrounded result gives 9197.6955 and the currency''s 0.001 precision gives 9197.696');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoundsToTheLcyPrecisionInForce()
    var
        LCYConverter: Codeunit "LCY Converter";
        Assert: Codeunit Assert;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] The LCY precision is whatever General Ledger Setup holds at call time, not an assumed 0.01
        // [GIVEN] LCY amounts rounding to 0.05, a currency rounding to 0.001 and a rate row of 1 : 7.45
        ConfigureLcyPrecision(0.05);
        CurrencyCode := CreateCurrency();
        SeedRate(CurrencyCode, DMY2Date(1, 3, 2024), 1, 7.45);

        // [WHEN] converting 1234.56
        // [THEN] the LCY amount is 9197.45
        Assert.AreEqual(9197.45, LCYConverter.ToLCY(1234.56, CurrencyCode, DMY2Date(15, 3, 2024)),
            'Expected 1234.56 x 7.45 = 9197.472 to be rounded to 9197.45 while General Ledger Setup''s Amount Rounding Precision is 0.05 — a precision of 0.01 written into the code gives 9197.47; the precision has to be read from the setup on every call');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsTheSignOfANegativeAmount()
    var
        LCYConverter: Codeunit "LCY Converter";
        Assert: Codeunit Assert;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] A negative amount converts and rounds the same way and keeps its sign
        // [GIVEN] LCY amounts rounding to 0.01 and a rate row of 1 : 7.45
        ConfigureLcyPrecision(0.01);
        CurrencyCode := CreateCurrency();
        SeedRate(CurrencyCode, DMY2Date(1, 3, 2024), 1, 7.45);

        // [WHEN] converting -1234.59
        // [THEN] the LCY amount is -9197.70
        Assert.AreEqual(-9197.7, LCYConverter.ToLCY(-1234.59, CurrencyCode, DMY2Date(15, 3, 2024)),
            'Expected -1234.59 x 7.45 = -9197.6955 to be rounded to -9197.70 — a negative amount converts like a positive one and keeps its sign');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UsesTheLatestRateStartedOnOrBeforeTheDate()
    var
        LCYConverter: Codeunit "LCY Converter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CurrencyCode: Code[10];
        Amount: Decimal;
        Rate: Decimal;
    begin
        // [SCENARIO] Between two starting dates the newest row already in force applies — not the first row, not the newest row overall
        // [GIVEN] a currency with rate rows of 1 : <rate - 1> from January 1, 1 : <rate> from March 1 and 1 : <rate + 1> from June 1
        ConfigureLcyPrecision(0.01);
        CurrencyCode := CreateCurrency();
        Rate := Any.DecimalInRange(5, 9, 2);
        SeedRate(CurrencyCode, DMY2Date(1, 1, 2024), 1, Rate - 1);
        SeedRate(CurrencyCode, DMY2Date(1, 3, 2024), 1, Rate);
        SeedRate(CurrencyCode, DMY2Date(1, 6, 2024), 1, Rate + 1);
        Amount := Any.IntegerInRange(1, 999);

        // [WHEN] converting on April 15
        // [THEN] the March 1 rate is used
        Assert.AreEqual(Amount * Rate, LCYConverter.ToLCY(Amount, CurrencyCode, DMY2Date(15, 4, 2024)),
            StrSubstNo('Expected %1 %2 on April 15 to convert with the March 1 rate (x %3) — the row with the latest Starting Date on or before the date wins, not the January 1 row (x %4) and not the June 1 row (x %5)', Amount, CurrencyCode, Rate, Rate - 1, Rate + 1));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UsesTheRateStartingOnTheDateItself()
    var
        LCYConverter: Codeunit "LCY Converter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CurrencyCode: Code[10];
        StartingDate: Date;
        Rate: Decimal;
    begin
        // [SCENARIO] On the very day a new rate row starts, the new row already applies
        // [GIVEN] a currency with a rate row of 1 : <rate - 1> from January 1 and 1 : <rate> from a random later date in 2024
        ConfigureLcyPrecision(0.01);
        CurrencyCode := CreateCurrency();
        Rate := Any.DecimalInRange(5, 9, 2);
        StartingDate := Any.DateInRange(DMY2Date(1, 1, 2024), 30, 300);
        SeedRate(CurrencyCode, DMY2Date(1, 1, 2024), 1, Rate - 1);
        SeedRate(CurrencyCode, StartingDate, 1, Rate);

        // [WHEN] converting 100 on the later row's starting date
        // [THEN] the later row's rate is used
        Assert.AreEqual(100 * Rate, LCYConverter.ToLCY(100, CurrencyCode, StartingDate),
            StrSubstNo('Expected 100 %1 converted on %2 to use the rate row starting that same day (x %3 = %4), not the earlier row (x %5 = %6) — a row applies from its Starting Date on', CurrencyCode, StartingDate, Rate, 100 * Rate, Rate - 1, 100 * (Rate - 1)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RaisesTheBaseAppErrorWhenNoRateHasStartedYet()
    var
        LCYConverter: Codeunit "LCY Converter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CurrencyCode: Code[10];
        StartingDate: Date;
    begin
        // [SCENARIO] A date before the first rate row surfaces the exchange rate table's own error instead of a number
        // [GIVEN] a currency whose only rate row starts on a random date in 2024
        ConfigureLcyPrecision(0.01);
        CurrencyCode := CreateCurrency();
        StartingDate := Any.DateInRange(DMY2Date(1, 1, 2024), 30, 300);
        SeedRate(CurrencyCode, StartingDate, 1, 7.45);

        // [WHEN] converting on the day before the row starts
        asserterror LCYConverter.ToLCY(100, CurrencyCode, StartingDate - 1);

        // [THEN] the base app's "nothing within the filter" error is raised
        Assert.ExpectedError('There is no Currency Exchange Rate within the filter');
    end;

    local procedure ConfigureLcyPrecision(Precision: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Amount Rounding Precision" := Precision;
        GeneralLedgerSetup.Modify();
    end;

    // The currency's own precision differs from the LCY one on purpose: an LCY
    // amount rounded with the foreign currency's record comes out as a wrong number.
    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency."Amount Rounding Precision" := 0.001;
        Currency.Modify();
        exit(Currency.Code);
    end;

    // Library - ERM's CreateExchangeRate pins the relational amount at 1, so the
    // per-unit and per-hundred rows are written with both amounts explicit.
    local procedure SeedRate(CurrencyCode: Code[10]; StartingDate: Date; ExchangeRateAmount: Decimal; RelationalExchRateAmount: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchRateAmount);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", RelationalExchRateAmount);
        CurrencyExchangeRate.Modify(true);
    end;
}
