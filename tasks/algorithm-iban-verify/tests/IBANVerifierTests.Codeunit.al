codeunit 50900 "IBAN Verifier Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsAKnownValidIbanWithSpaces()
    var
        IBANVerifier: Codeunit "IBAN Verifier";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(IBANVerifier.IsValid('GB82 WEST 1234 5698 7654 32'),
            'Expected the valid IBAN GB82 WEST 1234 5698 7654 32 to be accepted after removing the grouping spaces');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsLowercaseGroupedInput()
    var
        IBANVerifier: Codeunit "IBAN Verifier";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(IBANVerifier.IsValid('de89 3704 0044 0532 0130 00'),
            'Expected the lowercase spaced input de89 3704 0044 0532 0130 00 to be normalized to DE89370400440532013000 and accepted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsTheShortestRealWorldIban()
    var
        IBANVerifier: Codeunit "IBAN Verifier";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(IBANVerifier.IsValid('NO9386011117947'),
            'Expected the 15-character Norwegian IBAN NO9386011117947 — exactly at the minimum length — to be accepted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsALongIbanWithLettersInTheAccountPart()
    var
        IBANVerifier: Codeunit "IBAN Verifier";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(IBANVerifier.IsValid('MT84 MALT 0110 0001 2345 MTLC AST0 01S'),
            'Expected the 31-character Maltese IBAN to be accepted — its expanded number is far too large for any integer type, so the remainder must be carried through the string');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsAThirtyFourCharacterIban()
    var
        IBANVerifier: Codeunit "IBAN Verifier";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(IBANVerifier.IsValid('GB10WEST12345698765432001122334455'),
            'Expected the 34-character IBAN GB10WEST12345698765432001122334455 — exactly at the maximum length — to be accepted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsWrongCheckDigits()
    var
        IBANVerifier: Codeunit "IBAN Verifier";
        Assert: Codeunit Assert;
    begin
        Assert.IsFalse(IBANVerifier.IsValid('GB83 WEST 1234 5698 7654 32'),
            'Expected GB83 WEST 1234 5698 7654 32 to be rejected — the check digits 83 do not match the account (82 would), so the mod-97 remainder is not 1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsASingleDigitTypo()
    var
        IBANVerifier: Codeunit "IBAN Verifier";
        Assert: Codeunit Assert;
    begin
        Assert.IsFalse(IBANVerifier.IsValid('DE89 3704 0044 0532 0130 01'),
            'Expected the typo DE89...013001 (last digit flipped from the valid ...013000) to be caught by the mod-97 check');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsFourteenCharactersEvenWithRemainderOne()
    var
        IBANVerifier: Codeunit "IBAN Verifier";
        Assert: Codeunit Assert;
    begin
        Assert.IsFalse(IBANVerifier.IsValid('GB57WEST123456'),
            'Expected the 14-character GB57WEST123456 to be rejected: it is below the 15-character minimum even though its mod-97 remainder is 1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsThirtyFiveCharactersEvenWithRemainderOne()
    var
        IBANVerifier: Codeunit "IBAN Verifier";
        Assert: Codeunit Assert;
    begin
        Assert.IsFalse(IBANVerifier.IsValid('GB73WEST12345698765432001122334455X'),
            'Expected the 35-character candidate to be rejected: it is above the 34-character maximum even though its mod-97 remainder is 1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsDigitsInTheCountryCode()
    var
        IBANVerifier: Codeunit "IBAN Verifier";
        Assert: Codeunit Assert;
    begin
        Assert.IsFalse(IBANVerifier.IsValid('1225WEST123456987654'),
            'Expected 1225WEST123456987654 to be rejected: characters 1-2 must be letters, and passing the mod-97 arithmetic (this input does) is not enough');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsLettersInTheCheckDigitPositions()
    var
        IBANVerifier: Codeunit "IBAN Verifier";
        Assert: Codeunit Assert;
    begin
        Assert.IsFalse(IBANVerifier.IsValid('GBAKWEST12345698765432'),
            'Expected GBAKWEST12345698765432 to be rejected: characters 3-4 must be digits, and passing the mod-97 arithmetic (this input does) is not enough');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsHyphensAsSeparators()
    var
        IBANVerifier: Codeunit "IBAN Verifier";
        Assert: Codeunit Assert;
    begin
        Assert.IsFalse(IBANVerifier.IsValid('GB82-WEST-1234-5698-7654-32'),
            'Expected the hyphen-separated input to be rejected: only spaces are removed during normalization, so the hyphens fail the structure gate');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsEmptyInput()
    var
        IBANVerifier: Codeunit "IBAN Verifier";
        Assert: Codeunit Assert;
    begin
        Assert.IsFalse(IBANVerifier.IsValid(''),
            'Expected the empty string to be rejected without raising an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsARandomlyGeneratedIban()
    var
        IBANVerifier: Codeunit "IBAN Verifier";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CountryCode: Text;
        BBAN: Text;
        Iban: Text;
    begin
        CountryCode := UpperCase(Any.AlphabeticText(2));
        BBAN := UpperCase(Any.AlphanumericText(Any.IntegerInRange(11, 30)));
        Iban := CountryCode + ComputeCheckDigits(CountryCode, BBAN) + BBAN;

        Assert.IsTrue(IBANVerifier.IsValid(Iban),
            StrSubstNo('Expected the generated IBAN %1, whose check digits were computed per ISO 13616, to be accepted', Iban));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsARandomIbanWithShiftedCheckDigits()
    var
        IBANVerifier: Codeunit "IBAN Verifier";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CountryCode: Text;
        BBAN: Text;
        Iban: Text;
        CheckValue: Integer;
    begin
        CountryCode := UpperCase(Any.AlphabeticText(2));
        BBAN := UpperCase(Any.AlphanumericText(Any.IntegerInRange(11, 30)));
        Evaluate(CheckValue, ComputeCheckDigits(CountryCode, BBAN));
        // correct check digits are 02..98, so +1 keeps two digits and moves the remainder off 1
        Iban := CountryCode + TwoDigits(CheckValue + 1) + BBAN;

        Assert.IsFalse(IBANVerifier.IsValid(Iban),
            StrSubstNo('Expected %1 to be rejected — its check digits are off by one from the correct value', Iban));
    end;

    local procedure ComputeCheckDigits(CountryCode: Text; BBAN: Text): Text
    begin
        exit(TwoDigits(98 - Mod97(BBAN + CountryCode + '00')));
    end;

    local procedure TwoDigits(Value: Integer): Text
    begin
        if Value < 10 then
            exit('0' + Format(Value));
        exit(Format(Value));
    end;

    local procedure Mod97(Input: Text): Integer
    var
        Remainder: Integer;
        Index: Integer;
        Ch: Char;
        ZeroChar: Char;
        AChar: Char;
    begin
        ZeroChar := '0';
        AChar := 'A';
        for Index := 1 to StrLen(Input) do begin
            Ch := Input[Index];
            if (Ch >= '0') and (Ch <= '9') then
                Remainder := (Remainder * 10 + (Ch - ZeroChar)) mod 97
            else
                Remainder := (Remainder * 100 + (Ch - AChar + 10)) mod 97;
        end;
        exit(Remainder);
    end;
}
