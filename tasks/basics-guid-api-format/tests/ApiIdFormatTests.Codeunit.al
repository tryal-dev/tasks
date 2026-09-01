codeunit 50900 "Api Id Format Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApiIdIsLowercaseHyphenatedWithoutBraces()
    var
        ApiIdFormat: Codeunit "Api Id Format";
        Assert: Codeunit Assert;
        Id: Guid;
    begin
        Evaluate(Id, '{EA48A3E0-48E0-4AB7-B1A1-E3EA85BF1B75}');

        Assert.AreEqual('ea48a3e0-48e0-4ab7-b1a1-e3ea85bf1b75', ApiIdFormat.ToApiId(Id),
            'Expected the API form: 32 lowercase hex digits in 8-4-4-4-12 groups, hyphens kept, no braces');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApiIdOfGeneratedGuidIsItsLowercaseBareForm()
    var
        ApiIdFormat: Codeunit "Api Id Format";
        Assert: Codeunit Assert;
        Id: Guid;
        Expected: Text;
    begin
        Id := CreateGuid();
        Expected := LowerCase(DelChr(Format(Id), '=', '{}'));

        Assert.AreEqual(Expected, ApiIdFormat.ToApiId(Id),
            'Expected the generated GUID in API form — the display text with its braces removed and every hex digit lowercased');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApiIdIsNeverTheBracedUppercaseDisplayForm()
    var
        ApiIdFormat: Codeunit "Api Id Format";
        Assert: Codeunit Assert;
        Id: Guid;
    begin
        Id := CreateGuid();

        Assert.AreNotEqual(Format(Id), ApiIdFormat.ToApiId(Id),
            'Expected ToApiId to differ from Format(Id) — the braced uppercase display form is exactly what the partner API rejects');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NullGuidHasNoApiId()
    var
        ApiIdFormat: Codeunit "Api Id Format";
        Assert: Codeunit Assert;
        NullId: Guid;
    begin
        Assert.AreEqual('', ApiIdFormat.ToApiId(NullId),
            'Expected an empty text for the all-zero GUID — it means "no id" and must not be sent as 00000000-0000-0000-0000-000000000000');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParsesTheApiForm()
    var
        ApiIdFormat: Codeunit "Api Id Format";
        Assert: Codeunit Assert;
        Id: Guid;
    begin
        Assert.IsTrue(ApiIdFormat.TryParseId('ea48a3e0-48e0-4ab7-b1a1-e3ea85bf1b75', Id),
            'Expected the bare lowercase API form to be accepted (true)');
        Assert.AreEqual('{EA48A3E0-48E0-4AB7-B1A1-E3EA85BF1B75}', Format(Id),
            'Expected the bare lowercase API form to parse to the GUID it spells');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParsesTheBareUppercaseForm()
    var
        ApiIdFormat: Codeunit "Api Id Format";
        Assert: Codeunit Assert;
        Id: Guid;
    begin
        Assert.IsTrue(ApiIdFormat.TryParseId('EA48A3E0-48E0-4AB7-B1A1-E3EA85BF1B75', Id),
            'Expected the bare uppercase form to be accepted (true) — hex digits are valid in either case');
        Assert.AreEqual('{EA48A3E0-48E0-4AB7-B1A1-E3EA85BF1B75}', Format(Id),
            'Expected the bare uppercase form to parse to the GUID it spells');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParsesTheBracedUppercaseForm()
    var
        ApiIdFormat: Codeunit "Api Id Format";
        Assert: Codeunit Assert;
        Id: Guid;
    begin
        Assert.IsTrue(ApiIdFormat.TryParseId('{EA48A3E0-48E0-4AB7-B1A1-E3EA85BF1B75}', Id),
            'Expected the braced uppercase display form to be accepted (true)');
        Assert.AreEqual('{EA48A3E0-48E0-4AB7-B1A1-E3EA85BF1B75}', Format(Id),
            'Expected the braced uppercase display form to parse to the GUID it spells');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParsesTheBracedLowercaseForm()
    var
        ApiIdFormat: Codeunit "Api Id Format";
        Assert: Codeunit Assert;
        Id: Guid;
    begin
        Assert.IsTrue(ApiIdFormat.TryParseId('{ea48a3e0-48e0-4ab7-b1a1-e3ea85bf1b75}', Id),
            'Expected the braced lowercase form to be accepted (true) — hex digits are valid in either case, braces or not');
        Assert.AreEqual('{EA48A3E0-48E0-4AB7-B1A1-E3EA85BF1B75}', Format(Id),
            'Expected the braced lowercase form to parse to the GUID it spells');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedGuidSurvivesTheRoundTrip()
    var
        ApiIdFormat: Codeunit "Api Id Format";
        Assert: Codeunit Assert;
        Original: Guid;
        Parsed: Guid;
        ApiId: Text;
    begin
        Original := CreateGuid();

        ApiId := ApiIdFormat.ToApiId(Original);

        Assert.IsTrue(ApiIdFormat.TryParseId(ApiId, Parsed),
            StrSubstNo('Expected TryParseId to accept the text ToApiId produced, but %1 was rejected', ApiId));
        Assert.AreEqual(Format(Original), Format(Parsed),
            StrSubstNo('Expected the round trip through %1 to reproduce the original GUID', ApiId));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GarbageReturnsFalseInsteadOfError()
    var
        ApiIdFormat: Codeunit "Api Id Format";
        Assert: Codeunit Assert;
        Id: Guid;
    begin
        Assert.IsFalse(ApiIdFormat.TryParseId('not-an-id-at-all', Id),
            'Expected text that is no GUID to return false — a parse failure is reported, never raised as an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TruncatedIdReturnsFalse()
    var
        ApiIdFormat: Codeunit "Api Id Format";
        Assert: Codeunit Assert;
        Id: Guid;
        Accepted: Boolean;
    begin
        Accepted := ApiIdFormat.TryParseId('ea48a3e0-48e0-4ab7-b1a1', Id);

        Assert.IsFalse(Accepted,
            StrSubstNo('Expected the truncated id ea48a3e0-48e0-4ab7-b1a1 to be rejected (false), but it was accepted as %1', Id));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NonHexDigitsInGuidShapeReturnFalse()
    var
        ApiIdFormat: Codeunit "Api Id Format";
        Assert: Codeunit Assert;
        Id: Guid;
        Accepted: Boolean;
    begin
        Accepted := ApiIdFormat.TryParseId('zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz', Id);

        Assert.IsFalse(Accepted,
            StrSubstNo('Expected GUID-shaped text made of non-hex characters to be rejected (false), but it was accepted as %1', Id));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyInputReturnsFalse()
    var
        ApiIdFormat: Codeunit "Api Id Format";
        Assert: Codeunit Assert;
        Id: Guid;
        Accepted: Boolean;
    begin
        Accepted := ApiIdFormat.TryParseId('', Id);

        Assert.IsFalse(Accepted,
            StrSubstNo('Expected empty text to be rejected (false) — there is no id in it — but it was accepted as %1', Id));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AllZeroIdTextReturnsFalse()
    var
        ApiIdFormat: Codeunit "Api Id Format";
        Assert: Codeunit Assert;
        Id: Guid;
        Accepted: Boolean;
    begin
        Accepted := ApiIdFormat.TryParseId('00000000-0000-0000-0000-000000000000', Id);

        Assert.IsFalse(Accepted,
            'Expected the all-zero GUID to be rejected (false) — it is the null GUID, which means "no id"; IsNullGuid tells it apart from a real id');
    end;
}
