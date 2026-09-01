codeunit 50100 "Line Discount Helper"
{
    procedure ApplyDiscount(SalesLine: Record "Sales Line"; Pct: Decimal)
    begin
        // TODO: the caller never sees these two assignments — they land on a copy.
        SalesLine."Line Discount %" := Pct;
        SalesLine."Line Amount" := Round(SalesLine.Quantity * SalesLine."Unit Price" * (100 - Pct) / 100, 0.01);
    end;

    procedure PreviewDiscount(var SalesLine: Record "Sales Line"; Pct: Decimal): Decimal
    begin
        // TODO: a preview must leave the caller's line untouched — check this
        // signature against the statement.
        ApplyDiscount(SalesLine, Pct);
        exit(SalesLine."Line Amount");
    end;

    procedure NormalizeTag(Tag: Text)
    begin
        // TODO: same symptom — the normalized text never reaches the caller.
        Tag := UpperCase(Tag.Trim());
    end;

    procedure AppendTag(Tags: List of [Text]; Tag: Text)
    begin
        NormalizeTag(Tag);
        Tags.Add(Tag);
    end;

    procedure CountTags(Tags: List of [Text]): Integer
    begin
        // TODO: count the distinct normalized tags without changing the caller's list.
    end;
}
