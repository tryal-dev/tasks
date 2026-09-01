codeunit 50900 "Legacy Amount Import Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParseAmountReturnsTheValueOfAValidAmountText()
    var
        LegacyAmountImport: Codeunit "Legacy Amount Import";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Amount: Decimal;
    begin
        Amount := Any.DecimalInRange(1, 999, 2);

        Assert.AreEqual(Amount, LegacyAmountImport.ParseAmount(Format(Amount)),
            'Expected ParseAmount to return the decimal value of a valid amount text');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParseAmountAcceptsZero()
    var
        LegacyAmountImport: Codeunit "Legacy Amount Import";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(0.0, LegacyAmountImport.ParseAmount('0'),
            'Expected ParseAmount to accept zero — only negative amounts are invalid');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParseAmountErrorsOnTextThatIsNotANumber()
    var
        LegacyAmountImport: Codeunit "Legacy Amount Import";
        Assert: Codeunit Assert;
    begin
        asserterror LegacyAmountImport.ParseAmount('TRYAL-garbage');

        Assert.ExpectedError('''TRYAL-garbage'' is not a valid amount');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParseAmountErrorsOnANegativeAmount()
    var
        LegacyAmountImport: Codeunit "Legacy Amount Import";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NegativeText: Text;
    begin
        NegativeText := Format(-Any.DecimalInRange(1, 999, 2));

        asserterror LegacyAmountImport.ParseAmount(NegativeText);

        Assert.ExpectedError(StrSubstNo('''%1'' is not a valid amount', NegativeText));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TryParseAmountReturnsTrueAndTheValueForAValidText()
    var
        LegacyAmountImport: Codeunit "Legacy Amount Import";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Expected: Decimal;
        Amount: Decimal;
        FailureReason: Text;
    begin
        Expected := Any.DecimalInRange(1, 999, 2);

        Assert.IsTrue(LegacyAmountImport.TryParseAmount(Format(Expected), Amount, FailureReason),
            StrSubstNo('Expected TryParseAmount to return true for the valid amount text %1', Format(Expected)));
        Assert.AreEqual(Expected, Amount,
            'Expected TryParseAmount to put the parsed value into the Amount parameter');
        Assert.AreEqual('', FailureReason,
            'Expected an empty FailureReason after a successful conversion');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TryParseAmountReturnsFalseWithTheReasonInsteadOfFailing()
    var
        LegacyAmountImport: Codeunit "Legacy Amount Import";
        Assert: Codeunit Assert;
        Amount: Decimal;
        FailureReason: Text;
    begin
        // No asserterror here: if this call raises, the test fails — rule 3 says it never may.
        Assert.IsFalse(LegacyAmountImport.TryParseAmount('TRYAL-not-a-number', Amount, FailureReason),
            'Expected TryParseAmount to return false for text that is not a number');
        Assert.IsTrue(FailureReason.Contains('''TRYAL-not-a-number'' is not a valid amount'),
            StrSubstNo('Expected FailureReason to carry the conversion error text for TRYAL-not-a-number, got "%1"', FailureReason));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TryParseAmountReturnsFalseForANegativeAmount()
    var
        LegacyAmountImport: Codeunit "Legacy Amount Import";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NegativeText: Text;
        Amount: Decimal;
        FailureReason: Text;
    begin
        NegativeText := Format(-Any.DecimalInRange(1, 999, 2));

        // No asserterror here: if this call raises, the test fails — rule 3 says it never may.
        Assert.IsFalse(LegacyAmountImport.TryParseAmount(NegativeText, Amount, FailureReason),
            StrSubstNo('Expected TryParseAmount to return false for the negative amount text %1 — negatives are invalid by rule 1', NegativeText));
        Assert.IsTrue(FailureReason.Contains(StrSubstNo('''%1'' is not a valid amount', NegativeText)),
            StrSubstNo('Expected FailureReason to carry the conversion error text for %1, got "%2"', NegativeText, FailureReason));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TryParseAmountReportsTheLatestFailure()
    var
        LegacyAmountImport: Codeunit "Legacy Amount Import";
        Assert: Codeunit Assert;
        Amount: Decimal;
        FailureReason: Text;
    begin
        LegacyAmountImport.TryParseAmount('TRYAL-first-bad', Amount, FailureReason);

        LegacyAmountImport.TryParseAmount('TRYAL-second-bad', Amount, FailureReason);

        Assert.IsTrue(FailureReason.Contains('''TRYAL-second-bad'' is not a valid amount'),
            StrSubstNo('Expected FailureReason to describe the latest failed input TRYAL-second-bad, got "%1"', FailureReason));
        Assert.IsFalse(FailureReason.Contains('TRYAL-first-bad'),
            StrSubstNo('Expected FailureReason to no longer mention the earlier failed input TRYAL-first-bad, got "%1"', FailureReason));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TryParseAmountRecoversAfterAFailure()
    var
        LegacyAmountImport: Codeunit "Legacy Amount Import";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Expected: Decimal;
        Amount: Decimal;
        FailureReason: Text;
    begin
        Expected := Any.DecimalInRange(1, 999, 2);
        LegacyAmountImport.TryParseAmount('TRYAL-still-bad', Amount, FailureReason);

        Assert.IsTrue(LegacyAmountImport.TryParseAmount(Format(Expected), Amount, FailureReason),
            'Expected TryParseAmount to succeed on a valid text right after a failed attempt');
        Assert.AreEqual(Expected, Amount,
            'Expected the Amount parameter to hold the newly parsed value after recovering from a failure');
        Assert.AreEqual('', FailureReason,
            'Expected FailureReason to be empty again after a success — stale error text from the earlier failure must not leak through');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ImportLineInsertsTheEntryForAValidAmount()
    var
        LegacyAmountEntry: Record "Legacy Amount Entry";
        LegacyAmountImport: Codeunit "Legacy Amount Import";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Expected: Decimal;
    begin
        Expected := Any.DecimalInRange(1, 999, 2);

        Assert.IsTrue(LegacyAmountImport.ImportLine('TRYAL-I1', Format(Expected)),
            'Expected ImportLine to return true for a line with a valid amount');
        Assert.IsTrue(LegacyAmountEntry.Get('TRYAL-I1'),
            'Expected a Legacy Amount Entry with code TRYAL-I1 after a successful import');
        Assert.AreEqual(Expected, LegacyAmountEntry.Amount,
            'Expected the parsed amount to be stored on the imported entry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ImportLineLeavesNoRowBehindWhenTheAmountIsInvalid()
    var
        LegacyAmountEntry: Record "Legacy Amount Entry";
        LegacyAmountImport: Codeunit "Legacy Amount Import";
        Assert: Codeunit Assert;
    begin
        // Called directly: an error raised here — including the server refusing
        // a database write inside an error-catching scope — fails the test.
        Assert.IsFalse(LegacyAmountImport.ImportLine('TRYAL-I2', 'TRYAL-broken'),
            'Expected ImportLine to return false for a line whose amount text is not a number');

        LegacyAmountEntry.SetRange("Entry Code", 'TRYAL-I2');
        Assert.IsTrue(LegacyAmountEntry.IsEmpty(),
            'Expected no Legacy Amount Entry row for code TRYAL-I2 — a failed import must not leave partial data behind');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ImportLineRejectsANegativeAmount()
    var
        LegacyAmountEntry: Record "Legacy Amount Entry";
        LegacyAmountImport: Codeunit "Legacy Amount Import";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        Assert.IsFalse(LegacyAmountImport.ImportLine('TRYAL-I3', Format(-Any.DecimalInRange(1, 999, 2))),
            'Expected ImportLine to return false for a negative amount — negatives are invalid by rule 1');

        LegacyAmountEntry.SetRange("Entry Code", 'TRYAL-I3');
        Assert.IsTrue(LegacyAmountEntry.IsEmpty(),
            'Expected no Legacy Amount Entry row for code TRYAL-I3 — a rejected negative amount must not be imported');
    end;
}
