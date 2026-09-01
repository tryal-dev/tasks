codeunit 50900 "Receipt Formatter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShortDescriptionIsPaddedToTwentyColumns()
    var
        ReceiptFormatter: Codeunit "Receipt Formatter";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('Coffee              ' + '        3.50', ReceiptFormatter.ReceiptLine('Coffee', 3.5),
            'Expected the description left-aligned in columns 1-20 and 3.50 right-aligned in columns 21-32');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedDescriptionStaysLeftAlignedInItsColumn()
    var
        ReceiptFormatter: Codeunit "Receipt Formatter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Description: Text;
    begin
        Description := Any.AlphabeticText(Any.IntegerInRange(1, 19));

        Assert.AreEqual(Description + PadStr('', 20 - StrLen(Description), ' ') + '        7.25', ReceiptFormatter.ReceiptLine(Description, 7.25),
            StrSubstNo('Expected the %1-character description "%2" followed by spaces up to column 20, then 7.25 right-aligned in 12 columns', StrLen(Description), Description));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LongDescriptionIsCutToTwentyColumns()
    var
        ReceiptFormatter: Codeunit "Receipt Formatter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Description: Text;
    begin
        Description := Any.AlphabeticText(35);

        Assert.AreEqual(CopyStr(Description, 1, 20) + '       12.00', ReceiptFormatter.ReceiptLine(Description, 12),
            StrSubstNo('Expected the 35-character description "%1" to be cut to its first 20 characters so the amount still starts in column 21', Description));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyDescriptionLeavesTwentyBlankColumns()
    var
        ReceiptFormatter: Codeunit "Receipt Formatter";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('                    ' + '        0.99', ReceiptFormatter.ReceiptLine('', 0.99),
            'Expected an empty description to leave 20 spaces before the amount column');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WholeAmountStillShowsTwoDecimals()
    var
        ReceiptFormatter: Codeunit "Receipt Formatter";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('Bagel               ' + '        2.00', ReceiptFormatter.ReceiptLine('Bagel', 2),
            'Expected the whole-number amount 2 to print as 2.00 - exactly two decimals, always');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeAmountKeepsItsSignAndTwoDecimals()
    var
        ReceiptFormatter: Codeunit "Receipt Formatter";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('Refund              ' + '       -3.50', ReceiptFormatter.ReceiptLine('Refund', -3.5),
            'Expected -3.5 to print as -3.50 with the minus sign directly in front of the first digit');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LargeAmountHasNoThousandsSeparator()
    var
        ReceiptFormatter: Codeunit "Receipt Formatter";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('Catering            ' + '  1234567.80', ReceiptFormatter.ReceiptLine('Catering', 1234567.8),
            'Expected 1234567.8 to print as 1234567.80 - a period as decimal separator and no thousands separator');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LineIsAlwaysThirtyTwoCharacters()
    var
        ReceiptFormatter: Codeunit "Receipt Formatter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Description: Text;
        Amount: Decimal;
        Line: Text;
    begin
        Description := Any.AlphabeticText(Any.IntegerInRange(1, 40));
        Amount := Any.IntegerInRange(-99999999, 99999999) + Any.IntegerInRange(0, 99) / 100;

        Line := ReceiptFormatter.ReceiptLine(Description, Amount);

        Assert.AreEqual(32, StrLen(Line),
            StrSubstNo('Expected a 32-character line for description "%1" and amount %2, got [%3]', Description, Amount, Line));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DocumentNoZeroPadsTheSequenceOnTheLeft()
    var
        ReceiptFormatter: Codeunit "Receipt Formatter";
        Assert: Codeunit Assert;
        Actual: Text;
    begin
        Actual := ReceiptFormatter.DocumentNo('INV', 42);

        Assert.AreEqual('INV-00042', Actual,
            'Expected sequence 42 to be zero-padded in front to five digits - the zeros go before the number, not after it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DocumentNoUsesTheGivenPrefixAndSequence()
    var
        ReceiptFormatter: Codeunit "Receipt Formatter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Prefix: Code[10];
        Seq: Integer;
        Digits: Text;
        Actual: Text;
    begin
        Prefix := CopyStr(UpperCase(Any.AlphabeticText(Any.IntegerInRange(1, 10))), 1, 10);
        Seq := Any.IntegerInRange(1, 99999);
        Digits := Format(Seq, 0, 9);

        Actual := ReceiptFormatter.DocumentNo(Prefix, Seq);

        Assert.AreEqual(Prefix + '-' + PadStr('', 5 - StrLen(Digits), '0') + Digits, Actual,
            StrSubstNo('Expected prefix %1, a hyphen, and sequence %2 padded with leading zeros to five digits', Prefix, Seq));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DocumentNoKeepsAllDigitsOfASixDigitSequence()
    var
        ReceiptFormatter: Codeunit "Receipt Formatter";
        Assert: Codeunit Assert;
        Actual: Text;
    begin
        Actual := ReceiptFormatter.DocumentNo('INV', 100000);

        Assert.AreEqual('INV-100000', Actual,
            'Expected a six-digit sequence to keep all six digits - five is the minimum width, not a cut-off');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DocumentNoWithExactlyFiveDigitsGetsNoPadding()
    var
        ReceiptFormatter: Codeunit "Receipt Formatter";
        Assert: Codeunit Assert;
        Actual: Text;
    begin
        Actual := ReceiptFormatter.DocumentNo('RCP', 99999);

        Assert.AreEqual('RCP-99999', Actual,
            'Expected a five-digit sequence to print as-is, without any extra zero');
    end;
}
