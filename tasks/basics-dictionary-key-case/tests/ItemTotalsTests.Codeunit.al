codeunit 50900 "Item Totals Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RepeatedItemNosAreSummedUnderOneKey()
    var
        ItemTotals: Codeunit "Item Totals";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNos: List of [Text];
        Quantities: List of [Decimal];
        Totals: Dictionary of [Code[20], Decimal];
        FirstQty: Decimal;
        SecondQty: Decimal;
        ThirdQty: Decimal;
    begin
        // [SCENARIO] Two distinct items, one of them counted on two non-adjacent lines, give two keys with per-item sums
        FirstQty := Any.DecimalInRange(1, 100, 2);
        SecondQty := Any.DecimalInRange(1, 100, 2);
        ThirdQty := Any.DecimalInRange(1, 100, 2);
        AddLine(ItemNos, Quantities, 'TRYAL-SUM-A', FirstQty);
        AddLine(ItemNos, Quantities, 'TRYAL-SUM-B', SecondQty);
        AddLine(ItemNos, Quantities, 'TRYAL-SUM-A', ThirdQty);

        Totals := ItemTotals.TotalsByItem(ItemNos, Quantities);

        Assert.AreEqual(2, Totals.Count(), StrSubstNo('Expected one key per distinct item number (TRYAL-SUM-A and TRYAL-SUM-B), got keys: %1', KeysAsText(Totals)));
        Assert.AreEqual(FirstQty + ThirdQty, GetTotal(Totals, 'TRYAL-SUM-A'), 'Expected the two TRYAL-SUM-A lines to be summed under one key');
        Assert.AreEqual(SecondQty, GetTotal(Totals, 'TRYAL-SUM-B'), 'Expected the single TRYAL-SUM-B line to keep its own quantity as its total');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CaseVariantsOfAnItemNoShareOneKey()
    var
        ItemTotals: Codeunit "Item Totals";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNos: List of [Text];
        Quantities: List of [Decimal];
        Totals: Dictionary of [Code[20], Decimal];
        LowerQty: Decimal;
        UpperQty: Decimal;
        MixedQty: Decimal;
    begin
        // [SCENARIO] tryal-case, TRYAL-CASE and Tryal-Case are one item
        LowerQty := Any.DecimalInRange(1, 100, 2);
        UpperQty := Any.DecimalInRange(1, 100, 2);
        MixedQty := Any.DecimalInRange(1, 100, 2);
        AddLine(ItemNos, Quantities, 'tryal-case', LowerQty);
        AddLine(ItemNos, Quantities, 'TRYAL-CASE', UpperQty);
        AddLine(ItemNos, Quantities, 'Tryal-Case', MixedQty);

        Totals := ItemTotals.TotalsByItem(ItemNos, Quantities);

        Assert.AreEqual(1, Totals.Count(), StrSubstNo('Expected tryal-case, TRYAL-CASE and Tryal-Case to share a single key — item numbers are compared uppercased, got keys: %1', KeysAsText(Totals)));
        Assert.AreEqual(LowerQty + UpperQty + MixedQty, GetTotal(Totals, 'TRYAL-CASE'), 'Expected the quantities of all three spellings to be summed under TRYAL-CASE');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PaddedVariantsOfAnItemNoShareOneKey()
    var
        ItemTotals: Codeunit "Item Totals";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNos: List of [Text];
        Quantities: List of [Decimal];
        Totals: Dictionary of [Code[20], Decimal];
        PlainQty: Decimal;
        TrailingQty: Decimal;
        LeadingQty: Decimal;
        BothQty: Decimal;
    begin
        // [SCENARIO] Leading and trailing spaces around an item number do not make a new item
        PlainQty := Any.DecimalInRange(1, 100, 2);
        TrailingQty := Any.DecimalInRange(1, 100, 2);
        LeadingQty := Any.DecimalInRange(1, 100, 2);
        BothQty := Any.DecimalInRange(1, 100, 2);
        AddLine(ItemNos, Quantities, 'TRYAL-PAD', PlainQty);
        AddLine(ItemNos, Quantities, 'TRYAL-PAD ', TrailingQty);
        AddLine(ItemNos, Quantities, ' TRYAL-PAD', LeadingQty);
        AddLine(ItemNos, Quantities, '  TRYAL-PAD  ', BothQty);

        Totals := ItemTotals.TotalsByItem(ItemNos, Quantities);

        Assert.AreEqual(1, Totals.Count(), StrSubstNo('Expected TRYAL-PAD with and without surrounding spaces to share a single key — item numbers are trimmed, got keys: %1', KeysAsText(Totals)));
        Assert.AreEqual(PlainQty + TrailingQty + LeadingQty + BothQty, GetTotal(Totals, 'TRYAL-PAD'), 'Expected the quantities of all four padded spellings to be summed under TRYAL-PAD');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnedKeyIsUppercasedAndTrimmed()
    var
        ItemTotals: Codeunit "Item Totals";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNos: List of [Text];
        Quantities: List of [Decimal];
        Totals: Dictionary of [Code[20], Decimal];
        ReturnedKey: Code[20];
        ReturnedKeyText: Text;
    begin
        // [SCENARIO] The key stored for ' tryal-key-7 ' reads back as TRYAL-KEY-7
        AddLine(ItemNos, Quantities, ' tryal-key-7 ', Any.DecimalInRange(1, 100, 2));

        Totals := ItemTotals.TotalsByItem(ItemNos, Quantities);

        Assert.AreEqual(1, Totals.Count(), StrSubstNo('Expected exactly one key for the single line, got keys: %1', KeysAsText(Totals)));
        foreach ReturnedKey in Totals.Keys() do
            ReturnedKeyText := ReturnedKey;
        Assert.AreEqual('TRYAL-KEY-7', ReturnedKeyText, 'Expected the key to be the uppercased, trimmed item number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LowercaseLookupFindsTheItem()
    var
        ItemTotals: Codeunit "Item Totals";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNos: List of [Text];
        Quantities: List of [Decimal];
        Totals: Dictionary of [Code[20], Decimal];
        Qty: Decimal;
        FoundTotal: Decimal;
    begin
        // [SCENARIO] Get with the lowercase spelling finds the total stored under the uppercase key
        Qty := Any.DecimalInRange(1, 100, 2);
        AddLine(ItemNos, Quantities, 'TRYAL-LOOKUP', Qty);

        Totals := ItemTotals.TotalsByItem(ItemNos, Quantities);

        Assert.IsTrue(Totals.Get('tryal-lookup', FoundTotal), StrSubstNo('Expected Get with the lowercase spelling tryal-lookup to find the total stored under TRYAL-LOOKUP, got keys: %1', KeysAsText(Totals)));
        Assert.AreEqual(Qty, FoundTotal, 'Expected the lowercase lookup to return the total counted for TRYAL-LOOKUP');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroQuantityStillCreatesTheKey()
    var
        ItemTotals: Codeunit "Item Totals";
        Assert: Codeunit Assert;
        ItemNos: List of [Text];
        Quantities: List of [Decimal];
        Totals: Dictionary of [Code[20], Decimal];
    begin
        // [SCENARIO] A line counted as 0 still shows its item with a total of 0
        AddLine(ItemNos, Quantities, 'TRYAL-ZERO', 0);

        Totals := ItemTotals.TotalsByItem(ItemNos, Quantities);

        Assert.AreEqual(1, Totals.Count(), StrSubstNo('Expected the zero-quantity line to create its key, got keys: %1', KeysAsText(Totals)));
        Assert.AreEqual(0, GetTotal(Totals, 'TRYAL-ZERO'), 'Expected the total under TRYAL-ZERO to be 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeQuantitiesReduceTheTotal()
    var
        ItemTotals: Codeunit "Item Totals";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNos: List of [Text];
        Quantities: List of [Decimal];
        Totals: Dictionary of [Code[20], Decimal];
        CountedQty: Decimal;
        CorrectionQty: Decimal;
    begin
        // [SCENARIO] A negative correction line is subtracted from the item's total
        CountedQty := Any.DecimalInRange(50, 100, 2);
        CorrectionQty := Any.DecimalInRange(1, 49, 2);
        AddLine(ItemNos, Quantities, 'TRYAL-NEG', CountedQty);
        AddLine(ItemNos, Quantities, 'TRYAL-NEG', -CorrectionQty);

        Totals := ItemTotals.TotalsByItem(ItemNos, Quantities);

        Assert.AreEqual(1, Totals.Count(), StrSubstNo('Expected both TRYAL-NEG lines under one key, got keys: %1', KeysAsText(Totals)));
        Assert.AreEqual(CountedQty - CorrectionQty, GetTotal(Totals, 'TRYAL-NEG'), 'Expected the negative quantity to be subtracted from the TRYAL-NEG total');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TwentyCharacterItemNoIsAccepted()
    var
        ItemTotals: Codeunit "Item Totals";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNos: List of [Text];
        Quantities: List of [Decimal];
        Totals: Dictionary of [Code[20], Decimal];
        ItemNo: Text;
        Qty: Decimal;
    begin
        // [SCENARIO] An item number of exactly 20 characters is totalled like any other
        ItemNo := 'TRYAL-' + UpperCase(Any.AlphabeticText(14));
        Qty := Any.DecimalInRange(1, 100, 2);
        AddLine(ItemNos, Quantities, ItemNo, Qty);

        Totals := ItemTotals.TotalsByItem(ItemNos, Quantities);

        Assert.AreEqual(1, Totals.Count(), StrSubstNo('Expected the 20-character item number %1 to be accepted as a key, got keys: %2', ItemNo, KeysAsText(Totals)));
        Assert.AreEqual(Qty, GetTotal(Totals, CopyStr(ItemNo, 1, 20)), StrSubstNo('Expected the total under the 20-character item number %1 to be its quantity', ItemNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ItemNoLongerThanTwentyCharactersRaisesAnError()
    var
        ItemTotals: Codeunit "Item Totals";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNos: List of [Text];
        Quantities: List of [Decimal];
        Totals: Dictionary of [Code[20], Decimal];
    begin
        // [SCENARIO] A 21-character item number raises instead of being truncated to 20
        AddLine(ItemNos, Quantities, 'TRYAL-' + UpperCase(Any.AlphabeticText(15)), Any.DecimalInRange(1, 100, 2));

        asserterror Totals := ItemTotals.TotalsByItem(ItemNos, Quantities);

        Assert.ExpectedError('20');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyListsYieldAnEmptyDictionary()
    var
        ItemTotals: Codeunit "Item Totals";
        Assert: Codeunit Assert;
        ItemNos: List of [Text];
        Quantities: List of [Decimal];
        Totals: Dictionary of [Code[20], Decimal];
    begin
        // [SCENARIO] No lines means no keys
        Totals := ItemTotals.TotalsByItem(ItemNos, Quantities);

        Assert.AreEqual(0, Totals.Count(), StrSubstNo('Expected an empty dictionary for empty input lists, got keys: %1', KeysAsText(Totals)));
    end;

    local procedure AddLine(var ItemNos: List of [Text]; var Quantities: List of [Decimal]; ItemNo: Text; Qty: Decimal)
    begin
        ItemNos.Add(ItemNo);
        Quantities.Add(Qty);
    end;

    local procedure GetTotal(Totals: Dictionary of [Code[20], Decimal]; ItemNo: Code[20]): Decimal
    var
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(Totals.ContainsKey(ItemNo), StrSubstNo('Expected the dictionary to contain the key %1, got keys: %2', ItemNo, KeysAsText(Totals)));
        exit(Totals.Get(ItemNo));
    end;

    local procedure KeysAsText(Totals: Dictionary of [Code[20], Decimal]): Text
    var
        Joined: TextBuilder;
        ItemNo: Code[20];
    begin
        foreach ItemNo in Totals.Keys() do begin
            if Joined.Length() > 0 then
                Joined.Append(', ');
            Joined.Append('[' + ItemNo + ']');
        end;
        if Joined.Length() = 0 then
            exit('(none)');
        exit(Joined.ToText());
    end;
}
