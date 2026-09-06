codeunit 50900 "Composite Key Get Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTheDescriptionOfTheRequestedVariant()
    var
        VariantLookup: Codeunit "Variant Lookup";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        BlueDescription: Text[100];
    begin
        BlueDescription := CopyStr('Blue ' + Any.AlphabeticText(95), 1, 100);
        CreateVariant('TRYAL-CK1', 'BLUE', BlueDescription);
        CreateVariant('TRYAL-CK1', 'RED', CopyStr('Red ' + Any.AlphabeticText(20), 1, 100));

        Assert.AreEqual(BlueDescription, VariantLookup.VariantDescription('TRYAL-CK1', 'BLUE'),
            'Expected the description of variant BLUE of item TRYAL-CK1, in full — a 100-character description must not be cut short');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTheOtherVariantOfTheSameItem()
    var
        VariantLookup: Codeunit "Variant Lookup";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        RedDescription: Text[100];
    begin
        RedDescription := CopyStr('Red ' + Any.AlphabeticText(20), 1, 100);
        CreateVariant('TRYAL-CK2', 'BLUE', CopyStr('Blue ' + Any.AlphabeticText(20), 1, 100));
        CreateVariant('TRYAL-CK2', 'RED', RedDescription);

        Assert.AreEqual(RedDescription, VariantLookup.VariantDescription('TRYAL-CK2', 'RED'),
            'Expected the description of variant RED of item TRYAL-CK2 — the variant code decides which of the item''s variants is returned');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SameVariantCodeOnAnotherItemIsNotConfused()
    var
        VariantLookup: Codeunit "Variant Lookup";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        BlueOfSecondItem: Text[100];
    begin
        BlueOfSecondItem := CopyStr('Blue of CK3B ' + Any.AlphabeticText(20), 1, 100);
        CreateVariant('TRYAL-CK3A', 'BLUE', CopyStr('Blue of CK3A ' + Any.AlphabeticText(20), 1, 100));
        CreateVariant('TRYAL-CK3B', 'BLUE', BlueOfSecondItem);

        Assert.AreEqual(BlueOfSecondItem, VariantLookup.VariantDescription('TRYAL-CK3B', 'BLUE'),
            'Expected the BLUE variant of item TRYAL-CK3B, not the BLUE variant of another item — a variant code is only unique together with its item number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArgumentOrderIsItemThenVariant()
    var
        VariantLookup: Codeunit "Variant Lookup";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        VariantOfFirstItem: Text[100];
    begin
        VariantOfFirstItem := CopyStr('Variant CK4B of item CK4A ' + Any.AlphabeticText(20), 1, 100);
        CreateVariant('TRYAL-CK4A', 'TRYAL-CK4B', VariantOfFirstItem);
        CreateVariant('TRYAL-CK4B', 'TRYAL-CK4A', CopyStr('Variant CK4A of item CK4B ' + Any.AlphabeticText(20), 1, 100));

        Assert.AreEqual(VariantOfFirstItem, VariantLookup.VariantDescription('TRYAL-CK4A', 'TRYAL-CK4B'),
            'Expected the description of variant TRYAL-CK4B of item TRYAL-CK4A — the first argument is the item number and the second the variant code; swapped, the lookup lands on item TRYAL-CK4B''s variant TRYAL-CK4A instead');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MissingVariantReturnsBlankInsteadOfRaising()
    var
        VariantLookup: Codeunit "Variant Lookup";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        CreateVariant('TRYAL-CK5', 'BLUE', CopyStr('Blue ' + Any.AlphabeticText(20), 1, 100));

        Assert.AreEqual('', VariantLookup.VariantDescription('TRYAL-CK5', 'NOPE'),
            'Expected an empty string when the item has no variant with that code — a missing variant must not raise an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownItemReturnsBlankInsteadOfRaising()
    var
        VariantLookup: Codeunit "Variant Lookup";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', VariantLookup.VariantDescription('TRYAL-CK6', 'BLUE'),
            'Expected an empty string when the item itself does not exist — an unknown item must not raise an error');
    end;

    local procedure CreateVariant(ItemNo: Code[20]; VariantCode: Code[10]; VariantDescription: Text[100])
    var
        ItemVariant: Record "Item Variant";
    begin
        EnsureItem(ItemNo);
        ItemVariant.Init();
        ItemVariant."Item No." := ItemNo;
        ItemVariant.Code := VariantCode;
        ItemVariant.Description := VariantDescription;
        ItemVariant.Insert();
    end;

    local procedure EnsureItem(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then
            exit;
        Item.Init();
        Item."No." := ItemNo;
        Item.Description := ItemNo;
        Item.Insert();
    end;
}
