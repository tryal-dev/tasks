codeunit 50100 "Payment Terms Calculator"
{
    procedure CalcDueDate(DocumentDate: Date; DueDateFormulaText: Text): Date
    begin
        // TODO: apply the date-formula text to the document date —
        // month ends, leap years and weekday jumps included; blank text
        // falls due immediately, and invalid text must raise an error
        // naming the rejected text.
    end;

    procedure QualifiesForDiscount(DocumentDate: Date; PaymentDate: Date; DiscountDateFormulaText: Text): Boolean
    begin
        // TODO: true when PaymentDate is on or before the discount date
        // computed from DocumentDate with the same rules.
    end;
}
