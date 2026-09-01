codeunit 50900 "Serial Number Generator Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NextSerialsMovesOnlyTheLastNumberAndKeepsLeadingZeros()
    var
        Generator: Codeunit "Serial Number Generator";
        Assert: Codeunit Assert;
        Serials: List of [Text];
    begin
        Serials := Generator.NextSerials('SN-2024-0099', 1);

        Assert.AreEqual(1, Serials.Count(), 'Expected NextSerials with a quantity of 1 to return exactly one serial');
        Assert.AreEqual('SN-2024-0100', Serials.Get(1),
            'Expected only the last number of SN-2024-0099 to move and its leading zero to survive — 2024 must stay untouched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NextSerialsReturnsTheRequestedNumberOfConsecutiveSerials()
    var
        Generator: Codeunit "Serial Number Generator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Serials: List of [Text];
        Qty: Integer;
        i: Integer;
    begin
        Qty := Any.IntegerInRange(2, 8);

        Serials := Generator.NextSerials('A10B20', Qty);

        Assert.AreEqual(Qty, Serials.Count(), StrSubstNo('Expected NextSerials to return exactly %1 serials for a quantity of %1', Qty));
        for i := 1 to Qty do
            Assert.AreEqual('A10B' + Format(20 + i), Serials.Get(i),
                StrSubstNo('Expected serial %1 of %2 to continue A10B20 by %1 — each serial is the previous one advanced by 1, and A10 never moves', i, Qty));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NextSerialsGrowsTheTextWhenTheNumberRollsOver()
    var
        Generator: Codeunit "Serial Number Generator";
        Assert: Codeunit Assert;
        Serials: List of [Text];
    begin
        Serials := Generator.NextSerials('X999', 2);

        Assert.AreEqual(2, Serials.Count(), 'Expected NextSerials with a quantity of 2 to return exactly two serials');
        Assert.AreEqual('X1000', Serials.Get(1), 'Expected X999 advanced by 1 to become X1000 — the text grows by one character');
        Assert.AreEqual('X1001', Serials.Get(2), 'Expected the second serial after X999 to be X1001');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NextSerialsTreatsTheDigitsAfterADotAsTheirOwnNumber()
    var
        Generator: Codeunit "Serial Number Generator";
        Assert: Codeunit Assert;
        Serials: List of [Text];
    begin
        Serials := Generator.NextSerials('B1.9', 1);

        Assert.AreEqual(1, Serials.Count(), 'Expected NextSerials with a quantity of 1 to return exactly one serial');
        Assert.AreEqual('B1.10', Serials.Get(1), 'Expected B1.9 advanced by 1 to become B1.10 — the dot is a separator, not a decimal point');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NextSerialsReturnsAnEmptyListForAQuantityOfZero()
    var
        Generator: Codeunit "Serial Number Generator";
        Assert: Codeunit Assert;
        Serials: List of [Text];
    begin
        Serials := Generator.NextSerials('SN-0001', 0);

        Assert.AreEqual(0, Serials.Count(), 'Expected NextSerials with a quantity of 0 to return an empty list');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NextSerialsRefusesASerialWithoutDigits()
    var
        Generator: Codeunit "Serial Number Generator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Serial: Text;
    begin
        Serial := UpperCase(Any.AlphabeticText(8));

        asserterror Generator.NextSerials(Serial, 1);

        Assert.ExpectedError(StrSubstNo('Serial number %1 contains no digits', Serial));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AdvanceJumpsByTheGivenStepInOneGo()
    var
        Generator: Codeunit "Serial Number Generator";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('LOT-0025', Generator.Advance('LOT-0005', 20),
            'Expected LOT-0005 advanced by 20 to become LOT-0025 — the number moves by the whole step and keeps its leading zeros');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AdvanceJumpsByARandomStep()
    var
        Generator: Codeunit "Serial Number Generator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        By: Integer;
    begin
        By := Any.IntegerInRange(1, 9000);

        Assert.AreEqual('LOT-' + Format(5 + By, 0, '<Integer,4><Filler Character,0>'), Generator.Advance('LOT-0005', By),
            StrSubstNo('Expected LOT-0005 advanced by %1 to carry the number %2, zero-padded to four digits', By, 5 + By));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AdvanceMovesOnlyTheLastNumber()
    var
        Generator: Codeunit "Serial Number Generator";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('SN-2024-0100', Generator.Advance('SN-2024-0099', 1),
            'Expected Advance to move only the number closest to the end of SN-2024-0099 — 2024 must stay untouched and the leading zero must survive');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AdvanceRefusesASerialWithoutDigits()
    var
        Generator: Codeunit "Serial Number Generator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Serial: Text;
    begin
        Serial := UpperCase(Any.AlphabeticText(8));

        asserterror Generator.Advance(Serial, 3);

        Assert.ExpectedError(StrSubstNo('Serial number %1 contains no digits', Serial));
    end;
}
