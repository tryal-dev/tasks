codeunit 50100 "Landed Cost Mgt."
{
    procedure AssignAndPostCharge(VendorNo: Code[20]; ItemChargeNo: Code[20]; ChargeAmount: Decimal; ReceiptNos: List of [Code[20]]; Method: Enum "Landed Cost Method"): Code[20]
    begin
        // TODO: build a purchase invoice with one Charge (Item) line, spread the charge
        // across the receipts' item lines by the chosen method, post the invoice, and
        // return the posted purchase invoice no.
        exit('');
    end;

    procedure GetReceiptCost(ReceiptNo: Code[20]): Decimal
    begin
        // TODO: report the receipt's actual landed cost from its item ledger entries
        exit(0);
    end;
}
