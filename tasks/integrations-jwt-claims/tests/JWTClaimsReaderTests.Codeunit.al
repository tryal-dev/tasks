codeunit 50900 "JWT Claims Reader Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [JWT] [Base64Url]

    var
        // Header and signature are the same in every fixture: the header decodes to
        // {"alg":"HS256","typ":"JWT"} and the signature is never inspected.
        HeaderSegmentTok: Label 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9', Locked = true;
        SignatureSegmentTok: Label 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk', Locked = true;

        // {"iss":"https://auth.contoso.com","sub":"pad-zero-01"} — 54 bytes, no padding stripped.
        PadNoneSegmentTok: Label 'eyJpc3MiOiJodHRwczovL2F1dGguY29udG9zby5jb20iLCJzdWIiOiJwYWQtemVyby0wMSJ9', Locked = true;
        // {"iss":"https://auth.contoso.com","sub":"pad-one-12"} — 53 bytes, one '=' stripped.
        PadOneSegmentTok: Label 'eyJpc3MiOiJodHRwczovL2F1dGguY29udG9zby5jb20iLCJzdWIiOiJwYWQtb25lLTEyIn0', Locked = true;
        // {"iss":"https://auth.contoso.com","sub":"pad-two-1234"} — 55 bytes, two '=' stripped.
        PadTwoSegmentTok: Label 'eyJpc3MiOiJodHRwczovL2F1dGguY29udG9zby5jb20iLCJzdWIiOiJwYWQtdHdvLTEyMzQifQ', Locked = true;
        // {"iss":"https://auth.contoso.com","scope":"read?yy>","sub":"svcx"} — the Base64 of this
        // payload contains both '+' and '/', so base64url carries '-' and '_' in their place.
        UrlSafeSegmentTok: Label 'eyJpc3MiOiJodHRwczovL2F1dGguY29udG9zby5jb20iLCJzY29wZSI6InJlYWQ_eXk-Iiwic3ViIjoic3ZjeCJ9', Locked = true;

        // iss https://auth.contoso.com, aud bc-integration, nbf 1748779140, exp 1748782800.
        InWindowSegmentTok: Label 'eyJpc3MiOiJodHRwczovL2F1dGguY29udG9zby5jb20iLCJhdWQiOiJiYy1pbnRlZ3JhdGlvbiIsInN1YiI6InVzZXItNDIiLCJuYmYiOjE3NDg3NzkxNDAsImV4cCI6MTc0ODc4MjgwMH0', Locked = true;
        // ... exp 1748779200 — exactly the AsOf instant.
        ExpiresAtAsOfSegmentTok: Label 'eyJpc3MiOiJodHRwczovL2F1dGguY29udG9zby5jb20iLCJhdWQiOiJiYy1pbnRlZ3JhdGlvbiIsInN1YiI6InVzZXItNDIiLCJuYmYiOjE3NDg3NzkxNDAsImV4cCI6MTc0ODc3OTIwMH0', Locked = true;
        // ... exp 1748779201 — one second after the AsOf instant.
        ExpiresNextSecondSegmentTok: Label 'eyJpc3MiOiJodHRwczovL2F1dGguY29udG9zby5jb20iLCJhdWQiOiJiYy1pbnRlZ3JhdGlvbiIsInN1YiI6InVzZXItNDIiLCJuYmYiOjE3NDg3NzkxNDAsImV4cCI6MTc0ODc3OTIwMX0', Locked = true;
        // ... nbf 1748779200 — exactly the AsOf instant.
        ValidFromAsOfSegmentTok: Label 'eyJpc3MiOiJodHRwczovL2F1dGguY29udG9zby5jb20iLCJhdWQiOiJiYy1pbnRlZ3JhdGlvbiIsInN1YiI6InVzZXItNDIiLCJuYmYiOjE3NDg3NzkyMDAsImV4cCI6MTc0ODc4MjgwMH0', Locked = true;
        // ... nbf 1748779201 — one second after the AsOf instant.
        ValidFromNextSecondSegmentTok: Label 'eyJpc3MiOiJodHRwczovL2F1dGguY29udG9zby5jb20iLCJhdWQiOiJiYy1pbnRlZ3JhdGlvbiIsInN1YiI6InVzZXItNDIiLCJuYmYiOjE3NDg3NzkyMDEsImV4cCI6MTc0ODc4MjgwMH0', Locked = true;
        // iss https://auth.fabrikam.com — inside its validity window, but a foreign issuer.
        ForeignIssuerSegmentTok: Label 'eyJpc3MiOiJodHRwczovL2F1dGguZmFicmlrYW0uY29tIiwiYXVkIjoiYmMtaW50ZWdyYXRpb24iLCJzdWIiOiJ1c2VyLTQyIiwibmJmIjoxNzQ4Nzc5MTQwLCJleHAiOjE3NDg3ODI4MDB9', Locked = true;
        // aud reporting-app — from an allowed issuer, but minted for another application.
        ForeignAudienceSegmentTok: Label 'eyJpc3MiOiJodHRwczovL2F1dGguY29udG9zby5jb20iLCJhdWQiOiJyZXBvcnRpbmctYXBwIiwic3ViIjoidXNlci00MiIsIm5iZiI6MTc0ODc3OTE0MCwiZXhwIjoxNzQ4NzgyODAwfQ', Locked = true;
        // {"iss":"https://auth.contoso.com","aud":"bc-integration","sub":"user-77"} — no exp, no nbf.
        NoTimesSegmentTok: Label 'eyJpc3MiOiJodHRwczovL2F1dGguY29udG9zby5jb20iLCJhdWQiOiJiYy1pbnRlZ3JhdGlvbiIsInN1YiI6InVzZXItNzcifQ', Locked = true;
        // iss https://auth.fabrikam.com AND exp 1748775600 — two rules broken at once.
        ForeignIssuerExpiredSegmentTok: Label 'eyJpc3MiOiJodHRwczovL2F1dGguZmFicmlrYW0uY29tIiwiYXVkIjoiYmMtaW50ZWdyYXRpb24iLCJzdWIiOiJ1c2VyLTQyIiwibmJmIjoxNzQ4NzcyMDAwLCJleHAiOjE3NDg3NzU2MDB9', Locked = true;
        // decodes to the plain text 'this is not json'.
        NotJsonSegmentTok: Label 'dGhpcyBpcyBub3QganNvbg', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecodesAPayloadThatNeedsNoPadding()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A segment whose length is already a multiple of 4 decodes unchanged
        Assert.AreEqual('{"iss":"https://auth.contoso.com","sub":"pad-zero-01"}',
            JWTClaimsReader.DecodePayload(MakeToken(PadNoneSegmentTok)),
            'Expected the payload segment to decode back to the original JSON, character for character');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecodesAPayloadThatNeedsOnePaddingCharacter()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A segment whose length leaves 3 over lost one '=' on its way into the token
        Assert.AreEqual('{"iss":"https://auth.contoso.com","sub":"pad-one-12"}',
            JWTClaimsReader.DecodePayload(MakeToken(PadOneSegmentTok)),
            'Expected the payload to decode even though base64url stripped one padding character off the segment');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecodesAPayloadThatNeedsTwoPaddingCharacters()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A segment whose length leaves 2 over lost two '=' on its way into the token
        Assert.AreEqual('{"iss":"https://auth.contoso.com","sub":"pad-two-1234"}',
            JWTClaimsReader.DecodePayload(MakeToken(PadTwoSegmentTok)),
            'Expected the payload to decode even though base64url stripped two padding characters off the segment');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecodesAPayloadThatUsesTheUrlSafeAlphabet()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A payload whose Base64 needs '+' and '/' travels as '-' and '_' in the token
        Assert.AreEqual('{"iss":"https://auth.contoso.com","scope":"read?yy>","sub":"svcx"}',
            JWTClaimsReader.DecodePayload(MakeToken(UrlSafeSegmentTok)),
            'Expected the - and _ in the segment to decode as the Base64 + and / they stand for');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecodesAFreshlyEncodedPayload()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        PayloadJson: Text;
    begin
        // [SCENARIO] A payload of unpredictable length survives encode and decode
        // [GIVEN] a payload built from generated text, so its padding shape is not known in advance
        PayloadJson := '{"iss":"https://auth.contoso.com","sub":"' + Any.AlphabeticText(Any.IntegerInRange(8, 24)) + '"}';

        // [WHEN] decoding the token that carries it
        // [THEN] the original payload comes back untouched
        Assert.AreEqual(PayloadJson, JWTClaimsReader.DecodePayload(BuildToken(PayloadJson)),
            'Expected any payload to survive the round trip, not only the sample tokens used in these tests');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsATokenWithTwoSegments()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
        Decoded: Text;
    begin
        // [SCENARIO] A token missing its signature segment is refused
        asserterror Decoded := JWTClaimsReader.DecodePayload(HeaderSegmentTok + '.' + InWindowSegmentTok);

        Assert.ExpectedError('must have three segments');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsATokenWithFourSegments()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
        Decoded: Text;
    begin
        // [SCENARIO] A token with one dot too many is refused
        asserterror Decoded := JWTClaimsReader.DecodePayload(MakeToken(InWindowSegmentTok) + '.' + SignatureSegmentTok);

        Assert.ExpectedError('must have three segments');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsATokenWithAnEmptySegment()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
        Decoded: Text;
    begin
        // [SCENARIO] Three dot-separated parts are not enough — none of them may be empty
        asserterror Decoded := JWTClaimsReader.DecodePayload(HeaderSegmentTok + '..' + SignatureSegmentTok);

        Assert.ExpectedError('must have three segments');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReadsATextClaimOutOfThePayload()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SubjectValue: Text;
    begin
        // [SCENARIO] A string claim comes back as its plain value, without the JSON quotes
        SubjectValue := Any.AlphabeticText(11);

        Assert.AreEqual(SubjectValue,
            JWTClaimsReader.GetClaim(BuildToken('{"iss":"https://auth.contoso.com","sub":"' + SubjectValue + '"}'), 'sub'),
            'Expected the sub claim to come back as the bare string value carried in the payload');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsEmptyForAClaimThePayloadDoesNotCarry()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Asking for an absent claim is answered with an empty text, not an error
        Assert.AreEqual('', JWTClaimsReader.GetClaim(MakeToken(PadNoneSegmentTok), 'aud'),
            'Expected an empty text for a claim this payload does not carry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsATokenInsideItsValidityWindow()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Allowed issuer, allowed audience, AsOf between nbf and exp
        Assert.AreEqual('OK',
            JWTClaimsReader.ValidateToken(MakeToken(InWindowSegmentTok), AsOfInstant(), AllowedIssuers(), AllowedAudiences()),
            'Expected OK for a token from an allowed issuer, for an allowed audience, inside its validity window');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsATokenExactlyAtItsExpiryTime()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] exp equals AsOf — the token is already too late
        Assert.AreEqual('EXPIRED',
            JWTClaimsReader.ValidateToken(MakeToken(ExpiresAtAsOfSegmentTok), AsOfInstant(), AllowedIssuers(), AllowedAudiences()),
            'Expected EXPIRED when AsOf lands exactly on exp — a token stops being usable at its expiry second, not after it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsATokenOneSecondBeforeItExpires()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] exp is one second after AsOf — the token is still good
        Assert.AreEqual('OK',
            JWTClaimsReader.ValidateToken(MakeToken(ExpiresNextSecondSegmentTok), AsOfInstant(), AllowedIssuers(), AllowedAudiences()),
            'Expected OK one second before exp — the expiry check must not swallow the last whole second');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsATokenExactlyAtItsNotBeforeTime()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] nbf equals AsOf — the token has just become usable
        Assert.AreEqual('OK',
            JWTClaimsReader.ValidateToken(MakeToken(ValidFromAsOfSegmentTok), AsOfInstant(), AllowedIssuers(), AllowedAudiences()),
            'Expected OK when AsOf lands exactly on nbf — a token becomes usable at its not-before second');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsATokenOneSecondBeforeItBecomesValid()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] nbf is one second after AsOf — the token cannot be used yet
        Assert.AreEqual('NOT YET VALID',
            JWTClaimsReader.ValidateToken(MakeToken(ValidFromNextSecondSegmentTok), AsOfInstant(), AllowedIssuers(), AllowedAudiences()),
            'Expected NOT YET VALID one second before nbf');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsAnIssuerOutsideTheAllowList()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A perfectly fresh token from an issuer nobody allowed
        Assert.AreEqual('ISSUER NOT ALLOWED',
            JWTClaimsReader.ValidateToken(MakeToken(ForeignIssuerSegmentTok), AsOfInstant(), AllowedIssuers(), AllowedAudiences()),
            'Expected ISSUER NOT ALLOWED for a token whose iss claim is not on the allow-list');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsAnAudienceOutsideTheAllowList()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A token from an allowed issuer, but minted for a different application
        Assert.AreEqual('AUDIENCE NOT ALLOWED',
            JWTClaimsReader.ValidateToken(MakeToken(ForeignAudienceSegmentTok), AsOfInstant(), AllowedIssuers(), AllowedAudiences()),
            'Expected AUDIENCE NOT ALLOWED for a token whose aud claim is not on the allow-list');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsATokenWithoutExpiryOrNotBefore()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] exp and nbf are optional — a payload without them carries no time limits
        Assert.AreEqual('OK',
            JWTClaimsReader.ValidateToken(MakeToken(NoTimesSegmentTok), AsOfInstant(), AllowedIssuers(), AllowedAudiences()),
            'Expected OK for a payload that carries neither exp nor nbf — a missing claim is not a failed check');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportsMalformedForABrokenTokenInsteadOfFailing()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Validation answers with a result code even for a structurally broken token
        Assert.AreEqual('MALFORMED',
            JWTClaimsReader.ValidateToken(HeaderSegmentTok + '.' + InWindowSegmentTok, AsOfInstant(), AllowedIssuers(), AllowedAudiences()),
            'Expected MALFORMED for a two-segment token — ValidateToken answers, it never raises an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportsMalformedWhenThePayloadIsNotAJsonObject()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Three good segments, but the payload decodes to something that is not JSON
        Assert.AreEqual('MALFORMED',
            JWTClaimsReader.ValidateToken(MakeToken(NotJsonSegmentTok), AsOfInstant(), AllowedIssuers(), AllowedAudiences()),
            'Expected MALFORMED for a payload that decodes to plain text instead of a JSON object');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportsTheIssuerProblemBeforeTheExpiryProblem()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A token that is both from a foreign issuer and long expired
        Assert.AreEqual('ISSUER NOT ALLOWED',
            JWTClaimsReader.ValidateToken(MakeToken(ForeignIssuerExpiredSegmentTok), AsOfInstant(), AllowedIssuers(), AllowedAudiences()),
            'Expected the issuer rule to decide — it is checked before the expiry rule');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsAnIssuerAbsentFromTheCallersAllowList()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The same in-window token is refused once the caller's allow-list drops its issuer
        Assert.AreEqual('ISSUER NOT ALLOWED',
            JWTClaimsReader.ValidateToken(MakeToken(InWindowSegmentTok), AsOfInstant(), NorthwindIssuers(), AllowedAudiences()),
            'Expected the iss claim to be judged against the AllowedIssuers handed to ValidateToken, not against a fixed issuer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsAnIssuerTheCallersAllowListNames()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The fabrikam token is welcome to a caller whose allow-list names fabrikam
        Assert.AreEqual('OK',
            JWTClaimsReader.ValidateToken(MakeToken(ForeignIssuerSegmentTok), AsOfInstant(), NorthwindAndFabrikamIssuers(), AllowedAudiences()),
            'Expected OK for an issuer named anywhere in AllowedIssuers — every entry of the list counts, not only the first');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsAnAudienceTheCallersAllowListNames()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The reporting-app token is welcome to a caller who allows reporting-app
        Assert.AreEqual('OK',
            JWTClaimsReader.ValidateToken(MakeToken(ForeignAudienceSegmentTok), AsOfInstant(), AllowedIssuers(), ReportingAppAudiences()),
            'Expected the aud claim to be judged against the AllowedAudiences handed to ValidateToken, not against a fixed audience');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsATokenThatHasRunOutByALaterAsOf()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The in-window token judged three hours later, well past its exp
        Assert.AreEqual('EXPIRED',
            JWTClaimsReader.ValidateToken(MakeToken(InWindowSegmentTok), LateAsOfInstant(), AllowedIssuers(), AllowedAudiences()),
            'Expected EXPIRED — exp must be compared with the AsOf handed to ValidateToken, not with a fixed instant');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsATokenNotYetUsableAtAnEarlierAsOf()
    var
        JWTClaimsReader: Codeunit "JWT Claims Reader";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The same in-window token judged an hour earlier, before its nbf
        Assert.AreEqual('NOT YET VALID',
            JWTClaimsReader.ValidateToken(MakeToken(InWindowSegmentTok), EarlyAsOfInstant(), AllowedIssuers(), AllowedAudiences()),
            'Expected NOT YET VALID — nbf must be compared with the AsOf handed to ValidateToken, not with a fixed instant');
    end;

    local procedure MakeToken(PayloadSegment: Text): Text
    begin
        exit(HeaderSegmentTok + '.' + PayloadSegment + '.' + SignatureSegmentTok);
    end;

    local procedure BuildToken(PayloadJson: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
    begin
        exit(MakeToken(Base64Convert.ToBase64Url(PayloadJson)));
    end;

    local procedure InstantAt(UnixSeconds: BigInteger): DateTime
    var
        UnixTimestamp: Codeunit "Unix Timestamp";
    begin
        exit(UnixTimestamp.EvaluateTimestamp(UnixSeconds));
    end;

    // 2025-06-01T12:00:00Z — the instant most ValidateToken fixtures are dated against.
    local procedure AsOfInstant(): DateTime
    begin
        exit(InstantAt(1748779200));
    end;

    // 2025-06-01T15:00:00Z — three hours past the in-window token's exp.
    local procedure LateAsOfInstant(): DateTime
    begin
        exit(InstantAt(1748790000));
    end;

    // 2025-06-01T11:00:00Z — an hour before the in-window token's nbf.
    local procedure EarlyAsOfInstant(): DateTime
    begin
        exit(InstantAt(1748775600));
    end;

    local procedure AllowedIssuers(): List of [Text]
    var
        Issuers: List of [Text];
    begin
        Issuers.Add('https://auth.contoso.com');
        Issuers.Add('https://auth.northwind.com');
        exit(Issuers);
    end;

    local procedure AllowedAudiences(): List of [Text]
    var
        Audiences: List of [Text];
    begin
        Audiences.Add('bc-integration');
        exit(Audiences);
    end;

    local procedure NorthwindIssuers(): List of [Text]
    var
        Issuers: List of [Text];
    begin
        Issuers.Add('https://auth.northwind.com');
        exit(Issuers);
    end;

    local procedure NorthwindAndFabrikamIssuers(): List of [Text]
    var
        Issuers: List of [Text];
    begin
        Issuers.Add('https://auth.northwind.com');
        Issuers.Add('https://auth.fabrikam.com');
        exit(Issuers);
    end;

    local procedure ReportingAppAudiences(): List of [Text]
    var
        Audiences: List of [Text];
    begin
        Audiences.Add('reporting-app');
        exit(Audiences);
    end;
}
