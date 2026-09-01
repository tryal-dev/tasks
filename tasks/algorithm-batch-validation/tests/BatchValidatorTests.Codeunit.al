codeunit 50900 "Batch Validator Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FullyValidRecordCounts()
    begin
        // [SCENARIO] A record with all four mandatory fields passing counts as valid
        AssertCount(ValidRecord(), 1, 'Expected a record whose four mandatory fields all pass to count as valid');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyBatchYieldsZero()
    begin
        // [SCENARIO] An empty batch contains no valid records
        AssertCount('', 0, 'Expected an empty Batch to yield 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankRecordsAreSkipped()
    begin
        // [SCENARIO] Empty and all-spaces records between separators are neither valid nor invalid
        AssertCount('  |' + ValidRecord() + '| |', 1, 'Expected empty and all-spaces records to be skipped, leaving one valid record');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MissingMandatoryFieldInvalidatesRecord()
    begin
        // [SCENARIO] Each record misses a different mandatory field, so none is valid
        AssertCount(
            RecordWithout('VAT') + '|' + RecordWithout('POSTCODE') + '|' + RecordWithout('CREDIT') + '|' + RecordWithout('CURRENCY'),
            0, 'Expected a record missing any one of the four mandatory fields to be invalid');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownKeysAreIgnored()
    begin
        // [SCENARIO] Extra fields with unknown keys never invalidate a record
        AssertCount(ValidRecord() + ';NOTE=call first;CID=42;vat=lowercase key;REF=call=me', 1, 'Expected fields with unknown keys (including a lowercase ''vat'' and a value containing ''='') to be ignored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VatMustBeTwoUppercaseLettersAndNineDigits()
    begin
        // [SCENARIO] Every malformed VAT variant invalidates its record
        AssertCount(
            RecordWith('VAT', 'de123456789') + '|' +
            RecordWith('VAT', 'DE12345678') + '|' +
            RecordWith('VAT', 'DE1234567890') + '|' +
            RecordWith('VAT', 'D1234567890') + '|' +
            RecordWith('VAT', '12123456789') + '|' +
            RecordWith('VAT', 'DE12345678A') + '|' +
            RecordWith('VAT', ''),
            0, 'Expected every VAT that is not exactly 2 uppercase letters followed by 9 digits to fail');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostcodeMustBeExactlyFiveDigits()
    begin
        // [SCENARIO] Wrong length or non-digit characters invalidate POSTCODE
        AssertCount(
            RecordWith('POSTCODE', '1234') + '|' +
            RecordWith('POSTCODE', '123456') + '|' +
            RecordWith('POSTCODE', '12A45') + '|' +
            RecordWith('POSTCODE', '12 45') + '|' +
            RecordWith('POSTCODE', '123 45') + '|' +
            RecordWith('POSTCODE', ''),
            0, 'Expected every POSTCODE that is not exactly 5 digits to fail');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostcodeKeepsLeadingZeros()
    begin
        // [SCENARIO] 00123 is exactly 5 digits and therefore valid
        AssertCount(RecordWith('POSTCODE', '00123'), 1, 'Expected POSTCODE 00123 to pass — leading zeros are fine, 5 digits is what counts');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreditBoundariesAreInclusive()
    begin
        // [SCENARIO] 500 and 20000 are inside the range; leading zeros do not change the value
        AssertCount(
            RecordWith('CREDIT', '500') + '|' +
            RecordWith('CREDIT', '20000') + '|' +
            RecordWith('CREDIT', '00500'),
            3, 'Expected CREDIT 500, 20000 and 00500 to all pass — the range 500..20000 is inclusive and leading zeros are fine');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreditOutsideRangeOrMalformedIsInvalid()
    begin
        // [SCENARIO] Out-of-range values, signs, separators, decimals and a 30-digit value all fail
        AssertCount(
            RecordWith('CREDIT', '499') + '|' +
            RecordWith('CREDIT', '20001') + '|' +
            RecordWith('CREDIT', '-500') + '|' +
            RecordWith('CREDIT', '+1500') + '|' +
            RecordWith('CREDIT', '1 500') + '|' +
            RecordWith('CREDIT', '1,500') + '|' +
            RecordWith('CREDIT', '1500.00') + '|' +
            RecordWith('CREDIT', '') + '|' +
            RecordWith('CREDIT', '999999999999999999999999999999'),
            0, 'Expected every CREDIT outside 500..20000 or not made of digits only to fail — including the 30-digit one, without crashing');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CurrencyMustMatchTheListExactly()
    begin
        // [SCENARIO] Only the exact case-sensitive codes EUR, USD, GBP pass
        AssertCount(
            RecordWith('CURRENCY', 'eur') + '|' +
            RecordWith('CURRENCY', 'EURO') + '|' +
            RecordWith('CURRENCY', 'EU') + '|' +
            RecordWith('CURRENCY', 'CHF') + '|' +
            RecordWith('CURRENCY', ''),
            0, 'Expected every CURRENCY other than exactly EUR, USD or GBP (case-sensitive) to fail');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DuplicateKeyLastOccurrenceWins()
    begin
        // [SCENARIO] The last occurrence of a duplicated key is the one validated
        AssertCount(
            'CREDIT=10;' + ValidRecord() + '|' + ValidRecord() + ';CREDIT=10',
            1, 'Expected the LAST occurrence of a duplicated key to be validated: bad-then-good is valid, good-then-bad is not');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SegmentWithoutEqualsOrEmptyKeyInvalidatesRecord()
    begin
        // [SCENARIO] A segment with no '=' and a segment with an empty key each break their record
        AssertCount(
            ValidRecord() + ';PENDING' + '|' + ValidRecord() + '; =500',
            0, 'Expected a field segment without ''='' or with an empty key to invalidate the whole record');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SpacesAroundKeysAndValuesAreTrimmed()
    begin
        // [SCENARIO] Padding around keys and values and blank field segments do not hurt
        AssertCount(
            ' VAT = DE123456789 ; ; POSTCODE= 54321 ;CREDIT =1500;  ; CURRENCY= EUR ',
            1, 'Expected keys and values to be trimmed of surrounding spaces and blank field segments to be skipped');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomizedBatchCountsExactlyTheValidRecords()
    var
        Any: Codeunit Any;
        Batch: Text;
        Expected: Integer;
        Credit: Integer;
        i: Integer;
    begin
        // [SCENARIO] Only the generated records whose CREDIT falls in range may be counted
        for i := 1 to 8 do begin
            if Any.Boolean() then begin
                Credit := Any.IntegerInRange(500, 20000);
                Expected += 1;
            end else
                Credit := Any.IntegerInRange(20001, 99999);
            if Batch <> '' then
                Batch += '|';
            Batch += StrSubstNo('VAT=%1%2;POSTCODE=%3;CREDIT=%4;CURRENCY=USD',
                Any.AlphabeticText(2).ToUpper(), RandomDigits(Any, 9), RandomDigits(Any, 5), Credit);
        end;

        AssertCount(Batch, Expected, 'Expected exactly the randomized records whose CREDIT lies in 500..20000 to be counted');
    end;

    local procedure AssertCount(Batch: Text; Expected: Integer; Explanation: Text)
    var
        BatchValidator: Codeunit "Batch Validator";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(Expected, BatchValidator.CountValid(Batch), StrSubstNo('%1 (batch: ''%2'')', Explanation, Batch));
    end;

    local procedure ValidRecord(): Text
    begin
        exit('VAT=DE123456789;POSTCODE=54321;CREDIT=1500;CURRENCY=EUR');
    end;

    local procedure RecordWithout(FieldKey: Text): Text
    var
        Parts: Text;
    begin
        if FieldKey <> 'VAT' then
            Parts += 'VAT=DE123456789;';
        if FieldKey <> 'POSTCODE' then
            Parts += 'POSTCODE=54321;';
        if FieldKey <> 'CREDIT' then
            Parts += 'CREDIT=1500;';
        if FieldKey <> 'CURRENCY' then
            Parts += 'CURRENCY=EUR;';
        exit(Parts.TrimEnd(';'));
    end;

    local procedure RecordWith(FieldKey: Text; FieldValue: Text): Text
    begin
        exit(RecordWithout(FieldKey) + ';' + FieldKey + '=' + FieldValue);
    end;

    local procedure RandomDigits(Any: Codeunit Any; Length: Integer): Text
    var
        Digits: Text;
        i: Integer;
    begin
        for i := 1 to Length do
            Digits += Format(Any.IntegerInRange(0, 9));
        exit(Digits);
    end;
}
