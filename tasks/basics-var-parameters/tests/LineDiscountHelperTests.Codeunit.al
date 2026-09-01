codeunit 50900 "Line Discount Helper Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApplyDiscountWritesTheLineAmountOnTheCallersRecord()
    var
        SalesLine: Record "Sales Line";
        Helper: Codeunit "Line Discount Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The discounted amount written by ApplyDiscount is visible on the caller's record
        NewLine(SalesLine, 3, 19.90);

        Helper.ApplyDiscount(SalesLine, 10);

        Assert.AreEqual(53.73, SalesLine."Line Amount",
            'Expected the caller''s "Line Amount" to be 3 x 19.90 less 10 % after ApplyDiscount — the change must reach the caller''s record, not a copy');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApplyDiscountWritesBothFieldsForGeneratedValues()
    var
        SalesLine: Record "Sales Line";
        Helper: Codeunit "Line Discount Helper";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Qty: Decimal;
        Price: Decimal;
        Pct: Decimal;
    begin
        // [SCENARIO] ApplyDiscount writes "Line Discount %" and "Line Amount" for generated inputs
        Qty := Any.IntegerInRange(1, 9);
        Price := Any.IntegerInRange(10, 500);
        Pct := Any.IntegerInRange(5, 40);
        NewLine(SalesLine, Qty, Price);

        Helper.ApplyDiscount(SalesLine, Pct);

        Assert.AreEqual(Pct, SalesLine."Line Discount %",
            'Expected the caller''s "Line Discount %" to hold the percentage passed to ApplyDiscount');
        Assert.AreEqual(Round(Qty * Price * (100 - Pct) / 100, 0.01), SalesLine."Line Amount",
            StrSubstNo('Expected the caller''s "Line Amount" to be %1 x %2 less %3 %% after ApplyDiscount', Qty, Price, Pct));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApplyDiscountRoundsTheLineAmountToTheNearestCent()
    var
        SalesLine: Record "Sales Line";
        Helper: Codeunit "Line Discount Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 19.99 less 12.5 % is 17.49125 before rounding; the caller must see 17.49
        NewLine(SalesLine, 1, 19.99);

        Helper.ApplyDiscount(SalesLine, 12.5);

        Assert.AreEqual(17.49, SalesLine."Line Amount",
            'Expected the caller''s "Line Amount" to be 1 x 19.99 less 12.5 % rounded to the nearest 0.01 after ApplyDiscount');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PreviewDiscountReturnsTheDiscountedAmount()
    var
        SalesLine: Record "Sales Line";
        Helper: Codeunit "Line Discount Helper";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Qty: Decimal;
        Price: Decimal;
        Pct: Decimal;
    begin
        // [SCENARIO] PreviewDiscount returns the amount ApplyDiscount would write
        Qty := Any.IntegerInRange(1, 9);
        Price := Any.IntegerInRange(10, 500);
        Pct := Any.IntegerInRange(5, 40);
        NewLine(SalesLine, Qty, Price);

        Assert.AreEqual(Round(Qty * Price * (100 - Pct) / 100, 0.01), Helper.PreviewDiscount(SalesLine, Pct),
            StrSubstNo('Expected PreviewDiscount to return %1 x %2 less %3 %%', Qty, Price, Pct));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PreviewDiscountRoundsToTheNearestCent()
    var
        SalesLine: Record "Sales Line";
        Helper: Codeunit "Line Discount Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 12.99 less 37.5 % is 8.11875 before rounding; the preview must report 8.12
        NewLine(SalesLine, 1, 12.99);

        Assert.AreEqual(8.12, Helper.PreviewDiscount(SalesLine, 37.5),
            'Expected PreviewDiscount to return 1 x 12.99 less 37.5 % rounded to the nearest 0.01');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PreviewDiscountLeavesTheCallersRecordUntouched()
    var
        SalesLine: Record "Sales Line";
        Helper: Codeunit "Line Discount Helper";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A preview must not change the caller's line
        NewLine(SalesLine, 3, 19.90);

        Helper.PreviewDiscount(SalesLine, 10);

        Assert.AreEqual(59.70, SalesLine."Line Amount",
            'Expected the caller''s "Line Amount" to keep its value after PreviewDiscount — a preview works on its own copy of the line');
        Assert.AreEqual(0, SalesLine."Line Discount %",
            'Expected the caller''s "Line Discount %" to keep its value after PreviewDiscount — a preview works on its own copy of the line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalizeTagChangesTheCallersText()
    var
        Helper: Codeunit "Line Discount Helper";
        Assert: Codeunit Assert;
        Tag: Text;
    begin
        // [SCENARIO] NormalizeTag trims the outer spaces, keeps inner ones and upper-cases, on the caller's variable
        Tag := '  Black  Friday ';

        Helper.NormalizeTag(Tag);

        Assert.AreEqual('BLACK  FRIDAY', Tag,
            'Expected the caller''s Tag to be trimmed and upper-cased after NormalizeTag — the change must reach the caller''s variable, not a copy');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalizeTagHandlesGeneratedText()
    var
        Helper: Codeunit "Line Discount Helper";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Raw: Text;
        Tag: Text;
    begin
        // [SCENARIO] NormalizeTag upper-cases generated text and drops the padding around it
        Raw := Any.AlphabeticText(12);
        Tag := ' ' + Raw + '   ';

        Helper.NormalizeTag(Tag);

        Assert.AreEqual(UpperCase(Raw), Tag,
            'Expected the caller''s Tag to hold the generated text upper-cased with no surrounding spaces after NormalizeTag');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AppendTagReachesTheCallersList()
    var
        Helper: Codeunit "Line Discount Helper";
        Assert: Codeunit Assert;
        Tags: List of [Text];
    begin
        // [SCENARIO] The list passed by value is shared, so the caller sees the appended entry
        Tags.Add('VIP');

        Helper.AppendTag(Tags, 'NEW');

        Assert.AreEqual(2, Tags.Count(),
            'Expected the caller''s list to be one entry longer after AppendTag — a List is a reference type, so the callee''s Add reaches it');
        Assert.AreEqual('NEW', Tags.Get(2),
            'Expected the appended tag to be the last entry of the caller''s list');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AppendTagStoresTheNormalizedForm()
    var
        Helper: Codeunit "Line Discount Helper";
        Assert: Codeunit Assert;
        Tags: List of [Text];
    begin
        // [SCENARIO] AppendTag stores the tag trimmed and upper-cased
        Helper.AppendTag(Tags, '  promo ');

        Assert.AreEqual(1, Tags.Count(), 'Expected AppendTag to add exactly one entry to the caller''s list');
        Assert.AreEqual('PROMO', Tags.Get(1),
            'Expected the entry added by AppendTag to be the normalized form of the tag (trimmed, upper-cased)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AppendTagLeavesTheCallersTagTextAsTyped()
    var
        Helper: Codeunit "Line Discount Helper";
        Assert: Codeunit Assert;
        Tags: List of [Text];
        Tag: Text;
    begin
        // [SCENARIO] The Tag text is passed by value, so the caller's variable is not normalized
        Tag := '  promo ';

        Helper.AppendTag(Tags, Tag);

        Assert.AreEqual('  promo ', Tag,
            'Expected the caller''s Tag variable to read exactly as typed after AppendTag — Tag travels by value, so the normalization must stay inside the callee');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountTagsCountsDistinctTagsIgnoringCaseAndOuterSpaces()
    var
        Helper: Codeunit "Line Discount Helper";
        Assert: Codeunit Assert;
        Tags: List of [Text];
    begin
        // [SCENARIO] Entries that normalize to the same text count once
        Tags.Add('promo');
        Tags.Add(' PROMO');
        Tags.Add('vip');
        Tags.Add('Vip ');
        Tags.Add('new');

        Assert.AreEqual(3, Helper.CountTags(Tags),
            'Expected CountTags to count promo, vip and new once each — entries that only differ in case or outer spaces are the same tag');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountTagsCountsGeneratedDistinctTags()
    var
        Helper: Codeunit "Line Discount Helper";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Tags: List of [Text];
        Base: Text;
        Expected: Integer;
        i: Integer;
    begin
        // [SCENARIO] Each generated tag added twice in different spellings counts once
        Expected := Any.IntegerInRange(2, 6);
        for i := 1 to Expected do begin
            Base := 'tag' + Format(i) + Any.AlphabeticText(5);
            Tags.Add(Base);
            Tags.Add('  ' + UpperCase(Base) + ' ');
        end;

        Assert.AreEqual(Expected, Helper.CountTags(Tags),
            StrSubstNo('Expected CountTags to return %1 for %2 entries that pair up into %1 distinct tags', Expected, Tags.Count()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountTagsReturnsZeroForAnEmptyList()
    var
        Helper: Codeunit "Line Discount Helper";
        Assert: Codeunit Assert;
        Tags: List of [Text];
    begin
        // [SCENARIO] An empty list has no tags to count
        Assert.AreEqual(0, Helper.CountTags(Tags), 'Expected CountTags to return 0 for an empty list');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountTagsLeavesTheCallersListUntouched()
    var
        Helper: Codeunit "Line Discount Helper";
        Assert: Codeunit Assert;
        Tags: List of [Text];
    begin
        // [SCENARIO] Counting reads the shared list without normalizing or removing its entries
        Tags.Add('promo');
        Tags.Add(' PROMO');
        Tags.Add('vip');

        Helper.CountTags(Tags);

        Assert.AreEqual(3, Tags.Count(),
            'Expected the caller''s list to keep all its entries after CountTags — the list is shared, so removing duplicates removes them from the caller');
        Assert.AreEqual('promo', Tags.Get(1),
            'Expected entry 1 of the caller''s list to keep its raw text after CountTags — normalizing in place changes the caller''s shared list');
        Assert.AreEqual(' PROMO', Tags.Get(2),
            'Expected entry 2 of the caller''s list to keep its raw text after CountTags — normalizing in place changes the caller''s shared list');
        Assert.AreEqual('vip', Tags.Get(3),
            'Expected entry 3 of the caller''s list to keep its raw text after CountTags');
    end;

    local procedure NewLine(var SalesLine: Record "Sales Line"; Qty: Decimal; Price: Decimal)
    begin
        SalesLine.Init();
        SalesLine.Quantity := Qty;
        SalesLine."Unit Price" := Price;
        SalesLine."Line Amount" := Qty * Price;
    end;
}
