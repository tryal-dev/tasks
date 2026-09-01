codeunit 50900 "Markup Recalc Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidatingMarkupRecalculatesSuggestedPrice()
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Cost: Decimal;
        Markup: Decimal;
    begin
        LibraryInventory.CreateItem(Item);
        Cost := Any.DecimalInRange(10, 1000, 2);
        Item."Unit Cost" := Cost;
        Item.Modify();

        Markup := Any.IntegerInRange(5, 95);
        Item.Validate("Markup %", Markup);

        Assert.AreEqual(Round(Cost * (1 + Markup / 100), 0.01), Item."Suggested Price",
            'Expected validating "Markup %" to recalculate "Suggested Price" as "Unit Cost" * (1 + "Markup %" / 100), rounded to the nearest 0.01');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PlainAssignmentAndModifyDoNotRecalculate()
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Cost" := 100;
        Item.Modify();

        Item."Markup %" := 50;
        Item.Modify(true);

        Assert.AreEqual(0, Item."Suggested Price",
            'Expected a plain assignment (even followed by Modify) to leave "Suggested Price" untouched — the recalculation must live in the OnValidate trigger of "Markup %" only');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RecalculationRoundsToTheNearestCent()
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Cost" := 33.33;
        Item.Modify();

        Item.Validate("Markup %", 10);

        Assert.AreEqual(36.66, Item."Suggested Price",
            'Expected 33.33 * 1.10 = 36.663 to be rounded to 36.66 (nearest 0.01)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RecalculationRoundsUpAsWellAsDown()
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Cost" := 33.33;
        Item.Modify();

        Item.Validate("Markup %", 20);

        Assert.AreEqual(40.0, Item."Suggested Price",
            'Expected 33.33 * 1.20 = 39.996 to be rounded to 40.00 (nearest 0.01) — truncating instead of rounding gives 39.99');
    end;
}
