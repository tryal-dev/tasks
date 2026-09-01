codeunit 50100 "Recurring Rent Accrual"
{
    procedure CreateAccrualBatch(TemplateName: Code[10]; BatchName: Code[10])
    begin
        // TODO: create the journal the accrual lives in — a template named
        // TemplateName holding a batch named BatchName — set up so that posting
        // keeps its lines instead of consuming them.
    end;

    procedure AddAccrualLine(TemplateName: Code[10]; BatchName: Code[10]; DocumentNo: Code[20]; PostingDate: Date; AccrualAccountNo: Code[20]; LineAmount: Decimal; Method: Enum "Gen. Journal Recurring Method"; Frequency: DateFormula; ExpirationDate: Date): Integer
    begin
        // TODO: add one journal line to that batch — the amount on the accrual
        // account, first due on PostingDate, repeating every Frequency, handled
        // according to Method and stopping after ExpirationDate — and return the
        // line's "Line No.".
    end;

    procedure AddDepartmentShare(TemplateName: Code[10]; BatchName: Code[10]; AccrualLineNo: Integer; ExpenseAccountNo: Code[20]; DepartmentCode: Code[20]; SharePct: Decimal)
    begin
        // TODO: give SharePct percent of that line to ExpenseAccountNo under
        // DepartmentCode, as one of the line's balancing entries.
    end;
}
