codeunit 50100 "Order JSON Export"
{
    procedure ExportOrder(SalesHeader: Record "Sales Header"): Text
    var
        SalesLine: Record "Sales Line";
        Payload: TextBuilder;
        FirstLine: Boolean;
    begin
        // TODO: this hand-rolled writer follows the session's regional settings
        // (Format of dates and decimals) and pastes text values in unescaped —
        // hostile descriptions and non-invariant formats break the document.
        Payload.Append('{"orderNo": "' + SalesHeader."No." + '"');
        Payload.Append(', "customerNo": "' + SalesHeader."Sell-to Customer No." + '"');
        Payload.Append(', "orderDate": "' + Format(SalesHeader."Order Date") + '"');
        Payload.Append(', "lines": [');
        FirstLine := true;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                if not FirstLine then
                    Payload.Append(', ');
                FirstLine := false;
                Payload.Append('{"lineNo": ' + Format(SalesLine."Line No."));
                Payload.Append(', "itemNo": "' + SalesLine."No." + '"');
                Payload.Append(', "description": "' + SalesLine.Description + '"');
                Payload.Append(', "quantity": ' + Format(SalesLine.Quantity));
                Payload.Append(', "unitPrice": ' + Format(SalesLine."Unit Price"));
                Payload.Append(', "lineAmount": ' + Format(SalesLine."Line Amount") + '}');
            until SalesLine.Next() = 0;
        Payload.Append(']}');
        exit(Payload.ToText());
    end;
}
