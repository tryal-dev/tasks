codeunit 50900 "Stock By Location Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EachLocationGetsItsOwnOnHand()
    var
        StockByLocation: Codeunit "Stock By Location";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OnHand: Dictionary of [Code[10], Decimal];
        ItemNo: Code[20];
        FirstLocation: Code[10];
        SecondLocation: Code[10];
        FirstQty: Decimal;
        SecondQty: Decimal;
    begin
        ItemNo := CreateItemNo();
        FirstLocation := CreateLocationCode();
        SecondLocation := CreateLocationCode();
        FirstQty := Any.DecimalInRange(10, 99, 2);
        SecondQty := Any.DecimalInRange(100, 199, 2);
        PostAdjustment(ItemNo, FirstLocation, FirstQty);
        PostAdjustment(ItemNo, SecondLocation, SecondQty);

        OnHand := StockByLocation.OnHandByLocation(ItemNo);

        Assert.AreEqual(2, OnHand.Count(),
            StrSubstNo('Expected exactly the two locations the item was posted to as keys, got %1', KeysAsText(OnHand)));
        AssertOnHandAt(OnHand, FirstLocation, FirstQty);
        AssertOnHandAt(OnHand, SecondLocation, SecondQty);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddsUpEveryEntryAtTheSameLocation()
    var
        StockByLocation: Codeunit "Stock By Location";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OnHand: Dictionary of [Code[10], Decimal];
        ItemNo: Code[20];
        OnlyLocation: Code[10];
        FirstQty: Decimal;
        SecondQty: Decimal;
        ThirdQty: Decimal;
    begin
        ItemNo := CreateItemNo();
        OnlyLocation := CreateLocationCode();
        FirstQty := Any.DecimalInRange(10, 99, 2);
        SecondQty := Any.DecimalInRange(10, 99, 2);
        ThirdQty := Any.DecimalInRange(10, 99, 2);
        PostAdjustment(ItemNo, OnlyLocation, FirstQty);
        PostAdjustment(ItemNo, OnlyLocation, SecondQty);
        PostAdjustment(ItemNo, OnlyLocation, ThirdQty);

        OnHand := StockByLocation.OnHandByLocation(ItemNo);

        Assert.AreEqual(1, OnHand.Count(),
            StrSubstNo('Expected a single key for the single location all three adjustments were posted to, got %1', KeysAsText(OnHand)));
        AssertOnHandAt(OnHand, OnlyLocation, FirstQty + SecondQty + ThirdQty);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeEntriesReduceTheOnHand()
    var
        StockByLocation: Codeunit "Stock By Location";
        OnHand: Dictionary of [Code[10], Decimal];
        Any: Codeunit Any;
        ItemNo: Code[20];
        OnlyLocation: Code[10];
        ReceivedQty: Decimal;
        ShippedQty: Decimal;
    begin
        ItemNo := CreateItemNo();
        OnlyLocation := CreateLocationCode();
        ReceivedQty := Any.DecimalInRange(500, 900, 2);
        ShippedQty := Any.DecimalInRange(100, 400, 2);
        PostAdjustment(ItemNo, OnlyLocation, ReceivedQty);
        PostAdjustment(ItemNo, OnlyLocation, -ShippedQty);

        OnHand := StockByLocation.OnHandByLocation(ItemNo);

        AssertOnHandAt(OnHand, OnlyLocation, ReceivedQty - ShippedQty);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ANetZeroLocationStillAppearsWithZero()
    var
        StockByLocation: Codeunit "Stock By Location";
        Any: Codeunit Any;
        OnHand: Dictionary of [Code[10], Decimal];
        ItemNo: Code[20];
        EmptiedLocation: Code[10];
        MovedQty: Decimal;
    begin
        ItemNo := CreateItemNo();
        EmptiedLocation := CreateLocationCode();
        MovedQty := Any.DecimalInRange(100, 900, 2);
        PostAdjustment(ItemNo, EmptiedLocation, MovedQty);
        PostAdjustment(ItemNo, EmptiedLocation, -MovedQty);

        OnHand := StockByLocation.OnHandByLocation(ItemNo);

        AssertOnHandAt(OnHand, EmptiedLocation, 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OtherItemsEntriesDoNotLeakIn()
    var
        StockByLocation: Codeunit "Stock By Location";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OnHand: Dictionary of [Code[10], Decimal];
        ItemNo: Code[20];
        OtherItemNo: Code[20];
        SharedLocation: Code[10];
        OtherLocation: Code[10];
        OwnQty: Decimal;
    begin
        ItemNo := CreateItemNo();
        OtherItemNo := CreateItemNo();
        SharedLocation := CreateLocationCode();
        OtherLocation := CreateLocationCode();
        OwnQty := Any.DecimalInRange(10, 99, 2);
        PostAdjustment(ItemNo, SharedLocation, OwnQty);
        PostAdjustment(OtherItemNo, SharedLocation, Any.DecimalInRange(100, 900, 2));
        PostAdjustment(OtherItemNo, OtherLocation, Any.DecimalInRange(100, 900, 2));

        OnHand := StockByLocation.OnHandByLocation(ItemNo);

        Assert.AreEqual(1, OnHand.Count(),
            StrSubstNo('Expected only the one location where the given item itself has entries — a location holding only the other item must not appear; got %1', KeysAsText(OnHand)));
        AssertOnHandAt(OnHand, SharedLocation, OwnQty);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EntriesPostedWithoutALocationAreIgnored()
    var
        StockByLocation: Codeunit "Stock By Location";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        OnHand: Dictionary of [Code[10], Decimal];
        ItemNo: Code[20];
        RealLocation: Code[10];
        LocatedQty: Decimal;
    begin
        ItemNo := CreateItemNo();
        RealLocation := CreateLocationCode();
        LocatedQty := Any.DecimalInRange(10, 99, 2);
        PostAdjustment(ItemNo, RealLocation, LocatedQty);
        PostAdjustment(ItemNo, '', Any.DecimalInRange(100, 900, 2));

        OnHand := StockByLocation.OnHandByLocation(ItemNo);

        Assert.IsFalse(OnHand.ContainsKey(''),
            'Expected no blank key — an entry posted without a location code belongs to no location');
        Assert.AreEqual(1, OnHand.Count(),
            StrSubstNo('Expected only the real location as a key, got %1', KeysAsText(OnHand)));
        AssertOnHandAt(OnHand, RealLocation, LocatedQty);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnItemWithNoEntriesGivesAnEmptyDictionary()
    var
        StockByLocation: Codeunit "Stock By Location";
        Assert: Codeunit Assert;
        OnHand: Dictionary of [Code[10], Decimal];
        ItemNo: Code[20];
    begin
        ItemNo := CreateItemNo();

        OnHand := StockByLocation.OnHandByLocation(ItemNo);

        Assert.AreEqual(0, OnHand.Count(),
            StrSubstNo('Expected an empty dictionary for an item that has never been posted — not an error and not other locations; got %1', KeysAsText(OnHand)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnUnknownItemNoGivesAnEmptyDictionary()
    var
        Item: Record Item;
        StockByLocation: Codeunit "Stock By Location";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        OnHand: Dictionary of [Code[10], Decimal];
        UnknownItemNo: Code[20];
    begin
        UnknownItemNo := CopyStr(LibraryUtility.GenerateGUID() + 'NOITEM', 1, MaxStrLen(UnknownItemNo));
        Assert.IsFalse(Item.Get(UnknownItemNo), 'Test setup: the generated item number must not match any item');

        OnHand := StockByLocation.OnHandByLocation(UnknownItemNo);

        Assert.AreEqual(0, OnHand.Count(),
            StrSubstNo('Expected an empty dictionary, not an error, for an item number that matches no item; got %1', KeysAsText(OnHand)));
    end;

    local procedure AssertOnHandAt(OnHand: Dictionary of [Code[10], Decimal]; LocationCode: Code[10]; ExpectedQty: Decimal)
    var
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(OnHand.ContainsKey(LocationCode),
            StrSubstNo('Expected location %1 to appear as a key in the dictionary, got %2', LocationCode, KeysAsText(OnHand)));
        Assert.AreEqual(ExpectedQty, OnHand.Get(LocationCode),
            StrSubstNo('Expected the on-hand quantity at location %1 to be the net sum of the item''s entries there', LocationCode));
    end;

    local procedure KeysAsText(OnHand: Dictionary of [Code[10], Decimal]): Text
    var
        LocationCode: Code[10];
        Result: Text;
    begin
        if OnHand.Count() = 0 then
            exit('no keys at all');
        foreach LocationCode in OnHand.Keys() do begin
            if Result <> '' then
                Result += ', ';
            Result += LocationCode;
        end;
        exit(StrSubstNo('these %1 key(s): %2', OnHand.Count(), Result));
    end;

    local procedure CreateItemNo(): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure CreateLocationCode(): Code[10]
    var
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        exit(Location.Code);
    end;

    local procedure PostAdjustment(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        LibraryInventory: Codeunit "Library - Inventory";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        if Qty >= 0 then
            LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
                "Item Ledger Entry Type"::"Positive Adjmt.", ItemNo, Qty)
        else
            LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
                "Item Ledger Entry Type"::"Negative Adjmt.", ItemNo, -Qty);
        if LocationCode <> '' then begin
            ItemJournalLine.Validate("Location Code", LocationCode);
            ItemJournalLine.Modify(true);
        end;
        // Post through the line-level routine: the batch posting codeunit
        // commits, which AutoRollback tests forbid.
        ItemJnlPostLine.RunWithCheck(ItemJournalLine);
    end;
}
