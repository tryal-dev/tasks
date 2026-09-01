codeunit 50900 "Packing Calculator Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        PackingCalculator: Codeunit "Packing Calculator";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExactPalletMultipleSplitsIntoFullPalletsOnly()
    var
        Item: Record Item;
        Pallets: Integer;
        Boxes: Integer;
        Loose: Integer;
    begin
        // [SCENARIO] A quantity that is an exact number of pallets leaves no boxes and no loose units
        // [GIVEN] an item packed 12 per box and 10 boxes per pallet (120 units per pallet)
        CreatePackedItem(Item, 12, 10);

        // [WHEN] splitting 360 units
        PackingCalculator.SplitQuantity(Item."No.", 360, Pallets, Boxes, Loose);

        // [THEN] 3 pallets, 0 boxes, 0 loose
        AssertSplit(3, 0, 0, Pallets, Boxes, Loose, '360 units at 12 per box and 10 boxes per pallet');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MixedQuantitySplitsIntoPalletsBoxesAndLoose()
    var
        Item: Record Item;
        Pallets: Integer;
        Boxes: Integer;
        Loose: Integer;
    begin
        // [SCENARIO] A quantity with leftovers at every level splits into full pallets, full boxes and loose units
        // [GIVEN] an item packed 12 per box and 10 boxes per pallet
        CreatePackedItem(Item, 12, 10);

        // [WHEN] splitting 271 units
        PackingCalculator.SplitQuantity(Item."No.", 271, Pallets, Boxes, Loose);

        // [THEN] 2 pallets (240), 2 boxes (24), 7 loose
        AssertSplit(2, 2, 7, Pallets, Boxes, Loose, '271 units at 12 per box and 10 boxes per pallet');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QuantityBelowOneBoxIsAllLoose()
    var
        Item: Record Item;
        Pallets: Integer;
        Boxes: Integer;
        Loose: Integer;
    begin
        // [SCENARIO] Fewer units than one box holds are all loose — not rounded up to a box
        // [GIVEN] an item packed 12 per box and 10 boxes per pallet
        CreatePackedItem(Item, 12, 10);

        // [WHEN] splitting 7 units
        PackingCalculator.SplitQuantity(Item."No.", 7, Pallets, Boxes, Loose);

        // [THEN] 0 pallets, 0 boxes, 7 loose
        AssertSplit(0, 0, 7, Pallets, Boxes, Loose, '7 units at 12 per box and 10 boxes per pallet');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HalfABoxLeftOverIsNotRoundedUpToAFullBox()
    var
        Item: Record Item;
        Pallets: Integer;
        Boxes: Integer;
        Loose: Integer;
    begin
        // [SCENARIO] 7 units in boxes of 2 are 3 boxes and 1 loose unit, never 4 boxes
        // [GIVEN] an item packed 2 per box and 50 boxes per pallet
        CreatePackedItem(Item, 2, 50);

        // [WHEN] splitting 7 units
        PackingCalculator.SplitQuantity(Item."No.", 7, Pallets, Boxes, Loose);

        // [THEN] 0 pallets, 3 boxes, 1 loose
        AssertSplit(0, 3, 1, Pallets, Boxes, Loose, '7 units at 2 per box and 50 boxes per pallet');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroQuantitySplitsIntoNothing()
    var
        Item: Record Item;
        Pallets: Integer;
        Boxes: Integer;
        Loose: Integer;
    begin
        // [SCENARIO] Nothing to ship means no pallets, no boxes and no loose units
        // [GIVEN] an item packed 12 per box and 10 boxes per pallet
        CreatePackedItem(Item, 12, 10);

        // [WHEN] splitting 0 units
        PackingCalculator.SplitQuantity(Item."No.", 0, Pallets, Boxes, Loose);

        // [THEN] 0, 0, 0
        AssertSplit(0, 0, 0, Pallets, Boxes, Loose, '0 units');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedQuantityRecombinesIntoTheOriginal()
    var
        Item: Record Item;
        Any: Codeunit Any;
        UnitsPerBox: Integer;
        BoxesPerPallet: Integer;
        Quantity: Integer;
        Pallets: Integer;
        Boxes: Integer;
        Loose: Integer;
        Details: Text;
    begin
        // [SCENARIO] For any packing and any whole quantity, the three parts stay within bounds and add back up to the quantity
        // [GIVEN] generated box and pallet sizes and a generated quantity
        UnitsPerBox := Any.IntegerInRange(2, 9);
        BoxesPerPallet := Any.IntegerInRange(2, 9);
        Quantity := Any.IntegerInRange(1, 999);
        CreatePackedItem(Item, UnitsPerBox, BoxesPerPallet);

        // [WHEN] splitting the quantity
        PackingCalculator.SplitQuantity(Item."No.", Quantity, Pallets, Boxes, Loose);

        // [THEN] no part is negative, boxes and loose stay below one pallet / one box, and the parts recombine
        Details := StrSubstNo('%1 units at %2 per box and %3 boxes per pallet came back as pallets %4, boxes %5, loose %6',
            Quantity, UnitsPerBox, BoxesPerPallet, Pallets, Boxes, Loose);
        Assert.IsTrue(Pallets >= 0, 'Expected a non-negative pallet count: ' + Details);
        Assert.IsTrue((Boxes >= 0) and (Boxes < BoxesPerPallet),
            'Expected the box count to be between 0 and one less than "Boxes per Pallet" — a full pallet''s worth of boxes must be counted as a pallet: ' + Details);
        Assert.IsTrue((Loose >= 0) and (Loose < UnitsPerBox),
            'Expected the loose count to be between 0 and one less than "Units per Box" — a full box''s worth of loose units must be counted as a box: ' + Details);
        Assert.AreEqual(Quantity, Pallets * BoxesPerPallet * UnitsPerBox + Boxes * UnitsPerBox + Loose,
            'Expected pallets × units per pallet + boxes × units per box + loose to add back up to the quantity: ' + Details);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NonWholeQuantityIsRefusedNotTruncated()
    var
        Item: Record Item;
        Pallets: Integer;
        Boxes: Integer;
        Loose: Integer;
    begin
        // [SCENARIO] A fractional quantity cannot be packed and must raise a whole-number error
        // [GIVEN] an item packed 12 per box and 10 boxes per pallet
        CreatePackedItem(Item, 12, 10);

        // [WHEN] splitting 12.5 units
        asserterror PackingCalculator.SplitQuantity(Item."No.", 12.5, Pallets, Boxes, Loose);

        // [THEN] the error says the quantity must be a whole number
        Assert.ExpectedError('whole number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroUnitsPerBoxIsAClearErrorNotADivisionByZero()
    var
        Item: Record Item;
        Pallets: Integer;
        Boxes: Integer;
        Loose: Integer;
    begin
        // [SCENARIO] An item without a box size is refused with an error naming "Units per Box"
        // [GIVEN] an item with "Units per Box" = 0
        CreatePackedItem(Item, 0, 10);

        // [WHEN] splitting 25 units
        asserterror PackingCalculator.SplitQuantity(Item."No.", 25, Pallets, Boxes, Loose);

        // [THEN] the error names the field
        Assert.ExpectedError('Units per Box');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroBoxesPerPalletIsAClearErrorNotADivisionByZero()
    var
        Item: Record Item;
        Pallets: Integer;
        Boxes: Integer;
        Loose: Integer;
    begin
        // [SCENARIO] An item without a pallet size is refused with an error naming "Boxes per Pallet"
        // [GIVEN] an item with "Boxes per Pallet" = 0
        CreatePackedItem(Item, 5, 0);

        // [WHEN] splitting 25 units
        asserterror PackingCalculator.SplitQuantity(Item."No.", 25, Pallets, Boxes, Loose);

        // [THEN] the error names the field
        Assert.ExpectedError('Boxes per Pallet');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PalletsNeededIsExactForAFullPalletMultiple()
    var
        Item: Record Item;
    begin
        // [SCENARIO] An exact number of pallets needs exactly that many pallets — no spare one
        // [GIVEN] an item packed 12 per box and 10 boxes per pallet (120 per pallet)
        CreatePackedItem(Item, 12, 10);

        // [WHEN] asking how many pallets 240 units need
        // [THEN] 2
        Assert.AreEqual(2, PackingCalculator.PalletsNeeded(Item."No.", 240),
            'Expected 240 units at 120 per pallet to need exactly 2 pallets — nothing is left over, so no extra pallet');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PalletsNeededRoundsAPartialPalletUp()
    var
        Item: Record Item;
    begin
        // [SCENARIO] One unit past a full pallet needs a whole extra pallet
        // [GIVEN] an item packed 12 per box and 10 boxes per pallet (120 per pallet)
        CreatePackedItem(Item, 12, 10);

        // [WHEN] asking how many pallets 121 units need
        // [THEN] 2
        Assert.AreEqual(2, PackingCalculator.PalletsNeeded(Item."No.", 121),
            'Expected 121 units at 120 per pallet to need 2 pallets — the single leftover unit still needs a pallet, so round up, not to nearest');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PalletsNeededForASingleUnitIsOne()
    var
        Item: Record Item;
    begin
        // [SCENARIO] Even a single unit occupies one pallet
        // [GIVEN] an item packed 12 per box and 10 boxes per pallet (120 per pallet)
        CreatePackedItem(Item, 12, 10);

        // [WHEN] asking how many pallets 1 unit needs
        // [THEN] 1
        Assert.AreEqual(1, PackingCalculator.PalletsNeeded(Item."No.", 1),
            'Expected 1 unit at 120 per pallet to need 1 pallet — a fraction of a pallet rounds up to a whole one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PalletsNeededIsZeroForZeroQuantity()
    var
        Item: Record Item;
    begin
        // [SCENARIO] Nothing to ship needs no pallet
        // [GIVEN] an item packed 12 per box and 10 boxes per pallet
        CreatePackedItem(Item, 12, 10);

        // [WHEN] asking how many pallets 0 units need
        // [THEN] 0
        Assert.AreEqual(0, PackingCalculator.PalletsNeeded(Item."No.", 0),
            'Expected 0 units to need 0 pallets');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PalletsNeededFitsAGeneratedQuantityWithNoSparePallet()
    var
        Item: Record Item;
        Any: Codeunit Any;
        UnitsPerBox: Integer;
        BoxesPerPallet: Integer;
        UnitsPerPallet: Integer;
        Quantity: Integer;
        Needed: Integer;
    begin
        // [SCENARIO] The pallets needed carry the whole quantity, and one pallet fewer would not
        // [GIVEN] generated box and pallet sizes and a generated quantity
        UnitsPerBox := Any.IntegerInRange(2, 9);
        BoxesPerPallet := Any.IntegerInRange(2, 9);
        UnitsPerPallet := UnitsPerBox * BoxesPerPallet;
        Quantity := Any.IntegerInRange(1, 999);
        CreatePackedItem(Item, UnitsPerBox, BoxesPerPallet);

        // [WHEN] asking how many pallets the quantity needs
        Needed := PackingCalculator.PalletsNeeded(Item."No.", Quantity);

        // [THEN] Needed pallets hold the quantity, Needed - 1 pallets do not
        Assert.IsTrue(Needed * UnitsPerPallet >= Quantity,
            StrSubstNo('Expected %1 pallets of %2 units to carry all %3 units — PalletsNeeded must round up', Needed, UnitsPerPallet, Quantity));
        Assert.IsTrue((Needed - 1) * UnitsPerPallet < Quantity,
            StrSubstNo('Expected the smallest pallet count that fits: %1 units already fit on %2 pallets of %3 units, so %4 pallets is one too many', Quantity, Needed - 1, UnitsPerPallet, Needed));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PalletsNeededRefusesANonWholeQuantity()
    var
        Item: Record Item;
    begin
        // [SCENARIO] PalletsNeeded applies the same whole-number rule as SplitQuantity
        // [GIVEN] an item packed 12 per box and 10 boxes per pallet
        CreatePackedItem(Item, 12, 10);

        // [WHEN] asking how many pallets 12.5 units need
        asserterror PackingCalculator.PalletsNeeded(Item."No.", 12.5);

        // [THEN] the error says the quantity must be a whole number
        Assert.ExpectedError('whole number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PalletsNeededReportsAZeroUnitsPerBoxClearly()
    var
        Item: Record Item;
    begin
        // [SCENARIO] PalletsNeeded applies the same zero-field rule as SplitQuantity
        // [GIVEN] an item with "Units per Box" = 0
        CreatePackedItem(Item, 0, 10);

        // [WHEN] asking how many pallets 25 units need
        asserterror PackingCalculator.PalletsNeeded(Item."No.", 25);

        // [THEN] the error names the field
        Assert.ExpectedError('Units per Box');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PalletsNeededReportsAZeroBoxesPerPalletClearly()
    var
        Item: Record Item;
    begin
        // [SCENARIO] PalletsNeeded refuses a missing pallet size with an error naming "Boxes per Pallet", not a division by zero
        // [GIVEN] an item with "Boxes per Pallet" = 0
        CreatePackedItem(Item, 5, 0);

        // [WHEN] asking how many pallets 25 units need
        asserterror PackingCalculator.PalletsNeeded(Item."No.", 25);

        // [THEN] the error names the field
        Assert.ExpectedError('Boxes per Pallet');
    end;

    local procedure CreatePackedItem(var Item: Record Item; UnitsPerBox: Integer; BoxesPerPallet: Integer)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Units per Box" := UnitsPerBox;
        Item."Boxes per Pallet" := BoxesPerPallet;
        Item.Modify();
    end;

    local procedure AssertSplit(ExpectedPallets: Integer; ExpectedBoxes: Integer; ExpectedLoose: Integer; Pallets: Integer; Boxes: Integer; Loose: Integer; Context: Text)
    var
        Actual: Text;
    begin
        Actual := StrSubstNo('(got pallets %1, boxes %2, loose %3)', Pallets, Boxes, Loose);
        Assert.AreEqual(ExpectedPallets, Pallets, StrSubstNo('Expected %1 to fill %2 full pallets %3', Context, ExpectedPallets, Actual));
        Assert.AreEqual(ExpectedBoxes, Boxes, StrSubstNo('Expected %1 to fill %2 full boxes beyond the pallets %3', Context, ExpectedBoxes, Actual));
        Assert.AreEqual(ExpectedLoose, Loose, StrSubstNo('Expected %1 to leave %2 loose units beyond the boxes %3', Context, ExpectedLoose, Actual));
    end;
}
