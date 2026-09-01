codeunit 50900 "SEPA Remittance Wrap Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleInvoiceRendersNumberSpaceAmount()
    var
        Builder: Codeunit "SEPA Remittance Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] One applied invoice becomes one entry with two forced decimals
        Builder.AddInvoice('INV-1001', 250);

        Assert.AreEqual('INV-1001 250.00', Builder.GetRemittanceText(),
            'Expected the entry to be the invoice number, one space, and the amount with exactly two decimals — 250 must render as 250.00');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntriesAreJoinedWithCommaAndSpace()
    var
        Builder: Codeunit "SEPA Remittance Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Two applied invoices are joined by ', ' in the order they were added
        Builder.AddInvoice('INV-1001', 250);
        Builder.AddInvoice('INV-1002', 13.5);

        Assert.AreEqual('INV-1001 250.00, INV-1002 13.50', Builder.GetRemittanceText(),
            'Expected the entries joined by a comma and a single space, in the order added — and 13.5 padded to 13.50');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LargeAmountCarriesDotAndNoGroupSeparators()
    var
        Builder: Codeunit "SEPA Remittance Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A large amount renders culture-invariantly: dot decimal, no thousand separators
        Builder.AddInvoice('INV-2001', 1234567.8);

        Assert.AreEqual('INV-2001 1234567.80', Builder.GetRemittanceText(),
            'Expected plain digits with a dot and two decimals — no thousand separators and no comma, whatever the server''s regional settings');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoInvoicesYieldEmptyText()
    var
        Builder: Codeunit "SEPA Remittance Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A builder with nothing added produces an empty remittance line
        Assert.AreEqual('', Builder.GetRemittanceText(),
            'Expected an empty text when no invoice was added');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExactlyFullCapacityComesBackUntouched()
    var
        Builder: Codeunit "SEPA Remittance Builder";
        Assert: Codeunit Assert;
        InvoiceNoA: Text;
        InvoiceNoB: Text;
        ExpectedText: Text;
    begin
        // [SCENARIO] A join of exactly 140 characters fits the cap and gets no suffix
        // [GIVEN] two invoices whose entries are 69 characters each: 69 + 2 + 69 = 140
        InvoiceNoA := PadStr('TRYAL-EXACT-A-', 63, 'X');
        InvoiceNoB := PadStr('TRYAL-EXACT-B-', 63, 'X');
        Builder.AddInvoice(InvoiceNoA, 10);
        Builder.AddInvoice(InvoiceNoB, 10);
        ExpectedText := InvoiceNoA + ' 10.00, ' + InvoiceNoB + ' 10.00';

        Assert.AreEqual(ExpectedText, Builder.GetRemittanceText(),
            'Expected the full join back unchanged: it is exactly 140 characters, so nothing may be dropped and no suffix may appear');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleEntryOfExactlyFullCapacityIsAccepted()
    var
        Builder: Codeunit "SEPA Remittance Builder";
        Assert: Codeunit Assert;
        InvoiceNo: Text;
    begin
        // [SCENARIO] A lone entry of exactly 140 characters is still transmittable: accepted and returned untouched
        // [GIVEN] an invoice number of 134 characters — the entry is 134 + 1 + 5 = 140
        InvoiceNo := PadStr('TRYAL-FULL-', 134, 'X');
        Builder.AddInvoice(InvoiceNo, 10);

        Assert.AreEqual(InvoiceNo + ' 10.00', Builder.GetRemittanceText(),
            'Expected the single 140-character entry back unchanged: 140 is exactly the cap, so AddInvoice must accept it and no suffix may appear');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OneCharacterOverflowDropsTheLastEntry()
    var
        Builder: Codeunit "SEPA Remittance Builder";
        Assert: Codeunit Assert;
        InvoiceNoA: Text;
        InvoiceNoB: Text;
    begin
        // [SCENARIO] A join of 141 characters overflows: the last entry is replaced by the suffix
        // [GIVEN] entries of 69 and 70 characters: 69 + 2 + 70 = 141, one over the cap
        InvoiceNoA := PadStr('TRYAL-OVER-A-', 63, 'X');
        InvoiceNoB := PadStr('TRYAL-OVER-B-', 64, 'X');
        Builder.AddInvoice(InvoiceNoA, 10);
        Builder.AddInvoice(InvoiceNoB, 10);

        Assert.AreEqual(InvoiceNoA + ' 10.00, and 1 more', Builder.GetRemittanceText(),
            'Expected the 141-character join to overflow: keep the first entry whole and end with ", and 1 more" — entries are never cut in the middle');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SuffixSpaceForcesARecountOfTheOmitted()
    var
        Builder: Codeunit "SEPA Remittance Builder";
        Assert: Codeunit Assert;
        ExpectedText: Text;
        Index: Integer;
    begin
        // [SCENARIO] The suffix claims its own space: appending it pushes one more entry out
        // [GIVEN] 13 entries of 12 characters — 10 fit without a suffix (138), but only 9 fit next to it
        for Index := 1 to 13 do
            Builder.AddInvoice(TwoDigitInvoiceNo(Index), 10);
        for Index := 1 to 9 do begin
            if Index > 1 then
                ExpectedText += ', ';
            ExpectedText += TwoDigitInvoiceNo(Index) + ' 10.00';
        end;
        ExpectedText += ', and 4 more';

        Assert.AreEqual(ExpectedText, Builder.GetRemittanceText(),
            'Expected the suffix to claim its space first: with ", and N more" appended only 9 entries fit within 140, so 4 invoices are omitted — dropping until the entries fit and appending afterwards keeps 10 and overshoots the cap');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SuffixedTextOfExactly140IsKept()
    var
        Builder: Codeunit "SEPA Remittance Builder";
        Assert: Codeunit Assert;
        ExpectedText: Text;
        Index: Integer;
    begin
        // [SCENARIO] A suffixed text of exactly 140 characters stays within the cap — no extra entry may be dropped
        // [GIVEN] 12 entries of 11 characters: the full join is 154, but 10 entries (128) plus ', and 2 more' (12) land on exactly 140
        for Index := 1 to 12 do
            Builder.AddInvoice(FiveCharInvoiceNo(Index), 10);
        for Index := 1 to 10 do begin
            if Index > 1 then
                ExpectedText += ', ';
            ExpectedText += FiveCharInvoiceNo(Index) + ' 10.00';
        end;
        ExpectedText += ', and 2 more';

        Assert.AreEqual(ExpectedText, Builder.GetRemittanceText(),
            'Expected 10 kept entries and "and 2 more": the suffixed text is exactly 140 characters, which still fits the cap — dropping an eleventh invoice gives up space rule 6 allows');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnlyTheSuffixRemainsWhenNotEvenTheFirstEntryFits()
    var
        Builder: Codeunit "SEPA Remittance Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] When the first entry plus the suffix exceeds 140, the text is the bare suffix
        // [GIVEN] a first entry of 130 characters (130 + ", and 3 more" = 142) and three normal ones
        Builder.AddInvoice(PadStr('TRYAL-SOLO-', 124, 'X'), 10);
        Builder.AddInvoice('TRYAL-S2', 10);
        Builder.AddInvoice('TRYAL-S3', 10);
        Builder.AddInvoice('TRYAL-S4', 10);

        Assert.AreEqual('and 4 more', Builder.GetRemittanceText(),
            'Expected just "and 4 more": not even the first entry fits alongside the suffix, so every invoice counts as omitted and no leading comma appears');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OverlongSingleEntryRaisesAnError()
    var
        Builder: Codeunit "SEPA Remittance Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] An entry longer than 140 characters can never be transmitted and must be refused
        // [GIVEN] an invoice number of 135 characters — the entry is 135 + 1 + 5 = 141, one over the cap
        asserterror Builder.AddInvoice(PadStr('TRYAL-HUGE-', 135, 'X'), 10);

        Assert.ExpectedError('140');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedAmountsAreRenderedExactly()
    var
        Builder: Codeunit "SEPA Remittance Builder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        AmountA: Decimal;
        AmountB: Decimal;
    begin
        // [SCENARIO] Random amounts survive composition — hardcoding the examples cannot pass
        AmountA := Any.DecimalInRange(1, 999, 2);
        AmountB := Any.DecimalInRange(1, 999, 2);
        Builder.AddInvoice('TRYAL-G1', AmountA);
        Builder.AddInvoice('TRYAL-G2', AmountB);

        Assert.AreEqual('TRYAL-G1 ' + InvariantAmount(AmountA) + ', TRYAL-G2 ' + InvariantAmount(AmountB),
            Builder.GetRemittanceText(),
            StrSubstNo('Expected the amounts %1 and %2 rendered with a dot and exactly two decimals, joined by ", "', AmountA, AmountB));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedInvoiceCountDrivesTheSuffix()
    var
        Builder: Codeunit "SEPA Remittance Builder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExpectedText: Text;
        Total: Integer;
        Index: Integer;
    begin
        // [SCENARIO] However many 12-character entries are added, 9 fit next to the suffix and N is Total - 9
        Total := Any.IntegerInRange(13, 40);
        for Index := 1 to Total do
            Builder.AddInvoice(TwoDigitInvoiceNo(Index), 10);
        for Index := 1 to 9 do begin
            if Index > 1 then
                ExpectedText += ', ';
            ExpectedText += TwoDigitInvoiceNo(Index) + ' 10.00';
        end;
        ExpectedText += StrSubstNo(', and %1 more', Total - 9);

        Assert.AreEqual(ExpectedText, Builder.GetRemittanceText(),
            StrSubstNo('Expected 9 kept entries and "and %1 more" for %2 added invoices — N must count everything the 140 cap (suffix included) pushed out', Total - 9, Total));
    end;

    local procedure FiveCharInvoiceNo(Index: Integer): Text
    begin
        if Index < 10 then
            exit('INV0' + Format(Index));
        exit('INV' + Format(Index));
    end;

    local procedure TwoDigitInvoiceNo(Index: Integer): Text
    begin
        if Index < 10 then
            exit('INV-0' + Format(Index));
        exit('INV-' + Format(Index));
    end;

    local procedure InvariantAmount(Value: Decimal): Text
    begin
        exit(Format(Value, 0, '<Precision,2:2><Standard Format,9>'));
    end;
}
