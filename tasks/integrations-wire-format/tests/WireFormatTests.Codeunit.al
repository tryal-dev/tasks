codeunit 50900 "Wire Format Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecimalUsesDotAsDecimalSeparator()
    var
        WireFormat: Codeunit "Wire Format";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('12.34', WireFormat.ToWireDecimal(12.34),
            'Expected the fractional part behind a dot — wire text must not depend on the server''s decimal separator');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecimalCarriesNoGroupSeparators()
    var
        WireFormat: Codeunit "Wire Format";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('1234567.89', WireFormat.ToWireDecimal(1234567.89),
            'Expected plain digits with no thousand separators — group separators are locale decoration, not wire format');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeDecimalKeepsLeadingMinus()
    var
        WireFormat: Codeunit "Wire Format";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('-1234.5', WireFormat.ToWireDecimal(-1234.5),
            'Expected a leading minus, no group separator and a dot for a negative value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DateIsRenderedAsYearMonthDay()
    var
        WireFormat: Codeunit "Wire Format";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('2026-01-23', WireFormat.ToWireDate(DMY2Date(23, 1, 2026)),
            'Expected 23 January 2026 to render as 2026-01-23 — wire dates are YYYY-MM-DD whatever the server''s date format');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DatePadsSingleDigitMonthAndDay()
    var
        WireFormat: Codeunit "Wire Format";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('2026-02-03', WireFormat.ToWireDate(DMY2Date(3, 2, 2026)),
            'Expected zero-padded month and day: 3 February 2026 is 2026-02-03 on the wire');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParsesWireDecimalText()
    var
        WireFormat: Codeunit "Wire Format";
        Assert: Codeunit Assert;
        Value: Decimal;
    begin
        Assert.IsTrue(WireFormat.FromWireDecimal('1234.56', Value),
            'Expected the wire text 1234.56 to be accepted (true)');
        Assert.AreEqual(1234.56, Value, 'Expected the wire text 1234.56 to parse to exactly that value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParsesNegativeWireDecimalText()
    var
        WireFormat: Codeunit "Wire Format";
        Assert: Codeunit Assert;
        Value: Decimal;
    begin
        Assert.IsTrue(WireFormat.FromWireDecimal('-42.75', Value),
            'Expected the wire text -42.75 to be accepted (true)');
        Assert.AreEqual(-42.75, Value, 'Expected the wire text -42.75 to parse to exactly that value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsCommaFormattedDecimalText()
    var
        WireFormat: Codeunit "Wire Format";
        Assert: Codeunit Assert;
        Value: Decimal;
        Accepted: Boolean;
    begin
        Accepted := WireFormat.FromWireDecimal('1,5', Value);

        Assert.IsFalse(Accepted,
            StrSubstNo('Expected 1,5 to be rejected (false) — a comma is locale formatting, never wire format — but it was accepted and parsed as %1', Value));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GarbageDecimalTextReturnsFalseInsteadOfError()
    var
        WireFormat: Codeunit "Wire Format";
        Assert: Codeunit Assert;
        Value: Decimal;
    begin
        Assert.IsFalse(WireFormat.FromWireDecimal('twelve point five', Value),
            'Expected text that is no number at all to return false — a parse failure must be reported, not raised as an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParsesWireDateText()
    var
        WireFormat: Codeunit "Wire Format";
        Assert: Codeunit Assert;
        Value: Date;
    begin
        Assert.IsTrue(WireFormat.FromWireDate('2026-01-23', Value),
            'Expected the wire text 2026-01-23 to be accepted (true)');
        Assert.AreEqual(DMY2Date(23, 1, 2026), Value, 'Expected the wire text 2026-01-23 to parse to 23 January 2026');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsLocaleFormattedDateText()
    var
        WireFormat: Codeunit "Wire Format";
        Assert: Codeunit Assert;
        Value: Date;
        Accepted: Boolean;
    begin
        Accepted := WireFormat.FromWireDate('05-02-2026', Value);

        Assert.IsFalse(Accepted,
            StrSubstNo('Expected 05-02-2026 to be rejected (false) — day-first text is locale formatting, not YYYY-MM-DD wire format — but it was accepted and parsed as %1', Value));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GarbageDateTextReturnsFalseInsteadOfError()
    var
        WireFormat: Codeunit "Wire Format";
        Assert: Codeunit Assert;
        Value: Date;
    begin
        Assert.IsFalse(WireFormat.FromWireDate('23rd of January 2026', Value),
            'Expected text that is no YYYY-MM-DD date to return false — a parse failure must be reported, not raised as an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedDecimalSurvivesTheRoundTrip()
    var
        WireFormat: Codeunit "Wire Format";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Original: Decimal;
        Parsed: Decimal;
        WireText: Text;
    begin
        Original := Any.DecimalInRange(1000, 9999999, 2);
        if Any.Boolean() then
            Original := -Original;

        WireText := WireFormat.ToWireDecimal(Original);

        Assert.IsTrue(WireFormat.FromWireDecimal(WireText, Parsed),
            StrSubstNo('Expected FromWireDecimal to accept the text ToWireDecimal produced, but %1 was rejected', WireText));
        Assert.AreEqual(Original, Parsed,
            StrSubstNo('Expected the round trip through the wire text %1 to reproduce the original value', WireText));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedDateSurvivesTheRoundTrip()
    var
        WireFormat: Codeunit "Wire Format";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Original: Date;
        Parsed: Date;
        WireText: Text;
    begin
        Original := Any.DateInRange(DMY2Date(1, 1, 2019), 1, 4000);

        WireText := WireFormat.ToWireDate(Original);

        Assert.IsTrue(WireFormat.FromWireDate(WireText, Parsed),
            StrSubstNo('Expected FromWireDate to accept the text ToWireDate produced, but %1 was rejected', WireText));
        Assert.AreEqual(Original, Parsed,
            StrSubstNo('Expected the round trip through the wire text %1 to reproduce the original date', WireText));
    end;
}
