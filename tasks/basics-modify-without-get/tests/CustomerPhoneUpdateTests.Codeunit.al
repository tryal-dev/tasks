codeunit 50900 "Customer Phone Update Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdatePhoneStoresTheNewNumber()
    var
        Customer: Record Customer;
        CustomerPhoneUpdate: Codeunit "Customer Phone Update";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NewPhone: Text[30];
    begin
        // [SCENARIO] UpdatePhone replaces the stored phone number with the one passed
        CreateCustomerWithDetails(Customer, 'TRYAL-P1 ' + Any.AlphabeticText(12), Any.AlphabeticText(15) + ' Street 1', Any.Email(10, 8), PhoneWithPrefix('+45', Any.IntegerInRange(1000000, 9999999)));
        NewPhone := PhoneWithPrefix('+46', Any.IntegerInRange(1000000, 9999999));

        CustomerPhoneUpdate.UpdatePhone(Customer."No.", NewPhone);

        Customer.Get(Customer."No.");
        Assert.AreEqual(NewPhone, Customer."Phone No.", 'Expected UpdatePhone to store the number passed to it in "Phone No.", exactly as passed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdatePhoneKeepsNameAddressAndEmail()
    var
        Customer: Record Customer;
        CustomerPhoneUpdate: Codeunit "Customer Phone Update";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CustomerName: Text;
        CustomerAddress: Text;
        CustomerEmail: Text;
    begin
        // [SCENARIO] Changing the phone leaves the customer's name, address and e-mail as they were
        CustomerName := 'TRYAL-P2 ' + Any.AlphabeticText(12);
        CustomerAddress := Any.AlphabeticText(15) + ' Road 2';
        CustomerEmail := Any.Email(10, 8);
        CreateCustomerWithDetails(Customer, CustomerName, CustomerAddress, CustomerEmail, PhoneWithPrefix('+45', Any.IntegerInRange(1000000, 9999999)));

        CustomerPhoneUpdate.UpdatePhone(Customer."No.", PhoneWithPrefix('+46', Any.IntegerInRange(1000000, 9999999)));

        Customer.Get(Customer."No.");
        Assert.AreEqual(CustomerName, Customer.Name, 'Expected UpdatePhone to leave the customer''s Name as it was — a Modify on a record variable that was never read writes the variable''s blanks over the stored row');
        Assert.AreEqual(CustomerAddress, Customer.Address, 'Expected UpdatePhone to leave the customer''s Address as it was');
        Assert.AreEqual(CustomerEmail, Customer."E-Mail", 'Expected UpdatePhone to leave the customer''s E-Mail as it was');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdatePhoneKeepsEveryOtherStoredField()
    var
        Customer: Record Customer;
        CustomerPhoneUpdate: Codeunit "Customer Phone Update";
        Any: Codeunit Any;
        StoredValues: Dictionary of [Text, Text];
    begin
        // [SCENARIO] Every stored field except "Phone No." survives UpdatePhone unchanged
        CreateCustomerWithDetails(Customer, 'TRYAL-P3 ' + Any.AlphabeticText(12), Any.AlphabeticText(15) + ' Avenue 3', Any.Email(10, 8), PhoneWithPrefix('+45', Any.IntegerInRange(1000000, 9999999)));
        Customer.Get(Customer."No.");
        SnapshotStoredFields(Customer, StoredValues);

        CustomerPhoneUpdate.UpdatePhone(Customer."No.", PhoneWithPrefix('+46', Any.IntegerInRange(1000000, 9999999)));

        Customer.Get(Customer."No.");
        AssertStoredFieldsUnchanged(Customer, StoredValues);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdatePhoneLeavesOtherCustomersAlone()
    var
        TargetCustomer: Record Customer;
        BystanderCustomer: Record Customer;
        CustomerPhoneUpdate: Codeunit "Customer Phone Update";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        BystanderPhone: Text[30];
    begin
        // [SCENARIO] Updating one customer's phone does not touch another customer
        CreateCustomerWithDetails(TargetCustomer, 'TRYAL-P4 Target ' + Any.AlphabeticText(8), Any.AlphabeticText(15) + ' Lane 4', Any.Email(10, 8), PhoneWithPrefix('+45', Any.IntegerInRange(1000000, 9999999)));
        BystanderPhone := PhoneWithPrefix('+47', Any.IntegerInRange(1000000, 9999999));
        CreateCustomerWithDetails(BystanderCustomer, 'TRYAL-P4 Bystander ' + Any.AlphabeticText(8), Any.AlphabeticText(15) + ' Lane 5', Any.Email(10, 8), BystanderPhone);

        CustomerPhoneUpdate.UpdatePhone(TargetCustomer."No.", PhoneWithPrefix('+46', Any.IntegerInRange(1000000, 9999999)));

        BystanderCustomer.Get(BystanderCustomer."No.");
        Assert.AreEqual(BystanderPhone, BystanderCustomer."Phone No.", 'Expected the other customer''s "Phone No." to be untouched — UpdatePhone changes exactly the customer whose number it was given');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdatePhoneRefusesAMissingCustomer()
    var
        Customer: Record Customer;
        CustomerPhoneUpdate: Codeunit "Customer Phone Update";
        Assert: Codeunit Assert;
        MissingCustomerNo: Code[20];
        ErrorText: Text;
    begin
        // [SCENARIO] A customer number that does not exist is refused with a clear error
        MissingCustomerNo := 'TRYAL-NOBODY';
        if Customer.Get(MissingCustomerNo) then
            Customer.Delete();

        asserterror CustomerPhoneUpdate.UpdatePhone(MissingCustomerNo, '+45 12345678');

        ErrorText := GetLastErrorText();
        Assert.IsTrue(ErrorText.Contains('does not exist'), StrSubstNo('Expected UpdatePhone to refuse customer %1 with an error saying it does not exist, got: "%2"', MissingCustomerNo, ErrorText));
        Assert.IsTrue(ErrorText.Contains(MissingCustomerNo), StrSubstNo('Expected the error for a missing customer to name the customer number %1, got: "%2"', MissingCustomerNo, ErrorText));
    end;

    local procedure CreateCustomerWithDetails(var Customer: Record Customer; NewName: Text; NewAddress: Text; NewEmail: Text; NewPhone: Text[30])
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, CopyStr(NewName, 1, MaxStrLen(Customer.Name)));
        Customer.Validate(Address, CopyStr(NewAddress, 1, MaxStrLen(Customer.Address)));
        Customer.Validate("E-Mail", CopyStr(NewEmail, 1, MaxStrLen(Customer."E-Mail")));
        Customer.Validate("Phone No.", NewPhone);
        Customer.Modify(true);
    end;

    local procedure PhoneWithPrefix(CountryCode: Text; Subscriber: Integer): Text[30]
    begin
        exit(CopyStr(CountryCode + ' ' + Format(Subscriber), 1, 30));
    end;

    local procedure SnapshotStoredFields(var Customer: Record Customer; var StoredValues: Dictionary of [Text, Text])
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        i: Integer;
    begin
        RecRef.GetTable(Customer);
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            if IsComparedField(FldRef) then
                StoredValues.Add(FldRef.Name(), Format(FldRef.Value()));
        end;
    end;

    local procedure AssertStoredFieldsUnchanged(var Customer: Record Customer; StoredValues: Dictionary of [Text, Text])
    var
        Assert: Codeunit Assert;
        RecRef: RecordRef;
        FldRef: FieldRef;
        i: Integer;
    begin
        RecRef.GetTable(Customer);
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            if IsComparedField(FldRef) then
                Assert.AreEqual(StoredValues.Get(FldRef.Name()), Format(FldRef.Value()),
                    StrSubstNo('Expected UpdatePhone to leave the customer''s "%1" untouched — only "Phone No." may change. A Modify on a record variable that was never read writes the variable''s blanks over the stored row', FldRef.Name()));
        end;
    end;

    // Only what the customer actually stores is compared: FlowFields are computed, blobs and media
    // have no comparable text form, and the modified stamps legitimately move under Modify(true).
    local procedure IsComparedField(FldRef: FieldRef): Boolean
    begin
        if FldRef.Class() <> FieldClass::Normal then
            exit(false);
        if (FldRef.Number() = 0) or (FldRef.Number() >= 2000000000) then
            exit(false);
        if FldRef.Type() in [FieldType::Blob, FieldType::Media, FieldType::MediaSet] then
            exit(false);
        case FldRef.Name() of
            'Phone No.', 'Last Date Modified', 'Last Modified Date Time':
                exit(false);
        end;
        exit(true);
    end;
}
