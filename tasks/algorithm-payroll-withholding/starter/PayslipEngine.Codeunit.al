codeunit 50103 "Payslip Engine"
{
    procedure PersonalAllowance(GrossPay: Decimal): Decimal
    begin
        // TODO: the setup record's allowance, reduced by 1 for every 2 of
        // gross pay above the taper threshold, never below zero.
    end;

    procedure IncomeTax(GrossPay: Decimal): Decimal
    begin
        // TODO: charge the income tax bands on gross pay minus
        // PersonalAllowance(GrossPay), floored at zero.
    end;

    procedure NIContribution(GrossPay: Decimal): Decimal
    begin
        // TODO: charge the NI contribution bands on gross pay itself —
        // the personal allowance plays no part here.
    end;

    procedure NetPay(GrossPay: Decimal): Decimal
    begin
        // TODO: gross pay minus income tax minus NI contribution.
    end;
}
