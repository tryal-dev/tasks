codeunit 50900 "Customer Queries Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountWithoutSalespersonGrowsOnlyByTheCustomersWithoutACode()
    var
        CustomerQueries: Codeunit "Customer Queries";
        Any: Codeunit Any;
        SalespersonCode: Code[20];
        CountBefore: Integer;
        CountAfter: Integer;
        WithoutCode: Integer;
        WithCode: Integer;
        i: Integer;
    begin
        CountBefore := CustomerQueries.CountWithoutSalesperson();
        WithoutCode := Any.IntegerInRange(2, 5);
        WithCode := WithoutCode + 1;
        SalespersonCode := CreateSalespersonCode();
        for i := 1 to WithoutCode do
            CreateCustomer('TQS1-N' + Format(i), '');
        for i := 1 to WithCode do
            CreateCustomer('TQS1-C' + Format(i), SalespersonCode);

        CountAfter := CustomerQueries.CountWithoutSalesperson();

        Assert.AreEqual(WithoutCode, CountAfter - CountBefore,
            StrSubstNo('Expected the count of customers without a salesperson code to grow by exactly %1 after adding %1 customers without a code next to %2 customers that have one — customers carrying a salesperson code must stay out of the count', WithoutCode, WithCode));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountWithoutSalespersonIsUnchangedByCustomersThatHaveACode()
    var
        CustomerQueries: Codeunit "Customer Queries";
        CountBefore: Integer;
        CountAfter: Integer;
    begin
        CountBefore := CustomerQueries.CountWithoutSalesperson();
        CreateCustomer('TQS2-C1', CreateSalespersonCode());
        CreateCustomer('TQS2-C2', CreateSalespersonCode());
        CreateCustomer('TQS2-C3', CreateSalespersonCode());

        CountAfter := CustomerQueries.CountWithoutSalesperson();

        Assert.AreEqual(0, CountAfter - CountBefore,
            'Expected the count of customers without a salesperson code to stay the same after adding three customers that all have one — the count grew, so customers with a salesperson code are being counted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountInRangeIncludesBothEndsAndExcludesTheNeighbours()
    var
        CustomerQueries: Codeunit "Customer Queries";
        Prefix: Code[10];
        FromNo: Code[20];
        ToNo: Code[20];
    begin
        Prefix := GeneratedPrefix() + 'A';
        CreateCustomer(Prefix + '05', '');
        CreateCustomer(Prefix + '10', '');
        CreateCustomer(Prefix + '15', '');
        CreateCustomer(Prefix + '20', '');
        CreateCustomer(Prefix + '25', '');
        FromNo := Prefix + '10';
        ToNo := Prefix + '20';

        Assert.AreEqual(3, CustomerQueries.CountInRange(FromNo, ToNo),
            StrSubstNo('Expected the three customers numbered %1 through %2 — both boundary numbers included, the neighbours %3 and %4 excluded', FromNo, ToNo, Prefix + '05', Prefix + '25'));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountInRangeOfASingleNumberCountsThatCustomer()
    var
        CustomerQueries: Codeunit "Customer Queries";
        Prefix: Code[10];
        OnlyNo: Code[20];
    begin
        Prefix := GeneratedPrefix() + 'S';
        CreateCustomer(Prefix + '09', '');
        CreateCustomer(Prefix + '10', '');
        CreateCustomer(Prefix + '11', '');
        OnlyNo := Prefix + '10';

        Assert.AreEqual(1, CustomerQueries.CountInRange(OnlyNo, OnlyNo),
            StrSubstNo('Expected a range whose FromNo and ToNo are both %1 to count exactly that one customer', OnlyNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountInRangeCountsEveryCustomerInsideAWiderRange()
    var
        CustomerQueries: Codeunit "Customer Queries";
        Any: Codeunit Any;
        Prefix: Code[10];
        FromNo: Code[20];
        ToNo: Code[20];
        Inside: Integer;
        i: Integer;
    begin
        Prefix := GeneratedPrefix();
        Inside := Any.IntegerInRange(2, 8);
        for i := 1 to Inside do
            CreateCustomer(Prefix + 'B' + Format(i), '');
        CreateCustomer(Prefix + 'A9', '');
        CreateCustomer(Prefix + 'C0', '');
        FromNo := Prefix + 'B1';
        ToNo := Prefix + 'B' + Format(Inside);

        Assert.AreEqual(Inside, CustomerQueries.CountInRange(FromNo, ToNo),
            StrSubstNo('Expected every one of the %1 customers numbered %2 through %3 to be counted, and neither of the two customers outside that range', Inside, FromNo, ToNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountInRangeIsZeroWhenNoCustomerFallsInside()
    var
        CustomerQueries: Codeunit "Customer Queries";
        Prefix: Code[10];
        FromNo: Code[20];
        ToNo: Code[20];
    begin
        Prefix := GeneratedPrefix() + 'E';
        CreateCustomer(Prefix + '05', '');
        CreateCustomer(Prefix + '25', '');
        FromNo := Prefix + '10';
        ToNo := Prefix + '20';

        Assert.AreEqual(0, CustomerQueries.CountInRange(FromNo, ToNo),
            StrSubstNo('Expected 0 for the range %1 through %2 — the only customers under that prefix sit outside it', FromNo, ToNo));
    end;

    // Inserted without the trigger: Customer.OnInsert stamps the session user's
    // default salesperson from User Setup, which would turn a "blank" customer
    // into a coded one behind the test's back.
    local procedure CreateCustomer(CustomerNo: Code[20]; SalespersonCode: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer."No." := CustomerNo;
        Customer.Name := CustomerNo;
        Customer."Salesperson Code" := SalespersonCode;
        Customer.Insert();
    end;

    local procedure CreateSalespersonCode(): Code[20]
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        exit(SalespersonPurchaser.Code);
    end;

    // Nine-character numbers keep FromNo + '..' + ToNo inside Code[20], so the
    // starter's literal range string fails by matching nothing instead of by
    // overflowing the field.
    local procedure GeneratedPrefix(): Code[10]
    var
        Any: Codeunit Any;
    begin
        exit('TQ' + UpperCase(Any.AlphabeticText(3)) + '-');
    end;
}
