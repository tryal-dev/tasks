codeunit 50900 "Return Reason Policy Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Sales] [Return Reason]

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RegisteringSendsTheLineToTheReasonsDefaultLocation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReason: Record "Return Reason";
        Item: Record Item;
        ReturnLineRegistrar: Codeunit "Return Line Registrar";
        ReturnReasonPolicyListener: Codeunit "Return Reason Policy Listener";
        Any: Codeunit Any;
        RepairLocationCode: Code[10];
    begin
        // [SCENARIO] The reason's default location takes over the return line
        // [GIVEN] a return line for an item, sitting at the origin location
        Initialize();
        CreateItemWithCost(Item, Any.DecimalInRange(10, 500, 2));
        CreateReturnLine(SalesHeader, SalesLine, Item."No.", CreateLocationCode(), Any.IntegerInRange(2, 9));
        // [GIVEN] a return reason whose default location is the repair location
        RepairLocationCode := CreateLocationCode();
        CreateReturnReason(ReturnReason, RepairLocationCode, false);

        // [WHEN] registering the line under that reason
        BindSubscription(ReturnReasonPolicyListener);
        ReturnLineRegistrar.RegisterReturnLine(SalesLine, ReturnReason.Code);
        UnbindSubscription(ReturnReasonPolicyListener);

        // [THEN] the line has moved to the reason's default location
        Assert.AreEqual(RepairLocationCode, SalesLine."Location Code",
            'Expected the line to move to the return reason''s "Default Location Code" — applying the reason must let the field''s own logic run');
        // [THEN] the base application's own validation is what moved it
        Assert.IsTrue(ReturnReasonPolicyListener.ReasonCodeValidations() > 0,
            'Expected the base application''s own "Return Reason Code" validation to run inside RegisterReturnLine — reproducing the location switch and zero valuation by hand instead of letting the field''s logic run does not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AZeroValueReasonTakesTheCostOffTheLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReason: Record "Return Reason";
        Item: Record Item;
        ReturnLineRegistrar: Codeunit "Return Line Registrar";
        Any: Codeunit Any;
    begin
        // [SCENARIO] A reason marked "Inventory Value Zero" leaves the line valued at nothing
        // [GIVEN] a return line for an item that has a unit cost
        Initialize();
        CreateItemWithCost(Item, Any.DecimalInRange(10, 500, 2));
        CreateReturnLine(SalesHeader, SalesLine, Item."No.", CreateLocationCode(), Any.IntegerInRange(2, 9));
        // [GIVEN] a return reason marked "Inventory Value Zero"
        CreateReturnReason(ReturnReason, CreateLocationCode(), true);

        // [WHEN] registering the line under that reason
        ReturnLineRegistrar.RegisterReturnLine(SalesLine, ReturnReason.Code);

        // [THEN] the line carries no cost any more
        Assert.AreEqual(0, SalesLine."Unit Cost (LCY)",
            'Expected "Unit Cost (LCY)" to be 0 on a line registered under a reason marked "Inventory Value Zero"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnOrdinaryReasonLeavesTheItemsCostOnTheLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReason: Record "Return Reason";
        Item: Record Item;
        ReturnLineRegistrar: Codeunit "Return Line Registrar";
        Any: Codeunit Any;
    begin
        // [SCENARIO] A reason that is not marked "Inventory Value Zero" keeps the line's cost
        // [GIVEN] a return line for an item that has a generated unit cost
        Initialize();
        CreateItemWithCost(Item, Any.DecimalInRange(10, 500, 2));
        CreateReturnLine(SalesHeader, SalesLine, Item."No.", CreateLocationCode(), Any.IntegerInRange(2, 9));
        // [GIVEN] a return reason that is not marked "Inventory Value Zero"
        CreateReturnReason(ReturnReason, CreateLocationCode(), false);

        // [WHEN] registering the line under that reason
        ReturnLineRegistrar.RegisterReturnLine(SalesLine, ReturnReason.Code);

        // [THEN] the line still carries the item's unit cost
        Assert.AreEqual(Item."Unit Cost", SalesLine."Unit Cost (LCY)",
            'Expected the item''s unit cost to stay on the line — only a reason marked "Inventory Value Zero" may zero it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheRegisteredLineIsSavedToTheDatabase()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        StoredSalesLine: Record "Sales Line";
        ReturnReason: Record "Return Reason";
        Item: Record Item;
        ReturnLineRegistrar: Codeunit "Return Line Registrar";
        Any: Codeunit Any;
        RepairLocationCode: Code[10];
    begin
        // [SCENARIO] Registering a line writes the change through to the database
        // [GIVEN] a return line at the origin location and a reason defaulting to the repair location
        Initialize();
        CreateItemWithCost(Item, Any.DecimalInRange(10, 500, 2));
        CreateReturnLine(SalesHeader, SalesLine, Item."No.", CreateLocationCode(), Any.IntegerInRange(2, 9));
        RepairLocationCode := CreateLocationCode();
        CreateReturnReason(ReturnReason, RepairLocationCode, false);

        // [WHEN] registering the line under that reason
        ReturnLineRegistrar.RegisterReturnLine(SalesLine, ReturnReason.Code);

        // [THEN] a fresh read of the line shows the reason code and the new location
        StoredSalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        Assert.AreEqual(ReturnReason.Code, StoredSalesLine."Return Reason Code",
            'Expected the reason code to be saved on the line — a line that is only changed in memory is lost the moment it is read again');
        Assert.AreEqual(RepairLocationCode, StoredSalesLine."Location Code",
            'Expected the reason''s default location to be saved on the line, not just held in memory');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ThePostedEntryLandsAtTheReasonsDefaultLocation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReason: Record "Return Reason";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReturnLineRegistrar: Codeunit "Return Line Registrar";
        Any: Codeunit Any;
        RepairLocationCode: Code[10];
    begin
        // [SCENARIO] The returned goods are received into the reason's default location
        // [GIVEN] a return line registered under a reason defaulting to the repair location
        Initialize();
        CreateItemWithCost(Item, Any.DecimalInRange(10, 500, 2));
        CreateReturnLine(SalesHeader, SalesLine, Item."No.", CreateLocationCode(), Any.IntegerInRange(2, 9));
        RepairLocationCode := CreateLocationCode();
        CreateReturnReason(ReturnReason, RepairLocationCode, false);
        ReturnLineRegistrar.RegisterReturnLine(SalesLine, ReturnReason.Code);

        // [WHEN] receiving and invoicing the return order
        PostReturnOrder(SalesHeader);

        // [THEN] the item ledger entry sits at the reason's default location
        FindReturnReceiptEntry(ItemLedgerEntry, Item."No.");
        Assert.AreEqual(RepairLocationCode, ItemLedgerEntry."Location Code",
            'Expected the posted item ledger entry to be at the return reason''s "Default Location Code"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ThePostedEntryUnderAZeroValueReasonCostsNothing()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReason: Record "Return Reason";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReturnLineRegistrar: Codeunit "Return Line Registrar";
        Any: Codeunit Any;
    begin
        // [SCENARIO] Goods returned under a zero-value reason add nothing to the inventory value
        // [GIVEN] a return line for a costed item, registered under a reason marked "Inventory Value Zero"
        Initialize();
        CreateItemWithCost(Item, Any.DecimalInRange(10, 500, 2));
        CreateReturnLine(SalesHeader, SalesLine, Item."No.", CreateLocationCode(), Any.IntegerInRange(2, 9));
        CreateReturnReason(ReturnReason, CreateLocationCode(), true);
        ReturnLineRegistrar.RegisterReturnLine(SalesLine, ReturnReason.Code);

        // [WHEN] receiving and invoicing the return order
        PostReturnOrder(SalesHeader);

        // [THEN] the item ledger entry carries no cost at all
        FindReturnReceiptEntry(ItemLedgerEntry, Item."No.");
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        Assert.AreEqual(0, ItemLedgerEntry."Cost Amount (Actual)",
            'Expected "Cost Amount (Actual)" to be exactly 0 — goods returned under a reason marked "Inventory Value Zero" are still the customer''s and must not raise the inventory value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ThePostedEntryUnderAnOrdinaryReasonKeepsItsCost()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReason: Record "Return Reason";
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReturnLineRegistrar: Codeunit "Return Line Registrar";
        Any: Codeunit Any;
    begin
        // [SCENARIO] Goods returned under an ordinary reason enter inventory at their cost
        // [GIVEN] a return line for a costed item, registered under a reason that is not marked "Inventory Value Zero"
        Initialize();
        CreateItemWithCost(Item, Any.DecimalInRange(10, 500, 2));
        CreateReturnLine(SalesHeader, SalesLine, Item."No.", CreateLocationCode(), Any.IntegerInRange(2, 9));
        CreateReturnReason(ReturnReason, CreateLocationCode(), false);
        ReturnLineRegistrar.RegisterReturnLine(SalesLine, ReturnReason.Code);

        // [WHEN] receiving and invoicing the return order
        PostReturnOrder(SalesHeader);

        // [THEN] the item ledger entry carries a cost
        FindReturnReceiptEntry(ItemLedgerEntry, Item."No.");
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        Assert.AreNotEqual(0, ItemLedgerEntry."Cost Amount (Actual)",
            'Expected a non-zero "Cost Amount (Actual)" — only a reason marked "Inventory Value Zero" may strip the cost off the returned goods');
    end;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // The returns posted here are not applied to an original sale, so exact
        // cost reversing has to stay optional for the posting tests.
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Exact Cost Reversing Mandatory" then begin
            SalesReceivablesSetup."Exact Cost Reversing Mandatory" := false;
            SalesReceivablesSetup.Modify();
        end;
    end;

    local procedure CreateItemWithCost(var Item: Record Item; UnitCost: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Validate("Last Direct Cost", UnitCost);
        Item.Validate("Unit Cost", UnitCost);
        Item.Validate("Unit Price", UnitCost * 2);
        Item.Modify(true);
    end;

    local procedure CreateLocationCode(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        exit(Location.Code);
    end;

    local procedure CreateReturnReason(var ReturnReason: Record "Return Reason"; DefaultLocationCode: Code[10]; InventoryValueZero: Boolean)
    begin
        ReturnReason.Init();
        ReturnReason.Validate(Code, LibraryUtility.GenerateRandomCode(ReturnReason.FieldNo(Code), Database::"Return Reason"));
        ReturnReason.Validate(Description, 'TryAL return reason');
        ReturnReason.Validate("Default Location Code", DefaultLocationCode);
        ReturnReason.Validate("Inventory Value Zero", InventoryValueZero);
        ReturnReason.Insert(true);
    end;

    local procedure CreateReturnLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; OriginLocationCode: Code[10]; Quantity: Decimal)
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", Customer."No.", ItemNo, Quantity, OriginLocationCode, WorkDate());
    end;

    local procedure PostReturnOrder(var SalesHeader: Record "Sales Header")
    var
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesHeader.Receive := true;
        SalesHeader.Invoice := true;
        // Codeunit "Sales-Post" commits after a successful posting, which an
        // AutoRollback test forbids; SuppressCommit is the sanctioned way out.
        SalesPost.SetSuppressCommit(true);
        SalesPost.Run(SalesHeader);
    end;

    local procedure FindReturnReceiptEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Return Receipt");
        Assert.IsTrue(ItemLedgerEntry.FindFirst(),
            StrSubstNo('Expected a posted sales return receipt entry for item %1 — the registered line must reach the database before the return order is posted', ItemNo));
    end;
}
