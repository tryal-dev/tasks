codeunit 50900 "EAN Check Digit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ComputesTheTextbookCheckDigit()
    var
        EANCheckDigit: Codeunit "EAN Check Digit";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(1, EANCheckDigit.CalculateCheckDigit('400638133393'),
            'Expected the check digit of 400638133393 to be 1 — the weighted sum is 20 + 3 x 23 = 89, and 89 needs 1 to reach 90');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CheckDigitIsZeroWhenTheWeightedSumEndsInZero()
    var
        EANCheckDigit: Codeunit "EAN Check Digit";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(0, EANCheckDigit.CalculateCheckDigit('401234567897'),
            'Expected the check digit of 401234567897 to be 0 — its weighted sum is 110, already a multiple of 10, so there is nothing to add');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WrongLengthInputToCalculateIsAnError()
    var
        EANCheckDigit: Codeunit "EAN Check Digit";
        Assert: Codeunit Assert;
    begin
        asserterror EANCheckDigit.CalculateCheckDigit('4006381333931');
        Assert.ExpectedError('12 digits');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NonDigitInputToCalculateIsAnError()
    var
        EANCheckDigit: Codeunit "EAN Check Digit";
        Assert: Codeunit Assert;
    begin
        asserterror EANCheckDigit.CalculateCheckDigit('4006A8133393');
        Assert.ExpectedError('12 digits');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SpaceOrSignInputToCalculateIsAnError()
    var
        EANCheckDigit: Codeunit "EAN Check Digit";
        Assert: Codeunit Assert;
    begin
        // A whole-string Evaluate gate lets these through: it trims whitespace and accepts a leading sign.
        asserterror EANCheckDigit.CalculateCheckDigit(' 40063813339');
        Assert.ExpectedError('12 digits');
        asserterror EANCheckDigit.CalculateCheckDigit('+40063813339');
        Assert.ExpectedError('12 digits');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsAGenuineBarcode()
    var
        EANCheckDigit: Codeunit "EAN Check Digit";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(EANCheckDigit.IsValid('4006381333931'),
            'Expected 4006381333931 to be valid — its 13th digit 1 is exactly the check digit of the first twelve');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsABarcodeWithZeroCheckDigit()
    var
        EANCheckDigit: Codeunit "EAN Check Digit";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(EANCheckDigit.IsValid('4012345678970'),
            'Expected 4012345678970 to be valid — the weighted sum of the first twelve digits ends in 0, so the check digit is 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsEveryWrongCheckDigit()
    var
        EANCheckDigit: Codeunit "EAN Check Digit";
        Assert: Codeunit Assert;
        WrongDigit: Integer;
    begin
        for WrongDigit := 0 to 9 do
            if WrongDigit <> 1 then
                Assert.IsFalse(EANCheckDigit.IsValid('400638133393' + Format(WrongDigit)),
                    StrSubstNo('Expected 400638133393%1 to be invalid — the only correct check digit for these twelve digits is 1', WrongDigit));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsWrongLengthWithoutError()
    var
        EANCheckDigit: Codeunit "EAN Check Digit";
        Assert: Codeunit Assert;
    begin
        Assert.IsFalse(EANCheckDigit.IsValid('400638133393'),
            'Expected the 12-character code 400638133393 to be invalid — an EAN-13 barcode is exactly 13 digits');
        Assert.IsFalse(EANCheckDigit.IsValid('40063813339310'),
            'Expected the 14-character code 40063813339310 to be invalid even though its first 13 characters form a valid barcode');
        Assert.IsFalse(EANCheckDigit.IsValid(''),
            'Expected the empty text to be invalid');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsNonDigitCharactersWithoutError()
    var
        EANCheckDigit: Codeunit "EAN Check Digit";
        Assert: Codeunit Assert;
    begin
        Assert.IsFalse(EANCheckDigit.IsValid('4OO6381333931'),
            'Expected 4OO6381333931 to be invalid — the letter O is not the digit 0');
        Assert.IsFalse(EANCheckDigit.IsValid('400638133393a'),
            'Expected 400638133393a to be invalid — the check digit position holds a letter');
        Assert.IsFalse(EANCheckDigit.IsValid('+400638133931'),
            'Expected +400638133931 to be invalid — a plus sign is not a digit, and IsValid must return false rather than raise an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomTwelveDigitsGetTheStandardCheckDigit()
    var
        EANCheckDigit: Codeunit "EAN Check Digit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FirstTwelve: Text;
        i: Integer;
    begin
        for i := 1 to 12 do
            FirstTwelve += Format(Any.IntegerInRange(0, 9));

        Assert.AreEqual(StandardCheckDigit(FirstTwelve), EANCheckDigit.CalculateCheckDigit(FirstTwelve),
            StrSubstNo('Expected the EAN-13 check digit defined by the standard for the generated digits %1', FirstTwelve));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomValidBarcodePassesValidation()
    var
        EANCheckDigit: Codeunit "EAN Check Digit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FirstTwelve: Text;
        Barcode: Text;
        i: Integer;
    begin
        for i := 1 to 12 do
            FirstTwelve += Format(Any.IntegerInRange(0, 9));
        Barcode := FirstTwelve + Format(StandardCheckDigit(FirstTwelve));

        Assert.IsTrue(EANCheckDigit.IsValid(Barcode),
            StrSubstNo('Expected the generated barcode %1 to be valid — its last digit is the check digit of the first twelve', Barcode));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomCorruptedDigitFailsValidation()
    var
        EANCheckDigit: Codeunit "EAN Check Digit";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FirstTwelve: Text;
        Barcode: Text;
        Corrupted: Text;
        Position: Integer;
        Delta: Integer;
        i: Integer;
    begin
        for i := 1 to 12 do
            FirstTwelve += Format(Any.IntegerInRange(0, 9));
        Barcode := FirstTwelve + Format(StandardCheckDigit(FirstTwelve));
        // Both weights (1 and 3) are coprime with 10, so changing any single
        // digit — data or check — always breaks the checksum.
        Position := Any.IntegerInRange(1, 13);
        Delta := Any.IntegerInRange(1, 9);
        for i := 1 to 13 do
            if i = Position then
                Corrupted += Format((DigitAt(Barcode, i) + Delta) mod 10)
            else
                Corrupted += Format(DigitAt(Barcode, i));

        Assert.IsFalse(EANCheckDigit.IsValid(Corrupted),
            StrSubstNo('Expected %1 to be invalid — it is the valid barcode %2 with the digit in position %3 changed', Corrupted, Barcode, Position));
    end;

    local procedure StandardCheckDigit(FirstTwelve: Text): Integer
    var
        WeightedSum: Integer;
        i: Integer;
    begin
        for i := 1 to 12 do
            if i mod 2 = 0 then
                WeightedSum += 3 * DigitAt(FirstTwelve, i)
            else
                WeightedSum += DigitAt(FirstTwelve, i);
        exit((10 - WeightedSum mod 10) mod 10);
    end;

    local procedure DigitAt(Input: Text; Position: Integer): Integer
    var
        Digit: Integer;
    begin
        Evaluate(Digit, CopyStr(Input, Position, 1));
        exit(Digit);
    end;
}
