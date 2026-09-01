codeunit 50900 "Credit Limit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PositiveLimitPassesValidationAndIsStored()
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Limit: Decimal;
    begin
        LibrarySales.CreateCustomer(Customer);
        Limit := Any.DecimalInRange(1, 10000, 2);

        Customer.Validate("Internal Credit Limit", Limit);
        Customer.Modify();

        Customer.Get(Customer."No.");
        Assert.AreEqual(Limit, Customer."Internal Credit Limit",
            'Expected a positive "Internal Credit Limit" to pass validation and be stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroIsAllowed()
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
    begin
        LibrarySales.CreateCustomer(Customer);

        Customer.Validate("Internal Credit Limit", 0);

        Assert.AreEqual(0, Customer."Internal Credit Limit",
            'Expected zero to be accepted — only negative values are invalid');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeValueIsRejected()
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        LibrarySales.CreateCustomer(Customer);

        asserterror Customer.Validate("Internal Credit Limit", -Any.DecimalInRange(1, 10000, 2));

        Assert.ExpectedError('must not be negative');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure JustBelowZeroIsRejected()
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
    begin
        LibrarySales.CreateCustomer(Customer);

        asserterror Customer.Validate("Internal Credit Limit", -0.01);

        Assert.ExpectedError('must not be negative');
    end;
}
