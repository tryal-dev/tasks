codeunit 50900 "Config Parser Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParsesAPlainTwoEntryConfig()
    var
        ConfigParser: Codeunit "Config Parser";
        Assert: Codeunit Assert;
        Settings: Dictionary of [Text, Text];
        Config: Text;
    begin
        Config := 'retries=3;timeout=30';

        Settings := ConfigParser.Parse(Config);

        Assert.AreEqual(2, Settings.Count(), StrSubstNo('Expected one dictionary entry per key=value pair in ''%1''', Config));
        VerifyEntry(Settings, Config, 'retries', '3');
        VerifyEntry(Settings, Config, 'timeout', '30');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TrimsSpacesAroundKeysAndValuesButKeepsInnerSpaces()
    var
        ConfigParser: Codeunit "Config Parser";
        Assert: Codeunit Assert;
        Settings: Dictionary of [Text, Text];
        Config: Text;
    begin
        Config := '  log level = verbose mode ;endpoint= https://bc.local ';

        Settings := ConfigParser.Parse(Config);

        Assert.AreEqual(2, Settings.Count(), StrSubstNo('Expected two entries when parsing ''%1'' — spaces around keys and values must not create extra entries', Config));
        VerifyEntry(Settings, Config, 'log level', 'verbose mode');
        VerifyEntry(Settings, Config, 'endpoint', 'https://bc.local');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CutsEachEntryAtTheFirstEqualsSignOnly()
    var
        ConfigParser: Codeunit "Config Parser";
        Assert: Codeunit Assert;
        Settings: Dictionary of [Text, Text];
        Config: Text;
    begin
        Config := 'token=abc==;formula=a=b';

        Settings := ConfigParser.Parse(Config);

        Assert.AreEqual(2, Settings.Count(), StrSubstNo('Expected two entries when parsing ''%1'' — an = inside a value must not split the entry', Config));
        VerifyEntry(Settings, Config, 'token', 'abc==');
        VerifyEntry(Settings, Config, 'formula', 'a=b');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyValueMapsTheKeyToEmptyText()
    var
        ConfigParser: Codeunit "Config Parser";
        Assert: Codeunit Assert;
        Settings: Dictionary of [Text, Text];
        Config: Text;
    begin
        Config := 'flag=';

        Settings := ConfigParser.Parse(Config);

        Assert.AreEqual(1, Settings.Count(), StrSubstNo('Expected exactly one entry when parsing ''%1'' — an empty value is still a valid entry', Config));
        VerifyEntry(Settings, Config, 'flag', '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyAndBlankSegmentsAreSkipped()
    var
        ConfigParser: Codeunit "Config Parser";
        Assert: Codeunit Assert;
        Settings: Dictionary of [Text, Text];
        Config: Text;
    begin
        Config := ';a=1;;   ;b=2;';

        Settings := ConfigParser.Parse(Config);

        Assert.AreEqual(2, Settings.Count(), StrSubstNo('Expected the empty and all-spaces segments of ''%1'' to be skipped, leaving two entries', Config));
        VerifyEntry(Settings, Config, 'a', '1');
        VerifyEntry(Settings, Config, 'b', '2');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LastDuplicateKeyWins()
    var
        ConfigParser: Codeunit "Config Parser";
        Assert: Codeunit Assert;
        Settings: Dictionary of [Text, Text];
        Config: Text;
    begin
        Config := 'retries=3;retries=5;retries=8';

        Settings := ConfigParser.Parse(Config);

        Assert.AreEqual(1, Settings.Count(), StrSubstNo('Expected a single entry for the key repeated in ''%1'' — duplicates must overwrite, not accumulate or fail', Config));
        VerifyEntry(Settings, Config, 'retries', '8');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeysAreCaseSensitive()
    var
        ConfigParser: Codeunit "Config Parser";
        Assert: Codeunit Assert;
        Settings: Dictionary of [Text, Text];
        Config: Text;
    begin
        Config := 'mode=live;Mode=test';

        Settings := ConfigParser.Parse(Config);

        Assert.AreEqual(2, Settings.Count(), StrSubstNo('Expected ''mode'' and ''Mode'' to be two different keys when parsing ''%1''', Config));
        VerifyEntry(Settings, Config, 'mode', 'live');
        VerifyEntry(Settings, Config, 'Mode', 'test');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntryWithoutEqualsSignIsAnInvalidEntry()
    var
        ConfigParser: Codeunit "Config Parser";
        Assert: Codeunit Assert;
    begin
        asserterror ConfigParser.Parse('a=1;timeout;b=2');

        Assert.ExpectedError('Invalid config entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntryWithEmptyKeyIsAnInvalidEntry()
    var
        ConfigParser: Codeunit "Config Parser";
        Assert: Codeunit Assert;
    begin
        asserterror ConfigParser.Parse(' = 5');

        Assert.ExpectedError('Invalid config entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyInputYieldsAnEmptyDictionary()
    var
        ConfigParser: Codeunit "Config Parser";
        Assert: Codeunit Assert;
        Settings: Dictionary of [Text, Text];
    begin
        Settings := ConfigParser.Parse('');

        Assert.AreEqual(0, Settings.Count(), 'Expected an empty Config to yield an empty dictionary');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AllSpacesInputYieldsAnEmptyDictionary()
    var
        ConfigParser: Codeunit "Config Parser";
        Assert: Codeunit Assert;
        Settings: Dictionary of [Text, Text];
    begin
        Settings := ConfigParser.Parse('   ');

        Assert.AreEqual(0, Settings.Count(), 'Expected an all-spaces Config to yield an empty dictionary — a blank segment is not an entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomizedConfigRoundTrips()
    var
        ConfigParser: Codeunit "Config Parser";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Settings: Dictionary of [Text, Text];
        Expected: Dictionary of [Text, Text];
        Config: Text;
        KeyText: Text;
        ValueText: Text;
        i: Integer;
    begin
        for i := 1 to 5 do begin
            KeyText := Any.AlphabeticText(6) + Format(i);
            ValueText := Any.AlphanumericText(10);
            Expected.Set(KeyText, ValueText);
            Config += StrSubstNo(' %1 = %2 ;', KeyText, ValueText);
        end;

        Settings := ConfigParser.Parse(Config);

        Assert.AreEqual(Expected.Count(), Settings.Count(), StrSubstNo('Expected one entry per key=value pair when parsing ''%1''', Config));
        foreach KeyText in Expected.Keys() do
            VerifyEntry(Settings, Config, KeyText, Expected.Get(KeyText));
    end;

    local procedure VerifyEntry(Settings: Dictionary of [Text, Text]; Config: Text; KeyText: Text; ExpectedValue: Text)
    var
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(Settings.ContainsKey(KeyText), StrSubstNo('Expected parsing ''%1'' to produce the key ''%2'', got keys: %3', Config, KeyText, JoinKeys(Settings)));
        Assert.AreEqual(ExpectedValue, Settings.Get(KeyText), StrSubstNo('Wrong value for key ''%2'' after parsing ''%1''', Config, KeyText));
    end;

    local procedure JoinKeys(Settings: Dictionary of [Text, Text]): Text
    var
        KeyText: Text;
        Listing: Text;
    begin
        foreach KeyText in Settings.Keys() do begin
            if Listing <> '' then
                Listing += ', ';
            Listing += '''' + KeyText + '''';
        end;
        if Listing = '' then
            exit('(none)');
        exit(Listing);
    end;
}
