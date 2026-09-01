codeunit 50900 "Order Text Builder Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Order Text Builder]

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PluralConfirmationNamesTheCustomerFirstAndQuotesTheOrderTwice()
    var
        OrderTextBuilder: Codeunit "Order Text Builder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OrderNo: Code[20];
        CustomerName: Text;
        LineCount: Integer;
    begin
        // [SCENARIO] An order with several lines gets the plural confirmation sentence
        // [GIVEN] a generated order number, customer name and a line count above 1
        OrderNo := CopyStr('SO-' + UpperCase(Any.AlphanumericText(6)), 1, MaxStrLen(OrderNo));
        CustomerName := 'Northwind ' + Any.AlphabeticText(8);
        LineCount := Any.IntegerInRange(2, 999);

        // [WHEN] building the confirmation text
        // [THEN] the customer opens the sentence, the order number appears twice and the count is followed by "lines"
        Assert.AreEqual(
            'Dear ' + CustomerName + ', your order ' + OrderNo + ' with ' + Format(LineCount) + ' lines is confirmed. Please quote ' + OrderNo + ' in all correspondence.',
            OrderTextBuilder.ConfirmationText(OrderNo, CustomerName, LineCount),
            'Expected the plural confirmation sentence character for character: the customer name first, the order number twice, and the line count followed by "lines"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleLineOrderUsesTheSingularWording()
    var
        OrderTextBuilder: Codeunit "Order Text Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] An order with exactly one line reads "1 line", not "1 lines"
        // [WHEN] building the confirmation text for a one-line order
        // [THEN] the singular sentence comes back
        Assert.AreEqual(
            'Dear Northwind Traders, your order SO-1001 with 1 line is confirmed. Please quote SO-1001 in all correspondence.',
            OrderTextBuilder.ConfirmationText('SO-1001', 'Northwind Traders', 1),
            'Expected the singular wording "with 1 line is confirmed" when the order has exactly one line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroLinesUsesThePluralWording()
    var
        OrderTextBuilder: Codeunit "Order Text Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Only a count of exactly 1 is singular — 0 lines is plural
        // [WHEN] building the confirmation text for an order without lines
        // [THEN] the sentence reads "0 lines"
        Assert.AreEqual(
            'Dear Adatum Corporation, your order SO-1002 with 0 lines is confirmed. Please quote SO-1002 in all correspondence.',
            OrderTextBuilder.ConfirmationText('SO-1002', 'Adatum Corporation', 0),
            'Expected "with 0 lines is confirmed" — only a count of exactly 1 takes the singular label');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyCustomerNameIsSubstitutedAsNothing()
    var
        OrderTextBuilder: Codeunit "Order Text Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A blank argument is inserted as an empty string, not refused and not left as a placeholder
        // [WHEN] building the confirmation text with an empty customer name
        // [THEN] the sentence reads "Dear , your order ..." with nothing in the name slot
        Assert.AreEqual(
            'Dear , your order SO-1003 with 3 lines is confirmed. Please quote SO-1003 in all correspondence.',
            OrderTextBuilder.ConfirmationText('SO-1003', '', 3),
            'Expected an empty customer name to leave nothing between "Dear" and the comma — no error, no leftover placeholder');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PlaceholderTextInsideTheCustomerNameStaysLiteral()
    var
        OrderTextBuilder: Codeunit "Order Text Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A value that happens to contain %1 is data, not a placeholder
        // [WHEN] building the confirmation text for a customer named "Discount %1 Ltd"
        // [THEN] the %1 inside the name comes out unchanged instead of expanding into the order number
        Assert.AreEqual(
            'Dear Discount %1 Ltd, your order SO-1004 with 2 lines is confirmed. Please quote SO-1004 in all correspondence.',
            OrderTextBuilder.ConfirmationText('SO-1004', 'Discount %1 Ltd', 2),
            'Expected the %1 inside the customer name to stay literal — placeholders are only replaced in the label text, never inside the values');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SlipColumnPadsShortValuesToTheirFieldWidth()
    var
        OrderTextBuilder: Codeunit "Order Text Builder";
        Any: Codeunit Any;
        ItemNo: Code[20];
        Description: Text;
    begin
        // [SCENARIO] Values shorter than their field are left-aligned and padded with spaces
        // [GIVEN] a generated 4-character item number and an 11-character description
        ItemNo := CopyStr(UpperCase(Any.AlphabeticText(4)), 1, MaxStrLen(ItemNo));
        Description := Any.AlphabeticText(11);

        // [WHEN] building the slip line
        // [THEN] the item number fills 8 characters, one space follows, and the description fills 24
        VerifySlipLine(
            PadStr(ItemNo, 8) + ' ' + PadStr(Description, 24),
            OrderTextBuilder.SlipColumn(ItemNo, Description),
            'short values');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SlipColumnKeepsValuesThatFillTheirFieldExactly()
    var
        OrderTextBuilder: Codeunit "Order Text Builder";
    begin
        // [SCENARIO] A value exactly as long as its field is printed as is — no padding, no asterisks
        // [WHEN] building the slip line for an 8-character item number and a 24-character description
        // [THEN] the line is the two values with a single space between them
        VerifySlipLine(
            'ITEM-008 Stainless hex bolt M12x4',
            OrderTextBuilder.SlipColumn('ITEM-008', 'Stainless hex bolt M12x4'),
            'values that exactly fill their fields');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SlipColumnOverflowsALongItemNumberIntoAsterisks()
    var
        OrderTextBuilder: Codeunit "Order Text Builder";
    begin
        // [SCENARIO] An item number one character too long for its field is printed as asterisks across the field
        // [WHEN] building the slip line for a 9-character item number
        // [THEN] the item field is 8 asterisks and the description is unaffected
        VerifySlipLine(
            PadStr('', 8, '*') + ' ' + PadStr('Blue widget', 24),
            OrderTextBuilder.SlipColumn('ITEM-0009', 'Blue widget'),
            'a 9-character item number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SlipColumnOverflowsALongDescriptionIntoAsterisks()
    var
        OrderTextBuilder: Codeunit "Order Text Builder";
    begin
        // [SCENARIO] A description one character too long for its field is printed as asterisks, not truncated
        // [WHEN] building the slip line for a 25-character description
        // [THEN] the description field is 24 asterisks and the item number is unaffected
        VerifySlipLine(
            PadStr('A-10', 8) + ' ' + PadStr('', 24, '*'),
            OrderTextBuilder.SlipColumn('A-10', 'Stainless hex bolt M12x40'),
            'a 25-character description');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SlipColumnLeavesAnEmptyDescriptionAsSpaces()
    var
        OrderTextBuilder: Codeunit "Order Text Builder";
    begin
        // [SCENARIO] An empty value still occupies its full field width
        // [WHEN] building the slip line with an empty description
        // [THEN] the description field is 24 spaces and the line is still 33 characters long
        VerifySlipLine(
            PadStr('A-11', 8) + ' ' + PadStr('', 24),
            OrderTextBuilder.SlipColumn('A-11', ''),
            'an empty description');
    end;

    local procedure VerifySlipLine(ExpectedLine: Text; ActualLine: Text; Context: Text)
    var
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(StrLen(ExpectedLine), StrLen(ActualLine),
            StrSubstNo('Expected the slip line for %1 to be exactly %2 characters long (8 + 1 + 24), padding spaces included', Context, StrLen(ExpectedLine)));
        Assert.AreEqual(ExpectedLine, ActualLine,
            StrSubstNo('Expected the slip line for %1 to match character for character, padding spaces and overflow asterisks included', Context));
    end;
}
