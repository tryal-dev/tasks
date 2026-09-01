codeunit 50900 "Landed Cost Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Standard posting commits on its own; CommitBehavior::Ignore on every test
    // silences those commits so the run stays rollback-safe and can grade in the
    // shared warm company.

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ByQuantitySplitsTheChargeThreeToSeven()
    var
        LandedCostMgt: Codeunit "Landed Cost Mgt.";
        ReceiptNos: List of [Code[20]];
        VendorNo: Code[20];
        ItemNo: Code[20];
        ChargeNo: Code[20];
        Receipt1: Code[20];
        Receipt2: Code[20];
        Cost1: Decimal;
        Cost2: Decimal;
    begin
        // [SCENARIO] A 100.00 charge assigned By Quantity over receipts of 3 and 7 pieces lands 30.00 and 70.00
        // [GIVEN] two fully posted purchase receipts of 3 and 7 pieces at generated direct unit costs
        Cost1 := LibraryRandom.RandDecInRange(10, 50, 2);
        Cost2 := LibraryRandom.RandDecInRange(10, 50, 2);
        SetupTwoReceipts(VendorNo, ItemNo, ChargeNo, Receipt1, Receipt2, Cost1, Cost2);
        ReceiptNos.Add(Receipt1);
        ReceiptNos.Add(Receipt2);

        // [WHEN] assigning and posting a 100.00 item charge by quantity
        LandedCostMgt.AssignAndPostCharge(VendorNo, ChargeNo, 100.0, ReceiptNos, "Landed Cost Method"::"By Quantity");

        // [THEN] each receipt's item ledger entry carries its direct cost plus its quantity-weighted share
        Assert.AreEqual(3 * Cost1 + 30.0, ReceiptActualCost(ItemNo, Receipt1),
            'Expected the 3-piece receipt''s "Cost Amount (Actual)" to gain 3/10 of the 100.00 charge (30.00) on top of its direct cost');
        Assert.AreEqual(7 * Cost2 + 70.0, ReceiptActualCost(ItemNo, Receipt2),
            'Expected the 7-piece receipt''s "Cost Amount (Actual)" to gain 7/10 of the 100.00 charge (70.00) on top of its direct cost');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ByAmountSplitsTheChargeByLineAmounts()
    var
        LandedCostMgt: Codeunit "Landed Cost Mgt.";
        ReceiptNos: List of [Code[20]];
        VendorNo: Code[20];
        ItemNo: Code[20];
        ChargeNo: Code[20];
        Receipt1: Code[20];
        Receipt2: Code[20];
    begin
        // [SCENARIO] A 100.00 charge assigned By Amount over line amounts 180.00 and 140.00 lands 56.25 and 43.75
        // [GIVEN] receipts of 3 pieces at 60.00 (amount 180.00) and 7 pieces at 20.00 (amount 140.00)
        SetupTwoReceipts(VendorNo, ItemNo, ChargeNo, Receipt1, Receipt2, 60.0, 20.0);
        ReceiptNos.Add(Receipt1);
        ReceiptNos.Add(Receipt2);

        // [WHEN] assigning and posting a 100.00 item charge by amount
        LandedCostMgt.AssignAndPostCharge(VendorNo, ChargeNo, 100.0, ReceiptNos, "Landed Cost Method"::"By Amount");

        // [THEN] the charge splits 56.25 / 43.75 — proportional to line amounts, not to quantities (30/70) and not equally (50/50)
        Assert.AreEqual(180.0 + 56.25, ReceiptActualCost(ItemNo, Receipt1),
            'Expected the receipt with line amount 180.00 to gain 180/320 of the 100.00 charge (56.25), weighted by amount — not by quantity and not an equal split');
        Assert.AreEqual(140.0 + 43.75, ReceiptActualCost(ItemNo, Receipt2),
            'Expected the receipt with line amount 140.00 to gain 140/320 of the 100.00 charge (43.75), weighted by amount — not by quantity and not an equal split');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure RoundingRemainderLandsOnTheLastReceipt()
    var
        LandedCostMgt: Codeunit "Landed Cost Mgt.";
        ReceiptNos: List of [Code[20]];
        VendorNo: Code[20];
        ItemNo: Code[20];
        ChargeNo: Code[20];
        Receipt1: Code[20];
        Receipt2: Code[20];
    begin
        // [SCENARIO] A 10.05 charge By Quantity rounds the first share to 3.02 and leaves the last line 7.03, never 7.04
        // [GIVEN] receipts of 3 and 7 pieces at a direct unit cost of 10.00 each
        SetupTwoReceipts(VendorNo, ItemNo, ChargeNo, Receipt1, Receipt2, 10.0, 10.0);
        ReceiptNos.Add(Receipt1);
        ReceiptNos.Add(Receipt2);

        // [WHEN] assigning and posting a 10.05 item charge by quantity
        LandedCostMgt.AssignAndPostCharge(VendorNo, ChargeNo, 10.05, ReceiptNos, "Landed Cost Method"::"By Quantity");

        // [THEN] first share is Round(3.015) = 3.02 and the last line takes 10.05 - 3.02 = 7.03, so the shares total the charge exactly
        Assert.AreEqual(30.0 + 3.02, ReceiptActualCost(ItemNo, Receipt1),
            'Expected the first receipt''s share of the 10.05 charge to be Round(10.05 * 3/10) = 3.02');
        Assert.AreEqual(70.0 + 7.03, ReceiptActualCost(ItemNo, Receipt2),
            'Expected the last receipt to take the remainder 10.05 - 3.02 = 7.03 — rounding its share independently gives 7.04 and inflates the total');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ByQuantitySplitsByGeneratedQuantities()
    var
        LandedCostMgt: Codeunit "Landed Cost Mgt.";
        ReceiptNos: List of [Code[20]];
        VendorNo: Code[20];
        ItemNo: Code[20];
        ChargeNo: Code[20];
        Receipt1: Code[20];
        Receipt2: Code[20];
        Qty1: Integer;
        Qty2: Integer;
        Cost1: Decimal;
        Cost2: Decimal;
        Share1: Decimal;
    begin
        // [SCENARIO] By Quantity follows whatever quantities the receipts actually carry, not a memorized 30/70 split
        // [GIVEN] two receipts at generated quantities and costs
        Qty1 := LibraryRandom.RandIntInRange(2, 5);
        Qty2 := LibraryRandom.RandIntInRange(6, 9);
        // The other tests use the 3-and-7 pair; excluding it here means a solution
        // that hardcodes their 30/70 split can never luck through this test.
        if (Qty1 = 3) and (Qty2 = 7) then
            Qty1 := 4;
        Cost1 := LibraryRandom.RandDecInRange(10, 50, 2);
        Cost2 := LibraryRandom.RandDecInRange(10, 50, 2);
        SetupTwoReceiptsQty(VendorNo, ItemNo, ChargeNo, Receipt1, Receipt2, Qty1, Qty2, Cost1, Cost2);
        ReceiptNos.Add(Receipt1);
        ReceiptNos.Add(Receipt2);

        // [WHEN] assigning and posting a 100.00 item charge by quantity
        LandedCostMgt.AssignAndPostCharge(VendorNo, ChargeNo, 100.0, ReceiptNos, "Landed Cost Method"::"By Quantity");

        // [THEN] the first receipt gains Round(100 * qty / total, 0.01) and the last takes the remainder, as rule 4 dictates
        Share1 := Round(100.0 * Qty1 / (Qty1 + Qty2), 0.01);
        Assert.AreEqual(Qty1 * Cost1 + Share1, ReceiptActualCost(ItemNo, Receipt1),
            StrSubstNo('Expected the %1-piece receipt''s "Cost Amount (Actual)" to gain Round(100.00 * %1/%2, 0.01) of the charge on top of its direct cost', Qty1, Qty1 + Qty2));
        Assert.AreEqual(Qty2 * Cost2 + (100.0 - Share1), ReceiptActualCost(ItemNo, Receipt2),
            StrSubstNo('Expected the %1-piece receipt, last in processing order, to take the remainder of the 100.00 charge after the first receipt''s rounded share', Qty2));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ByAmountSplitsByGeneratedLineAmounts()
    var
        LandedCostMgt: Codeunit "Landed Cost Mgt.";
        ReceiptNos: List of [Code[20]];
        VendorNo: Code[20];
        ItemNo: Code[20];
        ChargeNo: Code[20];
        Receipt1: Code[20];
        Receipt2: Code[20];
        Cost1: Decimal;
        Cost2: Decimal;
        Amount1: Decimal;
        Amount2: Decimal;
        Share1: Decimal;
    begin
        // [SCENARIO] By Amount weights come from the receipts' generated line amounts, so constant share fractions fail
        // [GIVEN] receipts of 3 and 7 pieces at generated direct unit costs, so the amount weights are generated too
        Cost1 := LibraryRandom.RandDecInRange(10, 50, 2);
        Cost2 := LibraryRandom.RandDecInRange(10, 50, 2);
        SetupTwoReceipts(VendorNo, ItemNo, ChargeNo, Receipt1, Receipt2, Cost1, Cost2);
        ReceiptNos.Add(Receipt1);
        ReceiptNos.Add(Receipt2);

        // [WHEN] assigning and posting a 100.00 item charge by amount
        LandedCostMgt.AssignAndPostCharge(VendorNo, ChargeNo, 100.0, ReceiptNos, "Landed Cost Method"::"By Amount");

        // [THEN] the first receipt gains Round(100 * amount / total amount, 0.01) and the last takes the remainder
        Amount1 := 3 * Cost1;
        Amount2 := 7 * Cost2;
        Share1 := Round(100.0 * Amount1 / (Amount1 + Amount2), 0.01);
        Assert.AreEqual(Amount1 + Share1, ReceiptActualCost(ItemNo, Receipt1),
            StrSubstNo('Expected the receipt with line amount %1 to gain Round(100.00 * %1/%2, 0.01) of the charge, weighted by amount — not by quantity and not an equal split', Amount1, Amount1 + Amount2));
        Assert.AreEqual(Amount2 + (100.0 - Share1), ReceiptActualCost(ItemNo, Receipt2),
            StrSubstNo('Expected the receipt with line amount %1, last in processing order, to take the remainder of the 100.00 charge after the first receipt''s rounded share', Amount2));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure SpreadsWithinAReceiptInAscendingLineOrder()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        LandedCostMgt: Codeunit "Landed Cost Mgt.";
        ReceiptNos: List of [Code[20]];
        VendorNo: Code[20];
        ItemNo: Code[20];
        ChargeNo: Code[20];
        ReceiptNo: Code[20];
    begin
        // [SCENARIO] Within one receipt every item line gets its share, processed in ascending line number so the remainder lands on the last line
        // [GIVEN] a single posted receipt whose two item lines hold 3 and 7 pieces at 10.00 each
        SetupMasterData(VendorNo, ItemNo, ChargeNo);
        ReceiptNo := PostTwoLineReceipt(VendorNo, ItemNo, 3, 7, 10.0);
        ReceiptNos.Add(ReceiptNo);

        // [WHEN] assigning and posting a 10.05 item charge by quantity
        LandedCostMgt.AssignAndPostCharge(VendorNo, ChargeNo, 10.05, ReceiptNos, "Landed Cost Method"::"By Quantity");

        // [THEN] the line with the lowest line no. carries Round(10.05 * 3/10) = 3.02 and the last line the remainder 7.03 — descending order would put 3.01 and 7.04
        PurchRcptLine.SetRange("Document No.", ReceiptNo);
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.FindFirst();
        FindReceiptLineEntry(ItemLedgerEntry, ItemNo, ReceiptNo, PurchRcptLine."Line No.");
        VerifyChargeValueEntry(ItemLedgerEntry."Entry No.", ChargeNo, 3.02,
            StrSubstNo('the first (3-piece) item line of receipt %1', ReceiptNo));
        PurchRcptLine.FindLast();
        FindReceiptLineEntry(ItemLedgerEntry, ItemNo, ReceiptNo, PurchRcptLine."Line No.");
        VerifyChargeValueEntry(ItemLedgerEntry."Entry No.", ChargeNo, 7.03,
            StrSubstNo('the last (7-piece) item line of receipt %1', ReceiptNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ChargePostingCreatesNoNewItemLedgerEntries()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        LandedCostMgt: Codeunit "Landed Cost Mgt.";
        ReceiptNos: List of [Code[20]];
        VendorNo: Code[20];
        ItemNo: Code[20];
        ChargeNo: Code[20];
        Receipt1: Code[20];
        Receipt2: Code[20];
    begin
        // [SCENARIO] An item charge only revalues the receipts' original entries — it never adds inventory
        // [GIVEN] two fully posted receipts of 3 and 7 pieces
        SetupTwoReceipts(VendorNo, ItemNo, ChargeNo, Receipt1, Receipt2, 10.0, 10.0);
        ReceiptNos.Add(Receipt1);
        ReceiptNos.Add(Receipt2);

        // [WHEN] assigning and posting a 100.00 item charge by quantity
        LandedCostMgt.AssignAndPostCharge(VendorNo, ChargeNo, 100.0, ReceiptNos, "Landed Cost Method"::"By Quantity");

        // [THEN] the item still owns exactly its two original entries with quantities 3 and 7
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        Assert.AreEqual(2, ItemLedgerEntry.Count(),
            'Expected the item to still own exactly the 2 item ledger entries its receipts created — posting an item charge must not create new entries or extra receipts');
        FindReceiptEntry(ItemLedgerEntry, ItemNo, Receipt1);
        Assert.AreEqual(3, ItemLedgerEntry.Quantity,
            'Expected the 3-piece receipt''s original item ledger entry to keep its quantity of 3 after the charge was posted');
        FindReceiptEntry(ItemLedgerEntry, ItemNo, Receipt2);
        Assert.AreEqual(7, ItemLedgerEntry.Quantity,
            'Expected the 7-piece receipt''s original item ledger entry to keep its quantity of 7 after the charge was posted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ReturnsThePostedPurchaseInvoiceHoldingTheCharge()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        LandedCostMgt: Codeunit "Landed Cost Mgt.";
        ReceiptNos: List of [Code[20]];
        VendorNo: Code[20];
        ItemNo: Code[20];
        ChargeNo: Code[20];
        Receipt1: Code[20];
        Receipt2: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO] The returned number identifies a posted purchase invoice for the vendor with the charge line on it
        // [GIVEN] two fully posted receipts
        SetupTwoReceipts(VendorNo, ItemNo, ChargeNo, Receipt1, Receipt2, 10.0, 10.0);
        ReceiptNos.Add(Receipt1);
        ReceiptNos.Add(Receipt2);

        // [WHEN] assigning and posting a 100.00 item charge by quantity
        PostedInvoiceNo := LandedCostMgt.AssignAndPostCharge(VendorNo, ChargeNo, 100.0, ReceiptNos, "Landed Cost Method"::"By Quantity");

        // [THEN] the returned no. is a posted purchase invoice for the vendor carrying the 100.00 charge line
        Assert.IsTrue(PurchInvHeader.Get(PostedInvoiceNo),
            StrSubstNo('Expected AssignAndPostCharge to return the number of a posted purchase invoice, but no "Purch. Inv. Header" exists with the returned value "%1"', PostedInvoiceNo));
        Assert.AreEqual(VendorNo, PurchInvHeader."Buy-from Vendor No.",
            'Expected the posted charge invoice to be bought from the vendor passed to AssignAndPostCharge');
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.SetRange(Type, PurchInvLine.Type::"Charge (Item)");
        PurchInvLine.SetRange("No.", ChargeNo);
        Assert.IsTrue(PurchInvLine.FindFirst(),
            StrSubstNo('Expected the posted invoice %1 to hold a Charge (Item) line for item charge %2', PostedInvoiceNo, ChargeNo));
        Assert.AreEqual(100.0, PurchInvLine.Amount,
            'Expected the posted charge line''s Amount to be the full charge amount of 100.00 (quantity 1 at direct unit cost 100.00)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure ChargeLandsAsValueEntriesOnTheOriginalEntries()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        LandedCostMgt: Codeunit "Landed Cost Mgt.";
        ReceiptNos: List of [Code[20]];
        VendorNo: Code[20];
        ItemNo: Code[20];
        ChargeNo: Code[20];
        Receipt1: Code[20];
        Receipt2: Code[20];
    begin
        // [SCENARIO] Each receipt's original entry gains a value entry carrying the item charge no. and the exact share
        // [GIVEN] two fully posted receipts of 3 and 7 pieces
        SetupTwoReceipts(VendorNo, ItemNo, ChargeNo, Receipt1, Receipt2, 10.0, 10.0);
        ReceiptNos.Add(Receipt1);
        ReceiptNos.Add(Receipt2);

        // [WHEN] assigning and posting a 100.00 item charge by quantity
        LandedCostMgt.AssignAndPostCharge(VendorNo, ChargeNo, 100.0, ReceiptNos, "Landed Cost Method"::"By Quantity");

        // [THEN] a value entry tagged with the item charge no. sits on each original item ledger entry with the exact share
        FindReceiptEntry(ItemLedgerEntry, ItemNo, Receipt1);
        VerifyChargeValueEntry(ItemLedgerEntry."Entry No.", ChargeNo, 30.0, StrSubstNo('receipt %1', Receipt1));
        FindReceiptEntry(ItemLedgerEntry, ItemNo, Receipt2);
        VerifyChargeValueEntry(ItemLedgerEntry."Entry No.", ChargeNo, 70.0, StrSubstNo('receipt %1', Receipt2));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure GetReceiptCostReportsDirectCostBeforeAnyCharge()
    var
        LandedCostMgt: Codeunit "Landed Cost Mgt.";
        VendorNo: Code[20];
        ItemNo: Code[20];
        ChargeNo: Code[20];
        Receipt1: Code[20];
        Receipt2: Code[20];
        Cost1: Decimal;
        Cost2: Decimal;
    begin
        // [SCENARIO] Before any charge, a receipt's landed cost is just its invoiced direct cost
        // [GIVEN] two fully posted receipts at generated direct unit costs and no charge
        Cost1 := LibraryRandom.RandDecInRange(10, 50, 2);
        Cost2 := LibraryRandom.RandDecInRange(10, 50, 2);
        SetupTwoReceipts(VendorNo, ItemNo, ChargeNo, Receipt1, Receipt2, Cost1, Cost2);

        // [WHEN] asking for each receipt's cost
        // [THEN] the result is quantity times the generated direct unit cost — hardcoded answers cannot match
        Assert.AreEqual(3 * Cost1, LandedCostMgt.GetReceiptCost(Receipt1),
            'Expected GetReceiptCost to report the 3-piece receipt''s invoiced direct cost while no charge has been assigned');
        Assert.AreEqual(7 * Cost2, LandedCostMgt.GetReceiptCost(Receipt2),
            'Expected GetReceiptCost to report the 7-piece receipt''s invoiced direct cost while no charge has been assigned');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure GetReceiptCostReportsLandedCostAfterTheCharge()
    var
        LandedCostMgt: Codeunit "Landed Cost Mgt.";
        ReceiptNos: List of [Code[20]];
        VendorNo: Code[20];
        ItemNo: Code[20];
        ChargeNo: Code[20];
        Receipt1: Code[20];
        Receipt2: Code[20];
        Cost1: Decimal;
        Cost2: Decimal;
    begin
        // [SCENARIO] After the charge is posted, GetReceiptCost reports direct cost plus the receipt's share
        // [GIVEN] two receipts at generated costs with a 100.00 charge posted by quantity
        Cost1 := LibraryRandom.RandDecInRange(10, 50, 2);
        Cost2 := LibraryRandom.RandDecInRange(10, 50, 2);
        SetupTwoReceipts(VendorNo, ItemNo, ChargeNo, Receipt1, Receipt2, Cost1, Cost2);
        ReceiptNos.Add(Receipt1);
        ReceiptNos.Add(Receipt2);
        LandedCostMgt.AssignAndPostCharge(VendorNo, ChargeNo, 100.0, ReceiptNos, "Landed Cost Method"::"By Quantity");

        // [WHEN] asking for each receipt's cost
        // [THEN] the report is the landed cost: direct cost plus the quantity-weighted share of the charge
        Assert.AreEqual(3 * Cost1 + 30.0, LandedCostMgt.GetReceiptCost(Receipt1),
            'Expected GetReceiptCost to report the 3-piece receipt''s direct cost plus its 30.00 share of the charge');
        Assert.AreEqual(7 * Cost2 + 70.0, LandedCostMgt.GetReceiptCost(Receipt2),
            'Expected GetReceiptCost to report the 7-piece receipt''s direct cost plus its 70.00 share of the charge');
    end;

    local procedure SetupTwoReceipts(var VendorNo: Code[20]; var ItemNo: Code[20]; var ChargeNo: Code[20]; var Receipt1: Code[20]; var Receipt2: Code[20]; Cost1: Decimal; Cost2: Decimal)
    begin
        SetupTwoReceiptsQty(VendorNo, ItemNo, ChargeNo, Receipt1, Receipt2, 3, 7, Cost1, Cost2);
    end;

    local procedure SetupTwoReceiptsQty(var VendorNo: Code[20]; var ItemNo: Code[20]; var ChargeNo: Code[20]; var Receipt1: Code[20]; var Receipt2: Code[20]; Qty1: Decimal; Qty2: Decimal; Cost1: Decimal; Cost2: Decimal)
    begin
        SetupMasterData(VendorNo, ItemNo, ChargeNo);
        Receipt1 := PostReceipt(VendorNo, ItemNo, Qty1, Cost1);
        Receipt2 := PostReceipt(VendorNo, ItemNo, Qty2, Cost2);
    end;

    local procedure SetupMasterData(var VendorNo: Code[20]; var ItemNo: Code[20]; var ChargeNo: Code[20])
    var
        Vendor: Record Vendor;
        Item: Record Item;
        ItemCharge: Record "Item Charge";
    begin
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemCharge(ItemCharge);
        VendorNo := Vendor."No.";
        ItemNo := Item."No.";
        ChargeNo := ItemCharge."No.";
    end;

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        if PurchasesPayablesSetup."Ext. Doc. No. Mandatory" then begin
            PurchasesPayablesSetup."Ext. Doc. No. Mandatory" := false;
            PurchasesPayablesSetup.Modify();
        end;
    end;

    local procedure PostReceipt(VendorNo: Code[20]; ItemNo: Code[20]; Qty: Decimal; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Order, VendorNo, ItemNo, Qty, '', 0D);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.FindFirst();
        exit(PurchRcptHeader."No.");
    end;

    local procedure PostTwoLineReceipt(VendorNo: Code[20]; ItemNo: Code[20]; Qty1: Decimal; Qty2: Decimal; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SecondLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, "Purchase Document Type"::Order, VendorNo, ItemNo, Qty1, '', 0D);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(SecondLine, PurchaseHeader, SecondLine.Type::Item, ItemNo, Qty2);
        SecondLine.Validate("Direct Unit Cost", DirectUnitCost);
        SecondLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.FindFirst();
        exit(PurchRcptHeader."No.");
    end;

    local procedure ReceiptActualCost(ItemNo: Code[20]; ReceiptNo: Code[20]): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindReceiptEntry(ItemLedgerEntry, ItemNo, ReceiptNo);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        exit(ItemLedgerEntry."Cost Amount (Actual)");
    end;

    local procedure FindReceiptEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; ReceiptNo: Code[20])
    begin
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document No.", ReceiptNo);
        Assert.IsTrue(ItemLedgerEntry.FindFirst(),
            StrSubstNo('Expected posted purchase receipt %1 to own an item ledger entry — the charge must attach to the entry the receipt created, not replace it', ReceiptNo));
    end;

    local procedure FindReceiptLineEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; ReceiptNo: Code[20]; LineNo: Integer)
    begin
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document No.", ReceiptNo);
        ItemLedgerEntry.SetRange("Document Line No.", LineNo);
        Assert.IsTrue(ItemLedgerEntry.FindFirst(),
            StrSubstNo('Expected receipt %1 line %2 to own its own item ledger entry — every item line of a receipt keeps the entry it created', ReceiptNo, LineNo));
    end;

    local procedure VerifyChargeValueEntry(ItemLedgerEntryNo: Integer; ChargeNo: Code[20]; ExpectedShare: Decimal; EntryDescription: Text)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        ValueEntry.SetRange("Item Charge No.", ChargeNo);
        Assert.IsTrue(ValueEntry.FindFirst(),
            StrSubstNo('Expected %1''s item ledger entry to gain a value entry tagged with item charge %2 — that is how an item charge must reach the entry', EntryDescription, ChargeNo));
        ValueEntry.CalcSums("Cost Amount (Actual)");
        Assert.AreEqual(ExpectedShare, ValueEntry."Cost Amount (Actual)",
            StrSubstNo('Expected the item charge value entries on %1''s item ledger entry to total exactly its share of the charge', EntryDescription));
    end;
}
