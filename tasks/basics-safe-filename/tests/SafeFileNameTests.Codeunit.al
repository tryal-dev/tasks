codeunit 50900 "Safe File Name Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReplacesEachIllegalCharacterWithAnUnderscore()
    var
        SafeFileName: Codeunit "Safe File Name";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('Invoice 1001_2026_ Müller & Co.pdf', SafeFileName.ToSafeFileName('Invoice 1001/2026: Müller & Co', 'pdf', 100),
            'Expected the / and the : to become one underscore each, and the space, the ü and the & to pass through untouched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MapsAllNineIllegalCharactersOneToOne()
    var
        SafeFileName: Codeunit "Safe File Name";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('a_b_c_d_e_f_g_h_i_j.txt', SafeFileName.ToSafeFileName('a\b/c:d*e?f"g<h>i|j', 'txt', 100),
            'Expected every one of the nine illegal characters \ / : * ? " < > | to become exactly one underscore');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsOneUnderscorePerCharacterWhenTheNameIsAllIllegal()
    var
        SafeFileName: Codeunit "Safe File Name";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('_________.pdf', SafeFileName.ToSafeFileName('\/:*?"<>|', 'pdf', 100),
            'Expected a name made of nothing but the nine illegal characters to become nine underscores — the characters are replaced, not deleted, so the stem is not empty');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsNonAsciiLettersUnchanged()
    var
        SafeFileName: Codeunit "Safe File Name";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('Ærøskøbing Straße 日本語 Ünal.docx', SafeFileName.ToSafeFileName('Ærøskøbing Straße 日本語 Ünal', 'docx', 100),
            'Expected letters outside ASCII to pass through untouched — only the nine illegal characters are replaced');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsLettersDigitsCaseAndAllowedPunctuationUnchanged()
    var
        SafeFileName: Codeunit "Safe File Name";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Stem: Text;
    begin
        Stem := 'Report ' + UpperCase(Any.AlphabeticText(6)) + ' 2026 (final) - O''Brien, ' + Any.AlphabeticText(5);

        Assert.AreEqual(Stem + '.xlsx', SafeFileName.ToSafeFileName(Stem, 'xlsx', 100),
            'Expected a name without illegal characters to come back unchanged — case, digits, parentheses, hyphen, apostrophe and comma included');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CollapsesTabsAndRepeatedSpacesToASingleSpace()
    var
        SafeFileName: Codeunit "Safe File Name";
        Assert: Codeunit Assert;
        TabTxt: Text[1];
    begin
        TabTxt[1] := 9;

        Assert.AreEqual('Q1 report final v2 draft.xlsx', SafeFileName.ToSafeFileName('Q1' + TabTxt + TabTxt + 'report   final' + TabTxt + ' v2' + TabTxt + 'draft', 'xlsx', 100),
            'Expected tabs to count as spaces — a single tab between two words becomes one space, and every run of spaces and tabs collapses to one single space');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StripsLeadingAndTrailingSpacesAndDots()
    var
        SafeFileName: Codeunit "Safe File Name";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('v1.2 notes.md', SafeFileName.ToSafeFileName(' ..v1.2 notes . ', 'md', 100),
            'Expected every leading and trailing space and dot to be removed, in any mix, while the dot and the space inside the stem stay');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FallsBackToDocumentForAnEmptyName()
    var
        SafeFileName: Codeunit "Safe File Name";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('document.pdf', SafeFileName.ToSafeFileName('', 'pdf', 100),
            'Expected an empty name to fall back to the stem document');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FallsBackToDocumentWhenOnlySpacesTabsAndDotsRemain()
    var
        SafeFileName: Codeunit "Safe File Name";
        Assert: Codeunit Assert;
        TabTxt: Text[1];
    begin
        TabTxt[1] := 9;

        Assert.AreEqual('document.pdf', SafeFileName.ToSafeFileName(' . ' + TabTxt + '.. ', 'pdf', 100),
            'Expected a name of nothing but spaces, tabs and dots to leave an empty stem and fall back to document');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CutsTheStemSoTheExtensionSurvivesIntact()
    var
        SafeFileName: Codeunit "Safe File Name";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Stem: Text;
    begin
        Stem := Any.AlphabeticText(300);

        Assert.AreEqual(CopyStr(Stem, 1, 96) + '.pdf', SafeFileName.ToSafeFileName(Stem, 'pdf', 100),
            'Expected a 300-character stem to be cut to 96 characters so that stem, dot and extension make exactly 100 — the extension must survive intact');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesANameExactlyAtMaxLengthUntouched()
    var
        SafeFileName: Codeunit "Safe File Name";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Stem: Text;
    begin
        Stem := Any.AlphabeticText(20);

        Assert.AreEqual(Stem + '.xlsx', SafeFileName.ToSafeFileName(Stem, 'xlsx', 25),
            'Expected a name whose stem, dot and extension add up to exactly MaxLength to come back untouched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CutsExactlyOneCharacterWhenOneOverMaxLength()
    var
        SafeFileName: Codeunit "Safe File Name";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Stem: Text;
    begin
        Stem := Any.AlphabeticText(21);

        Assert.AreEqual(CopyStr(Stem, 1, 20) + '.xlsx', SafeFileName.ToSafeFileName(Stem, 'xlsx', 25),
            'Expected a name one character over MaxLength to lose exactly the last character of its stem');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MeasuresTheLengthAfterCleaning()
    var
        SafeFileName: Codeunit "Safe File Name";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Stem: Text;
    begin
        Stem := Any.AlphabeticText(20);

        Assert.AreEqual(Stem + '.xlsx', SafeFileName.ToSafeFileName('   ' + Stem + '   ', 'xlsx', 25),
            'Expected the length cap to apply to the cleaned stem — the leading and trailing spaces are removed first and must not cost stem characters');
    end;
}
