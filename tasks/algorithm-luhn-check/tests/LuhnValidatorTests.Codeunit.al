codeunit 50900 "Luhn Validator Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidCardNumberPassesTheChecksum()
    var
        LuhnValidator: Codeunit "Luhn Validator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A well-formed 16-digit card number with a correct check digit is valid
        Assert.IsTrue(LuhnValidator.IsValid('4539 3195 0343 6467'),
            'Expected the card number 4539 3195 0343 6467 to be valid — its Luhn sum is 80, divisible by 10');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InvalidCardNumberFailsTheChecksum()
    var
        LuhnValidator: Codeunit "Luhn Validator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A 16-digit card number whose Luhn sum is not divisible by 10 is invalid
        Assert.IsFalse(LuhnValidator.IsValid('8273 1232 7352 0569'),
            'Expected the card number 8273 1232 7352 0569 to be invalid — its Luhn sum is 57, not divisible by 10');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleDigitIsInvalid()
    var
        LuhnValidator: Codeunit "Luhn Validator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Inputs of one character are invalid even when the sum is divisible by 10
        Assert.IsFalse(LuhnValidator.IsValid('0'),
            'Expected the single digit "0" to be invalid — after ignoring spaces the input must be at least two characters long, even though its sum 0 is divisible by 10');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleDigitWithSpacesIsInvalid()
    var
        LuhnValidator: Codeunit "Luhn Validator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Spaces do not count towards the minimum length
        Assert.IsFalse(LuhnValidator.IsValid(' 0'),
            'Expected " 0" to be invalid — spaces are ignored, so only one character is left and the input is too short');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyInputIsInvalid()
    var
        LuhnValidator: Codeunit "Luhn Validator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The empty string is invalid, not an error
        Assert.IsFalse(LuhnValidator.IsValid(''),
            'Expected the empty string to be invalid — it is shorter than two characters');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SpacesInsideTheNumberAreIgnored()
    var
        LuhnValidator: Codeunit "Luhn Validator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Spaces scattered through an otherwise valid number do not break validation
        Assert.IsTrue(LuhnValidator.IsValid(' 0 5 9 '),
            'Expected " 0 5 9 " to be valid — spaces are ignored, and 059 sums to 10');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PunctuationMakesTheNumberInvalid()
    var
        LuhnValidator: Codeunit "Luhn Validator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Only spaces are ignored — dashes are not
        Assert.IsFalse(LuhnValidator.IsValid('055-444-285'),
            'Expected "055-444-285" to be invalid — only spaces may be ignored, and a dash is not a space ("055 444 285" is the valid spelling)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LettersMakeTheNumberInvalid()
    var
        LuhnValidator: Codeunit "Luhn Validator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A letter anywhere in the input makes it invalid
        Assert.IsFalse(LuhnValidator.IsValid('055a 444 285'),
            'Expected "055a 444 285" to be invalid — a letter is not a digit and must not be silently dropped');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DoubledDigitAboveNineIsReducedByNine()
    var
        LuhnValidator: Codeunit "Luhn Validator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Doubling the 9 in 091 gives 18, which must count as 9
        Assert.IsTrue(LuhnValidator.IsValid('091'),
            'Expected "091" to be valid: 1 + (9 doubled = 18, minus 9 = 9) + 0 = 10 — summing the doubled 18 as-is gives 19 and wrongly rejects the number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EvenLengthNumberIsDoubledFromTheRight()
    var
        LuhnValidator: Codeunit "Luhn Validator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] On an even-length number, doubling from the left picks the wrong digits
        Assert.IsTrue(LuhnValidator.IsValid('095 245 88'),
            'Expected "095 245 88" to be valid — the 2nd, 4th, 6th and 8th digits counted from the RIGHT are doubled; doubling every second digit from the left wrongly rejects this even-length number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AllZerosLongerThanOneDigitAreValid()
    var
        LuhnValidator: Codeunit "Luhn Validator";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A sum of 0 is divisible by 10
        Assert.IsTrue(LuhnValidator.IsValid('0000 0'),
            'Expected "0000 0" to be valid — its sum is 0, and 0 is divisible by 10');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomNumberWithItsCheckDigitIsValid()
    var
        LuhnValidator: Codeunit "Luhn Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Digits: Text;
        CheckDigit: Integer;
        i: Integer;
    begin
        // [SCENARIO] A generated number closed with its correct check digit is valid
        for i := 1 to 11 do
            Digits += Format(Any.IntegerInRange(0, 9));
        CheckDigit := (10 - LuhnSumOfDigits(Digits + '0') mod 10) mod 10;

        Assert.IsTrue(LuhnValidator.IsValid(Digits + Format(CheckDigit)),
            StrSubstNo('Expected the generated number %1 to be valid — its last digit was computed so the Luhn sum is divisible by 10', Digits + Format(CheckDigit)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomNumberWithACorruptedCheckDigitIsInvalid()
    var
        LuhnValidator: Codeunit "Luhn Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Digits: Text;
        CheckDigit: Integer;
        i: Integer;
    begin
        // [SCENARIO] Bumping the correct check digit by one breaks the checksum
        for i := 1 to 11 do
            Digits += Format(Any.IntegerInRange(0, 9));
        CheckDigit := ((10 - LuhnSumOfDigits(Digits + '0') mod 10) mod 10 + 1) mod 10;

        Assert.IsFalse(LuhnValidator.IsValid(Digits + Format(CheckDigit)),
            StrSubstNo('Expected the generated number %1 to be invalid — its last digit is one off from the correct check digit, so the Luhn sum is not divisible by 10', Digits + Format(CheckDigit)));
    end;

    local procedure LuhnSumOfDigits(Digits: Text): Integer
    var
        Digit: Integer;
        Sum: Integer;
        Pos: Integer;
        DoubleThisDigit: Boolean;
    begin
        for Pos := StrLen(Digits) downto 1 do begin
            Digit := Digits[Pos] - '0';
            if DoubleThisDigit then begin
                Digit *= 2;
                if Digit > 9 then
                    Digit -= 9;
            end;
            Sum += Digit;
            DoubleThisDigit := not DoubleThisDigit;
        end;
        exit(Sum);
    end;
}
