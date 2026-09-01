codeunit 50900 "Amount In Words Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroReadsAsZeroAndZeroCents()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('zero and 00/100', AmountInWords.ToWords(0),
            'Expected a zero amount to read as the word zero followed by the always-present 00/100 fraction');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SpellsTheCheckExampleFromTheStatement()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('one thousand two hundred thirty-four and 56/100', AmountInWords.ToWords(1234.56),
            'Expected 1234.56 to be spelled exactly as on the check line from the statement');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SpellsARandomSingleDigitAmount()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Digit: Integer;
    begin
        Digit := Any.IntegerInRange(1, 9);

        Assert.AreEqual(NumberWord(Digit) + ' and 00/100', AmountInWords.ToWords(Digit),
            StrSubstNo('Expected the whole amount %1 to be a single word plus 00/100', Digit));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EveryTeenIsASingleWord()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
        Value: Integer;
    begin
        for Value := 10 to 19 do
            Assert.AreEqual(NumberWord(Value) + ' and 00/100', AmountInWords.ToWords(Value),
                StrSubstNo('Expected %1 to be spelled as its own single word — teens are never built from a tens word', Value));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FortyHasNoU()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('forty-four and 00/100', AmountInWords.ToWords(44),
            'Expected 44 to use the spelling forty (no u), hyphenated with four');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoundTensCarryNoHyphenOrExtraWord()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('sixty and 00/100', AmountInWords.ToWords(60),
            'Expected a round ten to be a single word — no hyphen and no unit word after it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SpellsRandomCompoundTensWithHyphenAndCents()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TensDigit: Integer;
        OnesDigit: Integer;
        Cents: Integer;
    begin
        TensDigit := Any.IntegerInRange(2, 9);
        OnesDigit := Any.IntegerInRange(1, 9);
        Cents := Any.IntegerInRange(10, 99);

        Assert.AreEqual(
            TensWord(TensDigit) + '-' + NumberWord(OnesDigit) + ' and ' + Format(Cents) + '/100',
            AmountInWords.ToWords(TensDigit * 10 + OnesDigit + Cents / 100),
            StrSubstNo('Expected %1.%2 to hyphenate the tens and units words and carry the cents over 100', TensDigit * 10 + OnesDigit, Cents));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SpellsRandomHundredsCombination()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        HundredsDigit: Integer;
        TensDigit: Integer;
        OnesDigit: Integer;
    begin
        HundredsDigit := Any.IntegerInRange(1, 9);
        TensDigit := Any.IntegerInRange(2, 9);
        OnesDigit := Any.IntegerInRange(1, 9);

        Assert.AreEqual(
            NumberWord(HundredsDigit) + ' hundred ' + TensWord(TensDigit) + '-' + NumberWord(OnesDigit) + ' and 00/100',
            AmountInWords.ToWords(HundredsDigit * 100 + TensDigit * 10 + OnesDigit),
            StrSubstNo('Expected %1 to read as digit word, hundred, then the hyphenated remainder', HundredsDigit * 100 + TensDigit * 10 + OnesDigit));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoundHundredsCarryNoTrailingWordOrSpace()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        HundredsDigit: Integer;
    begin
        HundredsDigit := Any.IntegerInRange(1, 9);

        Assert.AreEqual(NumberWord(HundredsDigit) + ' hundred and 00/100', AmountInWords.ToWords(HundredsDigit * 100),
            StrSubstNo('Expected the round hundred %1 to end at the word hundred — no extra space or zero word before the fraction', HundredsDigit * 100));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HundredsUseNoAndInsideTheWholePart()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('one hundred five and 00/100', AmountInWords.ToWords(105),
            'Expected 105 to read one hundred five — the word and belongs only before the cents fraction');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CentsBelowTenArePaddedToTwoDigits()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('three and 05/100', AmountInWords.ToWords(3.05),
            'Expected 5 cents to be written as the two-digit 05/100, not 5/100');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CentsOnlyAmountKeepsTheZeroWholePart()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('zero and 99/100', AmountInWords.ToWords(0.99),
            'Expected an amount below one to keep the word zero before the cents fraction');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OneMillionOmitsTheZeroGroups()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('one million and 00/100', AmountInWords.ToWords(1000000),
            'Expected 1,000,000 to read one million — groups whose value is zero are omitted entirely');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyThousandsGroupIsSkipped()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('two million fifteen and 00/100', AmountInWords.ToWords(2000015),
            'Expected 2,000,015 to skip the empty thousands group and join million directly to fifteen');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SpellsTheLargestSupportedAmount()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(
            'nine hundred ninety-nine million nine hundred ninety-nine thousand nine hundred ninety-nine and 99/100',
            AmountInWords.ToWords(999999999.99),
            'Expected the largest supported amount 999,999,999.99 to spell out all three groups with their scale words');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeAmountIsRejectedAsOutOfRange()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
    begin
        asserterror AmountInWords.ToWords(-0.01);

        Assert.ExpectedError('out of range');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OneBillionIsRejectedAsOutOfRange()
    var
        AmountInWords: Codeunit "Amount In Words";
        Assert: Codeunit Assert;
    begin
        asserterror AmountInWords.ToWords(1000000000.0);

        Assert.ExpectedError('out of range');
    end;

    local procedure NumberWord(Value: Integer): Text
    begin
        case Value of
            1:
                exit('one');
            2:
                exit('two');
            3:
                exit('three');
            4:
                exit('four');
            5:
                exit('five');
            6:
                exit('six');
            7:
                exit('seven');
            8:
                exit('eight');
            9:
                exit('nine');
            10:
                exit('ten');
            11:
                exit('eleven');
            12:
                exit('twelve');
            13:
                exit('thirteen');
            14:
                exit('fourteen');
            15:
                exit('fifteen');
            16:
                exit('sixteen');
            17:
                exit('seventeen');
            18:
                exit('eighteen');
            19:
                exit('nineteen');
        end;
    end;

    local procedure TensWord(TensDigit: Integer): Text
    begin
        case TensDigit of
            2:
                exit('twenty');
            3:
                exit('thirty');
            4:
                exit('forty');
            5:
                exit('fifty');
            6:
                exit('sixty');
            7:
                exit('seventy');
            8:
                exit('eighty');
            9:
                exit('ninety');
        end;
    end;
}
