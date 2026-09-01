codeunit 50101 "Nightly Repricer"
{
    procedure RunRepricing(): Integer
    var
        PriceReviewLine: Record "Price Review Line";
        Updated: Integer;
    begin
        // TODO: every price below comes out right — the nightly window does not
        // survive it. This loop writes all ~2,000 rows although only ~120
        // actually change, so every untouched row still gets stamped, the
        // return value counts rows instead of changes, and the DBA's trace
        // shows even more statements than rows. The grading budget allows
        // roughly one statement per row that truly needs a new price.
        if PriceReviewLine.FindSet() then
            repeat
                ApplyPrice(PriceReviewLine);
                Updated += 1;
            until PriceReviewLine.Next() = 0;
        exit(Updated);
    end;

    local procedure ApplyPrice(Line: Record "Price Review Line")
    begin
        Line."Unit Price" := Round(Line."Unit Cost" * (1 + Line."Markup %" / 100), 0.01);
        Line.Modify();
    end;
}
