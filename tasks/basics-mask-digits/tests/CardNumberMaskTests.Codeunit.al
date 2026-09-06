codeunit 50900 "Card Number Mask Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MasksAllButTheLastFourDigitsAndKeepsHyphens()
    var
        CardNumberMask: Codeunit "Card Number Mask";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('****-****-****-1234', CardNumberMask.MaskDigits('4111-1111-1111-1234'),
            'Expected the first twelve digits to become * and the last four to stay, with every hyphen left where it was');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MasksAGeneratedNumberAndKeepsSpaces()
    var
        CardNumberMask: Codeunit "Card Number Mask";
        Assert: Codeunit Assert;
        LastGroup: Text;
        Input: Text;
    begin
        LastGroup := RandomDigits(4);
        Input := RandomDigits(4) + ' ' + RandomDigits(4) + ' ' + RandomDigits(4) + ' ' + LastGroup;

        Assert.AreEqual('**** **** **** ' + LastGroup, CardNumberMask.MaskDigits(Input),
            StrSubstNo('Expected every digit of %1 except the last four to become *, with the three spaces left where they were', Input));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountsDigitsNotCharactersWhenKeepingTheLastFour()
    var
        CardNumberMask: Codeunit "Card Number Mask";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('**-*4-567', CardNumberMask.MaskDigits('12-34-567'),
            'Expected the last four DIGITS (4, 5, 6 and 7) to stay - the separators do not count towards the four, so the 4 before the second hyphen must survive');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsLettersInPlace()
    var
        CardNumberMask: Codeunit "Card Number Mask";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('GB** WEST **** **** **54 32', CardNumberMask.MaskDigits('GB82 WEST 1234 5698 7654 32'),
            'Expected letters to pass through untouched and only digits to be masked - the last four digits are the 5 and 4 before the final space and the 3 and 2 after it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsPunctuationInPlace()
    var
        CardNumberMask: Codeunit "Card Number Mask";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('+* (***) ***-9999', CardNumberMask.MaskDigits('+1 (555) 010-9999'),
            'Expected the plus sign, the parentheses, the space and the hyphen to stay exactly where they were while every digit before the last four becomes *');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesExactlyFourDigitsUnchanged()
    var
        CardNumberMask: Codeunit "Card Number Mask";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('12-34', CardNumberMask.MaskDigits('12-34'),
            'Expected an input with exactly four digits to come back unchanged - all four are the last four');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesFewerThanFourDigitsUnchanged()
    var
        CardNumberMask: Codeunit "Card Number Mask";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('Ext. 42', CardNumberMask.MaskDigits('Ext. 42'),
            'Expected an input with fewer than four digits to come back unchanged - there is nothing before the last four to mask');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MasksOnlyTheFirstDigitOfFive()
    var
        CardNumberMask: Codeunit "Card Number Mask";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('*2345', CardNumberMask.MaskDigits('12345'),
            'Expected exactly one * for a five-digit input: only the digit before the last four is masked');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsEmptyTextForEmptyInput()
    var
        CardNumberMask: Codeunit "Card Number Mask";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', CardNumberMask.MaskDigits(''),
            'Expected an empty input to return the empty text without raising an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesTextWithoutDigitsUnchanged()
    var
        CardNumberMask: Codeunit "Card Number Mask";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Input: Text;
    begin
        Input := 'No card on file for ' + Any.AlphabeticText(8);

        Assert.AreEqual(Input, CardNumberMask.MaskDigits(Input),
            'Expected a text without any digit to come back unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DigitCountCountsTheDigitsOfACardNumber()
    var
        CardNumberMask: Codeunit "Card Number Mask";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(16, CardNumberMask.DigitCount('4111-1111-1111-1234'),
            'Expected DigitCount to count the sixteen digits and not the three hyphens');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DigitCountIgnoresLettersSpacesAndPunctuation()
    var
        CardNumberMask: Codeunit "Card Number Mask";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(11, CardNumberMask.DigitCount('+1 (555) 010-9999 ext. A'),
            'Expected DigitCount to count only the characters 0 to 9 - the plus sign, parentheses, spaces, hyphen, dot and letters are not digits');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DigitCountIsZeroForEmptyText()
    var
        CardNumberMask: Codeunit "Card Number Mask";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(0, CardNumberMask.DigitCount(''),
            'Expected DigitCount of the empty text to be 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DigitCountIsZeroWithoutDigits()
    var
        CardNumberMask: Codeunit "Card Number Mask";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        Assert.AreEqual(0, CardNumberMask.DigitCount(Any.AlphabeticText(12) + ' - ' + Any.AlphabeticText(5)),
            'Expected DigitCount of a text made of letters, spaces and a hyphen to be 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DigitCountMatchesAGeneratedNumberOfDigits()
    var
        CardNumberMask: Codeunit "Card Number Mask";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FirstRun: Integer;
        SecondRun: Integer;
        Input: Text;
    begin
        FirstRun := Any.IntegerInRange(1, 12);
        SecondRun := Any.IntegerInRange(1, 12);
        Input := Any.AlphabeticText(3) + RandomDigits(FirstRun) + '/' + Any.AlphabeticText(2) + ' ' + RandomDigits(SecondRun);

        Assert.AreEqual(FirstRun + SecondRun, CardNumberMask.DigitCount(Input),
            StrSubstNo('Expected DigitCount of %1 to be the number of digit characters it contains', Input));
    end;

    local procedure RandomDigits(Count: Integer): Text
    var
        Any: Codeunit Any;
        Digits: Text;
        Index: Integer;
    begin
        for Index := 1 to Count do
            Digits += Format(Any.IntegerInRange(0, 9));
        exit(Digits);
    end;
}
