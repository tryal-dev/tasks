codeunit 50900 "Order Counter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountOpenOrdersCountsOnlyThatCustomersOpenOrders()
    var
        OrderCounter: Codeunit "Order Counter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CustomerA: Code[20];
        CustomerB: Code[20];
        OpenOrders: Integer;
        i: Integer;
    begin
        // [SCENARIO] A single call on a fresh instance counts the customer's open orders and nothing else
        // [GIVEN] a customer with several open orders, a released order and a quote, and another customer with an open order
        CustomerA := CreateCustomerNo();
        CustomerB := CreateCustomerNo();
        OpenOrders := Any.IntegerInRange(2, 4);
        for i := 1 to OpenOrders do
            CreateOrder(CustomerA, "Sales Document Status"::Open);
        CreateOrder(CustomerA, "Sales Document Status"::Released);
        CreateQuote(CustomerA);
        CreateOrder(CustomerB, "Sales Document Status"::Open);

        // [WHEN] counting the first customer's open orders
        // [THEN] only its open orders are counted
        Assert.AreEqual(OpenOrders, OrderCounter.CountOpenOrders(CustomerA),
            'Expected CountOpenOrders to count only the open orders of the given customer — not its released order, not its quote, not another customer''s order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountAllOrdersCountsEveryOrderWhateverTheCustomerOrStatus()
    var
        OrderCounter: Codeunit "Order Counter";
        Assert: Codeunit Assert;
        CustomerA: Code[20];
        CustomerB: Code[20];
        ExpectedOrders: Integer;
    begin
        // [SCENARIO] A single call on a fresh instance counts every order in the company, quotes excluded
        // [GIVEN] orders in three statuses for two customers, and a quote
        CustomerA := CreateCustomerNo();
        CustomerB := CreateCustomerNo();
        CreateOrder(CustomerA, "Sales Document Status"::Open);
        CreateOrder(CustomerA, "Sales Document Status"::Released);
        CreateOrder(CustomerB, "Sales Document Status"::"Pending Approval");
        CreateQuote(CustomerB);
        ExpectedOrders := CountOrdersInDatabase();

        // [WHEN] counting all orders
        // [THEN] the count equals the number of sales orders in the database
        Assert.AreEqual(ExpectedOrders, OrderCounter.CountAllOrders(),
            'Expected CountAllOrders to count every sales order in the company, whatever its customer or status, and no quotes');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountOrdersForCustomersCountsEveryOrderOfTheListedCustomers()
    var
        OrderCounter: Codeunit "Order Counter";
        Assert: Codeunit Assert;
        CustomerA: Code[20];
        CustomerB: Code[20];
        CustomerC: Code[20];
        CustomerNos: List of [Code[20]];
    begin
        // [SCENARIO] A single call on a fresh instance counts the orders of the listed customers in every status
        // [GIVEN] two listed customers with orders in mixed statuses and a quote, and an unlisted customer with an order
        CustomerA := CreateCustomerNo();
        CustomerB := CreateCustomerNo();
        CustomerC := CreateCustomerNo();
        CreateOrder(CustomerA, "Sales Document Status"::Open);
        CreateOrder(CustomerA, "Sales Document Status"::Released);
        CreateQuote(CustomerA);
        CreateOrder(CustomerB, "Sales Document Status"::"Pending Approval");
        CreateOrder(CustomerC, "Sales Document Status"::Open);
        CustomerNos.Add(CustomerA);
        CustomerNos.Add(CustomerB);

        // [WHEN] counting the orders of the two listed customers
        // [THEN] their three orders are counted; the quote and the unlisted customer's order are not
        Assert.AreEqual(3, OrderCounter.CountOrdersForCustomers(CustomerNos),
            'Expected CountOrdersForCustomers to count every order of the listed customers once, whatever its status — and neither the quote nor the unlisted customer''s order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountAllOrdersAfterCountOpenOrdersStillCountsEveryOrder()
    var
        OrderCounter: Codeunit "Order Counter";
        Assert: Codeunit Assert;
        CustomerA: Code[20];
        CustomerB: Code[20];
        ExpectedOrders: Integer;
    begin
        // [SCENARIO] The total is the same right after a customer-scoped count ran on the same instance
        // [GIVEN] orders for two customers in mixed statuses, and an instance that has just counted one customer's open orders
        CustomerA := CreateCustomerNo();
        CustomerB := CreateCustomerNo();
        CreateOrder(CustomerA, "Sales Document Status"::Open);
        CreateOrder(CustomerA, "Sales Document Status"::Released);
        CreateOrder(CustomerB, "Sales Document Status"::Open);
        ExpectedOrders := CountOrdersInDatabase();
        OrderCounter.CountOpenOrders(CustomerA);

        // [WHEN] counting all orders on that instance
        // [THEN] every order in the database is counted
        Assert.AreEqual(ExpectedOrders, OrderCounter.CountAllOrders(),
            'Expected CountAllOrders to count every order in the company right after CountOpenOrders ran on the same instance — the customer and status filters of the previous call must not narrow this one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountOpenOrdersAfterCountAllOrdersCountsOnlyThatCustomersOpenOrders()
    var
        OrderCounter: Codeunit "Order Counter";
        Assert: Codeunit Assert;
        CustomerA: Code[20];
        CustomerB: Code[20];
    begin
        // [SCENARIO] A customer-scoped count is right after the total ran on the same instance
        // [GIVEN] a customer with two open orders and a released one, another customer with an open order, and an instance that has just counted all orders
        CustomerA := CreateCustomerNo();
        CustomerB := CreateCustomerNo();
        CreateOrder(CustomerA, "Sales Document Status"::Open);
        CreateOrder(CustomerA, "Sales Document Status"::Open);
        CreateOrder(CustomerA, "Sales Document Status"::Released);
        CreateOrder(CustomerB, "Sales Document Status"::Open);
        OrderCounter.CountAllOrders();

        // [WHEN] counting the first customer's open orders on that instance
        // [THEN] exactly its two open orders are counted
        Assert.AreEqual(2, OrderCounter.CountOpenOrders(CustomerA),
            'Expected CountOpenOrders to count only the customer''s open orders right after CountAllOrders ran on the same instance');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountOpenOrdersForASecondCustomerCountsOnlyThatCustomer()
    var
        OrderCounter: Codeunit "Order Counter";
        Assert: Codeunit Assert;
        CustomerA: Code[20];
        CustomerB: Code[20];
    begin
        // [SCENARIO] Counting a second customer's open orders on the same instance ignores the first customer
        // [GIVEN] two customers with open orders, and an instance that has just counted the first customer
        CustomerA := CreateCustomerNo();
        CustomerB := CreateCustomerNo();
        CreateOrder(CustomerA, "Sales Document Status"::Open);
        CreateOrder(CustomerA, "Sales Document Status"::Open);
        CreateOrder(CustomerB, "Sales Document Status"::Open);
        CreateOrder(CustomerB, "Sales Document Status"::Released);
        OrderCounter.CountOpenOrders(CustomerA);

        // [WHEN] counting the second customer's open orders on that instance
        // [THEN] exactly its one open order is counted
        Assert.AreEqual(1, OrderCounter.CountOpenOrders(CustomerB),
            'Expected CountOpenOrders for a second customer on the same instance to count only that customer''s open orders');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountOrdersForCustomersAfterCountOpenOrdersCountsReleasedOrdersToo()
    var
        OrderCounter: Codeunit "Order Counter";
        Assert: Codeunit Assert;
        CustomerA: Code[20];
        CustomerB: Code[20];
        CustomerNos: List of [Code[20]];
    begin
        // [SCENARIO] Orders of every status are counted right after an open-only count ran on the same instance
        // [GIVEN] two customers with one open and two released orders between them, and an instance that has just counted open orders
        CustomerA := CreateCustomerNo();
        CustomerB := CreateCustomerNo();
        CreateOrder(CustomerA, "Sales Document Status"::Open);
        CreateOrder(CustomerA, "Sales Document Status"::Released);
        CreateOrder(CustomerB, "Sales Document Status"::Released);
        CustomerNos.Add(CustomerA);
        CustomerNos.Add(CustomerB);
        OrderCounter.CountOpenOrders(CustomerA);

        // [WHEN] counting the orders of both customers on that instance
        // [THEN] all three orders are counted, the released ones included
        Assert.AreEqual(3, OrderCounter.CountOrdersForCustomers(CustomerNos),
            'Expected CountOrdersForCustomers to count the released orders too right after CountOpenOrders ran on the same instance — the status filter of the previous call must not survive into this one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountAllOrdersAfterCountOrdersForCustomersStillCountsEveryOrder()
    var
        OrderCounter: Codeunit "Order Counter";
        Assert: Codeunit Assert;
        CustomerA: Code[20];
        CustomerB: Code[20];
        CustomerNos: List of [Code[20]];
        ExpectedOrders: Integer;
    begin
        // [SCENARIO] The total is the same right after a marked customer list was counted on the same instance
        // [GIVEN] orders for two customers, and an instance that has just counted the orders of the first customer only
        CustomerA := CreateCustomerNo();
        CustomerB := CreateCustomerNo();
        CreateOrder(CustomerA, "Sales Document Status"::Open);
        CreateOrder(CustomerB, "Sales Document Status"::Open);
        CreateOrder(CustomerB, "Sales Document Status"::Released);
        ExpectedOrders := CountOrdersInDatabase();
        CustomerNos.Add(CustomerA);
        OrderCounter.CountOrdersForCustomers(CustomerNos);

        // [WHEN] counting all orders on that instance
        // [THEN] every order in the database is counted
        Assert.AreEqual(ExpectedOrders, OrderCounter.CountAllOrders(),
            'Expected CountAllOrders to count every order in the company right after CountOrdersForCustomers ran on the same instance — the marked-only view of the previous call must not narrow this one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountOpenOrdersAfterCountOrdersForCustomersCountsThatCustomersOpenOrders()
    var
        OrderCounter: Codeunit "Order Counter";
        Assert: Codeunit Assert;
        CustomerA: Code[20];
        CustomerB: Code[20];
        CustomerNos: List of [Code[20]];
    begin
        // [SCENARIO] A customer outside the previously counted list is counted correctly on the same instance
        // [GIVEN] two customers with orders, and an instance that has just counted the orders of the first customer only
        CustomerA := CreateCustomerNo();
        CustomerB := CreateCustomerNo();
        CreateOrder(CustomerA, "Sales Document Status"::Open);
        CreateOrder(CustomerB, "Sales Document Status"::Open);
        CreateOrder(CustomerB, "Sales Document Status"::Open);
        CreateOrder(CustomerB, "Sales Document Status"::Released);
        CustomerNos.Add(CustomerA);
        OrderCounter.CountOrdersForCustomers(CustomerNos);

        // [WHEN] counting the second customer's open orders on that instance
        // [THEN] exactly its two open orders are counted
        Assert.AreEqual(2, OrderCounter.CountOpenOrders(CustomerB),
            'Expected CountOpenOrders to count the second customer''s open orders right after CountOrdersForCustomers ran for the first customer on the same instance — the marked-only view of the previous call must not hide them');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountOrdersForCustomersTwiceCountsOnlyTheSecondList()
    var
        OrderCounter: Codeunit "Order Counter";
        Assert: Codeunit Assert;
        CustomerA: Code[20];
        CustomerB: Code[20];
        FirstList: List of [Code[20]];
        SecondList: List of [Code[20]];
    begin
        // [SCENARIO] A second customer-list count on the same instance counts only its own list
        // [GIVEN] two customers with orders, and an instance that has just counted the first customer's orders
        CustomerA := CreateCustomerNo();
        CustomerB := CreateCustomerNo();
        CreateOrder(CustomerA, "Sales Document Status"::Open);
        CreateOrder(CustomerA, "Sales Document Status"::Released);
        CreateOrder(CustomerB, "Sales Document Status"::Open);
        FirstList.Add(CustomerA);
        SecondList.Add(CustomerB);
        OrderCounter.CountOrdersForCustomers(FirstList);

        // [WHEN] counting the second customer's orders on that instance
        // [THEN] exactly its one order is counted
        Assert.AreEqual(1, OrderCounter.CountOrdersForCustomers(SecondList),
            'Expected a second CountOrdersForCustomers call on the same instance to count only the customers in its own list — the marks of the previous call must not carry over');
    end;

    local procedure CreateCustomerNo(): Code[20]
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        exit(LibrarySales.CreateCustomerNo());
    end;

    local procedure CreateOrder(CustomerNo: Code[20]; OrderStatus: Enum "Sales Document Status")
    var
        SalesHeader: Record "Sales Header";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, CustomerNo);
        // Written without the trigger: releasing through the standard codeunit
        // needs lines, and only the stored status matters to the counter.
        SalesHeader.Status := OrderStatus;
        SalesHeader.Modify();
    end;

    local procedure CreateQuote(CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Quote, CustomerNo);
    end;

    // The shared test company already holds sales orders, so the expected total
    // is read from the database with a fresh record rather than hardcoded.
    local procedure CountOrdersInDatabase(): Integer
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", "Sales Document Type"::Order);
        exit(SalesHeader.Count());
    end;
}
