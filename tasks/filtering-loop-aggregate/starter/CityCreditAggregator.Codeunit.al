codeunit 50100 "City Credit Aggregator"
{
    procedure TotalCreditLimit(CityName: Text): Decimal
    var
        Customer: Record Customer;
        Total: Decimal;
    begin
        // TODO: this loop shipped with the widget — multi-customer cities
        // come up short, a one-customer city shows 0, an empty city errors.
        Customer.SetRange(City, CityName);
        Customer.FindSet();
        while Customer.Next() <> 0 do
            Total := Customer."Credit Limit (LCY)";
        exit(Total);
    end;

    procedure TotalCreditLimitCapped(CityName: Text; Cap: Decimal): Decimal
    var
        Customer: Record Customer;
    begin
        // TODO: same city rule as above; each customer contributes at most Cap.
        exit(0);
    end;
}
