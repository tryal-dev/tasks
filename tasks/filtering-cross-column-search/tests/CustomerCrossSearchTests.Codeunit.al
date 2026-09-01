codeunit 50900 "Customer Cross Search Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountsACustomerCarryingTheTextInItsNameOnly()
    var
        CrossSearch: Codeunit "Customer Cross Search";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SearchText: Text;
    begin
        SearchText := Any.AlphabeticText(10);
        CreateCustomer('TRYAL-X1 ' + SearchText + ' Freight', 'TRYAL-X1 Plainville', '');
        CreateCustomer('TRYAL-X1 Ordinary Trading', 'TRYAL-X1 Plainville', '');

        Assert.AreEqual(1, CrossSearch.CountMatches(SearchText),
            'Expected the customer carrying the text in its Name to count even though its City does not — matching one column is enough');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountsACustomerCarryingTheTextInItsCityOnly()
    var
        CrossSearch: Codeunit "Customer Cross Search";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SearchText: Text;
    begin
        SearchText := Any.AlphabeticText(10);
        CreateCustomer('TRYAL-X2 Ordinary Trading', 'TRYAL-X2 ' + SearchText, '');
        CreateCustomer('TRYAL-X2 Other Trading', 'TRYAL-X2 Plainville', '');

        Assert.AreEqual(1, CrossSearch.CountMatches(SearchText),
            'Expected the customer carrying the text in its City to count even though its Name does not — matching one column is enough');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountsACustomerMatchingInBothColumnsOnce()
    var
        CrossSearch: Codeunit "Customer Cross Search";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SearchText: Text;
    begin
        SearchText := Any.AlphabeticText(10);
        CreateCustomer('TRYAL-X3 ' + SearchText + ' Logistics', 'Port ' + SearchText, '');

        Assert.AreEqual(1, CrossSearch.CountMatches(SearchText),
            'Expected a customer carrying the text in Name and City to count exactly once — not once per column');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountsTheFullUnionForAGeneratedText()
    var
        CrossSearch: Codeunit "Customer Cross Search";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SearchText: Text;
    begin
        SearchText := Any.AlphabeticText(10);
        CreateCustomer(SearchText + ' TRYAL-X4 Freight', 'TRYAL-X4 Plainhaven', '');
        CreateCustomer('TRYAL-X4 Mid ' + SearchText + ' Trading', 'TRYAL-X4 Plainhaven', '');
        CreateCustomer('TRYAL-X4 Ordinary Trading', 'Port ' + SearchText, '');
        CreateCustomer('TRYAL-X4 Ordinary Freight', 'TRYAL-X4 Plainhaven', '');

        Assert.AreEqual(3, CrossSearch.CountMatches(SearchText),
            'Expected the two customers carrying the text in the Name (at the start and in the middle) plus the one carrying it at the end of the City — and not the decoy carrying it nowhere');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LowercaseSearchFindsUppercaseValuesInBothColumns()
    var
        CrossSearch: Codeunit "Customer Cross Search";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SearchText: Text;
    begin
        SearchText := Any.AlphabeticText(10);
        CreateCustomer('TRYAL-X5 ' + UpperCase(SearchText) + ' Group', 'TRYAL-X5 Plainville', '');
        CreateCustomer('TRYAL-X5 Ordinary Group', 'TRYAL-X5 ' + UpperCase(SearchText), '');

        Assert.AreEqual(2, CrossSearch.CountMatches(SearchText),
            'Expected the lowercase search text to find the value stored in uppercase in the Name of one customer and in the City of the other — the search ignores case in both columns');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FindsNothingWhenTheTextIsInNeitherColumn()
    var
        CrossSearch: Codeunit "Customer Cross Search";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        CreateCustomer('TRYAL-X6 Ordinary Supplies', 'TRYAL-X6 Plainville', '');

        Assert.AreEqual(0, CrossSearch.CountMatches(Any.AlphabeticText(12)),
            'Expected 0 for a text that appears in no customer''s Name or City — an empty result is zero, not an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContactableCountsOnlyMatchesWithAnEmail()
    var
        CrossSearch: Codeunit "Customer Cross Search";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SearchText: Text;
    begin
        SearchText := Any.AlphabeticText(10);
        CreateCustomer('TRYAL-X7 ' + SearchText + ' Freight', 'TRYAL-X7 Plainville', 'first@tryal.example');
        CreateCustomer('TRYAL-X7 Ordinary Trading', 'TRYAL-X7 ' + SearchText, 'second@tryal.example');
        CreateCustomer('TRYAL-X7 ' + SearchText + ' Group', 'TRYAL-X7 Plainville', '');

        Assert.AreEqual(2, CrossSearch.CountContactableMatches(SearchText),
            'Expected the name match and the city match that carry an e-mail — the matching customer with a blank E-Mail must not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContactableNeverCountsACustomerOnItsEmailAlone()
    var
        CrossSearch: Codeunit "Customer Cross Search";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SearchText: Text;
    begin
        SearchText := Any.AlphabeticText(10);
        CreateCustomer('TRYAL-X8 ' + SearchText + ' Freight', 'TRYAL-X8 Plainville', 'match@tryal.example');
        CreateCustomer('TRYAL-X8 Ordinary Trading', 'TRYAL-X8 Plainville', 'decoy@tryal.example');

        Assert.AreEqual(1, CrossSearch.CountContactableMatches(SearchText),
            'Expected only the customer that matches the text — having an e-mail must never add a customer the text search alone would not have found');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContactableIsZeroWhenEveryMatchLacksAnEmail()
    var
        CrossSearch: Codeunit "Customer Cross Search";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SearchText: Text;
    begin
        SearchText := Any.AlphabeticText(10);
        CreateCustomer('TRYAL-X9 ' + SearchText + ' Freight', 'TRYAL-X9 Plainville', '');
        CreateCustomer('TRYAL-X9 Ordinary Trading', 'TRYAL-X9 ' + SearchText, '');

        Assert.AreEqual(0, CrossSearch.CountContactableMatches(SearchText),
            'Expected 0 when every customer matching the text has a blank E-Mail — matching the text is not enough to be contactable');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContactableCountsABothColumnMatchWithAnEmailOnce()
    var
        CrossSearch: Codeunit "Customer Cross Search";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SearchText: Text;
    begin
        SearchText := Any.AlphabeticText(10);
        CreateCustomer('TRYAL-X10 ' + SearchText + ' Logistics', 'Port ' + SearchText, 'both@tryal.example');
        CreateCustomer('TRYAL-X10 ' + SearchText + ' Freight', 'TRYAL-X10 Plainville', 'name@tryal.example');

        Assert.AreEqual(2, CrossSearch.CountContactableMatches(SearchText),
            'Expected the customer carrying the text in Name and City to count exactly once among the contactable matches — not once per column');
    end;

    local procedure CreateCustomer(NewName: Text; NewCity: Text; NewEmail: Text)
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := CopyStr(NewName, 1, MaxStrLen(Customer.Name));
        Customer.City := CopyStr(NewCity, 1, MaxStrLen(Customer.City));
        Customer."E-Mail" := CopyStr(NewEmail, 1, MaxStrLen(Customer."E-Mail"));
        Customer.Modify(true);
    end;
}
