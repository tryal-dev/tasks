codeunit 50900 "Excel Column Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FirstColumnIsA()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Index 1 is the first single-letter column
        Assert.AreEqual('A', ExcelColumn.ColumnLetters(1),
            'Expected column 1 to be A');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TwentySixthColumnIsZ()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 26 is the last single-letter column - there is no letter for zero
        Assert.AreEqual('Z', ExcelColumn.ColumnLetters(26),
            'Expected column 26 to be Z — column letters have no digit for zero, so treating 26 as an ordinary base-26 number lands one letter off (A@ and BA are the classic wrong answers)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TwentySeventhColumnRollsOverToAA()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 27 is the first two-letter column
        Assert.AreEqual('AA', ExcelColumn.ColumnLetters(27),
            'Expected column 27 to be AA — the column after Z starts the two-letter range');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FiftySecondColumnIsAZ()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Every multiple of 26 ends in Z, not in a letter before A
        Assert.AreEqual('AZ', ExcelColumn.ColumnLetters(52),
            'Expected column 52 to be AZ — every multiple of 26 ends in Z; the rightmost letter comes from (Index - 1) mod 26, not from Index mod 26');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LastTwoLetterColumnIsZZ()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 702 = 26 * 26 + 26 is the last two-letter column
        Assert.AreEqual('ZZ', ExcelColumn.ColumnLetters(702),
            'Expected column 702 to be ZZ — the last two-letter column, both letters at their maximum');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FirstThreeLetterColumnIsAAA()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 703 is the first three-letter column
        Assert.AreEqual('AAA', ExcelColumn.ColumnLetters(703),
            'Expected column 703 to be AAA — the column after ZZ starts the three-letter range');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExcelLastColumnIsXFD()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The last column of an Excel sheet, 16384, is XFD
        Assert.AreEqual('XFD', ExcelColumn.ColumnLetters(16384),
            'Expected column 16384 (the last column of an Excel sheet) to be XFD');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomThreeLetterColumnGetsItsLetters()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        First: Integer;
        Second: Integer;
        Third: Integer;
        Index: Integer;
        Expected: Text;
    begin
        // [SCENARIO] A random three-letter column is spelled from its positional index
        First := Any.IntegerInRange(1, 26);
        Second := Any.IntegerInRange(1, 26);
        Third := Any.IntegerInRange(1, 26);
        Index := First * 676 + Second * 26 + Third;
        Expected := LetterAt(First) + LetterAt(Second) + LetterAt(Third);

        Assert.AreEqual(Expected, ExcelColumn.ColumnLetters(Index),
            StrSubstNo('Expected column %1 to be %2 — the index was computed as %3 * 676 + %4 * 26 + %5 with A = 1, so hardcoded examples cannot pass', Index, Expected, First, Second, Third));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleLettersMapToOneThroughTwentySix()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
        i: Integer;
    begin
        // [SCENARIO] Every single letter A..Z maps to its position 1..26
        for i := 1 to 26 do
            Assert.AreEqual(i, ExcelColumn.ColumnIndex(LetterAt(i)),
                StrSubstNo('Expected the single letter %1 to be column %2', LetterAt(i), i));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AAIsColumnTwentySeven()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The first two-letter column is 27
        Assert.AreEqual(27, ExcelColumn.ColumnIndex('AA'),
            'Expected AA to be column 27 — the leading A counts as 1 * 26, not as 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZZIsColumnSevenHundredTwo()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The last two-letter column is 702
        Assert.AreEqual(702, ExcelColumn.ColumnIndex('ZZ'),
            'Expected ZZ to be column 702 = 26 * 26 + 26');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AAAIsColumnSevenHundredThree()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The first three-letter column is 703
        Assert.AreEqual(703, ExcelColumn.ColumnIndex('AAA'),
            'Expected AAA to be column 703 = 1 * 676 + 1 * 26 + 1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure XFDIsColumnSixteenThousandThreeHundredEightyFour()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The last column of an Excel sheet, XFD, is 16384
        Assert.AreEqual(16384, ExcelColumn.ColumnIndex('XFD'),
            'Expected XFD (the last column of an Excel sheet) to be column 16384 = 24 * 676 + 6 * 26 + 4');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LowercaseLettersAreAccepted()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Lowercase letters name the same column as their uppercase form
        Assert.AreEqual(27, ExcelColumn.ColumnIndex('aa'),
            'Expected the lowercase aa to be column 27, the same as AA — letters are accepted in any case, so validate and convert after uppercasing, not before');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MixedCaseLettersAreAccepted()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Mixed case is accepted too
        Assert.AreEqual(16384, ExcelColumn.ColumnIndex('xFd'),
            'Expected the mixed-case xFd to be column 16384, the same as XFD — every letter is read case-insensitively');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomThreeLetterColumnGetsItsIndex()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        First: Integer;
        Second: Integer;
        Third: Integer;
        Letters: Text;
    begin
        // [SCENARIO] A random three-letter column resolves to its positional index
        First := Any.IntegerInRange(1, 26);
        Second := Any.IntegerInRange(1, 26);
        Third := Any.IntegerInRange(1, 26);
        Letters := LetterAt(First) + LetterAt(Second) + LetterAt(Third);

        Assert.AreEqual(First * 676 + Second * 26 + Third, ExcelColumn.ColumnIndex(Letters),
            StrSubstNo('Expected %1 to be column %2 * 676 + %3 * 26 + %4 with A = 1 — hardcoded examples cannot pass this', Letters, First, Second, Third));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoundTripsARandomIndex()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Index: Integer;
        Letters: Text;
    begin
        // [SCENARIO] ColumnIndex undoes ColumnLetters for a random index
        Index := Any.IntegerInRange(1, 1000000);
        Letters := ExcelColumn.ColumnLetters(Index);

        Assert.AreEqual(Index, ExcelColumn.ColumnIndex(Letters),
            StrSubstNo('Expected ColumnIndex(ColumnLetters(%1)) to give %1 back — ColumnLetters returned %2', Index, Letters));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoundTripsARandomIndexThroughLowercase()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Index: Integer;
        Letters: Text;
    begin
        // [SCENARIO] The round trip survives lowercasing the letters in between
        Index := Any.IntegerInRange(1, 1000000);
        Letters := LowerCase(ExcelColumn.ColumnLetters(Index));

        Assert.AreEqual(Index, ExcelColumn.ColumnIndex(Letters),
            StrSubstNo('Expected the lowercased letters %1 to resolve back to column %2 — ColumnIndex accepts any case', Letters, Index));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsIndexZero()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] There is no column 0
        asserterror ExcelColumn.ColumnLetters(0);

        Assert.ExpectedError('positive');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsNegativeIndex()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] A negative index is refused, not spelled
        asserterror ExcelColumn.ColumnLetters(-Any.IntegerInRange(1, 100000));

        Assert.ExpectedError('positive');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsEmptyLetters()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The empty string names no column
        asserterror ExcelColumn.ColumnIndex('');

        Assert.ExpectedError('not a valid column');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsLettersWithADigit()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A cell reference like A1 is not a column reference
        asserterror ExcelColumn.ColumnIndex('A1');

        Assert.ExpectedError('not a valid column');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsLettersWithSpaces()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A space is not a letter, even at the edges - the input is validated as given, not trimmed
        asserterror ExcelColumn.ColumnIndex(' A ');

        Assert.ExpectedError('not a valid column');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectsLettersWithPunctuation()
    var
        ExcelColumn: Codeunit "Excel Column";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The underscore sits between Z and a in the character table, so it slips past a check that only looks below A
        asserterror ExcelColumn.ColumnIndex('A_B');

        Assert.ExpectedError('not a valid column');
    end;

    // Deliberately not Char arithmetic, so the expected letters are not derived
    // the same way a solution derives them.
    local procedure LetterAt(Position: Integer): Text
    begin
        exit(CopyStr('ABCDEFGHIJKLMNOPQRSTUVWXYZ', Position, 1));
    end;
}
