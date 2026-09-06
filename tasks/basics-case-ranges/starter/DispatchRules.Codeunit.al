codeunit 50100 "Dispatch Rules"
{
    procedure ShippingZone(PostCode: Code[10]): Integer
    begin
        // TODO: this never returns 1 or 2. PostCode arrives uppercased, but
        // the value sets of a case on a Code expression are compared exactly
        // as written, so 'ec1' can never match 'EC1'.
        case PostCode of
            'ec1', 'ec2', 'ec3', 'ec4', 'wc1', 'wc2':
                exit(1);
            'e1', 'n1', 'nw1', 'se1', 'sw1', 'w1':
                exit(2);
            else
                exit(3);
        end;
    end;

    procedure Grade(Score: Integer): Text
    begin
        // TODO: a chain of lower bounds has no upper bound and no branch for
        // a score outside every band: 101 grades as A and -5 as F. Rewrite
        // it as one case statement with ranges and an else.
        if Score >= 90 then
            exit('A');
        if Score >= 75 then
            exit('B');
        if Score >= 60 then
            exit('C');
        if Score >= 40 then
            exit('D');
        exit('F');
    end;
}
