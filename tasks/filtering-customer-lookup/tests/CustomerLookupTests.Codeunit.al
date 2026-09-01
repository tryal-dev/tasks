codeunit 50900 "Customer Lookup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountInCityCountsExactlyTheCustomersInThatCity()
    var
        CustomerLookup: Codeunit "Customer Lookup";
        Assert: Codeunit Assert;
    begin
        CreateCustomerInCity('TRYAL-L1 Silverport');
        CreateCustomerInCity('TRYAL-L1 Silverport');
        CreateCustomerInCity('TRYAL-L1 Ironvale');

        Assert.AreEqual(2, CustomerLookup.CountInCity('TRYAL-L1 Silverport'),
            'Expected exactly the two customers whose City is TRYAL-L1 Silverport — the customer in TRYAL-L1 Ironvale must not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountInCityDoesNotMatchACityThatMerelyStartsTheSameWay()
    var
        CustomerLookup: Codeunit "Customer Lookup";
        Assert: Codeunit Assert;
    begin
        CreateCustomerInCity('TRYAL-L2 North');
        CreateCustomerInCity('TRYAL-L2 Northport');

        Assert.AreEqual(1, CustomerLookup.CountInCity('TRYAL-L2 North'),
            'Expected only the customer whose City is exactly TRYAL-L2 North — TRYAL-L2 Northport merely starts the same way and must not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountInCityWorksForAGeneratedCityName()
    var
        CustomerLookup: Codeunit "Customer Lookup";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CityName: Text[30];
    begin
        CityName := CopyStr('TRYAL-L3 ' + Any.AlphabeticText(12), 1, 30);
        CreateCustomerInCity(CityName);
        CreateCustomerInCity(CityName);
        CreateCustomerInCity(CityName);
        CreateCustomerInCity('TRYAL-L3 Elsewhere');

        Assert.AreEqual(3, CustomerLookup.CountInCity(CityName),
            'Expected the three customers seeded into a city name generated at run time — the count cannot come from anything but the City filter');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountInCityFindsNothingInAnEmptyCity()
    var
        CustomerLookup: Codeunit "Customer Lookup";
        Assert: Codeunit Assert;
    begin
        CreateCustomerInCity('TRYAL-L4 Somewhere');

        Assert.AreEqual(0, CustomerLookup.CountInCity('TRYAL-L4 Nowhere'),
            'Expected 0 for a city no customer lives in — an empty result is zero, not an error and not the count of other cities');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountInEitherCityCountsCustomersFromBothCities()
    var
        CustomerLookup: Codeunit "Customer Lookup";
        Assert: Codeunit Assert;
    begin
        CreateCustomerInCity('TRYAL-L5 Ashford');
        CreateCustomerInCity('TRYAL-L5 Ashford');
        CreateCustomerInCity('TRYAL-L5 Briarton');
        CreateCustomerInCity('TRYAL-L5 Ashfordham');
        CreateCustomerInCity('TRYAL-L5 Coldwell');

        Assert.AreEqual(3, CustomerLookup.CountInEitherCity('TRYAL-L5 Ashford', 'TRYAL-L5 Briarton'),
            'Expected the two customers in TRYAL-L5 Ashford plus the one in TRYAL-L5 Briarton — TRYAL-L5 Ashfordham merely starts with one of the searched names and TRYAL-L5 Coldwell is a third city, so neither may count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountInEitherCityCountsTheSameCustomersWhenTheCitiesAreSwapped()
    var
        CustomerLookup: Codeunit "Customer Lookup";
        Assert: Codeunit Assert;
    begin
        CreateCustomerInCity('TRYAL-L10 Kestrel');
        CreateCustomerInCity('TRYAL-L10 Kestrel');
        CreateCustomerInCity('TRYAL-L10 Larkspur');

        Assert.AreEqual(3, CustomerLookup.CountInEitherCity('TRYAL-L10 Larkspur', 'TRYAL-L10 Kestrel'),
            'Expected the same three customers no matter which city is passed first — the two cities are alternatives, not a from-to span');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountInEitherCityCountsEachCustomerOnceWhenBothCitiesAreTheSame()
    var
        CustomerLookup: Codeunit "Customer Lookup";
        Assert: Codeunit Assert;
    begin
        CreateCustomerInCity('TRYAL-L6 Duskvale');
        CreateCustomerInCity('TRYAL-L6 Duskvale');

        Assert.AreEqual(2, CustomerLookup.CountInEitherCity('TRYAL-L6 Duskvale', 'TRYAL-L6 Duskvale'),
            'Expected the same city in both parameters to return that city''s count once — each customer counts once, never twice');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountInEitherCityFindsNothingWhenNeitherCityHasCustomers()
    var
        CustomerLookup: Codeunit "Customer Lookup";
        Assert: Codeunit Assert;
    begin
        CreateCustomerInCity('TRYAL-L7 Emberly');

        Assert.AreEqual(0, CustomerLookup.CountInEitherCity('TRYAL-L7 Frostmoor', 'TRYAL-L7 Galeport'),
            'Expected 0 when neither city has a customer — the customer in TRYAL-L7 Emberly is in neither of the two searched cities');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountWithEmailInCityCountsOnlyCustomersWithAnEmail()
    var
        CustomerLookup: Codeunit "Customer Lookup";
        Assert: Codeunit Assert;
    begin
        CreateCustomerInCityWithEmail('TRYAL-L8 Havenbrook', 'first@tryal.example');
        CreateCustomerInCityWithEmail('TRYAL-L8 Havenbrook', 'second@tryal.example');
        CreateCustomerInCity('TRYAL-L8 Havenbrook');
        CreateCustomerInCity('TRYAL-L8 Havenbrook');
        CreateCustomerInCityWithEmail('TRYAL-L8 Isleworth', 'decoy@tryal.example');
        CreateCustomerInCityWithEmail('TRYAL-L8 Havenbrooke', 'prefix@tryal.example');

        Assert.AreEqual(2, CustomerLookup.CountWithEmailInCity('TRYAL-L8 Havenbrook'),
            'Expected only the two TRYAL-L8 Havenbrook customers with a non-blank E-Mail — blank-email neighbours, the emailable customer in TRYAL-L8 Isleworth and the one in TRYAL-L8 Havenbrooke (which merely starts the same way) must not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountWithEmailInCityIsZeroWhenEveryEmailInTheCityIsBlank()
    var
        CustomerLookup: Codeunit "Customer Lookup";
        Assert: Codeunit Assert;
    begin
        CreateCustomerInCity('TRYAL-L9 Junction');
        CreateCustomerInCity('TRYAL-L9 Junction');

        Assert.AreEqual(0, CustomerLookup.CountWithEmailInCity('TRYAL-L9 Junction'),
            'Expected 0 when every customer in the city has a blank E-Mail — living in the city is not enough');
    end;

    local procedure CreateCustomerInCity(CityName: Text[30])
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.City := CityName;
        Customer."E-Mail" := '';
        Customer.Modify(true);
    end;

    local procedure CreateCustomerInCityWithEmail(CityName: Text[30]; Email: Text[80])
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.City := CityName;
        Customer."E-Mail" := Email;
        Customer.Modify(true);
    end;
}
