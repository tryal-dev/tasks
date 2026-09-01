codeunit 50900 "Search Key Folding Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UppercasesPlainLettersAndKeepsSingleSpaces()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Input: Text;
    begin
        Input := Any.AlphabeticText(6) + ' ' + Any.AlphabeticText(6);

        Assert.AreEqual(UpperCase(Input), SearchKeyFolding.ToSearchKey(Input),
            'Expected a plain lowercase two-word name to come back uppercased with its single space intact');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FoldsGermanUmlautsToBaseLetters()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('UBER MUDE ARZTE HOREN OFTER', SearchKeyFolding.ToSearchKey('Über müde Ärzte hören öfter'),
            'Expected ä ö ü (and their uppercase forms) to fold to A O U — plain uppercasing leaves Ü as Ü');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FoldsSharpSToDoubleS()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('STRASSE WEISSBIER', SearchKeyFolding.ToSearchKey('Straße Weißbier'),
            'Expected every ß to fold to the two letters SS');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FoldsNordicAndSpanishLetters()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('ANGSTROM CELIK PENA ODEGARD IBANEZ', SearchKeyFolding.ToSearchKey('Ångström Çelik Peña Ødegård Ibáñez'),
            'Expected å ç ñ ø á (and their uppercase forms) to fold to their base letters');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FoldsFrenchAccentsAcrossTheVowelMap()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('CHATEAU CREME BRULEE A COTE', SearchKeyFolding.ToSearchKey('Château Crème brûlée à côté'),
            'Expected â è é û à ô to fold to their base vowels');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FoldsLigaturesToTwoLetters()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('AEBLESKIVER OEUVRE', SearchKeyFolding.ToSearchKey('Æbleskiver Œuvre'),
            'Expected the ligatures æ and œ to fold to the letter pairs AE and OE');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FoldsEveryMappedLowercaseCharacter()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('AAAAAA EEEE IIII OOOOOO UUUU YY N C SS AE OE',
            SearchKeyFolding.ToSearchKey('àáâãäå èéêë ìíîï òóôõöø ùúûü ýÿ ñ ç ß æ œ'),
            'Expected every lowercase character of the fold map to fold to its mapped letters — none of them is a separator');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FoldsEveryMappedUppercaseCharacter()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('AAAAAA EEEE IIII OOOOOO UUUU YY N C AE OE',
            SearchKeyFolding.ToSearchKey('ÀÁÂÃÄÅ ÈÉÊË ÌÍÎÏ ÒÓÔÕÖØ ÙÚÛÜ ÝŸ Ñ Ç Æ Œ'),
            'Expected every uppercase character of the fold map to fold to the same letters as its lowercase form');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FoldsAccentsEmbeddedInRandomText()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Middle: Text;
    begin
        Middle := Any.AlphabeticText(6);

        Assert.AreEqual('MU' + UpperCase(Middle) + 'SS', SearchKeyFolding.ToSearchKey('mü' + Middle + 'ß'),
            'Expected the folded key of a randomly generated name to keep the fold map and uppercasing intact — hardcoded example outputs cannot pass this');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CollapsesPunctuationRunsToSingleSpaces()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('O BRIEN SONS LTD', SearchKeyFolding.ToSearchKey('O''Brien   &  Sons, Ltd.'),
            'Expected every run of punctuation and whitespace to become exactly one space');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TrimsLeadingAndTrailingSeparators()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('NORDWIND', SearchKeyFolding.ToSearchKey(' --Nordwind-- '),
            'Expected separators at the start and end of the input to be dropped, not turned into spaces');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsDigitsUnchanged()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('KRAN BAU 4711 GMBH', SearchKeyFolding.ToSearchKey('Kran-Bau 4711 GmbH'),
            'Expected digits to survive folding unchanged while the dash collapses to a space');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyInputGivesEmptyKey()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', SearchKeyFolding.ToSearchKey(''),
            'Expected the empty input to fold to the empty key without raising an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SeparatorOnlyInputGivesEmptyKey()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', SearchKeyFolding.ToSearchKey('*** !!! ***'),
            'Expected an input consisting only of separators to fold to the empty string, not to spaces');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RefoldingAKeyReturnsItUnchanged()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FirstKey: Text;
    begin
        FirstKey := SearchKeyFolding.ToSearchKey('Grü' + Any.AlphabeticText(5) + '-ß & Co. 42');

        Assert.AreEqual(FirstKey, SearchKeyFolding.ToSearchKey(FirstKey),
            'Expected ToSearchKey to be idempotent — folding an already folded key must return it unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LookupCountsCustomersSharingTheFoldedKey()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
    begin
        CreateCustomerNamed('TRYAL-SKF1 Müller GmbH');
        CreateCustomerNamed('TRYAL-SKF1 MULLER GMBH');
        CreateCustomerNamed('TRYAL-SKF1 Mueller GmbH');

        Assert.AreEqual(2, SearchKeyFolding.CountCustomersMatching('tryal skf1 muller gmbh'),
            'Expected the lowercase unaccented query to find Müller GmbH and MULLER GMBH but not Mueller GmbH — ü folds to U, not to UE');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LookupIgnoresPunctuationAndSpacingDifferences()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
    begin
        CreateCustomerNamed('TRYAL-SKF2 Nord-Wind A/S');
        CreateCustomerNamed('TRYAL-SKF2 NordWind AS');

        Assert.AreEqual(1, SearchKeyFolding.CountCustomersMatching('  tryal skf2   nord wind, a.s. '),
            'Expected the ragged query to match Nord-Wind A/S on the folded key and to leave NordWind AS out — collapsed separators are not removed letters');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LookupReturnsZeroWhenNoKeyMatches()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        CreateCustomerNamed('TRYAL-SKF3 Findable Ltd');

        Assert.AreEqual(0, SearchKeyFolding.CountCustomersMatching('TRYAL-SKF3 ' + Any.AlphabeticText(12)),
            'Expected 0 for a query whose folded key no customer name folds to');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LookupWithSeparatorOnlyQueryMatchesNothing()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
    begin
        CreateCustomerNamed('****');

        Assert.AreEqual(0, SearchKeyFolding.CountCustomersMatching('!!! ???'),
            'Expected a query that folds to the empty key to match nothing — even a customer whose name also folds to the empty key');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LookupWithEmptyQueryMatchesNothing()
    var
        SearchKeyFolding: Codeunit "Search Key Folding";
        Assert: Codeunit Assert;
    begin
        CreateCustomerNamed('----');

        Assert.AreEqual(0, SearchKeyFolding.CountCustomersMatching(''),
            'Expected the empty query to return 0 without raising an error — even when a customer name also folds to the empty key');
    end;

    local procedure CreateCustomerNamed(NewName: Text[100])
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, NewName);
        Customer.Modify(true);
    end;
}
