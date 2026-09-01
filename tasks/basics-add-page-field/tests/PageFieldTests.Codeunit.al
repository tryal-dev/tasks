codeunit 50900 "Page Field Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerCardHasAControlBoundToCustomField()
    var
        PageControlField: Record "Page Control Field";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(Database::Customer);
        FldRef := FieldByName(RecRef, 'Custom Field');

        // A TestPage binds to its controls at compile time, so the page's control list
        // is read from the "Page Control Field" virtual table instead.
        PageControlField.SetRange(PageNo, Page::"Customer Card");
        PageControlField.SetRange(TableNo, Database::Customer);
        PageControlField.SetRange(FieldNo, FldRef.Number());
        Assert.IsTrue(PageControlField.FindFirst(),
            'Expected page "Customer Card" to have a field control bound to Rec."Custom Field" — add it in a page extension of "Customer Card"');
        Assert.AreEqual('Custom Field', PageControlField.ControlName,
            StrSubstNo('Expected the control bound to Rec."Custom Field" to be named "Custom Field", found "%1"', PageControlField.ControlName));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerCardOpensOnACustomerCarryingACustomFieldValue()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        RecRef: RecordRef;
        Stored: Text;
    begin
        Customer.Init();
        Customer."No." := 'TRYAL-P101';
        RecRef.GetTable(Customer);
        FieldByName(RecRef, 'Custom Field').Value := 'Already stored';
        RecRef.Insert();

        Customer.Get('TRYAL-P101');
        CustomerCard.OpenView();
        CustomerCard.GoToRecord(Customer);
        CustomerCard.Close();

        Customer.Get('TRYAL-P101');
        RecRef.GetTable(Customer);
        Stored := FieldByName(RecRef, 'Custom Field').Value;
        Assert.AreEqual('Already stored', Stored, 'Expected "Custom Field" to still hold the stored value after the customer was opened on the card');
    end;

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
        Assert.Fail(StrSubstNo('Expected table %1 to have a field named "%2" — keep the table extension from the starter in your submission', RecRef.Name(), FieldName));
    end;
}
