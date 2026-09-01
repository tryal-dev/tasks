codeunit 50900 "Undo Receipt Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Standard posting commits on its own; CommitBehavior::Ignore on every test
    // silences those commits so the run stays rollback-safe and can grade in the
    // shared warm company.

    // [FEATURE] [Purchase] [Undo Receipt]

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure UndoWritesACorrectionReceiptLineWithNegativeQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReceiptCorrection: Codeunit "Receipt Correction";
        ItemNo: Code[20];
        ReceiptNo: Code[20];
        LineNo: Integer;
        Qty: Decimal;
    begin
        // [SCENARIO] Undoing a receipt line leaves a corrective receipt line carrying the negative quantity
        // [GIVEN] a purchase order posted as received but not invoiced
        Qty := LibraryRandom.RandIntInRange(3, 20);
        ReceiptNo := SetupReceivedOrder(PurchaseHeader, ItemNo, Qty, false);
        LineNo := FirstReceiptLineNo(ReceiptNo);

        // [WHEN] undoing that receipt line
        ReceiptCorrection.UndoReceiptLine(ReceiptNo, LineNo);

        // [THEN] the posted receipt carries a second line, flagged Correction, for minus the received quantity
        PurchRcptLine.SetRange("Document No.", ReceiptNo);
        PurchRcptLine.SetFilter("Line No.", '<>%1', LineNo);
        Assert.IsTrue(PurchRcptLine.FindFirst(),
            StrSubstNo('Expected the undo to add a corrective line to posted receipt %1 — the receipt must keep its history and gain the reversal, not be rewritten', ReceiptNo));
        Assert.AreEqual(-Qty, PurchRcptLine.Quantity,
            'Expected the corrective receipt line to carry exactly minus the received quantity');
        Assert.AreEqual(true, PurchRcptLine.Correction,
            'Expected the corrective receipt line to be flagged as a Correction line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure UndoFlagsTheOriginalReceiptLineAsCorrection()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReceiptCorrection: Codeunit "Receipt Correction";
        ItemNo: Code[20];
        ReceiptNo: Code[20];
        LineNo: Integer;
        Qty: Decimal;
    begin
        // [SCENARIO] The reversed receipt line itself is marked as corrected, so it can never be undone twice
        // [GIVEN] a purchase order posted as received but not invoiced
        Qty := LibraryRandom.RandIntInRange(3, 20);
        ReceiptNo := SetupReceivedOrder(PurchaseHeader, ItemNo, Qty, false);
        LineNo := FirstReceiptLineNo(ReceiptNo);

        // [WHEN] undoing that receipt line
        ReceiptCorrection.UndoReceiptLine(ReceiptNo, LineNo);

        // [THEN] the original line still exists, still carries its positive quantity, and is now flagged Correction
        PurchRcptLine.Get(ReceiptNo, LineNo);
        Assert.AreEqual(Qty, PurchRcptLine.Quantity,
            'Expected the original receipt line to keep its received quantity — a reversal corrects, it does not erase');
        Assert.AreEqual(true, PurchRcptLine.Correction,
            'Expected the reversed receipt line itself to be flagged as corrected');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure UndoLeavesTheItemLedgerQuantityAtZero()
    var
        PurchaseHeader: Record "Purchase Header";
        ReceiptCorrection: Codeunit "Receipt Correction";
        ItemNo: Code[20];
        ReceiptNo: Code[20];
        LineNo: Integer;
        Qty: Decimal;
    begin
        // [SCENARIO] After the undo the item owns no quantity at all
        // [GIVEN] a purchase order posted as received but not invoiced
        Qty := LibraryRandom.RandIntInRange(3, 20);
        ReceiptNo := SetupReceivedOrder(PurchaseHeader, ItemNo, Qty, false);
        LineNo := FirstReceiptLineNo(ReceiptNo);

        // [WHEN] undoing that receipt line
        ReceiptCorrection.UndoReceiptLine(ReceiptNo, LineNo);

        // [THEN] the item's item ledger entries sum to exactly zero
        Assert.AreEqual(0.0, ItemLedgerQuantity(ItemNo),
            StrSubstNo('Expected the item ledger quantity of the received item to be back to 0 after undoing the receipt of %1', Qty));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure UndoReversesTheItemLedgerEntryInsteadOfDeletingIt()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReceiptCorrection: Codeunit "Receipt Correction";
        ItemNo: Code[20];
        ReceiptNo: Code[20];
        LineNo: Integer;
        Qty: Decimal;
    begin
        // [SCENARIO] The reversal is posted as a second, negative, correcting purchase entry — history is never removed
        // [GIVEN] a purchase order posted as received but not invoiced
        Qty := LibraryRandom.RandIntInRange(3, 20);
        ReceiptNo := SetupReceivedOrder(PurchaseHeader, ItemNo, Qty, false);
        LineNo := FirstReceiptLineNo(ReceiptNo);

        // [WHEN] undoing that receipt line
        ReceiptCorrection.UndoReceiptLine(ReceiptNo, LineNo);

        // [THEN] the item owns exactly two entries: the original receipt and its reversal
        Assert.AreEqual(2, ItemLedgerEntryCount(ItemNo),
            'Expected the item to own exactly two item ledger entries after the undo — the original receipt plus a reversing entry, never a deleted one');
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Purchase Receipt");
        ItemLedgerEntry.SetRange("Document No.", ReceiptNo);
        ItemLedgerEntry.SetRange(Correction, true);
        ItemLedgerEntry.SetRange(Quantity, -Qty);
        Assert.IsTrue(ItemLedgerEntry.FindFirst(),
            StrSubstNo('Expected the reversal to be posted as a correcting purchase entry of %1 against receipt %2 — an item journal adjustment reaches the same on-hand quantity but is not a reversal', -Qty, ReceiptNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure UndoResetsQuantityReceivedOnTheOrderLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptCorrection: Codeunit "Receipt Correction";
        ItemNo: Code[20];
        ReceiptNo: Code[20];
        LineNo: Integer;
        Qty: Decimal;
    begin
        // [SCENARIO] The originating purchase order line is fully outstanding again after the undo
        // [GIVEN] a purchase order posted as received but not invoiced
        Qty := LibraryRandom.RandIntInRange(3, 20);
        ReceiptNo := SetupReceivedOrder(PurchaseHeader, ItemNo, Qty, false);
        LineNo := FirstReceiptLineNo(ReceiptNo);

        // [WHEN] undoing that receipt line
        ReceiptCorrection.UndoReceiptLine(ReceiptNo, LineNo);

        // [THEN] the order line reads as never received
        GetOrderLine(PurchaseLine, ReceiptNo, LineNo);
        Assert.AreEqual(0.0, PurchaseLine."Quantity Received",
            'Expected "Quantity Received" on the purchase order line to be back to 0 — a hand-rolled reversal leaves the order thinking the goods arrived');
        Assert.AreEqual(0.0, PurchaseLine."Qty. Rcd. Not Invoiced",
            'Expected "Qty. Rcd. Not Invoiced" on the purchase order line to be back to 0');
        Assert.AreEqual(Qty, PurchaseLine."Outstanding Quantity",
            'Expected the whole ordered quantity to be outstanding again on the purchase order line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure UndoReturnsTheReversedQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        ReceiptCorrection: Codeunit "Receipt Correction";
        ItemNo: Code[20];
        ReceiptNo: Code[20];
        LineNo: Integer;
        Qty: Decimal;
    begin
        // [SCENARIO] The service reports how much it took back
        // [GIVEN] a purchase order posted as received but not invoiced, at a quantity generated at run time
        Qty := LibraryRandom.RandIntInRange(3, 20);
        ReceiptNo := SetupReceivedOrder(PurchaseHeader, ItemNo, Qty, false);
        LineNo := FirstReceiptLineNo(ReceiptNo);

        // [WHEN] undoing that receipt line
        // [THEN] the received quantity is returned, positive
        Assert.AreEqual(Qty, ReceiptCorrection.UndoReceiptLine(ReceiptNo, LineNo),
            'Expected UndoReceiptLine to return the quantity it reversed — the receipt line''s own positive Quantity');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure OrderCanBeReceivedAgainAfterTheUndo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReceiptCorrection: Codeunit "Receipt Correction";
        ItemNo: Code[20];
        ReceiptNo: Code[20];
        OrderNo: Code[20];
        LineNo: Integer;
        Qty: Decimal;
    begin
        // [SCENARIO] Undoing a receipt makes the purchase order receivable again
        // [GIVEN] a purchase order received, then undone
        Qty := LibraryRandom.RandIntInRange(3, 20);
        ReceiptNo := SetupReceivedOrder(PurchaseHeader, ItemNo, Qty, false);
        OrderNo := PurchaseHeader."No.";
        LineNo := FirstReceiptLineNo(ReceiptNo);
        ReceiptCorrection.UndoReceiptLine(ReceiptNo, LineNo);

        // [WHEN] posting the receipt of the same order a second time
        GetOrderLine(PurchaseLine, ReceiptNo, LineNo);
        PurchaseLine.Validate("Qty. to Receive", Qty);
        PurchaseLine.Modify(true);
        PurchaseHeader.Get("Purchase Document Type"::Order, OrderNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] a new posted receipt carries the full quantity and the item is on hand again
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.SetFilter("No.", '<>%1', ReceiptNo);
        Assert.IsTrue(PurchRcptHeader.FindFirst(),
            StrSubstNo('Expected purchase order %1 to be receivable again after the undo, producing a second posted receipt', OrderNo));
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.FindFirst();
        Assert.AreEqual(Qty, PurchRcptLine.Quantity,
            'Expected the second posted receipt to carry the full ordered quantity — the undo must have released it for receiving again');
        Assert.AreEqual(Qty, ItemLedgerQuantity(ItemNo),
            'Expected the item ledger quantity to equal the ordered quantity once the order has been received again');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure UndoTouchesOnlyTheNamedReceiptLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseLine: Record "Purchase Line";
        ReceiptCorrection: Codeunit "Receipt Correction";
        ReceiptNo: Code[20];
        LineNo1: Integer;
        LineNo2: Integer;
        Qty1: Decimal;
        Qty2: Decimal;
    begin
        // [SCENARIO] Undoing one line of a two-line receipt leaves the other line posted
        // [GIVEN] a purchase order with two item lines, posted as received
        Qty1 := LibraryRandom.RandIntInRange(3, 20);
        Qty2 := LibraryRandom.RandIntInRange(21, 40);
        ReceiptNo := SetupTwoLineReceivedOrder(PurchaseHeader, Qty1, Qty2);
        ReceiptLineNos(ReceiptNo, LineNo1, LineNo2);

        // [WHEN] undoing only the first receipt line
        ReceiptCorrection.UndoReceiptLine(ReceiptNo, LineNo1);

        // [THEN] the second line is untouched and its order line still counts as received
        PurchRcptLine.Get(ReceiptNo, LineNo2);
        Assert.AreEqual(false, PurchRcptLine.Correction,
            'Expected the second line of the receipt to stay untouched — the reversal must be scoped to the line it was asked about');
        GetOrderLine(PurchaseLine, ReceiptNo, LineNo2);
        Assert.AreEqual(Qty2, PurchaseLine."Quantity Received",
            'Expected the second order line to keep its received quantity — only the named receipt line may be reversed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure UndoRefusesAnAlreadyInvoicedLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReceiptCorrection: Codeunit "Receipt Correction";
        ItemNo: Code[20];
        ReceiptNo: Code[20];
        LineNo: Integer;
        Qty: Decimal;
    begin
        // [SCENARIO] A receipt line that has been invoiced can no longer be undone
        // [GIVEN] a purchase order posted as received and invoiced
        Qty := LibraryRandom.RandIntInRange(3, 20);
        ReceiptNo := SetupReceivedOrder(PurchaseHeader, ItemNo, Qty, true);
        LineNo := FirstReceiptLineNo(ReceiptNo);

        // [WHEN] undoing that receipt line
        if TryUndoReceiptLine(ReceiptNo, LineNo) then
            Assert.Fail(StrSubstNo('Expected the undo of receipt line %1 of %2 to be refused, but it went through', LineNo, ReceiptNo));

        // [THEN] the service refuses with its own message and changes nothing
        Assert.ExpectedError(StrSubstNo('Receipt line %1 of %2 is already invoiced and cannot be undone.', LineNo, ReceiptNo));
        PurchRcptLine.Get(ReceiptNo, LineNo);
        Assert.AreEqual(false, PurchRcptLine.Correction,
            'Expected a refused undo to leave the invoiced receipt line exactly as it was');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure UndoRefusesAPartlyInvoicedLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReceiptCorrection: Codeunit "Receipt Correction";
        ItemNo: Code[20];
        ReceiptNo: Code[20];
        LineNo: Integer;
        QtyReceived: Integer;
        QtyInvoiced: Integer;
    begin
        // [SCENARIO] A receipt line that has been invoiced in part is refused too — its "Qty. Rcd. Not Invoiced" differs from its Quantity without being 0
        // [GIVEN] a purchase order received in full and then invoiced for part of that quantity
        QtyReceived := LibraryRandom.RandIntInRange(4, 20);
        QtyInvoiced := LibraryRandom.RandIntInRange(1, QtyReceived - 1);
        ReceiptNo := SetupPartlyInvoicedOrder(PurchaseHeader, ItemNo, QtyReceived, QtyInvoiced);
        LineNo := FirstReceiptLineNo(ReceiptNo);

        // [WHEN] undoing that receipt line
        if TryUndoReceiptLine(ReceiptNo, LineNo) then
            Assert.Fail(StrSubstNo('Expected the undo of receipt line %1 of %2 to be refused, but it went through', LineNo, ReceiptNo));

        // [THEN] the service refuses with its own invoiced message and changes nothing
        Assert.ExpectedError(StrSubstNo('Receipt line %1 of %2 is already invoiced and cannot be undone.', LineNo, ReceiptNo));
        PurchRcptLine.Get(ReceiptNo, LineNo);
        Assert.AreEqual(false, PurchRcptLine.Correction,
            'Expected a refused undo to leave the partly invoiced receipt line exactly as it was');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure IsReversibleIsFalseForAPartlyInvoicedLine()
    var
        PurchaseHeader: Record "Purchase Header";
        ReceiptCorrection: Codeunit "Receipt Correction";
        ItemNo: Code[20];
        ReceiptNo: Code[20];
        LineNo: Integer;
        QtyReceived: Integer;
        QtyInvoiced: Integer;
    begin
        // [SCENARIO] A line invoiced in part reports itself as no longer reversible
        // [GIVEN] a purchase order received in full and then invoiced for part of that quantity
        QtyReceived := LibraryRandom.RandIntInRange(4, 20);
        QtyInvoiced := LibraryRandom.RandIntInRange(1, QtyReceived - 1);
        ReceiptNo := SetupPartlyInvoicedOrder(PurchaseHeader, ItemNo, QtyReceived, QtyInvoiced);
        LineNo := FirstReceiptLineNo(ReceiptNo);

        // [WHEN] asking whether the line is reversible
        // [THEN] the answer is false
        Assert.AreEqual(false, ReceiptCorrection.IsReversible(ReceiptNo, LineNo),
            StrSubstNo('Expected a receipt line of %1 invoiced for %2 to report itself as not reversible — its "Qty. Rcd. Not Invoiced" no longer matches its Quantity, even though it is not 0', QtyReceived, QtyInvoiced));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure UndoRefusesAnAlreadyReversedLine()
    var
        PurchaseHeader: Record "Purchase Header";
        ReceiptCorrection: Codeunit "Receipt Correction";
        ItemNo: Code[20];
        ReceiptNo: Code[20];
        LineNo: Integer;
        Qty: Decimal;
    begin
        // [SCENARIO] The same receipt line cannot be reversed twice
        // [GIVEN] a receipt line that has already been undone once
        Qty := LibraryRandom.RandIntInRange(3, 20);
        ReceiptNo := SetupReceivedOrder(PurchaseHeader, ItemNo, Qty, false);
        LineNo := FirstReceiptLineNo(ReceiptNo);
        ReceiptCorrection.UndoReceiptLine(ReceiptNo, LineNo);

        // [WHEN] undoing the same receipt line again
        if TryUndoReceiptLine(ReceiptNo, LineNo) then
            Assert.Fail(StrSubstNo('Expected the undo of receipt line %1 of %2 to be refused, but it went through', LineNo, ReceiptNo));

        // [THEN] the service refuses with the already-reversed message, not the invoiced one
        Assert.ExpectedError(StrSubstNo('Receipt line %1 of %2 is already reversed.', LineNo, ReceiptNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure UndoRefusesALineThatDoesNotExist()
    var
        ReceiptCorrection: Codeunit "Receipt Correction";
        ReceiptNo: Code[20];
        LineNo: Integer;
    begin
        // [SCENARIO] An unknown receipt line is reported, not silently ignored
        // [GIVEN] a receipt number that no posted receipt carries
        ReceiptNo := 'TRYAL-U11';
        LineNo := 10000;

        // [WHEN] undoing a line of that receipt
        if TryUndoReceiptLine(ReceiptNo, LineNo) then
            Assert.Fail(StrSubstNo('Expected the undo of receipt line %1 of %2 to be refused, but it went through', LineNo, ReceiptNo));

        // [THEN] the service refuses with the does-not-exist message
        Assert.ExpectedError(StrSubstNo('Receipt line %1 of %2 does not exist.', LineNo, ReceiptNo));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure IsReversibleIsTrueForAReceivedNotInvoicedLine()
    var
        PurchaseHeader: Record "Purchase Header";
        ReceiptCorrection: Codeunit "Receipt Correction";
        ItemNo: Code[20];
        ReceiptNo: Code[20];
        LineNo: Integer;
        Qty: Decimal;
    begin
        // [SCENARIO] A freshly received, uninvoiced line reports itself reversible
        // [GIVEN] a purchase order posted as received but not invoiced
        Qty := LibraryRandom.RandIntInRange(3, 20);
        ReceiptNo := SetupReceivedOrder(PurchaseHeader, ItemNo, Qty, false);
        LineNo := FirstReceiptLineNo(ReceiptNo);

        // [WHEN] asking whether the line is reversible
        // [THEN] the answer is true
        Assert.AreEqual(true, ReceiptCorrection.IsReversible(ReceiptNo, LineNo),
            'Expected a received but uninvoiced receipt line to report itself as reversible');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure IsReversibleIsFalseForAnInvoicedLine()
    var
        PurchaseHeader: Record "Purchase Header";
        ReceiptCorrection: Codeunit "Receipt Correction";
        ItemNo: Code[20];
        ReceiptNo: Code[20];
        LineNo: Integer;
        Qty: Decimal;
    begin
        // [SCENARIO] An invoiced line reports itself as no longer reversible
        // [GIVEN] a purchase order posted as received and invoiced
        Qty := LibraryRandom.RandIntInRange(3, 20);
        ReceiptNo := SetupReceivedOrder(PurchaseHeader, ItemNo, Qty, true);
        LineNo := FirstReceiptLineNo(ReceiptNo);

        // [WHEN] asking whether the line is reversible
        // [THEN] the answer is false
        Assert.AreEqual(false, ReceiptCorrection.IsReversible(ReceiptNo, LineNo),
            'Expected an invoiced receipt line to report itself as not reversible — its "Qty. Rcd. Not Invoiced" no longer matches its Quantity');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure IsReversibleIsFalseForAnAlreadyReversedLine()
    var
        PurchaseHeader: Record "Purchase Header";
        ReceiptCorrection: Codeunit "Receipt Correction";
        ItemNo: Code[20];
        ReceiptNo: Code[20];
        LineNo: Integer;
        Qty: Decimal;
    begin
        // [SCENARIO] A line that was already undone reports itself as no longer reversible
        // [GIVEN] a receipt line that has already been undone once
        Qty := LibraryRandom.RandIntInRange(3, 20);
        ReceiptNo := SetupReceivedOrder(PurchaseHeader, ItemNo, Qty, false);
        LineNo := FirstReceiptLineNo(ReceiptNo);
        ReceiptCorrection.UndoReceiptLine(ReceiptNo, LineNo);

        // [WHEN] asking whether the line is reversible
        // [THEN] the answer is false
        Assert.AreEqual(false, ReceiptCorrection.IsReversible(ReceiptNo, LineNo),
            'Expected a receipt line flagged as a Correction line to report itself as not reversible');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure IsReversibleIsFalseForALineThatDoesNotExist()
    var
        ReceiptCorrection: Codeunit "Receipt Correction";
    begin
        // [SCENARIO] An unknown receipt line answers false instead of erroring
        // [GIVEN] a receipt number that no posted receipt carries
        // [WHEN] asking whether one of its lines is reversible
        // [THEN] the answer is false and no error is raised
        Assert.AreEqual(false, ReceiptCorrection.IsReversible('TRYAL-U15', 10000),
            'Expected IsReversible to answer false for a receipt line that does not exist, without raising an error');
    end;

    // A refused undo is caught through a try function, not asserterror: an error
    // caught by asserterror rolls the transaction back to the last commit and
    // would take the posted receipt with it; a try function keeps every row.
    [TryFunction]
    local procedure TryUndoReceiptLine(ReceiptNo: Code[20]; LineNo: Integer)
    var
        ReceiptCorrection: Codeunit "Receipt Correction";
    begin
        ReceiptCorrection.UndoReceiptLine(ReceiptNo, LineNo);
    end;

    local procedure SetupReceivedOrder(var PurchaseHeader: Record "Purchase Header"; var ItemNo: Code[20]; Qty: Decimal; Invoice: Boolean): Code[20]
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        ItemNo := Item."No.";
        LibraryPurchase.CreatePurchaseDocumentWithItem(
            PurchaseHeader, PurchaseLine, "Purchase Document Type"::Order, Vendor."No.", ItemNo, Qty, '', 0D);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);
        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.FindFirst();
        exit(PurchRcptHeader."No.");
    end;

    local procedure SetupPartlyInvoicedOrder(var PurchaseHeader: Record "Purchase Header"; var ItemNo: Code[20]; Qty: Decimal; QtyToInvoice: Decimal) ReceiptNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        OrderNo: Code[20];
    begin
        ReceiptNo := SetupReceivedOrder(PurchaseHeader, ItemNo, Qty, false);
        OrderNo := PurchaseHeader."No.";
        GetOrderLine(PurchaseLine, ReceiptNo, FirstReceiptLineNo(ReceiptNo));
        PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.Modify(true);
        PurchaseHeader.Get("Purchase Document Type"::Order, OrderNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure SetupTwoLineReceivedOrder(var PurchaseHeader: Record "Purchase Header"; Qty1: Decimal; Qty2: Decimal): Code[20]
    var
        Vendor: Record Vendor;
        FirstItem: Record Item;
        SecondItem: Record Item;
        PurchaseLine: Record "Purchase Line";
        SecondPurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(FirstItem);
        LibraryInventory.CreateItem(SecondItem);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
            PurchaseHeader, PurchaseLine, "Purchase Document Type"::Order, Vendor."No.", FirstItem."No.", Qty1, '', 0D);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
            SecondPurchaseLine, PurchaseHeader, SecondPurchaseLine.Type::Item, SecondItem."No.", Qty2);
        SecondPurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 50, 2));
        SecondPurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.FindFirst();
        exit(PurchRcptHeader."No.");
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

    local procedure FirstReceiptLineNo(ReceiptNo: Code[20]): Integer
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Document No.", ReceiptNo);
        Assert.IsTrue(PurchRcptLine.FindFirst(),
            StrSubstNo('Test setup expected posted purchase receipt %1 to carry a line', ReceiptNo));
        exit(PurchRcptLine."Line No.");
    end;

    local procedure ReceiptLineNos(ReceiptNo: Code[20]; var LineNo1: Integer; var LineNo2: Integer)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Document No.", ReceiptNo);
        Assert.IsTrue(PurchRcptLine.FindSet(),
            StrSubstNo('Test setup expected posted purchase receipt %1 to carry two lines', ReceiptNo));
        LineNo1 := PurchRcptLine."Line No.";
        Assert.IsTrue(PurchRcptLine.Next() <> 0,
            StrSubstNo('Test setup expected posted purchase receipt %1 to carry a second line', ReceiptNo));
        LineNo2 := PurchRcptLine."Line No.";
    end;

    local procedure GetOrderLine(var PurchaseLine: Record "Purchase Line"; ReceiptNo: Code[20]; LineNo: Integer)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.Get(ReceiptNo, LineNo);
        PurchaseLine.Get("Purchase Document Type"::Order, PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
    end;

    local procedure ItemLedgerQuantity(ItemNo: Code[20]): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.CalcSums(Quantity);
        exit(ItemLedgerEntry.Quantity);
    end;

    local procedure ItemLedgerEntryCount(ItemNo: Code[20]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        exit(ItemLedgerEntry.Count());
    end;
}
