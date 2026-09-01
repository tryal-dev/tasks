codeunit 50900 "Customer Name Search Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExactSearchFindsExactlyThePlainName()
    var
        CustomerNameSearch: Codeunit "Customer Name Search";
        Assert: Codeunit Assert;
    begin
        CreateCustomerNamed('TRYAL-E1 Plain Trading');
        CreateCustomerNamed('TRYAL-E1 Plain Trading Co');

        Assert.AreEqual(1, CustomerNameSearch.CountExactName('TRYAL-E1 Plain Trading'),
            'Expected exactly one customer named TRYAL-E1 Plain Trading — a name that merely starts the same way must not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExactSearchCountsEveryCustomerWithThatName()
    var
        CustomerNameSearch: Codeunit "Customer Name Search";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SharedName: Text;
    begin
        SharedName := 'TRYAL-E2 ' + UpperCase(Any.AlphabeticText(10));
        CreateCustomerNamed(CopyStr(SharedName, 1, 100));
        CreateCustomerNamed(CopyStr(SharedName, 1, 100));

        Assert.AreEqual(2, CustomerNameSearch.CountExactName(SharedName),
            'Expected both customers carrying the identical name to be counted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExactSearchSurvivesApostropheAndAmpersand()
    var
        CustomerNameSearch: Codeunit "Customer Name Search";
        Assert: Codeunit Assert;
    begin
        CreateCustomerNamed('TRYAL-E3 O''Brien & Sons');
        CreateCustomerNamed('TRYAL-E3 OBrien Sons');

        Assert.AreEqual(1, CustomerNameSearch.CountExactName('TRYAL-E3 O''Brien & Sons'),
            'Expected the customer named O''Brien & Sons to be found — the apostrophe and the & must be matched literally, not parsed as filter syntax');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExactSearchTakesPipeLiterally()
    var
        CustomerNameSearch: Codeunit "Customer Name Search";
        Assert: Codeunit Assert;
    begin
        CreateCustomerNamed('TRYAL-E4 Import|TRYAL-E4 Export');
        CreateCustomerNamed('TRYAL-E4 Import');
        CreateCustomerNamed('TRYAL-E4 Export');

        Assert.AreEqual(1, CustomerNameSearch.CountExactName('TRYAL-E4 Import|TRYAL-E4 Export'),
            'Expected only the customer whose name literally contains the | character — a pipe in the search text must not turn into an either/or filter');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExactSearchTakesAsteriskLiterally()
    var
        CustomerNameSearch: Codeunit "Customer Name Search";
        Assert: Codeunit Assert;
    begin
        CreateCustomerNamed('TRYAL-E5 Star* Retail');
        CreateCustomerNamed('TRYAL-E5 Starfish Retail');

        Assert.AreEqual(1, CustomerNameSearch.CountExactName('TRYAL-E5 Star* Retail'),
            'Expected only the customer whose name literally contains the * character — a star in the search text must not act as a wildcard');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExactSearchTakesQuestionMarkLiterally()
    var
        CustomerNameSearch: Codeunit "Customer Name Search";
        Assert: Codeunit Assert;
    begin
        CreateCustomerNamed('TRYAL-E6 Hans?n Shipping');
        CreateCustomerNamed('TRYAL-E6 Hansen Shipping');

        Assert.AreEqual(1, CustomerNameSearch.CountExactName('TRYAL-E6 Hans?n Shipping'),
            'Expected only the customer whose name literally contains the ? character — a question mark in the search text must not match any one character');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExactSearchTakesRangeDotsLiterally()
    var
        CustomerNameSearch: Codeunit "Customer Name Search";
        Assert: Codeunit Assert;
    begin
        CreateCustomerNamed('TRYAL-E7 10..20 Storage');
        CreateCustomerNamed('TRYAL-E7 15 Storage');

        Assert.AreEqual(1, CustomerNameSearch.CountExactName('TRYAL-E7 10..20 Storage'),
            'Expected only the customer whose name literally contains .. — two dots in the search text must not turn into a range filter');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExactSearchFindsNothingWhenNoCustomerHasTheName()
    var
        CustomerNameSearch: Codeunit "Customer Name Search";
        Assert: Codeunit Assert;
    begin
        CreateCustomerNamed('TRYAL-E8 OMalley Daughters');

        Assert.AreEqual(0, CustomerNameSearch.CountExactName('TRYAL-E8 O''Malley & Daughters'),
            'Expected 0 when no customer carries the searched name — a hostile name that is absent must return zero, not an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContainsSearchFindsTheFragmentAnywhereInTheName()
    var
        CustomerNameSearch: Codeunit "Customer Name Search";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Fragment: Text;
    begin
        Fragment := Any.AlphabeticText(10);
        CreateCustomerNamed(CopyStr('TRYAL-C1 ' + Fragment + ' Logistics', 1, 100));
        CreateCustomerNamed(CopyStr(Fragment + ' TRYAL-C1', 1, 100));
        CreateCustomerNamed(CopyStr('TRYAL-C1 ' + Fragment, 1, 100));
        CreateCustomerNamed('TRYAL-C1 Plain Freight');

        Assert.AreEqual(3, CustomerNameSearch.CountNamesContaining(Fragment),
            'Expected the three customers carrying the fragment (at the start, in the middle and at the end of the name) and not the one without it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContainsSearchMatchesWhenFragmentIsTheWholeName()
    var
        CustomerNameSearch: Codeunit "Customer Name Search";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Fragment: Text;
    begin
        Fragment := 'TRYAL-C6 ' + Any.AlphabeticText(10);
        CreateCustomerNamed(CopyStr(Fragment, 1, 100));

        Assert.AreEqual(1, CustomerNameSearch.CountNamesContaining(Fragment),
            'Expected a fragment equal to the entire name to match it — contains includes the whole-name case');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContainsSearchIgnoresCase()
    var
        CustomerNameSearch: Codeunit "Customer Name Search";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Fragment: Text;
    begin
        Fragment := Any.AlphabeticText(10);
        CreateCustomerNamed(CopyStr('TRYAL-C2 ' + UpperCase(Fragment) + ' Group', 1, 100));

        Assert.AreEqual(1, CustomerNameSearch.CountNamesContaining(Fragment),
            'Expected a lowercase fragment to find the customer whose name carries it in uppercase — the contains search is case-insensitive');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContainsSearchSurvivesApostropheAndAmpersand()
    var
        CustomerNameSearch: Codeunit "Customer Name Search";
        Assert: Codeunit Assert;
    begin
        CreateCustomerNamed('TRYAL-C3 O''Brien & Sons Ltd');
        CreateCustomerNamed('TRYAL-C3 OBrien Sons Ltd');

        Assert.AreEqual(1, CustomerNameSearch.CountNamesContaining('O''Brien & Sons'),
            'Expected the fragment O''Brien & Sons to match only the name that literally contains it — quotes and & must not be parsed as filter syntax');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContainsSearchTakesParenthesesAndEqualsLiterally()
    var
        CustomerNameSearch: Codeunit "Customer Name Search";
        Assert: Codeunit Assert;
    begin
        CreateCustomerNamed('TRYAL-C4 Alpha (Beta) = Gamma');
        CreateCustomerNamed('TRYAL-C4 Alpha Beta Gamma');

        Assert.AreEqual(1, CustomerNameSearch.CountNamesContaining('(Beta) ='),
            'Expected the parentheses and = in the fragment to be matched literally, not treated as filter grouping or comparison');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContainsSearchTakesPipeLiterally()
    var
        CustomerNameSearch: Codeunit "Customer Name Search";
        Assert: Codeunit Assert;
    begin
        CreateCustomerNamed('TRYAL-C7 Import|Export GmbH');
        CreateCustomerNamed('TRYAL-C7 Import GmbH');
        CreateCustomerNamed('TRYAL-C7 Export GmbH');

        Assert.AreEqual(1, CustomerNameSearch.CountNamesContaining('Import|Export'),
            'Expected only the customer whose name literally contains Import|Export — a pipe in the fragment must not turn into an either/or filter');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContainsSearchFindsNothingWhenFragmentIsAbsent()
    var
        CustomerNameSearch: Codeunit "Customer Name Search";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        CreateCustomerNamed('TRYAL-C5 Ordinary Supplies');

        Assert.AreEqual(0, CustomerNameSearch.CountNamesContaining(Any.AlphabeticText(12)),
            'Expected no matches for a fragment that no customer name contains');
    end;

    local procedure CreateCustomerNamed(NewName: Text[100])
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, NewName);
        Customer.Modify(true);
    end;
}
