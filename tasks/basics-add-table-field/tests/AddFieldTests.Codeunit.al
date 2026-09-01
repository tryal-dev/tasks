codeunit 50900 "Add Field Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomFieldStoresAndReturnsAValue()
    var
        Customer: Record Customer;
        RecRef: RecordRef;
        Stored: Text;
    begin
        Customer.Init();
        Customer."No." := 'TRYAL-T101';
        Customer.Insert();

        RecRef.GetTable(Customer);
        FieldByName(RecRef, 'Custom Field').Value := 'Internal label';
        RecRef.Modify();

        Customer.Get('TRYAL-T101');
        RecRef.GetTable(Customer);
        Stored := FieldByName(RecRef, 'Custom Field').Value;
        Assert.AreEqual('Internal label', Stored, 'Expected "Custom Field" to store and return the value written to it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomFieldHoldsFiftyCharacters()
    var
        Customer: Record Customer;
        RecRef: RecordRef;
        FiftyChars: Text;
        Stored: Text;
    begin
        FiftyChars := PadStr('', 50, 'x');

        Customer.Init();
        Customer."No." := 'TRYAL-T101B';
        RecRef.GetTable(Customer);
        FieldByName(RecRef, 'Custom Field').Value := FiftyChars;
        RecRef.Insert();

        Customer.Get('TRYAL-T101B');
        RecRef.GetTable(Customer);
        Stored := FieldByName(RecRef, 'Custom Field').Value;
        Assert.AreEqual(FiftyChars, Stored, 'Expected "Custom Field" to hold a 50-character value (Text[50])');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomFieldIsDeclaredAsTextFifty()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(Database::Customer);
        FldRef := FieldByName(RecRef, 'Custom Field');

        Assert.AreEqual(Format(FieldType::Text), Format(FldRef.Type), StrSubstNo('Expected "Custom Field" to be declared as Text[50], not %1', FldRef.Type));
        Assert.AreEqual(50, FldRef.Length, 'Expected "Custom Field" to be declared as Text[50] — its maximum length must be exactly 50');
    end;

    // The tests must compile against the unchanged starter, which has no "Custom Field" yet,
    // so the field is looked up by name at run time instead of being referenced in code.
    local procedure FieldByName(var RecRef: RecordRef; FieldName: Text): FieldRef
    var
        FldRef: FieldRef;
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            if FldRef.Name() = FieldName then
                exit(FldRef);
        end;
        Assert.Fail(StrSubstNo('Expected table %1 to have a field named "%2"', RecRef.Name(), FieldName));
    end;
}
