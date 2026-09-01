codeunit 50900 "Transfer In Transit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Standard posting commits on its own; CommitBehavior::Ignore on every test
    // silences those commits so the run stays rollback-safe and can grade in the
    // shared warm company.

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure CreateOrderMakesARealOrderAndPostsNothing()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferFlow: Codeunit "Transfer Flow";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNo: Code[20];
        FromLoc: Code[10];
        InTransitLoc: Code[10];
        ToLoc: Code[10];
        OrderNo: Code[20];
        Qty: Decimal;
    begin
        // [SCENARIO] CreateOrder builds an unposted transfer order and returns its number
        ItemNo := CreateItemNo();
        FromLoc := CreateLocationCode();
        ToLoc := CreateLocationCode();
        InTransitLoc := CreateInTransitCode();
        Qty := Any.DecimalInRange(10, 99, 2);

        OrderNo := TransferFlow.CreateOrder(ItemNo, FromLoc, InTransitLoc, ToLoc, Qty);

        Assert.IsTrue(OrderNo <> '', 'Expected CreateOrder to return the number of the transfer order it created, got an empty code');
        Assert.IsTrue(TransferHeader.Get(OrderNo), StrSubstNo('Expected a Transfer Header with the returned number %1 to exist', OrderNo));
        Assert.AreEqual(FromLoc, TransferHeader."Transfer-from Code", 'Expected the order to ship from the given from-location');
        Assert.AreEqual(ToLoc, TransferHeader."Transfer-to Code", 'Expected the order to ship to the given to-location');
        Assert.AreEqual(InTransitLoc, TransferHeader."In-Transit Code", 'Expected the order to travel through the given in-transit location');
        FindOrderLine(TransferLine, OrderNo);
        Assert.AreEqual(ItemNo, TransferLine."Item No.", 'Expected the order line to carry the given item');
        Assert.AreEqual(Qty, TransferLine.Quantity, 'Expected the order line to carry the given quantity');
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        Assert.AreEqual(0, ItemLedgerEntry.Count(),
            StrSubstNo('Expected creating the order to post nothing — the ledger must stay empty until Ship is called, but it holds: %1', LedgerAsText(ItemNo)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ShippingParksTheQuantityAtTheInTransitLocation()
    var
        TransferFlow: Codeunit "Transfer Flow";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNo: Code[20];
        FromLoc: Code[10];
        InTransitLoc: Code[10];
        ToLoc: Code[10];
        OrderNo: Code[20];
        Seed: Decimal;
        Qty: Decimal;
    begin
        // [SCENARIO] After shipping only, on-hand excludes the quantity at both real locations while in-transit holds it
        ItemNo := CreateItemNo();
        FromLoc := CreateLocationCode();
        ToLoc := CreateLocationCode();
        InTransitLoc := CreateInTransitCode();
        Seed := Any.DecimalInRange(200, 400, 2);
        Qty := Any.DecimalInRange(50, 150, 2);
        SeedStock(ItemNo, FromLoc, Seed);
        OrderNo := TransferFlow.CreateOrder(ItemNo, FromLoc, InTransitLoc, ToLoc, Qty);

        TransferFlow.Ship(OrderNo, Qty);

        Assert.AreEqual(Seed - Qty, TransferFlow.OnHand(ItemNo, FromLoc),
            'Expected OnHand at the from-location to exclude the shipped quantity once it is on the truck');
        Assert.AreEqual(Qty, TransferFlow.OnHand(ItemNo, InTransitLoc),
            'Expected OnHand at the in-transit location to hold the shipped quantity while it is underway');
        Assert.AreEqual(0, TransferFlow.OnHand(ItemNo, ToLoc),
            'Expected OnHand at the to-location to stay at zero until the receipt is posted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ShippingWritesTransferEntriesNotAdjustments()
    var
        TransferFlow: Codeunit "Transfer Flow";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNo: Code[20];
        FromLoc: Code[10];
        InTransitLoc: Code[10];
        ToLoc: Code[10];
        OrderNo: Code[20];
        Seed: Decimal;
        Qty: Decimal;
    begin
        // [SCENARIO] The shipment's ledger footprint is two Transfer entries, not a pair of adjustments
        ItemNo := CreateItemNo();
        FromLoc := CreateLocationCode();
        ToLoc := CreateLocationCode();
        InTransitLoc := CreateInTransitCode();
        Seed := Any.DecimalInRange(200, 400, 2);
        Qty := Any.DecimalInRange(50, 150, 2);
        SeedStock(ItemNo, FromLoc, Seed);
        OrderNo := TransferFlow.CreateOrder(ItemNo, FromLoc, InTransitLoc, ToLoc, Qty);

        TransferFlow.Ship(OrderNo, Qty);

        AssertTransferEntry(ItemNo, FromLoc, -Qty, 'for the shipment out of the from-location');
        AssertTransferEntry(ItemNo, InTransitLoc, Qty, 'for the shipment into the in-transit location');
        Assert.AreEqual(2, TransferEntryCount(ItemNo),
            StrSubstNo('Expected exactly two Transfer-type entries after shipping, got %1 — the ledger holds: %2', TransferEntryCount(ItemNo), LedgerAsText(ItemNo)));
        Assert.AreEqual(3, TotalEntryCount(ItemNo),
            StrSubstNo('Expected only the seeded adjustment plus the two Transfer entries — item-journal adjustments give the right totals with the wrong entry types and locations. The ledger holds: %1', LedgerAsText(ItemNo)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ReceivingCompletesTheFourEntryTransferFootprint()
    var
        TransferFlow: Codeunit "Transfer Flow";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNo: Code[20];
        FromLoc: Code[10];
        InTransitLoc: Code[10];
        ToLoc: Code[10];
        OrderNo: Code[20];
        Seed: Decimal;
        Qty: Decimal;
    begin
        // [SCENARIO] A full ship-then-receive leaves exactly four Transfer entries: out of From, into In-Transit, out of In-Transit, into To
        ItemNo := CreateItemNo();
        FromLoc := CreateLocationCode();
        ToLoc := CreateLocationCode();
        InTransitLoc := CreateInTransitCode();
        Seed := Any.DecimalInRange(200, 400, 2);
        Qty := Any.DecimalInRange(50, 150, 2);
        SeedStock(ItemNo, FromLoc, Seed);
        OrderNo := TransferFlow.CreateOrder(ItemNo, FromLoc, InTransitLoc, ToLoc, Qty);
        TransferFlow.Ship(OrderNo, Qty);

        TransferFlow.Receive(OrderNo, Qty);

        AssertTransferEntry(ItemNo, FromLoc, -Qty, 'for the shipment out of the from-location');
        AssertTransferEntry(ItemNo, InTransitLoc, Qty, 'for the shipment into the in-transit location');
        AssertTransferEntry(ItemNo, InTransitLoc, -Qty, 'for the receipt out of the in-transit location');
        AssertTransferEntry(ItemNo, ToLoc, Qty, 'for the receipt into the to-location');
        Assert.AreEqual(4, TransferEntryCount(ItemNo),
            StrSubstNo('Expected exactly four Transfer-type entries for the full in-transit lifecycle, got %1 — the ledger holds: %2', TransferEntryCount(ItemNo), LedgerAsText(ItemNo)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ReceivingMovesTheQuantityToTheDestination()
    var
        TransferFlow: Codeunit "Transfer Flow";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNo: Code[20];
        FromLoc: Code[10];
        InTransitLoc: Code[10];
        ToLoc: Code[10];
        OrderNo: Code[20];
        Seed: Decimal;
        Qty: Decimal;
    begin
        // [SCENARIO] After the receipt, on-hand shows the quantity at the destination and an empty in-transit location
        ItemNo := CreateItemNo();
        FromLoc := CreateLocationCode();
        ToLoc := CreateLocationCode();
        InTransitLoc := CreateInTransitCode();
        Seed := Any.DecimalInRange(200, 400, 2);
        Qty := Any.DecimalInRange(50, 150, 2);
        SeedStock(ItemNo, FromLoc, Seed);
        OrderNo := TransferFlow.CreateOrder(ItemNo, FromLoc, InTransitLoc, ToLoc, Qty);
        TransferFlow.Ship(OrderNo, Qty);

        TransferFlow.Receive(OrderNo, Qty);

        Assert.AreEqual(Seed - Qty, TransferFlow.OnHand(ItemNo, FromLoc),
            'Expected OnHand at the from-location to stay reduced after the receipt');
        Assert.AreEqual(0, TransferFlow.OnHand(ItemNo, InTransitLoc),
            'Expected OnHand at the in-transit location to drop back to zero once the goods arrived');
        Assert.AreEqual(Qty, TransferFlow.OnHand(ItemNo, ToLoc),
            'Expected OnHand at the to-location to hold the received quantity');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure APartialQtyToReceiveLeavesTheRestInTransit()
    var
        TransferLine: Record "Transfer Line";
        TransferFlow: Codeunit "Transfer Flow";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNo: Code[20];
        FromLoc: Code[10];
        InTransitLoc: Code[10];
        ToLoc: Code[10];
        OrderNo: Code[20];
        Seed: Decimal;
        ShippedQty: Decimal;
        ReceivedQty: Decimal;
    begin
        // [SCENARIO] Receiving less than is in transit posts exactly that quantity and leaves the remainder on the truck
        ItemNo := CreateItemNo();
        FromLoc := CreateLocationCode();
        ToLoc := CreateLocationCode();
        InTransitLoc := CreateInTransitCode();
        Seed := Any.DecimalInRange(300, 500, 2);
        ReceivedQty := Any.DecimalInRange(20, 80, 2);
        ShippedQty := ReceivedQty + Any.DecimalInRange(30, 90, 2);
        SeedStock(ItemNo, FromLoc, Seed);
        OrderNo := TransferFlow.CreateOrder(ItemNo, FromLoc, InTransitLoc, ToLoc, ShippedQty);
        TransferFlow.Ship(OrderNo, ShippedQty);

        TransferFlow.Receive(OrderNo, ReceivedQty);

        AssertTransferEntry(ItemNo, InTransitLoc, -ReceivedQty, 'for the partial receipt out of the in-transit location');
        AssertTransferEntry(ItemNo, ToLoc, ReceivedQty, 'for the partial receipt into the to-location');
        Assert.AreEqual(4, TransferEntryCount(ItemNo),
            StrSubstNo('Expected the receipt to post only the received quantity — the two shipment entries plus two receipt entries — but the ledger holds: %1', LedgerAsText(ItemNo)));
        Assert.AreEqual(ShippedQty - ReceivedQty, TransferFlow.OnHand(ItemNo, InTransitLoc),
            'Expected OnHand at the in-transit location to keep the shipped-but-not-yet-received remainder');
        Assert.AreEqual(ReceivedQty, TransferFlow.OnHand(ItemNo, ToLoc),
            'Expected OnHand at the to-location to hold exactly the received quantity');
        FindOrderLine(TransferLine, OrderNo);
        Assert.AreEqual(ShippedQty - ReceivedQty, TransferLine."Qty. in Transit",
            'Expected "Qty. in Transit" on the order line to drop to the not-yet-received remainder');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure APartialQtyToShipSplitsTheOrderLine()
    var
        TransferLine: Record "Transfer Line";
        TransferFlow: Codeunit "Transfer Flow";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNo: Code[20];
        FromLoc: Code[10];
        InTransitLoc: Code[10];
        ToLoc: Code[10];
        OrderNo: Code[20];
        Seed: Decimal;
        OrderedQty: Decimal;
        ShippedQty: Decimal;
    begin
        // [SCENARIO] Shipping less than the ordered quantity splits the line into shipped, in-transit and outstanding parts
        ItemNo := CreateItemNo();
        FromLoc := CreateLocationCode();
        ToLoc := CreateLocationCode();
        InTransitLoc := CreateInTransitCode();
        Seed := Any.DecimalInRange(300, 500, 2);
        ShippedQty := Any.DecimalInRange(20, 80, 2);
        OrderedQty := ShippedQty + Any.DecimalInRange(30, 90, 2);
        SeedStock(ItemNo, FromLoc, Seed);
        OrderNo := TransferFlow.CreateOrder(ItemNo, FromLoc, InTransitLoc, ToLoc, OrderedQty);

        TransferFlow.Ship(OrderNo, ShippedQty);

        FindOrderLine(TransferLine, OrderNo);
        Assert.AreEqual(OrderedQty, TransferLine.Quantity, 'Expected the order line to still carry the full ordered quantity after a partial shipment');
        Assert.AreEqual(ShippedQty, TransferLine."Quantity Shipped", 'Expected "Quantity Shipped" on the order line to equal the quantity passed to Ship');
        Assert.AreEqual(OrderedQty - ShippedQty, TransferLine."Outstanding Quantity", 'Expected "Outstanding Quantity" on the order line to be the not-yet-shipped remainder');
        Assert.AreEqual(ShippedQty, TransferLine."Qty. in Transit", 'Expected "Qty. in Transit" on the order line to equal what was shipped but not yet received');
        AssertTransferEntry(ItemNo, FromLoc, -ShippedQty, 'for the partial shipment out of the from-location');
        AssertTransferEntry(ItemNo, InTransitLoc, ShippedQty, 'for the partial shipment into the in-transit location');
        Assert.AreEqual(2, TransferEntryCount(ItemNo),
            StrSubstNo('Expected only the partial quantity to be posted — two Transfer entries — but the ledger holds: %1', LedgerAsText(ItemNo)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ADirectTransferMovesStockWithJustTwoEntries()
    var
        TransferFlow: Codeunit "Transfer Flow";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNo: Code[20];
        FromLoc: Code[10];
        ToLoc: Code[10];
        Seed: Decimal;
        Qty: Decimal;
    begin
        // [SCENARIO] A direct transfer produces two Transfer entries and never touches an in-transit location
        ItemNo := CreateItemNo();
        FromLoc := CreateLocationCode();
        ToLoc := CreateLocationCode();
        Seed := Any.DecimalInRange(200, 400, 2);
        Qty := Any.DecimalInRange(50, 150, 2);
        SeedStock(ItemNo, FromLoc, Seed);

        TransferFlow.DirectTransfer(ItemNo, FromLoc, ToLoc, Qty);

        AssertTransferEntry(ItemNo, FromLoc, -Qty, 'for the direct transfer out of the from-location');
        AssertTransferEntry(ItemNo, ToLoc, Qty, 'for the direct transfer into the to-location');
        Assert.AreEqual(2, TransferEntryCount(ItemNo),
            StrSubstNo('Expected a direct transfer to write exactly two Transfer-type entries, got %1 — the ledger holds: %2', TransferEntryCount(ItemNo), LedgerAsText(ItemNo)));
        Assert.AreEqual(3, TotalEntryCount(ItemNo),
            StrSubstNo('Expected only the seeded adjustment plus the two Transfer entries — no extra adjustments or in-transit stops. The ledger holds: %1', LedgerAsText(ItemNo)));
        Assert.AreEqual(Seed - Qty, TransferFlow.OnHand(ItemNo, FromLoc),
            'Expected OnHand at the from-location to exclude the directly transferred quantity');
        Assert.AreEqual(Qty, TransferFlow.OnHand(ItemNo, ToLoc),
            'Expected OnHand at the to-location to hold the directly transferred quantity');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ReceivingMoreThanIsInTransitFailsAndPostsNothing()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TransferFlow: Codeunit "Transfer Flow";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNo: Code[20];
        FromLoc: Code[10];
        InTransitLoc: Code[10];
        ToLoc: Code[10];
        OrderNo: Code[20];
        Seed: Decimal;
        OrderedQty: Decimal;
        ShippedQty: Decimal;
    begin
        // [SCENARIO] Receiving more than was shipped is rejected and leaves the ledger untouched
        ItemNo := CreateItemNo();
        FromLoc := CreateLocationCode();
        ToLoc := CreateLocationCode();
        InTransitLoc := CreateInTransitCode();
        Seed := Any.DecimalInRange(300, 500, 2);
        ShippedQty := Any.DecimalInRange(10, 40, 2);
        OrderedQty := ShippedQty + Any.DecimalInRange(30, 60, 2);
        SeedStock(ItemNo, FromLoc, Seed);
        OrderNo := TransferFlow.CreateOrder(ItemNo, FromLoc, InTransitLoc, ToLoc, OrderedQty);
        TransferFlow.Ship(OrderNo, ShippedQty);

        if TryReceive(OrderNo, ShippedQty + Any.DecimalInRange(1, 25, 2)) then
            Assert.Fail('Expected receiving more than was shipped to be rejected, but the receipt was posted');

        Assert.ExpectedError('You cannot receive more than');
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", ToLoc);
        Assert.AreEqual(0, ItemLedgerEntry.Count(),
            StrSubstNo('Expected the failed receipt to post nothing at the to-location, but the ledger holds: %1', LedgerAsText(ItemNo)));
        Assert.AreEqual(2, TransferEntryCount(ItemNo),
            StrSubstNo('Expected the ledger to still hold only the two shipment entries after the failed receipt, but it holds: %1', LedgerAsText(ItemNo)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure OnHandReportsTheNetLedgerSumPerLocation()
    var
        TransferFlow: Codeunit "Transfer Flow";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemNo: Code[20];
        StockedLoc: Code[10];
        UntouchedLoc: Code[10];
        ReceivedQty: Decimal;
        RemovedQty: Decimal;
    begin
        // [SCENARIO] OnHand sums the item's ledger quantities at one location and reports zero where the item never moved
        ItemNo := CreateItemNo();
        StockedLoc := CreateLocationCode();
        UntouchedLoc := CreateLocationCode();
        ReceivedQty := Any.DecimalInRange(100, 300, 2);
        RemovedQty := Any.DecimalInRange(10, 90, 2);
        SeedStock(ItemNo, StockedLoc, ReceivedQty);
        SeedStock(ItemNo, StockedLoc, -RemovedQty);

        Assert.AreEqual(ReceivedQty - RemovedQty, TransferFlow.OnHand(ItemNo, StockedLoc),
            'Expected OnHand to return the net sum of the item''s ledger entries at the location — positive and negative postings together');
        Assert.AreEqual(0, TransferFlow.OnHand(ItemNo, UntouchedLoc),
            'Expected OnHand to return zero for a location the item has never touched');
    end;

    local procedure AssertTransferEntry(ItemNo: Code[20]; LocationCode: Code[10]; ExpectedQty: Decimal; Context: Text)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Assert: Codeunit Assert;
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange(Quantity, ExpectedQty);
        Assert.AreEqual(1, ItemLedgerEntry.Count(),
            StrSubstNo('Expected exactly one Transfer-type item ledger entry of quantity %1 at %2 %3. The item''s ledger holds: %4', ExpectedQty, LocationCode, Context, LedgerAsText(ItemNo)));
    end;

    local procedure TransferEntryCount(ItemNo: Code[20]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        exit(ItemLedgerEntry.Count());
    end;

    local procedure TotalEntryCount(ItemNo: Code[20]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        exit(ItemLedgerEntry.Count());
    end;

    local procedure LedgerAsText(ItemNo: Code[20]): Text
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Result: Text;
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        if not ItemLedgerEntry.FindSet() then
            exit('no entries at all');
        repeat
            if Result <> '' then
                Result += '; ';
            Result += StrSubstNo('%1 %2 at %3', ItemLedgerEntry."Entry Type", ItemLedgerEntry.Quantity, ItemLedgerEntry."Location Code");
        until ItemLedgerEntry.Next() = 0;
        exit(Result);
    end;

    local procedure FindOrderLine(var TransferLine: Record "Transfer Line"; OrderNo: Code[20])
    var
        Assert: Codeunit Assert;
    begin
        TransferLine.SetRange("Document No.", OrderNo);
        TransferLine.SetRange("Derived From Line No.", 0);
        Assert.IsTrue(TransferLine.FindFirst(),
            StrSubstNo('Expected transfer order %1 to have an order line of its own (with "Derived From Line No." = 0)', OrderNo));
    end;

    // A refused call is caught through a try function, not asserterror: an error
    // caught by asserterror rolls the transaction back to the last commit and
    // would take the arrangement with it; a try function keeps every row.
    [TryFunction]
    local procedure TryReceive(OrderNo: Code[20]; Qty: Decimal)
    var
        TransferFlow: Codeunit "Transfer Flow";
    begin
        TransferFlow.Receive(OrderNo, Qty);
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

    local procedure CreateInTransitCode(): Code[10]
    var
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateInTransitLocation(Location);
        exit(Location.Code);
    end;

    local procedure SeedStock(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
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
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        // Post through the line-level routine: the batch posting codeunit raises UI.
        ItemJnlPostLine.RunWithCheck(ItemJournalLine);
    end;
}
