codeunit 50900 "Freight Charge Archiver Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveCreatesTheArchiveRowUnderTheSameEntryNumber()
    var
        CarrierChargeArchive: Record "Carrier Charge Archive";
        FreightChargeArchiver: Codeunit "Freight Charge Archiver";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Archiving a freight charge writes one archive row keyed by the same entry number
        // [GIVEN] a fully populated freight charge 9101
        CreateFreightCharge(9101, 'SHP-9101', 'pallet freight to the north depot', 3, 40, 5, 20250401D, 'dhl');

        // [WHEN] archiving it
        FreightChargeArchiver.Archive(9101, 20250601D);

        // [THEN] the archive holds a row under entry no. 9101
        Assert.IsTrue(CarrierChargeArchive.Get(9101),
            'Expected a "Carrier Charge Archive" row whose "Entry No." equals the archived freight charge''s "Entry No."');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveCopiesTheShipmentNumber()
    var
        FreightCharge: Record "Freight Charge";
        CarrierChargeArchive: Record "Carrier Charge Archive";
        FreightChargeArchiver: Codeunit "Freight Charge Archiver";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ShipmentNo: Code[20];
    begin
        // [SCENARIO] The shipment number reaches the archive field that means "shipment number"
        ShipmentNo := CopyStr('SHP-' + Format(Any.IntegerInRange(100000, 999999)), 1, MaxStrLen(ShipmentNo));
        CreateFreightCharge(9102, ShipmentNo, 'crated machine parts', 2, 125, 0, 20250402D, 'ups');

        FreightChargeArchiver.Archive(9102, 20250601D);

        FreightCharge.Get(9102);
        CarrierChargeArchive.Get(9102);
        Assert.AreEqual(FreightCharge."Shipment No.", CarrierChargeArchive."Shipment No.",
            'Expected the archive''s "Shipment No." (field 70) to hold the freight charge''s "Shipment No." (field 2)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveCopiesTheQuantityIntoTheArchiveQuantityField()
    var
        FreightCharge: Record "Freight Charge";
        CarrierChargeArchive: Record "Carrier Charge Archive";
        FreightChargeArchiver: Codeunit "Freight Charge Archiver";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Qty: Decimal;
    begin
        // [SCENARIO] The quantity reaches the archive field that means "quantity", not the one that shares its number
        Qty := Any.DecimalInRange(2, 90, 2);
        CreateFreightCharge(9103, 'SHP-9103', 'bulk sacks', Qty, 12.5, 7.5, 20250403D, 'dsv');

        FreightChargeArchiver.Archive(9103, 20250601D);

        FreightCharge.Get(9103);
        CarrierChargeArchive.Get(9103);
        Assert.AreEqual(Qty, CarrierChargeArchive.Quantity,
            'Expected the archive''s Quantity (field 60) to hold the freight charge''s Quantity (field 10) — the two tables do not agree on field numbers, so the pairing has to be written out');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveFilesTheDiscountPercentageNotTheQuantity()
    var
        CarrierChargeArchive: Record "Carrier Charge Archive";
        FreightChargeArchiver: Codeunit "Freight Charge Archiver";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Qty: Decimal;
        DiscountPct: Decimal;
    begin
        // [SCENARIO] The archive's "Discount Pct" holds the freight charge's "Discount %", never its quantity
        // The quantity is deliberately far above any legal percentage, so a
        // copy that pairs field 10 with field 10 is visible in the value.
        Qty := Any.DecimalInRange(150, 500, 2);
        DiscountPct := Any.DecimalInRange(1, 99, 2);
        CreateFreightCharge(9104, 'SHP-9104', 'palletised drums', Qty, 9.75, DiscountPct, 20250404D, 'gls');

        FreightChargeArchiver.Archive(9104, 20250601D);

        CarrierChargeArchive.Get(9104);
        Assert.AreEqual(DiscountPct, CarrierChargeArchive."Discount Pct",
            'Expected the archive''s "Discount Pct" (field 10) to hold the freight charge''s "Discount %" (field 12) — field 10 of the freight charge is the Quantity, and copying it here files a quantity as a discount');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveStoresTheRoundedExtendedChargeAmount()
    var
        FreightCharge: Record "Freight Charge";
        CarrierChargeArchive: Record "Carrier Charge Archive";
        FreightChargeArchiver: Codeunit "Freight Charge Archiver";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] The archive's "Charge Amount" is quantity times unit freight cost, rounded to two decimals
        // Three-decimal factors, so a product that is never rounded misses by
        // a fraction of a cent.
        CreateFreightCharge(9105, 'SHP-9105', 'reefer container', Any.DecimalInRange(2, 50, 3), Any.DecimalInRange(2, 100, 3), 3, 20250405D, 'kn');

        FreightChargeArchiver.Archive(9105, 20250601D);

        FreightCharge.Get(9105);
        CarrierChargeArchive.Get(9105);
        Assert.AreEqual(Round(FreightCharge.Quantity * FreightCharge."Unit Freight Cost", 0.01), CarrierChargeArchive."Charge Amount",
            'Expected the archive''s "Charge Amount" to be Quantity * "Unit Freight Cost" rounded to two decimals — the archive table has no unit cost field to carry');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveCopiesTheCarrierCode()
    var
        FreightCharge: Record "Freight Charge";
        CarrierChargeArchive: Record "Carrier Charge Archive";
        FreightChargeArchiver: Codeunit "Freight Charge Archiver";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The carrier code reaches the archive even though its number changes on the way
        CreateFreightCharge(9106, 'SHP-9106', 'groupage consignment', 6, 22.4, 0, 20250406D, 'schenker');

        FreightChargeArchiver.Archive(9106, 20250601D);

        FreightCharge.Get(9106);
        CarrierChargeArchive.Get(9106);
        Assert.AreEqual(FreightCharge."Carrier Code", CarrierChargeArchive."Carrier Code",
            'Expected the archive''s "Carrier Code" (field 20) to hold the freight charge''s "Carrier Code" (field 30)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveNormalizesTheDescriptionIntoTheReferenceText()
    var
        FreightCharge: Record "Freight Charge";
        CarrierChargeArchive: Record "Carrier Charge Archive";
        FreightChargeArchiver: Codeunit "Freight Charge Archiver";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ChargeDescription: Text[100];
    begin
        // [SCENARIO] A 100-character lower-case description lands in the 30-character "Reference Text" in upper case
        ChargeDescription := CopyStr(Any.AlphabeticText(MaxStrLen(ChargeDescription)), 1, MaxStrLen(ChargeDescription));
        CreateFreightCharge(9107, 'SHP-9107', ChargeDescription, 4, 18, 2.5, 20250407D, 'dachser');

        FreightChargeArchiver.Archive(9107, 20250601D);

        FreightCharge.Get(9107);
        CarrierChargeArchive.Get(9107);
        Assert.AreEqual(UpperCase(CopyStr(ChargeDescription, 1, 30)), CarrierChargeArchive."Reference Text",
            'Expected "Reference Text" to hold the first 30 characters of the freight charge''s Description, upper-cased the way the archive table''s OnValidate upper-cases it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveStampsTheArchivedOnDate()
    var
        CarrierChargeArchive: Record "Carrier Charge Archive";
        FreightChargeArchiver: Codeunit "Freight Charge Archiver";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ArchivedOn: Date;
    begin
        // [SCENARIO] The date passed to Archive lands in the archive-only "Archived On" field
        ArchivedOn := Any.DateInRange(20250101D, 1, 500);
        CreateFreightCharge(9108, 'SHP-9108', 'express parcels', 11, 4.05, 0, 20250408D, 'tnt');

        FreightChargeArchiver.Archive(9108, ArchivedOn);

        CarrierChargeArchive.Get(9108);
        Assert.AreEqual(ArchivedOn, CarrierChargeArchive."Archived On",
            'Expected "Archived On" to hold the date passed to Archive — the freight charge has no field that could supply it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveFlagsTheFreightChargeAsArchived()
    var
        FreightCharge: Record "Freight Charge";
        FreightChargeArchiver: Codeunit "Freight Charge Archiver";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The freight charge stays in place and is flagged once it has been archived
        CreateFreightCharge(9109, 'SHP-9109', 'timber load', 9, 31.2, 1, 20250409D, 'geodis');

        FreightChargeArchiver.Archive(9109, 20250601D);

        Assert.IsTrue(FreightCharge.Get(9109),
            'Expected the "Freight Charge" row to survive archiving — the archiver copies it, it does not delete it');
        Assert.IsTrue(FreightCharge.Archived,
            StrSubstNo('Expected the freight charge''s Archived flag to be set to true after archiving, got %1', FreightCharge.Archived));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchivingADiscountOutsideTheAllowedRangeFailsAndWritesNothing()
    var
        CarrierChargeArchive: Record "Carrier Charge Archive";
        FreightCharge: Record "Freight Charge";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] A discount the archive table refuses stops the archiving instead of being stored silently
        CreateFreightCharge(9110, 'SHP-9110', 'legacy line with a broken discount', 8, 15, Any.DecimalInRange(101, 900, 2), 20250410D, 'dhl');

        if TryArchive(9110, 20250601D) then
            Assert.Fail('Expected Archive to refuse a freight charge whose "Discount %" is above 100, but it went through');

        Assert.IsFalse(CarrierChargeArchive.Get(9110),
            'Expected no archive row for a freight charge whose "Discount %" is outside 0..100 — the archive table rejects it, but only when its OnValidate is actually run');
        FreightCharge.Get(9110);
        Assert.IsFalse(FreightCharge.Archived,
            StrSubstNo('Expected the rejected freight charge to stay unflagged, got Archived = %1', FreightCharge.Archived));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchivingANegativeDiscountFailsAndWritesNothing()
    var
        CarrierChargeArchive: Record "Carrier Charge Archive";
        FreightCharge: Record "Freight Charge";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        DiscountPct: Decimal;
    begin
        // [SCENARIO] The lower end of the archive's 0..100 rule stops the archiving just as the upper end does
        DiscountPct := -Any.DecimalInRange(1, 50, 2);
        CreateFreightCharge(9116, 'SHP-9116', 'legacy line with a negative discount', 8, 15, DiscountPct, 20250416D, 'ups');

        if TryArchive(9116, 20250601D) then
            Assert.Fail('Expected Archive to refuse a freight charge whose "Discount %" is below 0, but it went through');

        Assert.IsFalse(CarrierChargeArchive.Get(9116),
            'Expected no archive row for a freight charge whose "Discount %" is below 0 — the archive table rejects everything outside 0..100, not only values above 100');
        FreightCharge.Get(9116);
        Assert.IsFalse(FreightCharge.Archived,
            StrSubstNo('Expected the rejected freight charge to stay unflagged, got Archived = %1', FreightCharge.Archived));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchivingADiscountOfExactlyOneHundredSucceeds()
    var
        CarrierChargeArchive: Record "Carrier Charge Archive";
        FreightChargeArchiver: Codeunit "Freight Charge Archiver";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] 100 is inside the archive's allowed range, so the boundary itself still archives
        CreateFreightCharge(9117, 'SHP-9117', 'fully discounted load', 5, 25, 100, 20250417D, 'gls');

        FreightChargeArchiver.Archive(9117, 20250601D);

        CarrierChargeArchive.Get(9117);
        Assert.AreEqual(100.0, CarrierChargeArchive."Discount Pct",
            'Expected a "Discount %" of exactly 100 to be archived — the archive table allows 0..100 inclusive, so neither boundary may be rejected');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchivingAChargeAlreadyFlaggedArchivedFailsWithoutWritingAnything()
    var
        CarrierChargeArchive: Record "Carrier Charge Archive";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The Archived flag alone refuses the archiving, with no archive row present to refuse it instead
        CreateArchivedFreightCharge(9115, 'SHP-9115', 'load flagged by an earlier run', 6, 14.5, 12, 20250415D, 'dhl');

        if TryArchive(9115, 20250601D) then
            Assert.Fail('Expected Archive to refuse a freight charge already flagged Archived, but it went through');

        Assert.IsFalse(CarrierChargeArchive.Get(9115),
            'Expected no archive row for a freight charge already flagged Archived — Archive must read that flag and refuse before it writes anything');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchivingTheSameChargeTwiceFailsAndKeepsTheFirstArchive()
    var
        CarrierChargeArchive: Record "Carrier Charge Archive";
        FreightChargeArchiver: Codeunit "Freight Charge Archiver";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] An already archived freight charge cannot be archived again
        CreateFreightCharge(9111, 'SHP-9111', 'twice-submitted load', 5, 20, 10, 20250411D, 'dhl');
        FreightChargeArchiver.Archive(9111, 20250601D);

        if TryArchive(9111, 20251231D) then
            Assert.Fail('Expected the second Archive call on an already archived freight charge to be refused, but it went through');

        CarrierChargeArchive.Get(9111);
        Assert.AreEqual(20250601D, CarrierChargeArchive."Archived On",
            'Expected the second Archive call on an already archived freight charge to fail and leave the first archive row untouched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchivingAnEntryThatDoesNotExistFailsAndWritesNothing()
    var
        CarrierChargeArchive: Record "Carrier Charge Archive";
        FreightChargeArchiver: Codeunit "Freight Charge Archiver";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Archiving an entry number with no freight charge behind it fails
        asserterror FreightChargeArchiver.Archive(9112, 20250601D);

        Assert.IsFalse(CarrierChargeArchive.Get(9112),
            'Expected no archive row for an entry number that has no "Freight Charge" — Archive must fail with an error and write nothing');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlindTransferFieldsErrorsOnTheMismatchedFieldPair()
    var
        FreightCharge: Record "Freight Charge";
        CarrierChargeArchive: Record "Carrier Charge Archive";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Field 20 is a Date on one table and a Code on the other, so a plain TransferFields cannot run
        CreateFreightCharge(9113, 'SHP-9113', 'mismatch probe', 7, 10, 4, 20250413D, 'dhl');
        FreightCharge.Get(9113);
        CarrierChargeArchive.Init();

        asserterror CarrierChargeArchive.TransferFields(FreightCharge);

        Assert.AreNotEqual('', GetLastErrorText(),
            'Expected TransferFields to fail on the pair of fields that share a number but not a type ("Posting Date" 20 vs "Carrier Code" 20) — submit both given tables exactly as they are, do not renumber or retype them');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlindTransferFieldsSkippingMismatchesFilesTheQuantityAsDiscount()
    var
        FreightCharge: Record "Freight Charge";
        CarrierChargeArchive: Record "Carrier Charge Archive";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Qty: Decimal;
    begin
        // [SCENARIO] Skipping the mismatched pair lets the blind copy run — and it pairs the wrong fields
        Qty := Any.DecimalInRange(150, 500, 2);
        CreateFreightCharge(9114, 'SHP-9114', 'skip probe', Qty, 10, 6, 20250414D, 'dhl');
        FreightCharge.Get(9114);
        CarrierChargeArchive.Init();

        CarrierChargeArchive.TransferFields(FreightCharge, true, true);

        Assert.AreEqual(Qty, CarrierChargeArchive."Discount Pct",
            'Expected the blind copy to land the freight charge''s Quantity (field 10) in the archive''s "Discount Pct" (field 10) — this is the misfiling the explicit map exists to prevent');
        Assert.AreEqual(0.0, CarrierChargeArchive.Quantity,
            'Expected the archive''s Quantity (field 60) to stay empty after a blind copy — no freight charge field carries number 60');
        Assert.IsTrue(CarrierChargeArchive."Carrier Code" = '',
            StrSubstNo('Expected the mismatched field 20 to be skipped rather than copied, got "Carrier Code" = %1', CarrierChargeArchive."Carrier Code"));
    end;

    local procedure CreateFreightCharge(EntryNo: Integer; ShipmentNo: Code[20]; ChargeDescription: Text[100]; Qty: Decimal; UnitCost: Decimal; DiscountPct: Decimal; PostingDate: Date; CarrierCode: Code[10])
    var
        FreightCharge: Record "Freight Charge";
    begin
        FreightCharge.Init();
        FreightCharge."Entry No." := EntryNo;
        FreightCharge."Shipment No." := ShipmentNo;
        FreightCharge.Description := ChargeDescription;
        FreightCharge.Quantity := Qty;
        FreightCharge."Unit Freight Cost" := UnitCost;
        FreightCharge."Discount %" := DiscountPct;
        FreightCharge."Posting Date" := PostingDate;
        FreightCharge."Carrier Code" := CarrierCode;
        FreightCharge.Insert();
    end;

    local procedure CreateArchivedFreightCharge(EntryNo: Integer; ShipmentNo: Code[20]; ChargeDescription: Text[100]; Qty: Decimal; UnitCost: Decimal; DiscountPct: Decimal; PostingDate: Date; CarrierCode: Code[10])
    var
        FreightCharge: Record "Freight Charge";
    begin
        CreateFreightCharge(EntryNo, ShipmentNo, ChargeDescription, Qty, UnitCost, DiscountPct, PostingDate, CarrierCode);
        FreightCharge.Get(EntryNo);
        FreightCharge.Archived := true;
        FreightCharge.Modify();
    end;

    [TryFunction]
    local procedure TryArchive(EntryNo: Integer; ArchivedOn: Date)
    var
        FreightChargeArchiver: Codeunit "Freight Charge Archiver";
    begin
        FreightChargeArchiver.Archive(EntryNo, ArchivedOn);
    end;
}
