codeunit 50900 "Safe Parser Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidReferenceIsSplitIntoItsParts()
    var
        SafeParser: Codeunit "Safe Parser";
        Assert: Codeunit Assert;
        Prefix: Text;
        Year: Integer;
        Seq: Integer;
    begin
        Assert.IsTrue(SafeParser.TryParseReference('INV-2026-000123', Prefix, Year, Seq),
            'Expected TryParseReference to return true for the well-formed reference INV-2026-000123');
        Assert.AreEqual('INV', Prefix, 'Expected the prefix of INV-2026-000123 to be INV');
        Assert.AreEqual(2026, Year, 'Expected the year of INV-2026-000123 to be 2026');
        Assert.AreEqual(123, Seq, 'Expected the sequence of INV-2026-000123 to be 123 — the leading zeros are padding, not part of the number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedReferenceIsSplitIntoItsParts()
    var
        SafeParser: Codeunit "Safe Parser";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Ref: Text;
        ExpectedPrefix: Text;
        ExpectedYear: Integer;
        ExpectedSeq: Integer;
        Prefix: Text;
        Year: Integer;
        Seq: Integer;
    begin
        ExpectedPrefix := UpperCase(Any.AlphabeticText(Any.IntegerInRange(2, 5)));
        ExpectedYear := Any.IntegerInRange(2000, 2099);
        ExpectedSeq := Any.IntegerInRange(1, 999999);
        Ref := StrSubstNo('%1-%2-%3', ExpectedPrefix, Format(ExpectedYear, 0, 9), Format(ExpectedSeq, 6, '<Integer,6><Filler Character,0>'));

        Assert.IsTrue(SafeParser.TryParseReference(Ref, Prefix, Year, Seq),
            StrSubstNo('Expected TryParseReference to return true for the well-formed reference %1', Ref));
        Assert.AreEqual(ExpectedPrefix, Prefix, StrSubstNo('Expected the prefix of %1 to be the text before the first hyphen', Ref));
        Assert.AreEqual(ExpectedYear, Year, StrSubstNo('Expected the year of %1 to be the middle segment as a number', Ref));
        Assert.AreEqual(ExpectedSeq, Seq, StrSubstNo('Expected the sequence of %1 to be the last segment as a number, leading zeros dropped', Ref));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MissingSegmentReturnsFalseWithoutAnError()
    var
        SafeParser: Codeunit "Safe Parser";
        Assert: Codeunit Assert;
        Prefix: Text;
        Year: Integer;
        Seq: Integer;
    begin
        Assert.IsFalse(SafeParser.TryParseReference('INV-2026', Prefix, Year, Seq),
            'Expected false for INV-2026 — the sequence segment is missing, so the reference is not valid');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExtraSegmentReturnsFalse()
    var
        SafeParser: Codeunit "Safe Parser";
        Assert: Codeunit Assert;
        Prefix: Text;
        Year: Integer;
        Seq: Integer;
    begin
        Assert.IsFalse(SafeParser.TryParseReference('INV-2026-000123-COPY', Prefix, Year, Seq),
            'Expected false for INV-2026-000123-COPY — a reference has exactly three hyphen-separated segments');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecimalSequenceReturnsFalse()
    var
        SafeParser: Codeunit "Safe Parser";
        Assert: Codeunit Assert;
        Prefix: Text;
        Year: Integer;
        Seq: Integer;
    begin
        Assert.IsFalse(SafeParser.TryParseReference('INV-2026-12.5', Prefix, Year, Seq),
            'Expected false for INV-2026-12.5 — 12.5 is not a whole number, and Evaluate into an Integer must not raise an error for it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OversizedSequenceReturnsFalseInsteadOfOverflowing()
    var
        SafeParser: Codeunit "Safe Parser";
        Assert: Codeunit Assert;
        Prefix: Text;
        Year: Integer;
        Seq: Integer;
    begin
        Assert.IsFalse(SafeParser.TryParseReference('INV-2026-3000000000', Prefix, Year, Seq),
            'Expected false for INV-2026-3000000000 — 3000000000 does not fit in an Integer, and that must be a false result, not a runtime error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NonNumericYearReturnsFalse()
    var
        SafeParser: Codeunit "Safe Parser";
        Assert: Codeunit Assert;
        Prefix: Text;
        Year: Integer;
        Seq: Integer;
    begin
        Assert.IsFalse(SafeParser.TryParseReference('INV-YEAR-000123', Prefix, Year, Seq),
            'Expected false for INV-YEAR-000123 — the year segment is not a number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TextWithoutHyphensReturnsFalse()
    var
        SafeParser: Codeunit "Safe Parser";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Garbage: Text;
        Prefix: Text;
        Year: Integer;
        Seq: Integer;
    begin
        Garbage := Any.AlphabeticText(12);

        Assert.IsFalse(SafeParser.TryParseReference(Garbage, Prefix, Year, Seq),
            StrSubstNo('Expected false for %1 — there are no hyphens, so there is only one segment', Garbage));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyReferenceReturnsFalse()
    var
        SafeParser: Codeunit "Safe Parser";
        Assert: Codeunit Assert;
        Prefix: Text;
        Year: Integer;
        Seq: Integer;
    begin
        Assert.IsFalse(SafeParser.TryParseReference('', Prefix, Year, Seq),
            'Expected false for an empty reference');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyPrefixReturnsFalse()
    var
        SafeParser: Codeunit "Safe Parser";
        Assert: Codeunit Assert;
        Prefix: Text;
        Year: Integer;
        Seq: Integer;
    begin
        Assert.IsFalse(SafeParser.TryParseReference('-2026-000123', Prefix, Year, Seq),
            'Expected false for -2026-000123 — the prefix segment is empty, and a prefix is at least one character');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeadTimeInDaysAndHoursIsParsed()
    var
        SafeParser: Codeunit "Safe Parser";
        Assert: Codeunit Assert;
        Lead: Duration;
        ExpectedLead: Duration;
    begin
        ExpectedLead := 52 * 3600000;

        Assert.IsTrue(SafeParser.TryParseLead('2 days 4 hours', Lead),
            'Expected TryParseLead to return true for 2 days 4 hours');
        Assert.AreEqual(ExpectedLead, Lead,
            'Expected 2 days 4 hours to parse to a duration of 52 hours (187200000 milliseconds)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedLeadTimeInDaysAndHoursIsParsed()
    var
        SafeParser: Codeunit "Safe Parser";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Input: Text;
        Days: Integer;
        Hours: Integer;
        Lead: Duration;
        ExpectedLead: Duration;
    begin
        Days := Any.IntegerInRange(2, 9);
        Hours := Any.IntegerInRange(2, 23);
        Input := StrSubstNo('%1 days %2 hours', Days, Hours);
        ExpectedLead := (Days * 24 + Hours) * 3600000;

        Assert.IsTrue(SafeParser.TryParseLead(Input, Lead),
            StrSubstNo('Expected TryParseLead to return true for %1', Input));
        Assert.AreEqual(ExpectedLead, Lead,
            StrSubstNo('Expected %1 to parse to a duration of %2 hours', Input, Days * 24 + Hours));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeadTimeInMinutesIsParsed()
    var
        SafeParser: Codeunit "Safe Parser";
        Assert: Codeunit Assert;
        Lead: Duration;
        ExpectedLead: Duration;
    begin
        ExpectedLead := 90 * 60000;

        Assert.IsTrue(SafeParser.TryParseLead('90 minutes', Lead),
            'Expected TryParseLead to return true for 90 minutes');
        Assert.AreEqual(ExpectedLead, Lead,
            'Expected 90 minutes to parse to a duration of one and a half hours (5400000 milliseconds)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GarbageLeadTimeReturnsFalseWithoutAnError()
    var
        SafeParser: Codeunit "Safe Parser";
        Assert: Codeunit Assert;
        Lead: Duration;
    begin
        Assert.IsFalse(SafeParser.TryParseLead('soon', Lead),
            'Expected false for the lead time "soon" — text that is not a duration must produce false, not a runtime error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyLeadTimeReturnsFalse()
    var
        SafeParser: Codeunit "Safe Parser";
        Assert: Codeunit Assert;
        Lead: Duration;
    begin
        Assert.IsFalse(SafeParser.TryParseLead('', Lead),
            'Expected false for an empty lead time — a blank cell is not a duration');
    end;
}
