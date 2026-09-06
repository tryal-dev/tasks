codeunit 50100 "Variant Lookup"
{
    procedure VariantDescription(ItemNo: Code[20]; VariantCode: Code[10]): Text[100]
    var
        ItemVariant: Record "Item Variant";
    begin
        // TODO: this compiles, yet no variant is ever found — and a variant
        // that does not exist must come back as '' instead of an error.
        ItemVariant.Get(VariantCode);
        exit(ItemVariant.Description);
    end;
}
