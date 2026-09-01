codeunit 50900 "Document Language Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Document Language]

    var
        EnglishGreetingTxt: Label 'Thank you for your order.', Locked = true;
        DanishGreetingTxt: Label 'Tak for din ordre.', Locked = true;
        FrenchGreetingTxt: Label 'Merci pour votre commande.', Locked = true;
        LineTooLongErr: Label 'The confirmation line does not fit in 100 characters.', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GreetingIsDanishWhenTheSessionRunsInDanish()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        OriginalLanguageId: Integer;
        ExpectedGreeting: Text;
        Greeting: Text;
    begin
        // [SCENARIO] The greeting follows the language the session is running in
        // [GIVEN] a session running in Danish (1030)
        ExpectedGreeting := DanishGreetingTxt;
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1030);

        // [WHEN] asking for the greeting of the session language
        Greeting := DocumentLanguageMgt.GreetingInSessionLanguage();
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the Danish text comes back
        Assert.AreEqual(ExpectedGreeting, Greeting,
            'Expected the Danish greeting while the session runs in Danish (language ID 1030)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GreetingIsFrenchWhenTheSessionRunsInFrench()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        OriginalLanguageId: Integer;
        ExpectedGreeting: Text;
        Greeting: Text;
    begin
        // [SCENARIO] The greeting follows the language the session is running in
        // [GIVEN] a session running in French (1036)
        ExpectedGreeting := FrenchGreetingTxt;
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1036);

        // [WHEN] asking for the greeting of the session language
        Greeting := DocumentLanguageMgt.GreetingInSessionLanguage();
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the French text comes back
        Assert.AreEqual(ExpectedGreeting, Greeting,
            'Expected the French greeting while the session runs in French (language ID 1036)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GreetingIsFrenchWhenTheSessionRunsInCanadianFrench()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        OriginalLanguageId: Integer;
        ExpectedGreeting: Text;
        Greeting: Text;
    begin
        // [SCENARIO] A regional variant carries the same two-letter ISO name as its parent language
        // [GIVEN] a session running in Canadian French (3084), whose ISO name is fr
        ExpectedGreeting := FrenchGreetingTxt;
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(3084);

        // [WHEN] asking for the greeting of the session language
        Greeting := DocumentLanguageMgt.GreetingInSessionLanguage();
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the French text comes back, not the English fallback
        Assert.AreEqual(ExpectedGreeting, Greeting,
            'Expected the French greeting for Canadian French (language ID 3084) — the greeting is keyed on the two-letter ISO name fr, not on the language ID');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GreetingIsFrenchWhenTheSessionRunsInSwissFrench()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        OriginalLanguageId: Integer;
        ExpectedGreeting: Text;
        Greeting: Text;
    begin
        // [SCENARIO] Every regional variant is keyed on its ISO name, not on a list of known language IDs
        // [GIVEN] a session running in Swiss French (4108), whose ISO name is fr
        ExpectedGreeting := FrenchGreetingTxt;
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(4108);

        // [WHEN] asking for the greeting of the session language
        Greeting := DocumentLanguageMgt.GreetingInSessionLanguage();
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the French text comes back
        Assert.AreEqual(ExpectedGreeting, Greeting,
            'Expected the French greeting for Swiss French (language ID 4108) — the text has to be picked by the two-letter ISO name of the session language, not by a list of language IDs');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GreetingIsEnglishWhenTheSessionRunsInBritishEnglish()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        OriginalLanguageId: Integer;
        ExpectedGreeting: Text;
        Greeting: Text;
    begin
        // [SCENARIO] A regional variant carries the same two-letter ISO name as its parent language
        // [GIVEN] a session running in British English (2057), whose ISO name is en
        ExpectedGreeting := EnglishGreetingTxt;
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(2057);

        // [WHEN] asking for the greeting of the session language
        Greeting := DocumentLanguageMgt.GreetingInSessionLanguage();
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the English text comes back
        Assert.AreEqual(ExpectedGreeting, Greeting,
            'Expected the English greeting for British English (language ID 2057) — the greeting is keyed on the two-letter ISO name en, not on the language ID');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GreetingIsEnglishForALanguageWithoutItsOwnText()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        OriginalLanguageId: Integer;
        ExpectedGreeting: Text;
        Greeting: Text;
    begin
        // [SCENARIO] A language the codeunit has no text for falls back to English
        // [GIVEN] a session running in German (1031)
        ExpectedGreeting := EnglishGreetingTxt;
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1031);

        // [WHEN] asking for the greeting of the session language
        Greeting := DocumentLanguageMgt.GreetingInSessionLanguage();
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the English text comes back
        Assert.AreEqual(ExpectedGreeting, Greeting,
            'Expected the English greeting for German (language ID 1031) — only en, da and fr have their own text');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConfirmationLineUsesTheCustomerLanguageNotTheSessionLanguage()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
        CustomerName: Text;
        OriginalLanguageId: Integer;
        Line: Text;
    begin
        // [SCENARIO] The document speaks the recipient's language, not the printing user's
        // [GIVEN] an en-US session and a customer whose language code resolves to Danish
        CustomerName := AnyCustomerName('TRYAL-DL06');
        CustomerNo := CreateCustomerWithLanguageCode(LanguageCodeForId(1030), CustomerName);
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1033);

        // [WHEN] building the confirmation line for that customer
        Line := DocumentLanguageMgt.ConfirmationLineFor(CustomerNo);
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the line carries the customer name and the Danish greeting
        Assert.AreEqual(CustomerName + ': ' + DanishGreetingTxt, Line,
            'Expected the confirmation line of a Danish customer to be the name, a colon, a space and the Danish greeting');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConfirmationLineFallsBackToTheSessionLanguageWhenTheCustomerHasNoLanguageCode()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
        CustomerName: Text;
        OriginalLanguageId: Integer;
        Line: Text;
    begin
        // [SCENARIO] A customer without a language code is served in the session language, not in en-US
        // [GIVEN] a session running in French and a customer with a blank language code
        CustomerName := AnyCustomerName('TRYAL-DL07');
        CustomerNo := CreateCustomerWithLanguageCode('', CustomerName);
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1036);

        // [WHEN] building the confirmation line for that customer
        Line := DocumentLanguageMgt.ConfirmationLineFor(CustomerNo);
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the line carries the French greeting of the session
        Assert.AreEqual(CustomerName + ': ' + FrenchGreetingTxt, Line,
            'Expected a customer with no language code to be served in the language the session runs in (French, 1036) — not in en-US');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConfirmationLineFallsBackToTheSessionLanguageWhenTheLanguageCodeIsUnknown()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
        CustomerName: Text;
        OriginalLanguageId: Integer;
        Line: Text;
    begin
        // [SCENARIO] A language code no Language record backs is served in the session language
        // [GIVEN] a session running in Danish and a customer carrying a language code that does not exist
        CustomerName := AnyCustomerName('TRYAL-DL08');
        CustomerNo := CreateCustomerWithLanguageCode('TRYALZZ', CustomerName);
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1030);

        // [WHEN] building the confirmation line for that customer
        Line := DocumentLanguageMgt.ConfirmationLineFor(CustomerNo);
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the line carries the Danish greeting of the session
        Assert.AreEqual(CustomerName + ': ' + DanishGreetingTxt, Line,
            'Expected an unresolvable language code to be served in the language the session runs in (Danish, 1030) — not in en-US');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConfirmationLineFillsTheDocumentFieldExactly()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
        CustomerName: Text;
        Line: Text;
    begin
        // [SCENARIO] A line of exactly 100 characters still fits the document field
        // [GIVEN] a Danish customer whose name is 80 characters long
        CustomerName := CustomerNameOfLength('TRYAL-DL09', 80);
        CustomerNo := CreateCustomerWithLanguageCode(LanguageCodeForId(1030), CustomerName);

        // [WHEN] building the confirmation line for that customer
        Line := DocumentLanguageMgt.ConfirmationLineFor(CustomerNo);

        // [THEN] the full 100-character line comes back
        Assert.AreEqual(CustomerName + ': ' + DanishGreetingTxt, Line,
            StrSubstNo('Expected the 100-character Danish line to be returned untouched, got %1 characters', StrLen(Line)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConfirmationLineErrorsWhenItIsTooLongForTheDocumentField()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
        OriginalLanguageId: Integer;
        ActualError: Text;
    begin
        // [SCENARIO] A line that does not fit the document field is rejected
        // [GIVEN] a Danish customer whose name is 85 characters long — 105 characters with the greeting
        CustomerNo := CreateCustomerWithLanguageCode(LanguageCodeForId(1030), CustomerNameOfLength('TRYAL-DL10', 85));
        OriginalLanguageId := GlobalLanguage();

        // [WHEN] building the confirmation line for that customer
        asserterror DocumentLanguageMgt.ConfirmationLineFor(CustomerNo);
        ActualError := GetLastErrorText();
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the too-long line is reported
        Assert.ExpectedMessage(LineTooLongErr, ActualError);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SessionLanguageIsUnchangedAfterAConfirmationLine()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
        OriginalLanguageId: Integer;
        LanguageIdAfterCall: Integer;
    begin
        // [SCENARIO] Printing in the customer's language does not leak into the session
        // [GIVEN] an en-US session and a Danish customer
        CustomerNo := CreateCustomerWithLanguageCode(LanguageCodeForId(1030), AnyCustomerName('TRYAL-DL11'));
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1033);

        // [WHEN] building the confirmation line for that customer
        DocumentLanguageMgt.ConfirmationLineFor(CustomerNo);
        LanguageIdAfterCall := GlobalLanguage();
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the session is still running in en-US
        Assert.AreEqual(1033, LanguageIdAfterCall,
            'Expected the session to be back in en-US (1033) after a confirmation line was printed in Danish');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SessionLanguageIsUnchangedAfterAConfirmationLineFails()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
        OriginalLanguageId: Integer;
        LanguageIdAfterCall: Integer;
    begin
        // [SCENARIO] A failing printout does not leave the session in the customer's language
        // [GIVEN] an en-US session and a Danish customer whose line is too long
        CustomerNo := CreateCustomerWithLanguageCode(LanguageCodeForId(1030), CustomerNameOfLength('TRYAL-DL12', 85));
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1033);

        // [WHEN] the confirmation line fails
        asserterror DocumentLanguageMgt.ConfirmationLineFor(CustomerNo);
        LanguageIdAfterCall := GlobalLanguage();
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the session is still running in en-US
        Assert.AreEqual(1033, LanguageIdAfterCall,
            'Expected the session to be back in en-US (1033) even though the confirmation line raised an error while the session ran in Danish');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SessionLanguageIsUnchangedAfterAnAuditLine()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
        OriginalLanguageId: Integer;
        LanguageIdAfterCall: Integer;
    begin
        // [SCENARIO] Filing the audit copy in the default language does not leak into the session
        // [GIVEN] a session running in French and a Danish customer
        CustomerNo := CreateCustomerWithLanguageCode(LanguageCodeForId(1030), AnyCustomerName('TRYAL-DL17'));
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1036);

        // [WHEN] building the audit copy for that customer
        DocumentLanguageMgt.AuditLineFor(CustomerNo);
        LanguageIdAfterCall := GlobalLanguage();
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the session is still running in French
        Assert.AreEqual(1036, LanguageIdAfterCall,
            'Expected the session to be back in French (1036) after the audit copy was written in the default application language');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SessionLanguageIsUnchangedAfterAWireTag()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
        OriginalLanguageId: Integer;
        LanguageIdAfterCall: Integer;
    begin
        // [SCENARIO] Reading the recipient's language tag does not leak into the session
        // [GIVEN] a session running in French and a Danish customer
        CustomerNo := CreateCustomerWithLanguageCode(LanguageCodeForId(1030), AnyCustomerName('TRYAL-DL18'));
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1036);

        // [WHEN] asking for the wire tag of that customer
        DocumentLanguageMgt.WireTagFor(CustomerNo);
        LanguageIdAfterCall := GlobalLanguage();
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the session is still running in French
        Assert.AreEqual(1036, LanguageIdAfterCall,
            'Expected the session to be back in French (1036) after the wire tag of a Danish customer was read');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WireTagIsTheTwoLetterIsoNameOfTheCustomerLanguage()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
    begin
        // [SCENARIO] The wire tag names the recipient's language
        // [GIVEN] a customer whose language code resolves to Danish
        CustomerNo := CreateCustomerWithLanguageCode(LanguageCodeForId(1030), AnyCustomerName('TRYAL-DL13'));

        // [WHEN] asking for the wire tag of that customer
        // [THEN] the two-letter ISO name of Danish comes back
        Assert.AreEqual('da', DocumentLanguageMgt.WireTagFor(CustomerNo),
            'Expected the wire tag of a Danish customer to be the two-letter ISO name da');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WireTagIsTheTwoLetterIsoNameOfALanguageWithoutItsOwnGreeting()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
    begin
        // [SCENARIO] The wire tag names the recipient's language even when no greeting is written in it
        // [GIVEN] a customer whose language code resolves to German (1031)
        CustomerNo := CreateCustomerWithLanguageCode(LanguageCodeForId(1031), AnyCustomerName('TRYAL-DL19'));

        // [WHEN] asking for the wire tag of that customer
        // [THEN] the two-letter ISO name of German comes back
        Assert.AreEqual('de', DocumentLanguageMgt.WireTagFor(CustomerNo),
            'Expected the wire tag of a German customer to be the two-letter ISO name de — the tag is the ISO name of the resolved language, not one of the three greeting languages');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WireTagFallsBackToTheSessionLanguage()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
        OriginalLanguageId: Integer;
        WireTag: Text;
    begin
        // [SCENARIO] A customer without a language code is tagged with the session language
        // [GIVEN] a session running in French and a customer with a blank language code
        CustomerNo := CreateCustomerWithLanguageCode('', AnyCustomerName('TRYAL-DL14'));
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1036);

        // [WHEN] asking for the wire tag of that customer
        WireTag := DocumentLanguageMgt.WireTagFor(CustomerNo);
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the two-letter ISO name of the session language comes back
        Assert.AreEqual('fr', WireTag,
            'Expected the wire tag of a customer with no language code to be the ISO name of the session language (fr) — not en');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AuditLineIsEnglishForACustomerInAnotherLanguage()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
        CustomerName: Text;
        OriginalLanguageId: Integer;
        Line: Text;
    begin
        // [SCENARIO] The audit copy is always filed in the default application language
        // [GIVEN] an en-US session and a customer whose language code resolves to Danish
        CustomerName := AnyCustomerName('TRYAL-DL15');
        CustomerNo := CreateCustomerWithLanguageCode(LanguageCodeForId(1030), CustomerName);
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1033);

        // [WHEN] building the audit copy for that customer
        Line := DocumentLanguageMgt.AuditLineFor(CustomerNo);
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the audit copy carries the English greeting, not the customer's Danish one
        Assert.AreEqual(CustomerName + ': ' + EnglishGreetingTxt, Line,
            'Expected the audit copy of a Danish customer to be filed in the default application language (en-US)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AuditLineStaysEnglishWhenTheSessionRunsInAnotherLanguage()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
        CustomerName: Text;
        OriginalLanguageId: Integer;
        Line: Text;
    begin
        // [SCENARIO] The audit copy ignores the session language too
        // [GIVEN] a session running in French and a customer whose language code resolves to Danish
        CustomerName := AnyCustomerName('TRYAL-DL16');
        CustomerNo := CreateCustomerWithLanguageCode(LanguageCodeForId(1030), CustomerName);
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1036);

        // [WHEN] building the audit copy for that customer
        Line := DocumentLanguageMgt.AuditLineFor(CustomerNo);
        GlobalLanguage(OriginalLanguageId);

        // [THEN] the audit copy is still English
        Assert.AreEqual(CustomerName + ': ' + EnglishGreetingTxt, Line,
            'Expected the audit copy to stay in the default application language (en-US) while the session runs in French');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AuditLineIsNotLimitedTo100Characters()
    var
        DocumentLanguageMgt: Codeunit "Document Language Mgt.";
        Assert: Codeunit Assert;
        CustomerNo: Code[20];
        CustomerName: Text;
        Line: Text;
    begin
        // [SCENARIO] The 100-character limit belongs to the confirmation line alone
        // [GIVEN] a Danish customer whose name is 95 characters long — 122 characters with the English greeting
        CustomerName := CustomerNameOfLength('TRYAL-DL20', 95);
        CustomerNo := CreateCustomerWithLanguageCode(LanguageCodeForId(1030), CustomerName);

        // [WHEN] building the audit copy for that customer
        Line := DocumentLanguageMgt.AuditLineFor(CustomerNo);

        // [THEN] the whole 122-character line comes back, without an error
        Assert.AreEqual(CustomerName + ': ' + EnglishGreetingTxt, Line,
            StrSubstNo('Expected the audit copy to carry the full 122-character line — the audit copy has no length limit — got %1 characters', StrLen(Line)));
    end;

    local procedure CreateCustomerWithLanguageCode(LanguageCode: Code[10]; CustomerName: Text): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := CopyStr(CustomerName, 1, MaxStrLen(Customer.Name));
        // Assigned rather than validated: one test needs a language code that
        // no Language record backs.
        Customer."Language Code" := LanguageCode;
        Customer.Modify();
        exit(Customer."No.");
    end;

    local procedure LanguageCodeForId(WindowsLanguageId: Integer): Code[10]
    var
        Language: Record Language;
    begin
        Language.SetRange("Windows Language ID", WindowsLanguageId);
        if Language.FindFirst() then
            exit(Language.Code);

        Language.Init();
        Language.Code := CopyStr('TRYAL' + Format(WindowsLanguageId), 1, MaxStrLen(Language.Code));
        Language.Name := CopyStr('TryAL ' + Format(WindowsLanguageId), 1, MaxStrLen(Language.Name));
        Language."Windows Language ID" := WindowsLanguageId;
        Language.Insert();
        exit(Language.Code);
    end;

    local procedure AnyCustomerName(Marker: Text): Text
    var
        Any: Codeunit Any;
    begin
        exit(Marker + ' ' + UpperCase(Any.AlphabeticText(10)));
    end;

    local procedure CustomerNameOfLength(Marker: Text; NameLength: Integer): Text
    begin
        exit(PadStr(Marker + ' ', NameLength, 'X'));
    end;
}
