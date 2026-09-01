// [FEATURE] [Integrations] [Form Url Encoded]
codeunit 50900 "Form Url Encoded Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    // The mock answers requests sent through the handler interface; grading
    // containers have no outbound network, so a submission that bypasses the
    // seam with a raw HttpClient must fail loudly instead of hanging on a
    // dead socket.
    TestHttpRequestPolicy = BlockOutboundRequests;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BuildsASingleFieldAsKeyEqualsValue()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Fields: Dictionary of [Text, Text];
        FieldName: Text;
        FieldValue: Text;
    begin
        // [SCENARIO] A field whose key and value need no escaping is written verbatim
        FieldName := Any.AlphabeticText(8);
        FieldValue := Any.AlphabeticText(12);
        Fields.Add(FieldName, FieldValue);

        Assert.AreEqual(FieldName + '=' + FieldValue, FormClient.BuildFormBody(Fields),
            'Expected a single field to be written as key=value with nothing added around it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EncodesASpaceAsPercent20NeverAsPlus()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Fields: Dictionary of [Text, Text];
    begin
        // [SCENARIO] A space in a value goes out percent-encoded, not as a plus
        Fields.Add('scope', 'orders read');

        Assert.AreEqual('scope=orders%20read', FormClient.BuildFormBody(Fields),
            'Expected a space to be written as %20 — a + is the other convention, and this gateway is not being asked for it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EncodesALiteralPlusAsPercent2B()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Fields: Dictionary of [Text, Text];
    begin
        // [SCENARIO] A + that is part of the data survives as %2B next to a real space
        Fields.Add('client_secret', 'a+b c');

        Assert.AreEqual('client_secret=a%2Bb%20c', FormClient.BuildFormBody(Fields),
            'Expected the literal + to go out as %2B and the space as %20 — an unescaped + is read as a space by the gateway');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EncodesAmpersandAndEqualsInKeysAndValues()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Fields: Dictionary of [Text, Text];
    begin
        // [SCENARIO] The two characters that carry form syntax are escaped on both halves
        Fields.Add('a&b', 'c=d&e');

        Assert.AreEqual('a%26b=c%3Dd%26e', FormClient.BuildFormBody(Fields),
            'Expected & to become %26 and = to become %3D in the key as well as in the value — unescaped they read as form syntax');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EncodesNonAsciiTextAsUtf8PercentBytes()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Fields: Dictionary of [Text, Text];
    begin
        // [SCENARIO] A non-ASCII letter is escaped byte by byte from its UTF-8 form
        Fields.Add('note', 'café');

        Assert.AreEqual('note=caf%C3%A9', FormClient.BuildFormBody(Fields),
            'Expected é to be encoded from its two UTF-8 bytes as %C3%A9');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesUnreservedCharactersUnescaped()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Fields: Dictionary of [Text, Text];
    begin
        // [SCENARIO] Letters, digits and - . _ travel as themselves
        Fields.Add('order-no_1', 'ABC-123_x.y');

        Assert.AreEqual('order-no_1=ABC-123_x.y', FormClient.BuildFormBody(Fields),
            'Expected letters, digits and - . _ to stay literal — escaping everything that is not alphanumeric is over-encoding');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmitsAnEmptyValueAsATrailingEqualsSign()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Fields: Dictionary of [Text, Text];
    begin
        // [SCENARIO] A field with an empty value is still sent, as key=
        Fields.Add('state', '');

        Assert.AreEqual('state=', FormClient.BuildFormBody(Fields),
            'Expected a field with an empty value to be sent as key= — neither dropped nor written as a bare key');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsEmptyTextWhenThereAreNoFields()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Fields: Dictionary of [Text, Text];
    begin
        // [SCENARIO] An empty field set produces an empty body
        Assert.AreEqual('', FormClient.BuildFormBody(Fields),
            'Expected an empty Fields dictionary to produce empty text, not a stray & or =');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure JoinsFieldsWithASingleAmpersand()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Fields: Dictionary of [Text, Text];
        Segments: List of [Text];
        Body: Text;
    begin
        // [SCENARIO] Several fields are joined by exactly one & with no leading or trailing separator
        Fields.Add('grant_type', 'client_credentials');
        Fields.Add('scope', 'orders read');
        Fields.Add('state', '');

        Body := FormClient.BuildFormBody(Fields);

        Segments := Body.Split('&');
        Assert.AreEqual(3, Segments.Count(),
            StrSubstNo('Expected three pairs joined by a single & each, with no leading, trailing or doubled &, got "%1"', Body));
        Assert.IsTrue(Segments.Contains('grant_type=client_credentials'),
            StrSubstNo('Expected the body to carry grant_type=client_credentials as one of its pairs, got "%1"', Body));
        Assert.IsTrue(Segments.Contains('scope=orders%20read'),
            StrSubstNo('Expected the body to carry the scope pair with its space percent-encoded, got "%1"', Body));
        Assert.IsTrue(Segments.Contains('state='),
            StrSubstNo('Expected the body to carry state= as one of its pairs, got "%1"', Body));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParsesASingleFieldIntoTheDictionary()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Parsed: Dictionary of [Text, Text];
        FieldName: Text;
        FieldValue: Text;
    begin
        // [SCENARIO] A plain key=value pair becomes one dictionary entry
        FieldName := Any.AlphabeticText(8);
        FieldValue := Any.AlphabeticText(12);

        Parsed := FormClient.ParseFormBody(FieldName + '=' + FieldValue);

        Assert.AreEqual(1, Parsed.Count(),
            StrSubstNo('Expected one field to be parsed out of a single pair, got the keys: %1', KeyList(Parsed)));
        Assert.AreEqual(FieldValue, ValueOf(Parsed, FieldName),
            'Expected the value to be stored under its own key, unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TurnsARawPlusIntoASpaceInKeysAndValues()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Parsed: Dictionary of [Text, Text];
    begin
        // [SCENARIO] The gateway's + stands for a space, in the key as well as the value
        Parsed := FormClient.ParseFormBody('user+name=orders+read');

        Assert.AreEqual('orders read', ValueOf(Parsed, 'user name'),
            'Expected a raw + to be read as a space in the key and in the value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsAnEncodedPlusAsALiteralPlus()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Parsed: Dictionary of [Text, Text];
    begin
        // [SCENARIO] %2B and a raw + in the same value decode to different characters
        Parsed := FormClient.ParseFormBody('signature=a%2Bb+c');

        Assert.AreEqual('a+b c', ValueOf(Parsed, 'signature'),
            'Expected %2B to decode to a literal + while the raw + becomes a space — translate + to space BEFORE unescaping, never after');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecodesPercentEscapesIncludingUtf8()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Parsed: Dictionary of [Text, Text];
    begin
        // [SCENARIO] Percent runs decode back into the original characters, multi-byte ones included
        Parsed := FormClient.ParseFormBody('note=caf%C3%A9%20au%20lait');

        Assert.AreEqual('café au lait', ValueOf(Parsed, 'note'),
            'Expected %C3%A9 to decode back to é and %20 to a space');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SplitsEachPairAtTheFirstEqualsSign()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Parsed: Dictionary of [Text, Text];
    begin
        // [SCENARIO] Only the first = separates a pair; base64 padding stays in the value
        Parsed := FormClient.ParseFormBody('code=YWJjZA==&state=1');

        Assert.AreEqual(2, Parsed.Count(),
            StrSubstNo('Expected two fields to be parsed, got the keys: %1', KeyList(Parsed)));
        Assert.AreEqual('YWJjZA==', ValueOf(Parsed, 'code'),
            'Expected only the first = to separate key from value — the padding of a base64 value belongs to the value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReadsAnEmptyValueAsEmptyText()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Parsed: Dictionary of [Text, Text];
    begin
        // [SCENARIO] key= yields the key with an empty value, not a missing key
        Parsed := FormClient.ParseFormBody('state=');

        Assert.AreEqual(1, Parsed.Count(),
            StrSubstNo('Expected the field to be parsed even though its value is empty, got the keys: %1', KeyList(Parsed)));
        Assert.AreEqual('', ValueOf(Parsed, 'state'),
            'Expected state to be present with an empty value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReadsAPairWithoutAnEqualsSignAsAnEmptyValue()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Parsed: Dictionary of [Text, Text];
    begin
        // [SCENARIO] A bare key with no = at all still becomes an entry
        Parsed := FormClient.ParseFormBody('sandbox');

        Assert.AreEqual('', ValueOf(Parsed, 'sandbox'),
            'Expected a pair with no = to yield that key with an empty value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LetsTheLastOccurrenceOfARepeatedKeyWin()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Parsed: Dictionary of [Text, Text];
    begin
        // [SCENARIO] A key the gateway repeats keeps its last value and raises nothing
        Parsed := FormClient.ParseFormBody('scope=read&scope=write');

        Assert.AreEqual(1, Parsed.Count(),
            StrSubstNo('Expected a repeated key to collapse into one entry, got the keys: %1', KeyList(Parsed)));
        Assert.AreEqual('write', ValueOf(Parsed, 'scope'),
            'Expected the last occurrence of a repeated key to win — and the parse to survive the duplicate instead of erroring');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsAnEmptyDictionaryForEmptyText()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Parsed: Dictionary of [Text, Text];
    begin
        // [SCENARIO] An empty body parses to nothing at all
        Parsed := FormClient.ParseFormBody('');

        Assert.AreEqual(0, Parsed.Count(),
            StrSubstNo('Expected empty text to yield an empty dictionary, got the keys: %1', KeyList(Parsed)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoundTripsAHostileFieldThroughBuildAndParse()
    var
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Fields: Dictionary of [Text, Text];
        Parsed: Dictionary of [Text, Text];
        FieldName: Text;
        FieldValue: Text;
    begin
        // [SCENARIO] Everything the two rules disagree about survives a build-then-parse round trip
        FieldName := Any.AlphabeticText(6) + ' name+1';
        FieldValue := Any.AlphabeticText(6) + ' a+b&c=d café';
        Fields.Add(FieldName, FieldValue);

        Parsed := FormClient.ParseFormBody(FormClient.BuildFormBody(Fields));

        Assert.AreEqual(1, Parsed.Count(),
            StrSubstNo('Expected the round trip to yield exactly the one field it started with, got the keys: %1', KeyList(Parsed)));
        Assert.AreEqual(FieldValue, ValueOf(Parsed, FieldName),
            'Expected a key and a value full of + & = spaces and non-ASCII letters to come back out of the round trip unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendsExactlyOnePostRequestToTheGivenUrl()
    var
        MockFormGateway: Codeunit "Mock Form Gateway";
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Fields: Dictionary of [Text, Text];
        ResponseFields: Dictionary of [Text, Text];
        Url: Text;
    begin
        // [SCENARIO] One POST reaches the gateway, at the address it was given
        Url := 'https://gateway.example.com/oauth2/' + Any.AlphabeticText(10) + '/token';
        Fields.Add('grant_type', 'client_credentials');

        FormClient.PostForm(Url, Fields, MockFormGateway, ResponseFields);

        Assert.AreEqual('POST', UpperCase(MockFormGateway.GetCapturedMethod()),
            'Expected the request sent through the handler to use the POST method');
        Assert.AreEqual(Url, MockFormGateway.GetCapturedUri(),
            'Expected the full request URL to be exactly the Url passed to PostForm');
        Assert.AreEqual(1, MockFormGateway.GetRequestCount(),
            'Expected exactly one request to reach the gateway for a single PostForm call');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostsTheFormEncodedBodyThroughTheHandler()
    var
        MockFormGateway: Codeunit "Mock Form Gateway";
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Fields: Dictionary of [Text, Text];
        ResponseFields: Dictionary of [Text, Text];
    begin
        // [SCENARIO] The request body is the encoded form, escaping and all
        Fields.Add('client_secret', 'a+b c');

        FormClient.PostForm('https://gateway.example.com/oauth2/token', Fields, MockFormGateway, ResponseFields);

        Assert.AreEqual('client_secret=a%2Bb%20c', MockFormGateway.GetCapturedBody(),
            'Expected the request body to be exactly the form-encoded fields, with the literal + escaped as %2B');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeclaresTheFormMediaTypeOnTheContentHeaders()
    var
        MockFormGateway: Codeunit "Mock Form Gateway";
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Fields: Dictionary of [Text, Text];
        ResponseFields: Dictionary of [Text, Text];
        ContentType: Text;
    begin
        // [SCENARIO] Content-Type declares the form media type and lives with the content
        Fields.Add('grant_type', 'client_credentials');

        FormClient.PostForm('https://gateway.example.com/oauth2/token', Fields, MockFormGateway, ResponseFields);

        ContentType := MockFormGateway.GetContentHeader('Content-Type');
        Assert.IsTrue(ContentType.StartsWith('application/x-www-form-urlencoded'),
            StrSubstNo('Expected the content headers to declare Content-Type application/x-www-form-urlencoded, got "%1"', ContentType));
        Assert.IsFalse(MockFormGateway.RequestHasHeader('Content-Type'),
            StrSubstNo('Expected Content-Type to stay off the request''s own headers — it travels with the content. The request headers carried Content-Type: %1',
                MockFormGateway.GetRequestHeader('Content-Type')));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParsesTheFormEncodedResponseIntoTheOutputDictionary()
    var
        MockFormGateway: Codeunit "Mock Form Gateway";
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Fields: Dictionary of [Text, Text];
        ResponseFields: Dictionary of [Text, Text];
    begin
        // [SCENARIO] The gateway's form-encoded answer comes back decoded
        MockFormGateway.SetResponse(200, 'access_token=x%2By+z&expires_in=3600');
        Fields.Add('grant_type', 'client_credentials');

        FormClient.PostForm('https://gateway.example.com/oauth2/token', Fields, MockFormGateway, ResponseFields);

        Assert.AreEqual('x+y z', ValueOf(ResponseFields, 'access_token'),
            'Expected the response body to be parsed by the reading rules — %2B back to a +, the raw + to a space');
        Assert.AreEqual('3600', ValueOf(ResponseFields, 'expires_in'),
            'Expected every field of the response body to reach ResponseFields');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTrueWhenTheGatewayAcceptsTheForm()
    var
        MockFormGateway: Codeunit "Mock Form Gateway";
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Fields: Dictionary of [Text, Text];
        ResponseFields: Dictionary of [Text, Text];
    begin
        // [SCENARIO] Any 2xx counts as accepted
        MockFormGateway.SetResponse(202, 'status=queued');
        Fields.Add('grant_type', 'client_credentials');

        Assert.IsTrue(FormClient.PostForm('https://gateway.example.com/orders', Fields, MockFormGateway, ResponseFields),
            'Expected PostForm to return true for a 202 response — any status in the 2xx class counts as accepted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsFalseWhenTheGatewayRejectsTheForm()
    var
        MockFormGateway: Codeunit "Mock Form Gateway";
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Fields: Dictionary of [Text, Text];
        ResponseFields: Dictionary of [Text, Text];
    begin
        // [SCENARIO] A 4xx answer is a failure even though its body parses fine
        MockFormGateway.SetResponse(400, 'error=invalid_grant');
        Fields.Add('grant_type', 'client_credentials');

        Assert.IsFalse(FormClient.PostForm('https://gateway.example.com/oauth2/token', Fields, MockFormGateway, ResponseFields),
            'Expected PostForm to return false for an HTTP 400 response, whatever the body says');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsFalseWhenTheRequestCannotBeSent()
    var
        MockFormGateway: Codeunit "Mock Form Gateway";
        FormClient: Codeunit "Form Url Encoded Client";
        Assert: Codeunit Assert;
        Fields: Dictionary of [Text, Text];
        ResponseFields: Dictionary of [Text, Text];
    begin
        // [SCENARIO] A transport failure reported by the handler is a failure
        MockFormGateway.SetSendFailure();
        Fields.Add('grant_type', 'client_credentials');

        Assert.IsFalse(FormClient.PostForm('https://gateway.example.com/oauth2/token', Fields, MockFormGateway, ResponseFields),
            'Expected PostForm to return false when the handler reports a transport failure — the request never reached the gateway');
    end;

    // Reports a missing key instead of erroring inside Get, so the failure
    // message shows what the submission actually produced.
    local procedure ValueOf(Fields: Dictionary of [Text, Text]; FieldName: Text): Text
    var
        FieldValue: Text;
    begin
        if Fields.Get(FieldName, FieldValue) then
            exit(FieldValue);
        exit(StrSubstNo('<no field named "%1"; keys present: %2>', FieldName, KeyList(Fields)));
    end;

    local procedure KeyList(Fields: Dictionary of [Text, Text]): Text
    var
        FieldName: Text;
        Joined: Text;
    begin
        foreach FieldName in Fields.Keys() do begin
            if Joined <> '' then
                Joined += ', ';
            Joined += FieldName;
        end;
        if Joined = '' then
            exit('<none>');
        exit(Joined);
    end;
}
