codeunit 50900 "Vendor Code Suggestion Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TakesTheFirstLetterOfEachWord()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('PNG', VendorCodeSuggestion.SuggestVendorNo('Portable Network Graphics'),
            'Expected the initials of the three space-separated words');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SplitsWordsOnHyphens()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('LCD', VendorCodeSuggestion.SuggestVendorNo('Liquid-crystal display'),
            'Expected the hyphen to separate Liquid and crystal into two words, each with its own initial');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UppercasesLowercaseInitials()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('ROR', VendorCodeSuggestion.SuggestVendorNo('ruby on rails'),
            'Expected the initials of an all-lowercase name to come back in uppercase');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsApostropheWordsTogether()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('TGIF', VendorCodeSuggestion.SuggestVendorNo('Thank George It''s Friday!'),
            'Expected It''s to stay one word (initial I) and the exclamation mark to be dropped — punctuation never splits a word');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SkipsWordsWithoutLettersOrDigits()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('OS', VendorCodeSuggestion.SuggestVendorNo('O''Brien & Sons'),
            'Expected O''Brien to be one word with the initial O and the lone & to contribute no initial');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SkipsLeadingPunctuationInsideAWord()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('SHL', VendorCodeSuggestion.SuggestVendorNo('Smith (Holdings) Ltd.'),
            'Expected the initial of (Holdings) to be H — the opening parenthesis is dropped, not taken as the initial');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DropsPunctuationBeyondTheExamples()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('JJ1SIHPG5', VendorCodeSuggestion.SuggestVendorNo('Johnson; Johnson: #1 Supply_Co, "Inc"/Ltd @Home *Plus+ [Group] $5%'),
            'Expected every character that is not a letter or digit to be dropped — ; : # _ , " / @ * + [ ] $ % as much as the punctuation in the examples — and none of them to split a word');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountsDigitsAsInitials()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('7ES', VendorCodeSuggestion.SuggestVendorNo('7-Eleven Stores'),
            'Expected the digit 7 to be the initial of its word, followed by E and S');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DigitsOnlyNameGivesDigitInitials()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('327', VendorCodeSuggestion.SuggestVendorNo('365 24 7'),
            'Expected a name made only of digits to yield the first digit of each word');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IgnoresRepeatedAndTrailingSeparators()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('LCD', VendorCodeSuggestion.SuggestVendorNo('Liquid--crystal  display '),
            'Expected doubled separators and the trailing space to produce no extra initial and no error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyNameGivesEmptyCode()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', VendorCodeSuggestion.SuggestVendorNo(''),
            'Expected the empty name to yield the empty code without raising an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PunctuationOnlyNameGivesEmptyCode()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', VendorCodeSuggestion.SuggestVendorNo('& - ... !!'),
            'Expected a name without any letter or digit to yield the empty code — punctuation is never an initial');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomWordsGiveTheirInitials()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
        Name: Text;
        Initials: Text;
    begin
        Name := RandomName(5, Initials);

        Assert.AreEqual(Initials, VendorCodeSuggestion.SuggestVendorNo(Name),
            StrSubstNo('Expected the initials of the randomly generated name "%1" — it mixes both separators, doubled ones, random punctuation and casing, so hardcoded example outputs cannot pass this', Name));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CutsLongNamesToTwentyInitials()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
        Name: Text;
        Initials: Text;
    begin
        Name := RandomName(25, Initials);

        Assert.AreEqual(CopyStr(Initials, 1, 20), VendorCodeSuggestion.SuggestVendorNo(Name),
            StrSubstNo('Expected the 25 initials of "%1" to be cut to the first 20 — a Code[20] cannot hold more, and overflowing it is an error, not a result', Name));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTheSuggestionWhenNoVendorHasIt()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
        Name: Text;
        Base: Text;
    begin
        Name := RandomName(4, Base);

        Assert.AreEqual(Base, VendorCodeSuggestion.UniqueVendorNo(Name),
            StrSubstNo('Expected the plain initials of "%1" when no vendor carries that number yet', Name));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AppendsDashTwoWhenTheSuggestionIsTaken()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
        Name: Text;
        Base: Text;
    begin
        Name := RandomName(4, Base);
        SeedVendor(Base);

        Assert.AreEqual(Base + '-2', VendorCodeSuggestion.UniqueVendorNo(Name),
            StrSubstNo('Expected the suffix -2 because a vendor numbered %1 already exists', Base));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SkipsEveryTakenSuffixInTurn()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
        Name: Text;
        Base: Text;
    begin
        Name := RandomName(4, Base);
        SeedVendor(Base);
        SeedVendor(Base + '-2');
        SeedVendor(Base + '-3');

        Assert.AreEqual(Base + '-4', VendorCodeSuggestion.UniqueVendorNo(Name),
            StrSubstNo('Expected -4 because %1, %1-2 and %1-3 are all taken — the counter keeps climbing until a free number turns up', Base));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TakesTheFirstFreeSuffixEvenWhenALaterOneIsTaken()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
        Name: Text;
        Base: Text;
    begin
        Name := RandomName(4, Base);
        SeedVendor(Base);
        SeedVendor(Base + '-3');

        Assert.AreEqual(Base + '-2', VendorCodeSuggestion.UniqueVendorNo(Name),
            StrSubstNo('Expected -2 because it is free — a taken %1-3 must not push the result past a free %1-2, and counting vendors that share the base is not the same as finding the first free number', Base));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IgnoresVendorsWhoseNumberMerelyStartsWithTheBase()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
        Name: Text;
        Base: Text;
    begin
        Name := RandomName(4, Base);
        SeedVendor(Base + 'X');

        Assert.AreEqual(Base, VendorCodeSuggestion.UniqueVendorNo(Name),
            StrSubstNo('Expected the plain base %1 — the vendor %1X only starts with it, and only an exact match on "No." counts as taken', Base));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TrimsTheBaseToMakeRoomForTheSuffix()
    var
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
        Name: Text;
        Base: Text;
    begin
        Name := RandomName(20, Base);
        SeedVendor(Base);

        Assert.AreEqual(CopyStr(Base, 1, 18) + '-2', VendorCodeSuggestion.UniqueVendorNo(Name),
            StrSubstNo('Expected the 20-character base %1 to lose its last two characters so that -2 still fits in Code[20]', Base));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesTheVendorTableUntouched()
    var
        Vendor: Record Vendor;
        VendorCodeSuggestion: Codeunit "Vendor Code Suggestion";
        Assert: Codeunit Assert;
        Name: Text;
        Base: Text;
        VendorsBefore: Integer;
    begin
        Name := RandomName(4, Base);
        SeedVendor(Base);
        VendorsBefore := Vendor.Count();

        VendorCodeSuggestion.UniqueVendorNo(Name);

        Assert.AreEqual(VendorsBefore, Vendor.Count(),
            'Expected UniqueVendorNo to only read the Vendor table — the number of vendors changed after the call');
    end;

    local procedure RandomName(WordCount: Integer; var Initials: Text): Text
    var
        Any: Codeunit Any;
        Name: Text;
        Word: Text;
        Slot: Integer;
        i: Integer;
    begin
        // Any is seeded deterministically, so independent draws could leave a
        // shape out of every run for good; instead word shapes, noise positions
        // and separator kinds rotate through their variants from a random slot,
        // which puts each of them into any name of four words or more.
        Initials := '';
        Slot := Any.IntegerInRange(12);
        if Slot mod 2 = 0 then
            Name := RandomSeparator(Any, Slot);
        for i := 1 to WordCount do begin
            Word := RandomWord(Any, Slot + i);
            Initials += UpperCase(CopyStr(Word, 1, 1));
            if i > 1 then
                Name += RandomSeparator(Any, Slot + i);
            Name += WithNoise(Any, Word, Slot + i);
        end;
        if Slot mod 2 = 1 then
            Name += RandomSeparator(Any, Slot);
        exit(Name);
    end;

    local procedure RandomWord(Any: Codeunit Any; Slot: Integer): Text
    var
        Word: Text;
    begin
        Word := Any.AlphabeticText(Any.IntegerInRange(2, 7));
        case Slot mod 3 of
            1:
                Word := UpperCase(CopyStr(Word, 1, 1)) + CopyStr(Word, 2);
            2:
                Word := Format(Any.IntegerInRange(0, 9)) + Word;
        end;
        exit(Word);
    end;

    local procedure WithNoise(Any: Codeunit Any; Word: Text; Slot: Integer): Text
    var
        Cut: Integer;
    begin
        case Slot mod 4 of
            1:
                exit(RandomNoise(Any) + Word);
            2:
                begin
                    Cut := Any.IntegerInRange(1, StrLen(Word) - 1);
                    exit(CopyStr(Word, 1, Cut) + RandomNoise(Any) + CopyStr(Word, Cut + 1));
                end;
            3:
                exit(Word + RandomNoise(Any));
        end;
        exit(Word);
    end;

    local procedure RandomSeparator(Any: Codeunit Any; Slot: Integer): Text
    begin
        case Slot mod 4 of
            1:
                exit('-');
            2:
                if Any.Boolean() then
                    exit('  ')
                else
                    exit('--');
            3:
                exit(' ' + RandomNoise(Any) + '-');
        end;
        exit(' ');
    end;

    local procedure RandomNoise(Any: Codeunit Any): Text
    var
        PunctuationTok: Label '!"#$%&''()*+,./:;<=>?@[\]^_`{|}~', Locked = true;
        Noise: Text;
        i: Integer;
    begin
        for i := 1 to Any.IntegerInRange(1, 2) do
            Noise += CopyStr(PunctuationTok, Any.IntegerInRange(1, StrLen(PunctuationTok)), 1);
        exit(Noise);
    end;

    local procedure SeedVendor(VendorNo: Text)
    var
        Vendor: Record Vendor;
    begin
        Vendor.Init();
        Vendor."No." := CopyStr(VendorNo, 1, MaxStrLen(Vendor."No."));
        Vendor.Insert();
    end;
}
