codeunit 50900 "Sales Guards Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsOverLimitIsFalseWhenQuantityIsZero()
    var
        Any: Codeunit Any;
        Total: Decimal;
        Limit: Decimal;
        Result: Boolean;
    begin
        // [SCENARIO] A line without quantity has no average to compare, so it is never over the limit
        // [GIVEN] a limit and a total well above it
        Limit := Any.DecimalInRange(1, 500, 2);
        Total := Limit + Any.DecimalInRange(1, 1000, 2);

        // [WHEN] checking the limit with a quantity of zero
        if not TryIsOverLimit(Total, 0, Limit, Result) then
            Assert.Fail(StrSubstNo('Expected IsOverLimit(%1, 0, %2) to return false without raising an error, but the call failed with: %3 — AL evaluates both operands of "and", so Total / Qty runs even when Qty <> 0 is false', Total, Limit, GetLastErrorText()));

        // [THEN] the line is not over the limit
        Assert.IsFalse(Result, StrSubstNo('Expected IsOverLimit(%1, 0, %2) to be false — a zero quantity is never over the limit, got %3', Total, Limit, Result));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsOverLimitIsTrueWhenAverageExceedsLimit()
    var
        SalesGuards: Codeunit "Sales Guards";
        Any: Codeunit Any;
        Qty: Decimal;
        Limit: Decimal;
        Average: Decimal;
        Total: Decimal;
    begin
        // [SCENARIO] A line whose average amount is above the limit is over the limit
        // [GIVEN] a random quantity and limit, and a total whose average lands above the limit
        Qty := Any.DecimalInRange(1, 50, 2);
        Limit := Any.DecimalInRange(1, 500, 2);
        Average := Limit + Any.DecimalInRange(1, 100, 2);
        Total := Qty * Average;

        // [WHEN] checking the limit
        // [THEN] the line is over the limit
        Assert.IsTrue(SalesGuards.IsOverLimit(Total, Qty, Limit),
            StrSubstNo('Expected IsOverLimit(%1, %2, %3) to be true — the average %4 is above the limit %3', Total, Qty, Limit, Average));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsOverLimitIsFalseWhenAverageIsBelowLimit()
    var
        SalesGuards: Codeunit "Sales Guards";
        Any: Codeunit Any;
        Qty: Decimal;
        Limit: Decimal;
        Average: Decimal;
        Total: Decimal;
    begin
        // [SCENARIO] A line whose average amount is below the limit is not over the limit
        // [GIVEN] a random quantity and limit, and a total whose average lands below the limit
        Qty := Any.DecimalInRange(1, 50, 2);
        Limit := Any.DecimalInRange(100, 500, 2);
        Average := Limit - Any.DecimalInRange(1, 99, 2);
        Total := Qty * Average;

        // [WHEN] checking the limit
        // [THEN] the line is not over the limit
        Assert.IsFalse(SalesGuards.IsOverLimit(Total, Qty, Limit),
            StrSubstNo('Expected IsOverLimit(%1, %2, %3) to be false — the average %4 is below the limit %3', Total, Qty, Limit, Average));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsOverLimitIsFalseWhenAverageEqualsLimit()
    var
        SalesGuards: Codeunit "Sales Guards";
        Any: Codeunit Any;
        Qty: Decimal;
        Limit: Decimal;
        Total: Decimal;
    begin
        // [SCENARIO] An average exactly on the limit is not over it
        // [GIVEN] a random whole quantity and limit, and a total whose average is exactly the limit
        Qty := Any.IntegerInRange(1, 50);
        Limit := Any.DecimalInRange(1, 500, 2);
        Total := Qty * Limit;

        // [WHEN] checking the limit
        // [THEN] the line is not over the limit
        Assert.IsFalse(SalesGuards.IsOverLimit(Total, Qty, Limit),
            StrSubstNo('Expected IsOverLimit(%1, %2, %3) to be false — the average equals the limit %3, and only a strictly greater average is over it', Total, Qty, Limit));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasOpenOrderIsFalseForBlankCustomer()
    var
        Result: Boolean;
    begin
        // [SCENARIO] A blank customer number has no open order and must not be looked up
        // [WHEN] asking about a blank customer number
        if not TryHasOpenOrder('', Result) then
            Assert.Fail(StrSubstNo('Expected HasOpenOrder('''') to return false without raising an error, but the call failed with: %1 — AL evaluates both operands of "and", so OpenOrderExists (and its Get) runs even when CustomerNo <> '''' is false', GetLastErrorText()));

        // [THEN] there is no open order
        Assert.IsFalse(Result, StrSubstNo('Expected HasOpenOrder('''') to be false — a blank number is no customer, got %1', Result));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasOpenOrderIsTrueForCustomerWithAnOpenOrder()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesGuards: Codeunit "Sales Guards";
    begin
        // [SCENARIO] A customer with a sales order in status Open has an open order
        // [GIVEN] a customer with one sales order in status Open
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [WHEN] asking about that customer
        // [THEN] there is an open order
        Assert.IsTrue(SalesGuards.HasOpenOrder(Customer."No."),
            StrSubstNo('Expected HasOpenOrder(%1) to be true — the customer has sales order %2 in status Open', Customer."No.", SalesHeader."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasOpenOrderIgnoresReleasedOrders()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesGuards: Codeunit "Sales Guards";
    begin
        // [SCENARIO] An order that is no longer in status Open does not count
        // [GIVEN] a customer whose only sales order is Released
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Status := SalesHeader.Status::Released;
        SalesHeader.Modify();

        // [WHEN] asking about that customer
        // [THEN] there is no open order
        Assert.IsFalse(SalesGuards.HasOpenOrder(Customer."No."),
            StrSubstNo('Expected HasOpenOrder(%1) to be false — the customer''s only sales order %2 is Released, and only orders in status Open count', Customer."No.", SalesHeader."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasOpenOrderIgnoresQuotes()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesGuards: Codeunit "Sales Guards";
    begin
        // [SCENARIO] A sales quote is not a sales order
        // [GIVEN] a customer whose only document is a sales quote in status Open
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");

        // [WHEN] asking about that customer
        // [THEN] there is no open order
        Assert.IsFalse(SalesGuards.HasOpenOrder(Customer."No."),
            StrSubstNo('Expected HasOpenOrder(%1) to be false — the customer''s only document is sales quote %2, and only sales orders count', Customer."No.", SalesHeader."No."));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasOpenOrderIgnoresOtherCustomersOrders()
    var
        Customer: Record Customer;
        OtherCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesGuards: Codeunit "Sales Guards";
    begin
        // [SCENARIO] Another customer's open order does not count for this customer
        // [GIVEN] a customer without documents, and another customer with an open sales order
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(OtherCustomer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, OtherCustomer."No.");

        // [WHEN] asking about the customer without documents
        // [THEN] there is no open order
        Assert.IsFalse(SalesGuards.HasOpenOrder(Customer."No."),
            StrSubstNo('Expected HasOpenOrder(%1) to be false — the customer has no documents; open sales order %2 belongs to customer %3', Customer."No.", SalesHeader."No.", OtherCustomer."No."));
    end;

    // The starter raises an error on the guarded branch. A try function lets the test
    // report that error in its own words instead of failing with the raw runtime text.
    [TryFunction]
    local procedure TryIsOverLimit(Total: Decimal; Qty: Decimal; Limit: Decimal; var Result: Boolean)
    var
        SalesGuards: Codeunit "Sales Guards";
    begin
        Result := SalesGuards.IsOverLimit(Total, Qty, Limit);
    end;

    [TryFunction]
    local procedure TryHasOpenOrder(CustomerNo: Code[20]; var Result: Boolean)
    var
        SalesGuards: Codeunit "Sales Guards";
    begin
        Result := SalesGuards.HasOpenOrder(CustomerNo);
    end;
}
