codeunit 50900 "Gilded Rose Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalItemAgesOneDayBeforeSellByDate()
    begin
        // [SCENARIO] A fresh normal item loses one quality and one sell-in day
        SeedItem('TRYAL-GR01', "Gilded Item Category"::Normal, 5, 10);

        UpdateOneDay('TRYAL-GR01');

        VerifyItem('TRYAL-GR01', 4, 9, 'a fresh Normal item (Sell In 5, Quality 10)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalItemDegradesTwiceOnSellByDate()
    begin
        // [SCENARIO] Sell In 0 already counts as expired — quality drops by 2
        SeedItem('TRYAL-GR02', "Gilded Item Category"::Normal, 0, 10);

        UpdateOneDay('TRYAL-GR02');

        VerifyItem('TRYAL-GR02', -1, 8, 'a Normal item on its sell-by date (Sell In 0, Quality 10)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalItemDegradesTwicePastSellByDate()
    begin
        // [SCENARIO] A long-expired normal item keeps dropping by 2 and Sell In keeps going negative
        SeedItem('TRYAL-GR03', "Gilded Item Category"::Normal, -3, 10);

        UpdateOneDay('TRYAL-GR03');

        VerifyItem('TRYAL-GR03', -4, 8, 'an expired Normal item (Sell In -3, Quality 10)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalItemQualityStopsAtZero()
    begin
        // [SCENARIO] An expired normal item at quality 1 lands on 0, never below
        SeedItem('TRYAL-GR04', "Gilded Item Category"::Normal, 0, 1);

        UpdateOneDay('TRYAL-GR04');

        VerifyItem('TRYAL-GR04', -1, 0, 'an expired Normal item at Quality 1 — quality is never negative');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AgedBrieRipensBeforeSellByDate()
    begin
        // [SCENARIO] Fresh Aged Brie gains one quality per day
        SeedItem('TRYAL-GR05', "Gilded Item Category"::"Aged Brie", 5, 10);

        UpdateOneDay('TRYAL-GR05');

        VerifyItem('TRYAL-GR05', 4, 11, 'fresh Aged Brie (Sell In 5, Quality 10)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AgedBrieRipensTwiceWhenExpired()
    begin
        // [SCENARIO] Expired Aged Brie gains two quality per day
        SeedItem('TRYAL-GR06', "Gilded Item Category"::"Aged Brie", 0, 10);

        UpdateOneDay('TRYAL-GR06');

        VerifyItem('TRYAL-GR06', -1, 12, 'Aged Brie on its sell-by date (Sell In 0, Quality 10)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AgedBrieQualityStopsAtFifty()
    begin
        // [SCENARIO] Expired Aged Brie at quality 49 would gain 2 but caps at 50
        SeedItem('TRYAL-GR07', "Gilded Item Category"::"Aged Brie", -2, 49);

        UpdateOneDay('TRYAL-GR07');

        VerifyItem('TRYAL-GR07', -3, 50, 'expired Aged Brie at Quality 49 — quality never exceeds 50');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SulfurasNeverChanges()
    begin
        // [SCENARIO] The legendary Sulfuras keeps both fields even on its sell-by date
        SeedItem('TRYAL-GR08', "Gilded Item Category"::Sulfuras, 0, 80);

        UpdateOneDay('TRYAL-GR08');

        VerifyItem('TRYAL-GR08', 0, 80, 'the legendary Sulfuras — neither Sell In nor Quality ever moves');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BackstagePassGainsOneElevenDaysOut()
    begin
        // [SCENARIO] At Sell In 11 the pass is still on the far side of the 10-day threshold
        SeedItem('TRYAL-GR09', "Gilded Item Category"::"Backstage Pass", 11, 20);

        UpdateOneDay('TRYAL-GR09');

        VerifyItem('TRYAL-GR09', 10, 21, 'a Backstage Pass 11 days out — still gains only 1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BackstagePassGainsTwoTenDaysOut()
    begin
        // [SCENARIO] Sell In 10 is the first day of the +2 window
        SeedItem('TRYAL-GR10', "Gilded Item Category"::"Backstage Pass", 10, 20);

        UpdateOneDay('TRYAL-GR10');

        VerifyItem('TRYAL-GR10', 9, 22, 'a Backstage Pass exactly 10 days out — first day of the +2 window');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BackstagePassGainsTwoSixDaysOut()
    begin
        // [SCENARIO] Sell In 6 is the last day of the +2 window
        SeedItem('TRYAL-GR11', "Gilded Item Category"::"Backstage Pass", 6, 20);

        UpdateOneDay('TRYAL-GR11');

        VerifyItem('TRYAL-GR11', 5, 22, 'a Backstage Pass 6 days out — last day of the +2 window');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BackstagePassGainsThreeFiveDaysOut()
    begin
        // [SCENARIO] Sell In 5 is the first day of the +3 window
        SeedItem('TRYAL-GR12', "Gilded Item Category"::"Backstage Pass", 5, 20);

        UpdateOneDay('TRYAL-GR12');

        VerifyItem('TRYAL-GR12', 4, 23, 'a Backstage Pass exactly 5 days out — first day of the +3 window');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BackstagePassGainsThreeOneDayOut()
    begin
        // [SCENARIO] The day before the concert still gains 3
        SeedItem('TRYAL-GR13', "Gilded Item Category"::"Backstage Pass", 1, 20);

        UpdateOneDay('TRYAL-GR13');

        VerifyItem('TRYAL-GR13', 0, 23, 'a Backstage Pass 1 day out — still gains 3');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BackstagePassWorthlessAfterConcert()
    begin
        // [SCENARIO] Once Sell In hits 0 the concert is over — quality drops to exactly 0
        SeedItem('TRYAL-GR14', "Gilded Item Category"::"Backstage Pass", 0, 30);

        UpdateOneDay('TRYAL-GR14');

        VerifyItem('TRYAL-GR14', -1, 0, 'a Backstage Pass after the concert — worth exactly 0, not merely less');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BackstagePassQualityStopsAtFifty()
    begin
        // [SCENARIO] A pass at quality 49 in the +3 window still caps at 50
        SeedItem('TRYAL-GR15', "Gilded Item Category"::"Backstage Pass", 3, 49);

        UpdateOneDay('TRYAL-GR15');

        VerifyItem('TRYAL-GR15', 2, 50, 'a Backstage Pass at Quality 49 in the +3 window — quality never exceeds 50');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BackstagePassQualityStopsAtFiftyTenToSixDaysOut()
    begin
        // [SCENARIO] A pass at quality 49 in the +2 window still caps at 50 — clamping only the +3 branch fails here
        SeedItem('TRYAL-GR22', "Gilded Item Category"::"Backstage Pass", 8, 49);

        UpdateOneDay('TRYAL-GR22');

        VerifyItem('TRYAL-GR22', 7, 50, 'a Backstage Pass at Quality 49 in the +2 window — quality never exceeds 50');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BackstagePassQualityStaysAtFiftyElevenOrMoreDaysOut()
    begin
        // [SCENARIO] A pass already at the cap in the +1 window stays at 50
        SeedItem('TRYAL-GR22B', "Gilded Item Category"::"Backstage Pass", 12, 50);

        UpdateOneDay('TRYAL-GR22B');

        VerifyItem('TRYAL-GR22B', 11, 50, 'a Backstage Pass at Quality 50 in the +1 window — quality never exceeds 50');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConjuredItemDegradesTwiceAsFast()
    begin
        // [SCENARIO] A fresh conjured item loses 2 where a normal one loses 1
        SeedItem('TRYAL-GR16', "Gilded Item Category"::Conjured, 5, 10);

        UpdateOneDay('TRYAL-GR16');

        VerifyItem('TRYAL-GR16', 4, 8, 'a fresh Conjured item (Sell In 5, Quality 10) — twice the normal decay');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConjuredItemDegradesFourWhenExpired()
    begin
        // [SCENARIO] An expired conjured item loses 4 per day
        SeedItem('TRYAL-GR17', "Gilded Item Category"::Conjured, 0, 10);

        UpdateOneDay('TRYAL-GR17');

        VerifyItem('TRYAL-GR17', -1, 6, 'a Conjured item on its sell-by date (Sell In 0, Quality 10)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConjuredItemQualityStopsAtZero()
    begin
        // [SCENARIO] An expired conjured item at quality 3 lands on 0, never below
        SeedItem('TRYAL-GR18', "Gilded Item Category"::Conjured, 0, 3);

        UpdateOneDay('TRYAL-GR18');

        VerifyItem('TRYAL-GR18', -1, 0, 'an expired Conjured item at Quality 3 — quality is never negative');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ConjuredItemQualityStopsAtZeroBeforeSellByDate()
    begin
        // [SCENARIO] A fresh conjured item at quality 1 lands on 0 — clamping only the expired branch fails here
        SeedItem('TRYAL-GR23', "Gilded Item Category"::Conjured, 3, 1);

        UpdateOneDay('TRYAL-GR23');

        VerifyItem('TRYAL-GR23', 2, 0, 'a fresh Conjured item at Quality 1 — quality is never negative');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalItemQualityStaysAtZeroBeforeSellByDate()
    begin
        // [SCENARIO] A fresh normal item already at quality 0 stays at 0
        SeedItem('TRYAL-GR23B', "Gilded Item Category"::Normal, 5, 0);

        UpdateOneDay('TRYAL-GR23B');

        VerifyItem('TRYAL-GR23B', 4, 0, 'a fresh Normal item at Quality 0 — quality is never negative');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomFreshNormalItemLosesExactlyOne()
    var
        Any: Codeunit Any;
        SellIn: Integer;
        Quality: Integer;
    begin
        // [SCENARIO] A fresh normal item with generated values loses exactly one of each — hardcoded answers fail here
        SellIn := Any.IntegerInRange(2, 30);
        Quality := Any.IntegerInRange(5, 45);
        SeedItem('TRYAL-GR19', "Gilded Item Category"::Normal, SellIn, Quality);

        UpdateOneDay('TRYAL-GR19');

        VerifyItem('TRYAL-GR19', SellIn - 1, Quality - 1, StrSubstNo('a fresh Normal item with generated values (Sell In %1, Quality %2)', SellIn, Quality));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomExpiredConjuredItemLosesFour()
    var
        Any: Codeunit Any;
        SellIn: Integer;
        Quality: Integer;
    begin
        // [SCENARIO] An expired conjured item with generated values loses exactly 4
        SellIn := -Any.IntegerInRange(1, 8);
        Quality := Any.IntegerInRange(10, 45);
        SeedItem('TRYAL-GR20', "Gilded Item Category"::Conjured, SellIn, Quality);

        UpdateOneDay('TRYAL-GR20');

        VerifyItem('TRYAL-GR20', SellIn - 1, Quality - 4, StrSubstNo('an expired Conjured item with generated values (Sell In %1, Quality %2)', SellIn, Quality));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EndOfDayAgesTheWholeInventoryOnce()
    var
        GildedRose: Codeunit "Gilded Rose";
    begin
        // [SCENARIO] EndOfDay moves every item in the table forward exactly one day, each by its own rule
        SeedItem('TRYAL-GR21A', "Gilded Item Category"::Normal, 5, 10);
        SeedItem('TRYAL-GR21B', "Gilded Item Category"::"Aged Brie", 2, 40);
        SeedItem('TRYAL-GR21C', "Gilded Item Category"::Sulfuras, 3, 80);
        SeedItem('TRYAL-GR21D', "Gilded Item Category"::"Backstage Pass", 7, 20);
        SeedItem('TRYAL-GR21E', "Gilded Item Category"::Conjured, 4, 10);

        GildedRose.EndOfDay();

        VerifyItem('TRYAL-GR21A', 4, 9, 'the Normal item after EndOfDay');
        VerifyItem('TRYAL-GR21B', 1, 41, 'the Aged Brie after EndOfDay');
        VerifyItem('TRYAL-GR21C', 3, 80, 'the Sulfuras after EndOfDay');
        VerifyItem('TRYAL-GR21D', 6, 22, 'the Backstage Pass (7 days out) after EndOfDay');
        VerifyItem('TRYAL-GR21E', 3, 8, 'the Conjured item after EndOfDay');
    end;

    local procedure SeedItem(No: Code[20]; ItemCategory: Enum "Gilded Item Category"; SellIn: Integer; Quality: Integer)
    var
        GildedItem: Record "Gilded Item";
    begin
        GildedItem.Init();
        GildedItem."No." := No;
        GildedItem.Category := ItemCategory;
        GildedItem."Sell In" := SellIn;
        GildedItem.Quality := Quality;
        GildedItem.Insert();
    end;

    local procedure UpdateOneDay(No: Code[20])
    var
        GildedItem: Record "Gilded Item";
        GildedRose: Codeunit "Gilded Rose";
    begin
        GildedItem.Get(No);
        GildedRose.UpdateItem(GildedItem);
    end;

    local procedure VerifyItem(No: Code[20]; ExpectedSellIn: Integer; ExpectedQuality: Integer; Context: Text)
    var
        GildedItem: Record "Gilded Item";
        Assert: Codeunit Assert;
    begin
        GildedItem.Get(No);
        Assert.AreEqual(ExpectedSellIn, GildedItem."Sell In", StrSubstNo('Expected the persisted "Sell In" after one day for %1', Context));
        Assert.AreEqual(ExpectedQuality, GildedItem.Quality, StrSubstNo('Expected the persisted Quality after one day for %1', Context));
    end;
}
