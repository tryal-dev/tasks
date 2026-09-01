codeunit 50900 "Exact Cost Reversal Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Standard posting commits on its own; CommitBehavior::Ignore on every test
    // silences those commits so the run stays rollback-safe and can grade in the
    // shared warm company.

    // [FEATURE] [Inventory Costing] [Sales Return]

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ReturnIsValuedAtTheCostTheGoodsWereSoldAt()
    var
        ExactCostReturnMgt: Codeunit "Exact Cost Return Mgt.";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ShipmentNo: Code[20];
    begin
        // [SCENARIO] Goods sold out of the 10.00 layer come back worth 10.00 each, not the item's current value
        // [GIVEN] purchase layers of 10 pieces at 10.00 and 10 pieces at 25.00 and a sale of 4 pieces
        SetupTwoLayers(CustomerNo, ItemNo, 10.0, 25.0);
        ShipmentNo := PostSale(CustomerNo, ItemNo, 4);

        // [WHEN] returning 2 of the 4 shipped pieces
        ExactCostReturnMgt.PostExactCostReturn(ShipmentNo, 2);

        // [THEN] the return's item ledger entry is worth 2 x 10.00 — FIFO's next layer (25.00 each) and the item's blended unit cost both give a different number
        AdjustCost(ItemNo);
        Assert.AreEqual(20.0, ReturnEntryCost(ItemNo),
            'Expected the returned 2 pieces to re-enter inventory at the 10.00 they were sold at, so "Cost Amount (Actual)" on the return''s item ledger entry is 20.00');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ReturnCostFollowsTheGeneratedOriginalCost()
    var
        ExactCostReturnMgt: Codeunit "Exact Cost Return Mgt.";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ShipmentNo: Code[20];
        OldCost: Decimal;
        NewCost: Decimal;
    begin
        // [SCENARIO] The reversed cost is read from the original entry, so generated costs are reversed just as exactly as round ones
        // [GIVEN] two purchase layers at generated unit costs and a sale of 4 pieces out of the older one
        OldCost := LibraryRandom.RandDecInRange(10, 30, 2);
        NewCost := OldCost + LibraryRandom.RandDecInRange(20, 40, 2);
        SetupTwoLayers(CustomerNo, ItemNo, OldCost, NewCost);
        ShipmentNo := PostSale(CustomerNo, ItemNo, 4);

        // [WHEN] returning 3 of the 4 shipped pieces
        ExactCostReturnMgt.PostExactCostReturn(ShipmentNo, 3);

        // [THEN] the return is worth 3 x the older layer's generated cost — a hardcoded amount cannot match
        AdjustCost(ItemNo);
        Assert.AreEqual(3 * OldCost, ReturnEntryCost(ItemNo),
            StrSubstNo('Expected the 3 returned pieces to be valued at the sale''s own unit cost of %1, not at the newer layer''s %2 or at any fixed amount', OldCost, NewCost));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ReturnUsesTheShipmentItWasGivenNotTheFirstOne()
    var
        ExactCostReturnMgt: Codeunit "Exact Cost Return Mgt.";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        FirstShipmentNo: Code[20];
        SecondShipmentNo: Code[20];
        OldCost: Decimal;
        NewCost: Decimal;
    begin
        // [SCENARIO] Two shipments of the same item drew from different layers — the return must reverse the shipment it was handed
        // [GIVEN] a first sale of 10 pieces that empties the older layer and a second sale of 5 pieces out of the newer one
        OldCost := LibraryRandom.RandDecInRange(10, 30, 2);
        NewCost := OldCost + LibraryRandom.RandDecInRange(20, 40, 2);
        SetupTwoLayers(CustomerNo, ItemNo, OldCost, NewCost);
        FirstShipmentNo := PostSale(CustomerNo, ItemNo, 10);
        SecondShipmentNo := PostSale(CustomerNo, ItemNo, 5);

        // [WHEN] returning 3 pieces against the second shipment
        ExactCostReturnMgt.PostExactCostReturn(SecondShipmentNo, 3);

        // [THEN] the return carries the second shipment's cost, not the first shipment's
        AdjustCost(ItemNo);
        Assert.AreEqual(3 * NewCost, ReturnEntryCost(ItemNo),
            StrSubstNo('Expected the return against shipment %1 to be valued at that shipment''s unit cost %2 — reversing the first shipment %3 instead would give %4', SecondShipmentNo, NewCost, FirstShipmentNo, 3 * OldCost));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure FullReturnReversesTheWholeSaleCost()
    var
        ExactCostReturnMgt: Codeunit "Exact Cost Return Mgt.";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ShipmentNo: Code[20];
        OldCost: Decimal;
        NewCost: Decimal;
    begin
        // [SCENARIO] Returning the entire shipped quantity of a sale that spanned both layers cancels the sale's cost exactly
        // [GIVEN] two layers of 10 pieces at generated costs and a sale of 14 pieces, so the sale drew 10 from the old layer and 4 from the new one
        OldCost := LibraryRandom.RandDecInRange(10, 30, 2);
        NewCost := OldCost + LibraryRandom.RandDecInRange(20, 40, 2);
        SetupTwoLayers(CustomerNo, ItemNo, OldCost, NewCost);
        ShipmentNo := PostSale(CustomerNo, ItemNo, 14);

        // [WHEN] returning all 14 shipped pieces — the largest quantity the guard may accept
        ExactCostReturnMgt.PostExactCostReturn(ShipmentNo, 14);

        // [THEN] the return is worth the sale's blended cost, and the two entries add up to nothing
        AdjustCost(ItemNo);
        // Cent tolerance: the blended unit cost of the sale does not divide evenly over 14
        // pieces, so the reversal is graded on the amount, not on the division's last digit.
        Assert.AreNearlyEqual(10 * OldCost + 4 * NewCost, ReturnEntryCost(ItemNo), 0.01,
            StrSubstNo('Expected the full return to carry the sale''s own cost of 10 x %1 + 4 x %2 — the whole point of an exact cost reversal is that the blend the sale was valued at comes back untouched', OldCost, NewCost));
        Assert.AreNearlyEqual(0, SaleEntryCost(ItemNo, ShipmentNo) + ReturnEntryCost(ItemNo), 0.01,
            'Expected the sale''s "Cost Amount (Actual)" and the return''s to cancel out to zero after a full exact cost reversal');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ReturnAboveTheShippedQuantityIsRejected()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ExactCostReturnMgt: Codeunit "Exact Cost Return Mgt.";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ShipmentNo: Code[20];
    begin
        // [SCENARIO] A customer cannot send back more than was shipped, and the refusal must come from the guard, not from a half-posted document
        // [GIVEN] a posted shipment of 4 pieces
        SetupTwoLayers(CustomerNo, ItemNo, 10.0, 25.0);
        ShipmentNo := PostSale(CustomerNo, ItemNo, 4);

        // [WHEN] asking to return 5 pieces
        if TryPostExactCostReturn(ShipmentNo, 5) then
            Assert.Fail('Expected a return of 5 pieces against a shipment of 4 to be rejected, but it was posted');

        // [THEN] the call fails with the promised phrase and nothing came back into inventory
        Assert.ExpectedError('exceeds the shipped quantity');
        FilterReturnEntries(ItemLedgerEntry, ItemNo);
        Assert.IsTrue(ItemLedgerEntry.IsEmpty(),
            StrSubstNo('Expected no return to be posted for item %1 when the requested quantity exceeds the shipment — check the quantity before you create or post anything', ItemNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ApplicationEntryLinksTheReturnToTheSale()
    var
        ItemApplicationEntry: Record "Item Application Entry";
        ExactCostReturnMgt: Codeunit "Exact Cost Return Mgt.";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ShipmentNo: Code[20];
        SaleEntryNo: Integer;
        ReturnEntryNo: Integer;
    begin
        // [SCENARIO] The reversal is recorded as an item application between the return entry and the sale entry it reverses
        // [GIVEN] a posted shipment of 4 pieces
        SetupTwoLayers(CustomerNo, ItemNo, 10.0, 25.0);
        ShipmentNo := PostSale(CustomerNo, ItemNo, 4);

        // [WHEN] returning 2 pieces
        ExactCostReturnMgt.PostExactCostReturn(ShipmentNo, 2);

        // [THEN] an item application entry names the return as the inbound entry and the sale as the outbound entry
        SaleEntryNo := ShipmentEntryNo(ItemNo, ShipmentNo);
        ReturnEntryNo := ReturnedEntryNo(ItemNo);
        ItemApplicationEntry.SetRange("Inbound Item Entry No.", ReturnEntryNo);
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", SaleEntryNo);
        Assert.IsTrue(ItemApplicationEntry.FindFirst(),
            StrSubstNo('Expected an "Item Application Entry" pairing the return''s entry %1 as the inbound entry with the sale''s entry %2 as the outbound entry — that pair is what carries the original cost onto the return', ReturnEntryNo, SaleEntryNo));
        Assert.AreEqual(2, Abs(ItemApplicationEntry.Quantity),
            'Expected the application between the return and the sale to cover the 2 returned pieces');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure PostsACreditMemoForTheShipmentsCustomer()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ExactCostReturnMgt: Codeunit "Exact Cost Return Mgt.";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ShipmentNo: Code[20];
        CreditMemoNo: Code[20];
    begin
        // [SCENARIO] The returned number identifies a posted sales credit memo for the shipment's customer carrying the returned line
        // [GIVEN] a posted shipment of 4 pieces
        SetupTwoLayers(CustomerNo, ItemNo, 10.0, 25.0);
        ShipmentNo := PostSale(CustomerNo, ItemNo, 4);

        // [WHEN] returning 2 pieces
        CreditMemoNo := ExactCostReturnMgt.PostExactCostReturn(ShipmentNo, 2);

        // [THEN] the returned no. is a posted credit memo for that customer with an item line of 2 pieces
        Assert.IsTrue(SalesCrMemoHeader.Get(CreditMemoNo),
            StrSubstNo('Expected PostExactCostReturn to return the number of a posted sales credit memo, but no "Sales Cr.Memo Header" exists with the returned value "%1"', CreditMemoNo));
        Assert.AreEqual(CustomerNo, SalesCrMemoHeader."Sell-to Customer No.",
            'Expected the posted credit memo to be for the customer the shipment went to');
        SalesCrMemoLine.SetRange("Document No.", CreditMemoNo);
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::Item);
        SalesCrMemoLine.SetRange("No.", ItemNo);
        Assert.IsTrue(SalesCrMemoLine.FindFirst(),
            StrSubstNo('Expected posted credit memo %1 to hold an item line for the shipped item %2', CreditMemoNo, ItemNo));
        Assert.AreEqual(2, SalesCrMemoLine.Quantity,
            'Expected the posted credit memo line to carry the quantity that was returned');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure FindSaleEntryNoPointsAtTheGivenShipmentsEntry()
    var
        ExactCostReturnMgt: Codeunit "Exact Cost Return Mgt.";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        FirstShipmentNo: Code[20];
        SecondShipmentNo: Code[20];
    begin
        // [SCENARIO] FindSaleEntryNo resolves the shipment it is given, not simply the item's first sale
        // [GIVEN] two posted shipments of the same item
        SetupTwoLayers(CustomerNo, ItemNo, 10.0, 25.0);
        FirstShipmentNo := PostSale(CustomerNo, ItemNo, 4);
        SecondShipmentNo := PostSale(CustomerNo, ItemNo, 3);

        // [WHEN] asking for the entry behind the second shipment
        // [THEN] the answer is that shipment's own item ledger entry
        Assert.AreEqual(ShipmentEntryNo(ItemNo, SecondShipmentNo), ExactCostReturnMgt.FindSaleEntryNo(SecondShipmentNo),
            StrSubstNo('Expected FindSaleEntryNo(%1) to return the item ledger entry that shipment created — returning the item''s first sale entry (%2, from shipment %3) is not the same entry', SecondShipmentNo, ShipmentEntryNo(ItemNo, FirstShipmentNo), FirstShipmentNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ReturnPostsWhenExactCostReversingIsMandatory()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ExactCostReturnMgt: Codeunit "Exact Cost Return Mgt.";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ShipmentNo: Code[20];
        OldCost: Decimal;
        NewCost: Decimal;
    begin
        // [SCENARIO] With "Exact Cost Reversing Mandatory" switched on, the return still posts — and still at the original cost
        // [GIVEN] a posted shipment of 4 pieces in a company that refuses returns without an exact cost reversal
        OldCost := LibraryRandom.RandDecInRange(10, 30, 2);
        NewCost := OldCost + LibraryRandom.RandDecInRange(20, 40, 2);
        SetupTwoLayers(CustomerNo, ItemNo, OldCost, NewCost);
        ShipmentNo := PostSale(CustomerNo, ItemNo, 4);
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Exact Cost Reversing Mandatory" := true;
        SalesReceivablesSetup.Modify();

        // [WHEN] returning 2 pieces
        ExactCostReturnMgt.PostExactCostReturn(ShipmentNo, 2);

        // [THEN] the credit memo posted and the returned pieces carry the sale's cost
        AdjustCost(ItemNo);
        Assert.AreEqual(2 * OldCost, ReturnEntryCost(ItemNo),
            'Expected the return to post and keep the sale''s cost even when "Exact Cost Reversing Mandatory" is switched on in Sales & Receivables Setup');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure OriginalSaleEntryKeepsItsOwnCost()
    var
        ExactCostReturnMgt: Codeunit "Exact Cost Return Mgt.";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ShipmentNo: Code[20];
        OldCost: Decimal;
        NewCost: Decimal;
    begin
        // [SCENARIO] The return adds an entry, it does not rewrite the sale — the shipment's own cost stays what it was
        // [GIVEN] a sale of 4 pieces out of the older layer at a generated cost
        OldCost := LibraryRandom.RandDecInRange(10, 30, 2);
        NewCost := OldCost + LibraryRandom.RandDecInRange(20, 40, 2);
        SetupTwoLayers(CustomerNo, ItemNo, OldCost, NewCost);
        ShipmentNo := PostSale(CustomerNo, ItemNo, 4);

        // [WHEN] returning 2 pieces
        ExactCostReturnMgt.PostExactCostReturn(ShipmentNo, 2);

        // [THEN] the shipment's item ledger entry still carries the full cost of goods sold for 4 pieces
        AdjustCost(ItemNo);
        Assert.AreEqual(-4 * OldCost, SaleEntryCost(ItemNo, ShipmentNo),
            'Expected the sale''s own item ledger entry to keep its "Cost Amount (Actual)" — a return posts a new inbound entry, it never revalues the shipment');
    end;

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Ext. Doc. No. Mandatory" := false;
        PurchasesPayablesSetup.Modify();

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Ext. Doc. No. Mandatory" := false;
        SalesReceivablesSetup."Exact Cost Reversing Mandatory" := false;
        // Keeps the credit memo's item ledger entry on the credit memo itself, so every test
        // sees the same document shape no matter how the grading company was left set up.
        SalesReceivablesSetup."Return Receipt on Credit Memo" := false;
        SalesReceivablesSetup.Modify();
    end;

    // A refused call is caught through a try function, not asserterror: an error
    // caught by asserterror rolls the transaction back to the last commit and
    // would take the arrangement with it; a try function keeps every row.
    [TryFunction]
    local procedure TryPostExactCostReturn(ShipmentNo: Code[20]; Qty: Decimal)
    var
        ExactCostReturnMgt: Codeunit "Exact Cost Return Mgt.";
    begin
        ExactCostReturnMgt.PostExactCostReturn(ShipmentNo, Qty);
    end;

    local procedure SetupTwoLayers(var CustomerNo: Code[20]; var ItemNo: Code[20]; OldCost: Decimal; NewCost: Decimal)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Modify(true);
        CustomerNo := Customer."No.";
        ItemNo := Item."No.";
        PostPurchase(Vendor."No.", ItemNo, 10, OldCost);
        PostPurchase(Vendor."No.", ItemNo, 10, NewCost);
    end;

    local procedure PostPurchase(VendorNo: Code[20]; ItemNo: Code[20]; Qty: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Order, VendorNo, ItemNo, Qty, '', 0D);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostSale(CustomerNo: Code[20]; ItemNo: Code[20]; Qty: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();
        exit(SalesShipmentHeader."No.");
    end;

    local procedure AdjustCost(ItemNo: Code[20])
    begin
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
    end;

    local procedure ShipmentEntryNo(ItemNo: Code[20]; ShipmentNo: Code[20]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindSaleEntry(ItemLedgerEntry, ItemNo, ShipmentNo);
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure SaleEntryCost(ItemNo: Code[20]; ShipmentNo: Code[20]): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindSaleEntry(ItemLedgerEntry, ItemNo, ShipmentNo);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        exit(ItemLedgerEntry."Cost Amount (Actual)");
    end;

    local procedure ReturnedEntryNo(ItemNo: Code[20]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindReturnEntry(ItemLedgerEntry, ItemNo);
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure ReturnEntryCost(ItemNo: Code[20]): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindReturnEntry(ItemLedgerEntry, ItemNo);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        exit(ItemLedgerEntry."Cost Amount (Actual)");
    end;

    local procedure FindSaleEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; ShipmentNo: Code[20])
    begin
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetRange("Document No.", ShipmentNo);
        Assert.IsTrue(ItemLedgerEntry.FindFirst(),
            StrSubstNo('Expected posted sales shipment %1 to own an item ledger entry for item %2', ShipmentNo, ItemNo));
    end;

    local procedure FindReturnEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        FilterReturnEntries(ItemLedgerEntry, ItemNo);
        Assert.IsTrue(ItemLedgerEntry.FindFirst(),
            StrSubstNo('Expected the return to have created an inbound Sale item ledger entry for item %1 — nothing came back into inventory', ItemNo));
    end;

    local procedure FilterReturnEntries(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetFilter(Quantity, '>0');
    end;
}
