codeunit 50900 "Customer Certificates Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CertificateThatExpiredTheDayBeforeIsExpired()
    var
        Customer: Record Customer;
        CustomerCertificates: Codeunit "Customer Certificates";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A certificate that expired the day before the check date is expired
        // [GIVEN] a customer whose certificate expired on 14 March 2024
        InsertCustomer('TRYAL-CE1', 20240314D);
        Customer.Get('TRYAL-CE1');

        // [WHEN] checking as of 15 March 2024
        // [THEN] the certificate is expired
        Assert.IsTrue(CustomerCertificates.IsExpired(Customer, 20240315D),
            'Expected a certificate that expired on 14 March 2024 to be reported expired as of 15 March 2024');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CertificateThatExpiredLongAgoIsExpired()
    var
        Customer: Record Customer;
        CustomerCertificates: Codeunit "Customer Certificates";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Expiry: Date;
    begin
        // [SCENARIO] A certificate that expired a random number of days before the check date is expired
        // [GIVEN] a customer whose certificate expired 2-3000 days before 15 March 2024
        Expiry := 20240315D - Any.IntegerInRange(2, 3000);
        InsertCustomer('TRYAL-CE2', Expiry);
        Customer.Get('TRYAL-CE2');

        // [WHEN] checking as of 15 March 2024
        // [THEN] the certificate is expired
        Assert.IsTrue(CustomerCertificates.IsExpired(Customer, 20240315D),
            StrSubstNo('Expected a certificate that expired on %1 to be reported expired as of 15 March 2024', Expiry));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CertificateExpiringOnTheCheckDateIsNotExpired()
    var
        Customer: Record Customer;
        CustomerCertificates: Codeunit "Customer Certificates";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A certificate is valid through its expiry date
        // [GIVEN] a customer whose certificate expires on 15 March 2024
        InsertCustomer('TRYAL-CE3', 20240315D);
        Customer.Get('TRYAL-CE3');

        // [WHEN] checking as of 15 March 2024
        // [THEN] the certificate is not expired
        Assert.IsFalse(CustomerCertificates.IsExpired(Customer, 20240315D),
            'Expected a certificate expiring on 15 March 2024 not to be expired as of 15 March 2024 — a certificate is valid through its expiry date, so only a strictly earlier expiry is expired');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CertificateExpiringLaterIsNotExpired()
    var
        Customer: Record Customer;
        CustomerCertificates: Codeunit "Customer Certificates";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Expiry: Date;
    begin
        // [SCENARIO] A certificate expiring after the check date is not expired
        // [GIVEN] a customer whose certificate expires 1-3000 days after 15 March 2024
        Expiry := 20240315D + Any.IntegerInRange(1, 3000);
        InsertCustomer('TRYAL-CE4', Expiry);
        Customer.Get('TRYAL-CE4');

        // [WHEN] checking as of 15 March 2024
        // [THEN] the certificate is not expired
        Assert.IsFalse(CustomerCertificates.IsExpired(Customer, 20240315D),
            StrSubstNo('Expected a certificate expiring on %1 not to be expired as of 15 March 2024', Expiry));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankCertificateExpiryNeverExpires()
    var
        Customer: Record Customer;
        CustomerCertificates: Codeunit "Customer Certificates";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        AsOf: Date;
    begin
        // [SCENARIO] A blank expiry means the certificate never expires
        // [GIVEN] a customer with a blank Certificate Expiry and a random check date between 2000 and 2098
        AsOf := Any.DateInRange(20000101D, 1, 36000);
        InsertCustomer('TRYAL-CE5', 0D);
        Customer.Get('TRYAL-CE5');

        // [WHEN] checking as of that date
        // [THEN] the certificate is not expired
        Assert.IsFalse(CustomerCertificates.IsExpired(Customer, AsOf),
            StrSubstNo('Expected a customer with a blank Certificate Expiry not to be expired as of %1 — blank means the certificate never expires, but 0D sorts before every real date, so a plain comparison reports it as expired', AsOf));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EarliestExpiryIsTheSmallestDateInTheSet()
    var
        Customer: Record Customer;
        CustomerCertificates: Codeunit "Customer Certificates";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Base: Date;
    begin
        // [SCENARIO] The earliest expiry is the smallest real date in the filtered set
        // [GIVEN] four customers with random real expiries, the earliest neither first nor last in the set
        Base := Any.DateInRange(20200101D, 1, 3000);
        InsertCustomer('TRYAL-CE6-1', Base + 45);
        InsertCustomer('TRYAL-CE6-2', Base);
        InsertCustomer('TRYAL-CE6-3', Base + 200);
        InsertCustomer('TRYAL-CE6-4', Base + 10);
        Customer.SetFilter("No.", 'TRYAL-CE6-*');

        // [WHEN] asking for the earliest expiry of the group
        // [THEN] it is the smallest of the four dates
        Assert.AreEqual(Base, CustomerCertificates.EarliestExpiry(Customer),
            'Expected EarliestExpiry to return the smallest Certificate Expiry among the four customers in the filter — the earliest date belongs neither to the first nor to the last customer of the set');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EarliestExpirySkipsBlankCertificates()
    var
        Customer: Record Customer;
        CustomerCertificates: Codeunit "Customer Certificates";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Base: Date;
    begin
        // [SCENARIO] Blank expiries never win the minimum
        // [GIVEN] blank customers before, between and after two customers with real expiries
        Base := Any.DateInRange(20200101D, 1, 3000);
        InsertCustomer('TRYAL-CE7-1', 0D);
        InsertCustomer('TRYAL-CE7-2', Base + 30);
        InsertCustomer('TRYAL-CE7-3', 0D);
        InsertCustomer('TRYAL-CE7-4', Base);
        InsertCustomer('TRYAL-CE7-5', 0D);
        Customer.SetFilter("No.", 'TRYAL-CE7-*');

        // [WHEN] asking for the earliest expiry of the group
        // [THEN] it is the earliest real date
        Assert.AreEqual(Base, CustomerCertificates.EarliestExpiry(Customer),
            'Expected EarliestExpiry to return the earliest real Certificate Expiry and skip the blank ones — a blank date means never expires, yet 0D sorts before every real date, so a naive minimum returns 0D');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EarliestExpiryIsBlankWhenEveryCertificateIsBlank()
    var
        Customer: Record Customer;
        CustomerCertificates: Codeunit "Customer Certificates";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A set of customers without certificates has no earliest expiry
        // [GIVEN] three customers with a blank Certificate Expiry
        InsertCustomer('TRYAL-CE8-1', 0D);
        InsertCustomer('TRYAL-CE8-2', 0D);
        InsertCustomer('TRYAL-CE8-3', 0D);
        Customer.SetFilter("No.", 'TRYAL-CE8-*');

        // [WHEN] asking for the earliest expiry of the group
        // [THEN] it is 0D
        Assert.AreEqual(0D, CustomerCertificates.EarliestExpiry(Customer),
            'Expected EarliestExpiry to return 0D when no customer in the set has a Certificate Expiry at all');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EarliestExpiryIsBlankWhenTheFilterMatchesNoCustomer()
    var
        Customer: Record Customer;
        CustomerCertificates: Codeunit "Customer Certificates";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] An empty set has no earliest expiry
        // [GIVEN] a dated customer and a filter that matches no customer
        InsertCustomer('TRYAL-CE9-1', 20240315D);
        Customer.SetRange("No.", 'TRYAL-CE9-NONE');

        // [WHEN] asking for the earliest expiry of the empty set
        // [THEN] it is 0D
        Assert.AreEqual(0D, CustomerCertificates.EarliestExpiry(Customer),
            'Expected EarliestExpiry to return 0D for a filter that matches no customer — an empty set has no earliest expiry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EarliestExpiryRespectsTheCallersFilters()
    var
        Customer: Record Customer;
        CustomerCertificates: Codeunit "Customer Certificates";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Base: Date;
    begin
        // [SCENARIO] Customers outside the caller's filter are not considered
        // [GIVEN] a customer outside the filter expiring earlier than the two inside it
        Base := Any.DateInRange(20200101D, 1, 3000);
        InsertCustomer('TRYAL-CE10-OUT', Base - 100);
        InsertCustomer('TRYAL-CE10-IN1', Base + 5);
        InsertCustomer('TRYAL-CE10-IN2', Base + 1);
        Customer.SetFilter("No.", 'TRYAL-CE10-IN*');

        // [WHEN] asking for the earliest expiry of the filtered group
        // [THEN] it is the earliest date inside the filter
        Assert.AreEqual(Base + 1, CustomerCertificates.EarliestExpiry(Customer),
            'Expected EarliestExpiry to consider only the customers inside the caller''s filter — TRYAL-CE10-OUT expires earlier but lies outside it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EarliestExpiryLeavesTheCallersFiltersUntouched()
    var
        Customer: Record Customer;
        CustomerCertificates: Codeunit "Customer Certificates";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] The caller's record shows the same set after the call
        // [GIVEN] a group of two blank customers and one dated customer, filtered on No.
        InsertCustomer('TRYAL-CE11-1', 0D);
        InsertCustomer('TRYAL-CE11-2', Any.DateInRange(20200101D, 1, 3000));
        InsertCustomer('TRYAL-CE11-3', 0D);
        Customer.SetFilter("No.", 'TRYAL-CE11-*');

        // [WHEN] asking for the earliest expiry of the group
        CustomerCertificates.EarliestExpiry(Customer);

        // [THEN] the record still counts all three customers and carries no filter on the expiry field
        Assert.AreEqual(3, Customer.Count(),
            'Expected the caller''s record to still see all three customers of the group (blank ones included) after EarliestExpiry — the procedure must not leave a filter of its own on the record it was given');
        Assert.AreEqual('', Customer.GetFilter("Certificate Expiry"),
            'Expected no filter on Certificate Expiry to remain on the caller''s record after EarliestExpiry');
    end;

    local procedure InsertCustomer(CustomerNo: Code[20]; Expiry: Date)
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer."No." := CustomerNo;
        Customer."Certificate Expiry" := Expiry;
        Customer.Insert();
    end;
}
