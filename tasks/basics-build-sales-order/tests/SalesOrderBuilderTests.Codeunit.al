codeunit 50900 "Sales Order Builder Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Sales] [Sales Order Builder]

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreateOrderReturnsAStoredOrderForTheCustomer()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesOrderBuilder: Codeunit "Sales Order Builder";
        OrderNo: Code[20];
    begin
        // [SCENARIO] CreateOrder stores a sales order for the customer and returns its No.
        // [GIVEN] a customer
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] creating an order for that customer
        OrderNo := SalesOrderBuilder.CreateOrder(Customer."No.");

        // [THEN] an Order document with the returned No. exists and is sold to that customer
        GetOrder(SalesHeader, OrderNo);
        Assert.AreEqual(Customer."No.", SalesHeader."Sell-to Customer No.",
            'Expected the created order to be sold to the customer passed to CreateOrder');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OrderIsNumberedFromTheOrderNumberSeries()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesOrderBuilder: Codeunit "Sales Order Builder";
    begin
        // [SCENARIO] The order is numbered by the document itself, from the order number series
        // [GIVEN] a customer
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] creating an order for that customer
        GetOrder(SalesHeader, SalesOrderBuilder.CreateOrder(Customer."No."));

        // [THEN] the order was numbered from the "Order Nos." series of Sales & Receivables Setup
        SalesReceivablesSetup.Get();
        Assert.AreEqual(SalesReceivablesSetup."Order Nos.", SalesHeader."No. Series",
            'Expected the order to be numbered from the "Order Nos." series in Sales & Receivables Setup, which is what letting the header''s insert trigger run gives you');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OrderInheritsPaymentTermsFromTheCustomer()
    var
        Customer: Record Customer;
        PayerCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesOrderBuilder: Codeunit "Sales Order Builder";
    begin
        // [SCENARIO] The order picks up the payment terms the customer card carries
        // [GIVEN] a customer with payment terms, a salesperson, a currency and a separate payer
        CreateCustomerWithSalesDefaults(Customer, PayerCustomer);

        // [WHEN] creating an order for that customer
        GetOrder(SalesHeader, SalesOrderBuilder.CreateOrder(Customer."No."));

        // [THEN] the order carries the customer's payment terms
        Assert.AreEqual(Customer."Payment Terms Code", SalesHeader."Payment Terms Code",
            'Expected the order to inherit "Payment Terms Code" from the customer, the way the Sales Order page fills it in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OrderInheritsSalespersonFromTheCustomer()
    var
        Customer: Record Customer;
        PayerCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesOrderBuilder: Codeunit "Sales Order Builder";
    begin
        // [SCENARIO] The order picks up the salesperson the customer card carries
        // [GIVEN] a customer with payment terms, a salesperson, a currency and a separate payer
        CreateCustomerWithSalesDefaults(Customer, PayerCustomer);

        // [WHEN] creating an order for that customer
        GetOrder(SalesHeader, SalesOrderBuilder.CreateOrder(Customer."No."));

        // [THEN] the order carries the customer's salesperson
        Assert.AreEqual(Customer."Salesperson Code", SalesHeader."Salesperson Code",
            'Expected the order to inherit "Salesperson Code" from the customer, the way the Sales Order page fills it in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OrderInheritsCurrencyFromTheCustomer()
    var
        Customer: Record Customer;
        PayerCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesOrderBuilder: Codeunit "Sales Order Builder";
    begin
        // [SCENARIO] The order picks up the currency the customer card carries
        // [GIVEN] a customer with payment terms, a salesperson, a currency and a separate payer
        CreateCustomerWithSalesDefaults(Customer, PayerCustomer);

        // [WHEN] creating an order for that customer
        GetOrder(SalesHeader, SalesOrderBuilder.CreateOrder(Customer."No."));

        // [THEN] the order carries the customer's currency
        Assert.AreEqual(Customer."Currency Code", SalesHeader."Currency Code",
            'Expected the order to inherit "Currency Code" from the customer, the way the Sales Order page fills it in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OrderInheritsBillToCustomerFromTheCustomer()
    var
        Customer: Record Customer;
        PayerCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesOrderBuilder: Codeunit "Sales Order Builder";
    begin
        // [SCENARIO] An order for a customer that is invoiced through another customer is billed to that other customer
        // [GIVEN] a customer whose "Bill-to Customer No." points at a second customer
        CreateCustomerWithSalesDefaults(Customer, PayerCustomer);

        // [WHEN] creating an order for that customer
        GetOrder(SalesHeader, SalesOrderBuilder.CreateOrder(Customer."No."));

        // [THEN] the order is billed to the second customer, not to the sell-to customer
        Assert.AreEqual(PayerCustomer."No.", SalesHeader."Bill-to Customer No.",
            'Expected the order to be billed to the "Bill-to Customer No." of the sell-to customer, not to the sell-to customer itself');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OrderIsBilledToTheCustomerItselfWhenItHasNoPayer()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesOrderBuilder: Codeunit "Sales Order Builder";
    begin
        // [SCENARIO] An ordinary customer pays its own invoices
        // [GIVEN] a customer whose "Bill-to Customer No." is blank
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] creating an order for that customer
        GetOrder(SalesHeader, SalesOrderBuilder.CreateOrder(Customer."No."));

        // [THEN] the order is billed to that same customer
        Assert.AreEqual(Customer."No.", SalesHeader."Bill-to Customer No.",
            'Expected the order to be billed to the customer itself when the customer card names no other payer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LineInheritsDescriptionFromTheItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrderBuilder: Codeunit "Sales Order Builder";
    begin
        // [SCENARIO] Putting an item on a line copies the item's description onto the line
        // [GIVEN] an order and an item with a generated description
        CreateItemForSale(Item);
        CreateOrderWithLibrary(SalesHeader);

        // [WHEN] adding a line for that item
        GetLine(SalesLine, SalesHeader."No.", SalesOrderBuilder.AddLine(SalesHeader."No.", Item."No.", LibraryRandom.RandIntInRange(2, 9)));

        // [THEN] the line shows the item's description
        Assert.AreEqual(Item.Description, SalesLine.Description,
            'Expected the line to inherit Description from the item, the way a line typed on the Sales Order page does');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LineInheritsUnitOfMeasureFromTheItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrderBuilder: Codeunit "Sales Order Builder";
    begin
        // [SCENARIO] Putting an item on a line copies the item's sales unit of measure onto the line
        // [GIVEN] an order and an item whose "Sales Unit of Measure" differs from its base unit of measure
        CreateItemForSale(Item);
        CreateOrderWithLibrary(SalesHeader);

        // [WHEN] adding a line for that item
        GetLine(SalesLine, SalesHeader."No.", SalesOrderBuilder.AddLine(SalesHeader."No.", Item."No.", LibraryRandom.RandIntInRange(2, 9)));

        // [THEN] the line is measured in the item's sales unit of measure
        Assert.AreEqual(Item."Sales Unit of Measure", SalesLine."Unit of Measure Code",
            'Expected the line to inherit "Unit of Measure Code" from the item''s "Sales Unit of Measure"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LineInheritsUnitPriceFromTheItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrderBuilder: Codeunit "Sales Order Builder";
    begin
        // [SCENARIO] Putting an item on a line prices the line from the item card
        // [GIVEN] an order and an item with a generated unit price
        CreateItemForSale(Item);
        CreateOrderWithLibrary(SalesHeader);

        // [WHEN] adding a line for that item
        GetLine(SalesLine, SalesHeader."No.", SalesOrderBuilder.AddLine(SalesHeader."No.", Item."No.", LibraryRandom.RandIntInRange(2, 9)));

        // [THEN] the line is priced at the item's unit price
        Assert.AreEqual(Item."Unit Price", SalesLine."Unit Price",
            'Expected the line to be priced from the item — a blank "Unit Price" means the item was never validated onto the line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LineCarriesTheRequestedQuantity()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrderBuilder: Codeunit "Sales Order Builder";
        Quantity: Decimal;
    begin
        // [SCENARIO] The quantity reaches the line as an outstanding quantity, ready to ship
        // [GIVEN] an order and an item
        CreateItemForSale(Item);
        CreateOrderWithLibrary(SalesHeader);
        Quantity := LibraryRandom.RandIntInRange(2, 9);

        // [WHEN] adding a line for that item and quantity
        GetLine(SalesLine, SalesHeader."No.", SalesOrderBuilder.AddLine(SalesHeader."No.", Item."No.", Quantity));

        // [THEN] the line holds the quantity, and the whole quantity is still outstanding
        Assert.AreEqual(Quantity, SalesLine.Quantity, 'Expected the line to hold the quantity passed to AddLine');
        Assert.AreEqual(Quantity, SalesLine."Outstanding Quantity",
            'Expected the whole quantity to be outstanding on the line — the order still has to ship it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LineAmountFollowsQuantityAndUnitPrice()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrderBuilder: Codeunit "Sales Order Builder";
        Quantity: Decimal;
    begin
        // [SCENARIO] The line amount of a plain line is quantity times unit price
        // [GIVEN] an order and an item with a generated unit price
        CreateItemForSale(Item);
        CreateOrderWithLibrary(SalesHeader);
        Quantity := LibraryRandom.RandIntInRange(2, 9);

        // [WHEN] adding a line for that item and quantity
        GetLine(SalesLine, SalesHeader."No.", SalesOrderBuilder.AddLine(SalesHeader."No.", Item."No.", Quantity));

        // [THEN] the line amount is the quantity times the price on the line
        Assert.AreNearlyEqual(Round(Quantity * SalesLine."Unit Price", 0.01), SalesLine."Line Amount", 0.01,
            'Expected "Line Amount" to be Quantity * "Unit Price" — a zero amount means the quantity never went through its validation');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LineNumbersStepInTenThousands()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrderBuilder: Codeunit "Sales Order Builder";
        FirstLineNo: Integer;
        SecondLineNo: Integer;
        ThirdLineNo: Integer;
    begin
        // [SCENARIO] Lines added to an empty order are numbered 10000, 20000, 30000
        // [GIVEN] an order without lines and an item
        CreateItemForSale(Item);
        CreateOrderWithLibrary(SalesHeader);

        // [WHEN] adding three lines
        FirstLineNo := SalesOrderBuilder.AddLine(SalesHeader."No.", Item."No.", LibraryRandom.RandIntInRange(2, 9));
        SecondLineNo := SalesOrderBuilder.AddLine(SalesHeader."No.", Item."No.", LibraryRandom.RandIntInRange(2, 9));
        ThirdLineNo := SalesOrderBuilder.AddLine(SalesHeader."No.", Item."No.", LibraryRandom.RandIntInRange(2, 9));

        // [THEN] their line numbers step in 10000s, and the third line is stored under the number that was returned
        Assert.AreEqual(10000, FirstLineNo, 'Expected the first line of an empty order to be line no. 10000');
        Assert.AreEqual(20000, SecondLineNo, 'Expected the second line to be line no. 20000');
        Assert.AreEqual(30000, ThirdLineNo, 'Expected the third line to be line no. 30000');
        GetLine(SalesLine, SalesHeader."No.", ThirdLineNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegotiatedPriceEndsUpOnTheLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrderBuilder: Codeunit "Sales Order Builder";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [SCENARIO] A negotiated unit price replaces the item price on the line
        // [GIVEN] an order, an item priced from its card, and a different negotiated price
        CreateItemForSale(Item);
        CreateOrderWithLibrary(SalesHeader);
        Quantity := LibraryRandom.RandIntInRange(2, 9);
        UnitPrice := LibraryRandom.RandDecInRange(1000, 2000, 2);

        // [WHEN] adding a negotiated line at that price, without a discount
        GetLine(SalesLine, SalesHeader."No.",
            SalesOrderBuilder.AddNegotiatedLine(SalesHeader."No.", Item."No.", Quantity, UnitPrice, 0));

        // [THEN] the line is priced at the negotiated price, and the amount follows it
        Assert.AreEqual(UnitPrice, SalesLine."Unit Price", 'Expected the negotiated unit price to be the price on the line');
        Assert.AreNearlyEqual(Round(Quantity * UnitPrice, 0.01), SalesLine."Line Amount", 0.01,
            'Expected "Line Amount" to follow the negotiated price — assigning "Unit Price" instead of validating it leaves the amounts on the item price');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegotiatedDiscountEndsUpOnTheLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrderBuilder: Codeunit "Sales Order Builder";
        DiscountPct: Decimal;
        ExpectedDiscountAmount: Decimal;
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [SCENARIO] A negotiated line discount survives on the line and reduces the line amount
        // [GIVEN] an order, an item, a negotiated price and a negotiated discount percentage
        CreateItemForSale(Item);
        CreateOrderWithLibrary(SalesHeader);
        Quantity := LibraryRandom.RandIntInRange(2, 9);
        UnitPrice := LibraryRandom.RandDecInRange(1000, 2000, 2);
        DiscountPct := LibraryRandom.RandIntInRange(5, 25);

        // [WHEN] adding a negotiated line
        GetLine(SalesLine, SalesHeader."No.",
            SalesOrderBuilder.AddNegotiatedLine(SalesHeader."No.", Item."No.", Quantity, UnitPrice, DiscountPct));

        // [THEN] the discount is on the line, converted into an amount, and deducted from the line amount
        ExpectedDiscountAmount := Round(Round(Quantity * UnitPrice, 0.01) * DiscountPct / 100, 0.01);
        Assert.AreEqual(DiscountPct, SalesLine."Line Discount %",
            'Expected the negotiated "Line Discount %" to stay on the line — the document re-reads it from the price setup whenever Quantity is validated');
        Assert.AreNearlyEqual(ExpectedDiscountAmount, SalesLine."Line Discount Amount", 0.01,
            'Expected "Line Discount Amount" to be the discount percentage of Quantity * "Unit Price"');
        Assert.AreNearlyEqual(Round(Quantity * UnitPrice, 0.01) - ExpectedDiscountAmount, SalesLine."Line Amount", 0.01,
            'Expected "Line Amount" to be Quantity * "Unit Price" minus the line discount amount');
    end;

    local procedure GetOrder(var SalesHeader: Record "Sales Header"; OrderNo: Code[20])
    begin
        Assert.IsTrue(SalesHeader.Get(SalesHeader."Document Type"::Order, OrderNo),
            StrSubstNo('Expected CreateOrder to return the No. of a stored sales order, but no Order document exists with No. ''%1''', OrderNo));
    end;

    local procedure GetLine(var SalesLine: Record "Sales Line"; OrderNo: Code[20]; LineNo: Integer)
    begin
        Assert.IsTrue(SalesLine.Get(SalesLine."Document Type"::Order, OrderNo, LineNo),
            StrSubstNo('Expected the returned line no. to identify a stored sales line, but order %1 has no line no. %2', OrderNo, LineNo));
    end;

    local procedure CreateCustomerWithSalesDefaults(var Customer: Record Customer; var PayerCustomer: Record Customer)
    var
        PaymentTerms: Record "Payment Terms";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CurrencyCode: Code[10];
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        CurrencyCode := CreateCurrencyAtParity();

        // Payment terms and currency travel from the bill-to customer, the salesperson
        // from either card — both customers carry the same values so the assertions
        // hold whichever card the document reads.
        LibrarySales.CreateCustomer(PayerCustomer);
        ApplySalesDefaults(PayerCustomer, PaymentTerms.Code, SalespersonPurchaser.Code, CurrencyCode);

        LibrarySales.CreateCustomer(Customer);
        ApplySalesDefaults(Customer, PaymentTerms.Code, SalespersonPurchaser.Code, CurrencyCode);
        Customer.Validate("Bill-to Customer No.", PayerCustomer."No.");
        Customer.Modify(true);
    end;

    local procedure ApplySalesDefaults(var Customer: Record Customer; PaymentTermsCode: Code[10]; SalespersonCode: Code[20]; CurrencyCode: Code[10])
    begin
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Validate("Salesperson Code", SalespersonCode);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
    end;

    local procedure CreateCurrencyAtParity(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Amount Rounding Precision", 0.01);
        Currency.Validate("Unit-Amount Rounding Precision", 0.01);
        Currency.Modify(true);

        // Rate 1:1 on the work date, so the order can be created without the
        // currency moving any amount away from the values under test.
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 1, 1);
        exit(Currency.Code);
    end;

    local procedure CreateOrderWithLibrary(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
    end;

    local procedure CreateItemForSale(var Item: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
        Item.Validate(Description, LibraryRandom.RandText(30));
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 900, 2));
        Item.Modify(true);
    end;
}
