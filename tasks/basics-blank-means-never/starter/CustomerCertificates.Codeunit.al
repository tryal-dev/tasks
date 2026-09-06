codeunit 50100 "Customer Certificates"
{
    procedure IsExpired(var Customer: Record Customer; AsOf: Date): Boolean
    begin
        // TODO: a customer with no certificate at all is reported as expired
        // here — a blank date is smaller than every real date.
        exit(Customer."Certificate Expiry" < AsOf);
    end;

    procedure EarliestExpiry(var Customer: Record Customer): Date
    var
        Earliest: Date;
    begin
        // TODO: the same comparison lets a blank expiry win the minimum, so
        // the answer is blank whenever any customer in the set has no
        // certificate — instead of the earliest real date.
        Earliest := 0D;
        if Customer.FindSet() then
            repeat
            until Customer.Next() = 0;
        exit(Earliest);
    end;
}
