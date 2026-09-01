codeunit 50900 "Campaign Call List Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CampaignCityCustomersAreOnTheList()
    var
        Customer: Record Customer;
        FirstCityCustomer: Record Customer;
        SecondCityCustomer: Record Customer;
        OtherCityCustomer: Record Customer;
        CampaignCallList: Codeunit "Campaign Call List";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CampaignCity: Text[30];
    begin
        CampaignCity := CopyStr('TRYAL-U1 ' + Any.AlphabeticText(10), 1, 30);
        CreateCustomerInCity(FirstCityCustomer, CampaignCity, 0);
        CreateCustomerInCity(SecondCityCustomer, CampaignCity, 0);
        CreateCustomerInCity(OtherCityCustomer, 'TRYAL-U1 Elsewhere', 0);

        CampaignCallList.BuildCallList(Customer, CampaignCity, 100000);

        Assert.AreEqual(1, CountVisits(Customer, FirstCityCustomer."No."),
            'Expected the first customer in the campaign city to be visited exactly once when iterating the call list');
        Assert.AreEqual(1, CountVisits(Customer, SecondCityCustomer."No."),
            'Expected the second customer in the campaign city to be visited exactly once when iterating the call list');
        Assert.AreEqual(0, CountVisits(Customer, OtherCityCustomer."No."),
            'Expected the low-credit customer in another city to stay off the call list');
        AssertSeededCustomerUnchanged(FirstCityCustomer);
        AssertSeededCustomerUnchanged(SecondCityCustomer);
        AssertSeededCustomerUnchanged(OtherCityCustomer);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure VipCustomersOutsideTheCityAreOnTheList()
    var
        Customer: Record Customer;
        VipCustomer: Record Customer;
        ModestCustomer: Record Customer;
        CampaignCallList: Codeunit "Campaign Call List";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Threshold: Decimal;
    begin
        Threshold := Any.DecimalInRange(1000, 5000, 2);
        CreateCustomerInCity(VipCustomer, 'TRYAL-U2 Faraway', Threshold + Any.DecimalInRange(100, 900, 2));
        CreateCustomerInCity(ModestCustomer, 'TRYAL-U2 Faraway', Threshold - Any.DecimalInRange(100, 900, 2));

        CampaignCallList.BuildCallList(Customer, 'TRYAL-U2 Campaign Town', Threshold);

        Assert.AreEqual(1, CountVisits(Customer, VipCustomer."No."),
            'Expected the customer whose credit limit is above the threshold to be on the call list even though they live outside the campaign city');
        Assert.AreEqual(0, CountVisits(Customer, ModestCustomer."No."),
            'Expected the customer below the credit-limit threshold and outside the campaign city to stay off the call list');
        AssertSeededCustomerUnchanged(VipCustomer);
        AssertSeededCustomerUnchanged(ModestCustomer);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerMatchingBothRulesIsVisitedExactlyOnce()
    var
        Customer: Record Customer;
        BothRulesCustomer: Record Customer;
        CityOnlyCustomer: Record Customer;
        VipOnlyCustomer: Record Customer;
        CampaignCallList: Codeunit "Campaign Call List";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Threshold: Decimal;
    begin
        Threshold := Any.DecimalInRange(1000, 5000, 2);
        CreateCustomerInCity(BothRulesCustomer, 'TRYAL-U3 Harborview', Threshold + Any.DecimalInRange(100, 900, 2));
        CreateCustomerInCity(CityOnlyCustomer, 'TRYAL-U3 Harborview', 0);
        CreateCustomerInCity(VipOnlyCustomer, 'TRYAL-U3 Millbrook', Threshold + Any.DecimalInRange(100, 900, 2));

        CampaignCallList.BuildCallList(Customer, 'TRYAL-U3 Harborview', Threshold);

        Assert.AreEqual(1, CountVisits(Customer, BothRulesCustomer."No."),
            'Expected the customer matching both rules to be visited exactly once — nobody gets called twice');
        Assert.AreEqual(1, CountVisits(Customer, CityOnlyCustomer."No."),
            'Expected the customer matching only the city rule to be on the same list as the customer matching both');
        Assert.AreEqual(1, CountVisits(Customer, VipOnlyCustomer."No."),
            'Expected the customer matching only the credit-limit rule to be on the same list as the customer matching both');
        AssertSeededCustomerUnchanged(BothRulesCustomer);
        AssertSeededCustomerUnchanged(CityOnlyCustomer);
        AssertSeededCustomerUnchanged(VipOnlyCustomer);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreditLimitExactlyAtThresholdQualifies()
    var
        Customer: Record Customer;
        AtThresholdCustomer: Record Customer;
        JustBelowCustomer: Record Customer;
        CampaignCallList: Codeunit "Campaign Call List";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Threshold: Decimal;
    begin
        Threshold := Any.DecimalInRange(1000, 5000, 2);
        CreateCustomerInCity(AtThresholdCustomer, 'TRYAL-U4 Riverside', Threshold);
        CreateCustomerInCity(JustBelowCustomer, 'TRYAL-U4 Riverside', Threshold - 0.01);

        CampaignCallList.BuildCallList(Customer, 'TRYAL-U4 Campaign Town', Threshold);

        Assert.AreEqual(1, CountVisits(Customer, AtThresholdCustomer."No."),
            'Expected a credit limit exactly at the threshold to qualify — the rule is at or above, not strictly above');
        Assert.AreEqual(0, CountVisits(Customer, JustBelowCustomer."No."),
            'Expected a credit limit one cent below the threshold to stay off the call list');
        AssertSeededCustomerUnchanged(AtThresholdCustomer);
        AssertSeededCustomerUnchanged(JustBelowCustomer);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CampaignCityMatchesTheWholeValueOnly()
    var
        Customer: Record Customer;
        ExactCityCustomer: Record Customer;
        PrefixCityCustomer: Record Customer;
        CampaignCallList: Codeunit "Campaign Call List";
        Assert: Codeunit Assert;
    begin
        CreateCustomerInCity(ExactCityCustomer, 'TRYAL-U5 North', 0);
        CreateCustomerInCity(PrefixCityCustomer, 'TRYAL-U5 Northport', 0);

        CampaignCallList.BuildCallList(Customer, 'TRYAL-U5 North', 100000);

        Assert.AreEqual(1, CountVisits(Customer, ExactCityCustomer."No."),
            'Expected the customer whose city is exactly TRYAL-U5 North to be on the call list');
        Assert.AreEqual(0, CountVisits(Customer, PrefixCityCustomer."No."),
            'Expected the customer in TRYAL-U5 Northport to stay off the list — the city must match the whole value, not merely start the same way');
        AssertSeededCustomerUnchanged(ExactCityCustomer);
        AssertSeededCustomerUnchanged(PrefixCityCustomer);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BuildingTheListDeletesNoCustomers()
    var
        Customer: Record Customer;
        CityCustomer: Record Customer;
        BystanderCustomer: Record Customer;
        CampaignCallList: Codeunit "Campaign Call List";
        Assert: Codeunit Assert;
    begin
        CreateCustomerInCity(CityCustomer, 'TRYAL-U6 Campaign Town', 0);
        CreateCustomerInCity(BystanderCustomer, 'TRYAL-U6 Quietside', 0);

        CampaignCallList.BuildCallList(Customer, 'TRYAL-U6 Campaign Town', 100000);

        Assert.AreEqual(0, CountVisits(Customer, BystanderCustomer."No."),
            'Expected the customer matching neither rule to stay off the call list');
        AssertSeededCustomerUnchanged(CityCustomer);
        AssertSeededCustomerUnchanged(BystanderCustomer);
    end;

    local procedure CreateCustomerInCity(var SeededCustomer: Record Customer; CityName: Text[30]; CreditLimit: Decimal)
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(SeededCustomer);
        SeededCustomer.City := CityName;
        SeededCustomer."Credit Limit (LCY)" := CreditLimit;
        SeededCustomer.Modify(true);
        // Re-read so the caller's snapshot matches the database exactly,
        // SystemModifiedAt included — AssertSeededCustomerUnchanged compares
        // against this snapshot after BuildCallList.
        SeededCustomer.Get(SeededCustomer."No.");
    end;

    // Rule 6 says BuildCallList must not write to any customer. Spot-checking
    // the two fields the task talks about is not enough: a solution could
    // smuggle the union through a sentinel value written into some unrelated
    // field and filter on that. So compare every normal field against the
    // seed-time snapshot, plus SystemModifiedAt to catch a write that restores
    // the original values.
    local procedure AssertSeededCustomerUnchanged(SeededCustomer: Record Customer)
    var
        RereadCustomer: Record Customer;
        Assert: Codeunit Assert;
        SeededRef: RecordRef;
        RereadRef: RecordRef;
        SeededField: FieldRef;
        i: Integer;
    begin
        Assert.IsTrue(RereadCustomer.Get(SeededCustomer."No."),
            StrSubstNo('Expected seeded customer %1 to still exist under its original number after the call — the call list only shapes which records the caller sees, it never deletes or renames anything', SeededCustomer."No."));
        SeededRef.GetTable(SeededCustomer);
        RereadRef.GetTable(RereadCustomer);
        for i := 1 to SeededRef.FieldCount do begin
            SeededField := SeededRef.FieldIndex(i);
            if (SeededField.Class = FieldClass::Normal) and not (SeededField.Type in [FieldType::Blob, FieldType::Media, FieldType::MediaSet]) then
                Assert.AreEqual(Format(SeededField.Value, 0, 9), Format(RereadRef.Field(SeededField.Number).Value, 0, 9),
                    StrSubstNo('Expected field %1 of seeded customer %2 to be unchanged after BuildCallList — the procedure must only shape which records the caller sees, never rewrite them', SeededField.Name, SeededCustomer."No."));
        end;
        Assert.AreEqual(SeededCustomer.SystemModifiedAt, RereadCustomer.SystemModifiedAt,
            StrSubstNo('Expected seeded customer %1 to never be written to by BuildCallList — SystemModifiedAt changed, so the record was modified even if its values were put back', SeededCustomer."No."));
    end;

    // Walks the view the submission left on the record; called repeatedly per
    // test, which also proves the list survives being iterated more than once.
    local procedure CountVisits(var Customer: Record Customer; CustomerNo: Code[20]): Integer
    var
        Visits: Integer;
    begin
        if Customer.FindSet() then
            repeat
                if Customer."No." = CustomerNo then
                    Visits += 1;
            until Customer.Next() = 0;
        exit(Visits);
    end;
}
