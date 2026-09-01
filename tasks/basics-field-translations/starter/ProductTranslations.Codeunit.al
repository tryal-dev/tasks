codeunit 50101 "Product Translations"
{
    procedure SetDescription(ProductCode: Code[20]; LanguageId: Integer; Value: Text)
    begin
        // TODO: store Value as the product's Description translation for LanguageId.
    end;

    procedure GetDescription(ProductCode: Code[20]; LanguageId: Integer): Text
    begin
        // TODO: return the value stored for LanguageId, or the Description field when none exists.
    end;

    procedure DuplicateProduct(FromCode: Code[20]; NewCode: Code[20])
    begin
        // TODO: create the product NewCode with the same Description and every translation carried over.
    end;
}
