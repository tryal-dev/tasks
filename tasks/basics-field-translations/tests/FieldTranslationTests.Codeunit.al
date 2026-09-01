codeunit 50900 "Field Translation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StoresAndReturnsAValuePerLanguage()
    var
        ProductTranslations: Codeunit "Product Translations";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        GermanText: Text;
        FrenchText: Text;
    begin
        // [SCENARIO] Each language keeps its own description value
        CreateProduct('TRYAL-FT1', 'TRYAL-FT1 base description');
        GermanText := 'DE ' + Any.AlphabeticText(12);
        FrenchText := 'FR ' + Any.AlphabeticText(12);

        ProductTranslations.SetDescription('TRYAL-FT1', 1031, GermanText);
        ProductTranslations.SetDescription('TRYAL-FT1', 1036, FrenchText);

        Assert.AreEqual(GermanText, ProductTranslations.GetDescription('TRYAL-FT1', 1031),
            'Expected GetDescription to return the value stored for German (1031)');
        Assert.AreEqual(FrenchText, ProductTranslations.GetDescription('TRYAL-FT1', 1036),
            'Expected GetDescription to return the value stored for French (1036) — each language keeps its own value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FallsBackToTheDescriptionFieldWhenNoTranslationExists()
    var
        ProductTranslations: Codeunit "Product Translations";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        BaseDescription: Text;
    begin
        // [SCENARIO] A language with no stored value falls back to the Description field
        BaseDescription := 'TRYAL-FT2 ' + Any.AlphabeticText(10);
        CreateProduct('TRYAL-FT2', BaseDescription);
        ProductTranslations.SetDescription('TRYAL-FT2', 1031, 'DE ' + Any.AlphabeticText(12));

        Assert.AreEqual(BaseDescription, ProductTranslations.GetDescription('TRYAL-FT2', 1030),
            'Expected GetDescription to fall back to the Description field for Danish (1030), which has no stored translation');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OverwritingALanguageKeepsOnlyTheLatestValue()
    var
        ProductTranslations: Codeunit "Product Translations";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SecondText: Text;
    begin
        // [SCENARIO] Storing twice for the same language replaces the first value
        CreateProduct('TRYAL-FT3', 'TRYAL-FT3 base description');
        SecondText := 'DE2 ' + Any.AlphabeticText(12);

        ProductTranslations.SetDescription('TRYAL-FT3', 1031, 'DE1 ' + Any.AlphabeticText(12));
        ProductTranslations.SetDescription('TRYAL-FT3', 1031, SecondText);

        Assert.AreEqual(SecondText, ProductTranslations.GetDescription('TRYAL-FT3', 1031),
            'Expected the second value stored for German (1031) to replace the first');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DuplicationCarriesTheDescriptionAndAllTranslations()
    var
        LocalizedProduct: Record "Localized Product";
        ProductTranslations: Codeunit "Product Translations";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        GermanText: Text;
        FrenchText: Text;
    begin
        // [SCENARIO] Duplicating a product carries the Description field and every stored language
        CreateProduct('TRYAL-FT4A', 'TRYAL-FT4 base description');
        GermanText := 'DE ' + Any.AlphabeticText(12);
        FrenchText := 'FR ' + Any.AlphabeticText(12);
        ProductTranslations.SetDescription('TRYAL-FT4A', 1031, GermanText);
        ProductTranslations.SetDescription('TRYAL-FT4A', 1036, FrenchText);

        ProductTranslations.DuplicateProduct('TRYAL-FT4A', 'TRYAL-FT4B');

        Assert.IsTrue(LocalizedProduct.Get('TRYAL-FT4B'),
            'Expected DuplicateProduct to insert a Localized Product with the new code');
        Assert.AreEqual('TRYAL-FT4 base description', LocalizedProduct.Description,
            'Expected the duplicate to carry the Description field value of the original');
        Assert.AreEqual(GermanText, ProductTranslations.GetDescription('TRYAL-FT4B', 1031),
            'Expected the German (1031) translation to be carried to the duplicate');
        Assert.AreEqual(FrenchText, ProductTranslations.GetDescription('TRYAL-FT4B', 1036),
            'Expected the French (1036) translation to be carried to the duplicate');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletionRemovesTheProductsTranslationsAndOnlyItsOwn()
    var
        LocalizedProduct: Record "Localized Product";
        DeletedProduct: Record "Localized Product";
        TranslationBuffer: Record "Translation Buffer";
        ProductTranslations: Codeunit "Product Translations";
        Translation: Codeunit Translation;
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OtherGermanText: Text;
    begin
        // [SCENARIO] Deleting a product leaves zero translation rows for it, but does not touch other products
        CreateProduct('TRYAL-FT5A', 'TRYAL-FT5A base description');
        CreateProduct('TRYAL-FT5B', 'TRYAL-FT5B base description');
        ProductTranslations.SetDescription('TRYAL-FT5A', 1031, 'DE ' + Any.AlphabeticText(12));
        ProductTranslations.SetDescription('TRYAL-FT5A', 1036, 'FR ' + Any.AlphabeticText(12));
        OtherGermanText := 'DE ' + Any.AlphabeticText(12);
        ProductTranslations.SetDescription('TRYAL-FT5B', 1031, OtherGermanText);
        // Keep a copy carrying the SystemId so orphans can be counted after the row is gone.
        DeletedProduct.Get('TRYAL-FT5A');
        Translation.GetTranslations(DeletedProduct, 0, TranslationBuffer);
        Assert.AreEqual(2, TranslationBuffer.Count(),
            'Expected SetDescription to store both translations in the System Application Translation module — that is the storage the task requires');

        LocalizedProduct.Get('TRYAL-FT5A');
        LocalizedProduct.Delete(true);

        Translation.GetTranslations(DeletedProduct, 0, TranslationBuffer);
        Assert.AreEqual(0, TranslationBuffer.Count(),
            'Expected zero translation rows to remain for the deleted product — the OnDelete trigger must clean them up');
        Assert.AreEqual(OtherGermanText, ProductTranslations.GetDescription('TRYAL-FT5B', 1031),
            'Expected the other product to keep its own German (1031) translation after an unrelated deletion');
    end;

    local procedure CreateProduct(ProductCode: Code[20]; ProductDescription: Text)
    var
        LocalizedProduct: Record "Localized Product";
    begin
        LocalizedProduct.Init();
        LocalizedProduct."Code" := ProductCode;
        LocalizedProduct.Description := CopyStr(ProductDescription, 1, MaxStrLen(LocalizedProduct.Description));
        LocalizedProduct.Insert();
    end;
}
