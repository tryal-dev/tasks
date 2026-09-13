codeunit 50900 "Phone E164 Formatter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FormatsNationalNumberWithTrunkZeroAndPunctuation()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('+491512345678', PhoneE164Formatter.ToE164('(0)151 234-5678', '+49'),
            'Expected (0)151 234-5678 to lose its parentheses, space and dash, drop the trunk 0 and get the default prefix +49 in front');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DropsDotsAndSlashesLikeAnyOtherSeparator()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('+493012345678', PhoneE164Formatter.ToE164('030/123.456-78', '+49'),
            'Expected the slash, the dot and the dash in 030/123.456-78 to be dropped like any other non-digit — every character that is not a digit 0-9 goes, not only spaces, parentheses and dashes');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsInternationalNumberAndIgnoresDefaultPrefix()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('+491512345678', PhoneE164Formatter.ToE164('+49 (151) 2345678', '+44'),
            'Expected a number that starts with + to keep its own country code 49 — the default prefix +44 must not be applied');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TurnsDoubleZeroIntoPlus()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('+491512345678', PhoneE164Formatter.ToE164('0049 151 2345678', '+44'),
            'Expected the leading 00 to become a + and the country code 49 that follows it to be kept — the default prefix +44 must not be applied');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CutsLowercaseExtension()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('+491512345678', PhoneE164Formatter.ToE164('0151 234 5678 x123', '+49'),
            'Expected the extension x123 to be cut off before the digits are collected — its digits must not end up in the number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CutsUppercaseExtension()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('+491512345678', PhoneE164Formatter.ToE164('+49 151 2345678 X 45', '+1'),
            'Expected an uppercase X to introduce an extension just like a lowercase x — X 45 must be cut off and must not count as letters');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IgnoresSurroundingWhitespace()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('+491512345678', PhoneE164Formatter.ToE164('  +49 151 2345678  ', '+1'),
            'Expected leading and trailing spaces to be ignored — the + after the spaces still counts as the first character');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsCanonicalNumberUnchanged()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Canonical: Text;
    begin
        Canonical := '+' + RandomNumber(Any, 11);

        Assert.AreEqual(Canonical, PhoneE164Formatter.ToE164(Canonical, '+49'),
            StrSubstNo('Expected the already canonical number %1 to come back unchanged', Canonical));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PrependsDefaultPrefixWhenThereIsNoTrunkZero()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('+12125550123', PhoneE164Formatter.ToE164('212 555 0123', '+1'),
            'Expected a national number without a leading 0 to keep all its digits and get the default prefix +1 in front — only a leading 0 is a trunk prefix');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UsesTheGivenDefaultPrefix()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CountryCode: Text;
        Subscriber: Text;
        CodeLength: Integer;
    begin
        CodeLength := Any.IntegerInRange(1, 3);
        CountryCode := RandomNumber(Any, CodeLength);
        Subscriber := RandomNumber(Any, 9);

        Assert.AreEqual('+' + CountryCode + Subscriber,
            PhoneE164Formatter.ToE164('0' + CopyStr(Subscriber, 1, 3) + ' ' + CopyStr(Subscriber, 4), '+' + CountryCode),
            StrSubstNo('Expected the national number 0%1 to get the default prefix +%2 in front — a hardcoded +49 cannot pass this', Subscriber, CountryCode));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsExactlyEightDigits()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('+49123456', PhoneE164Formatter.ToE164('+49 123456', '+49'),
            'Expected +49 123456 — exactly 8 digits — to be accepted: 8 is the minimum, not below it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsExactlyFifteenDigits()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Subscriber: Text;
    begin
        Subscriber := RandomNumber(Any, 13);

        Assert.AreEqual('+49' + Subscriber, PhoneE164Formatter.ToE164('+49 ' + Subscriber, '+49'),
            StrSubstNo('Expected +49 %1 — exactly 15 digits — to be accepted: 15 is the maximum, not above it', Subscriber));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsPlusInTheMiddle()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        asserterror PhoneE164Formatter.ToE164('49+151 2345678', '+49');

        Assert.ExpectedError('Phone number 49+151 2345678 has a + that is not at the start');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsSecondPlus()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        asserterror PhoneE164Formatter.ToE164('++49 151 2345678', '+49');

        Assert.ExpectedError('has a + that is not at the start');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsUppercaseLetters()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        asserterror PhoneE164Formatter.ToE164('0151 234 ABCD', '+49');

        Assert.ExpectedError('Phone number 0151 234 ABCD contains letters');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsLowercaseLetters()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        asserterror PhoneE164Formatter.ToE164('0151 234 abcd', '+49');

        Assert.ExpectedError('Phone number 0151 234 abcd contains letters');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsSevenDigitsQuotingTheInputAsTyped()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        asserterror PhoneE164Formatter.ToE164('+49 12345 x7', '+49');

        Assert.ExpectedError('Phone number +49 12345 x7 has 7 digits, but an E.164 number has 8 to 15');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsSixteenDigits()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        asserterror PhoneE164Formatter.ToE164('+49 12345678901234', '+49');

        Assert.ExpectedError('has 16 digits, but an E.164 number has 8 to 15');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountsDigitsAfterApplyingThePrefix()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        asserterror PhoneE164Formatter.ToE164('01234', '+49');

        Assert.ExpectedError('has 6 digits, but an E.164 number has 8 to 15');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsEmptyInput()
    var
        PhoneE164Formatter: Codeunit "Phone E164 Formatter";
        Assert: Codeunit Assert;
    begin
        asserterror PhoneE164Formatter.ToE164('', '+49');

        Assert.ExpectedError('but an E.164 number has 8 to 15');
    end;

    local procedure RandomNumber(var Any: Codeunit Any; Length: Integer): Text
    var
        Digits: Text;
        i: Integer;
    begin
        Digits := Format(Any.IntegerInRange(1, 9));
        for i := 2 to Length do
            Digits += Format(Any.IntegerInRange(0, 9));
        exit(Digits);
    end;
}
