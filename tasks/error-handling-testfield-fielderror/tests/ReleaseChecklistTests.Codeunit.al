codeunit 50900 "Release Checklist Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        PastShipmentDateTxt: Label 'must not be in the past';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankShipToCodeIsReportedWithThePlatformWording()
    var
        SalesHeader: Record "Sales Header";
        ActualText: Text;
    begin
        // [SCENARIO] A blank Ship-to Code is refused with the platform's own "must have a value" message
        // [GIVEN] the work date pinned to 15 January 2024, and a released order shipping on the work date with no Ship-to Code
        WorkDate(20240115D);
        CreateOrder(SalesHeader, false, SalesHeader.Status::Released, WorkDate());

        // [WHEN] running the release checklist
        ActualText := RefusedWith(SalesHeader, 'a blank Ship-to Code');

        // [THEN] the message is the one the platform composes for a blank Ship-to Code on this document
        Assert.AreEqual(PlatformBlankShipToCodeText(SalesHeader), ActualText,
            'Expected the blank Ship-to Code to be reported with the platform''s own "must have a value" wording for the "Ship-to Code" field of this sales order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnreleasedStatusIsReportedWithThePlatformWording()
    var
        SalesHeader: Record "Sales Header";
        Any: Codeunit Any;
        ActualText: Text;
    begin
        // [SCENARIO] A status other than Released is refused with the platform's own "must be equal to" message
        // [GIVEN] the work date pinned to 15 January 2024, and an order with a Ship-to Code shipping on the work date whose status is not Released
        WorkDate(20240115D);
        CreateOrder(SalesHeader, true, RandomUnreleasedStatus(Any), WorkDate());

        // [WHEN] running the release checklist
        ActualText := RefusedWith(SalesHeader, StrSubstNo('status %1', SalesHeader.Status));

        // [THEN] the message is the one the platform composes for a Status that must be Released, naming the current value
        Assert.AreEqual(PlatformStatusMustBeReleasedText(SalesHeader), ActualText,
            StrSubstNo('Expected status %1 to be reported with the platform''s own "must be equal to ... Current value is ..." wording for the Status field of this sales order', SalesHeader.Status));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PastShipmentDateIsReportedWithThePlatformWording()
    var
        SalesHeader: Record "Sales Header";
        Any: Codeunit Any;
        ActualText: Text;
    begin
        // [SCENARIO] A shipment date before the work date is refused with a platform field message carrying the custom text
        // [GIVEN] the work date pinned to 15 January 2024, and a released order with a Ship-to Code shipping some days before it
        WorkDate(20240115D);
        CreateOrder(SalesHeader, true, SalesHeader.Status::Released, WorkDate() - Any.IntegerInRange(1, 30));

        // [WHEN] running the release checklist
        ActualText := RefusedWith(SalesHeader, StrSubstNo('shipment date %1 before work date %2', SalesHeader."Shipment Date", WorkDate()));

        // [THEN] the message is the platform's field message for "Shipment Date" with the text "must not be in the past" and its automatic period
        Assert.AreEqual(PlatformPastShipmentDateText(SalesHeader), ActualText,
            'Expected the past shipment date to be reported with the platform''s own field-message shape for "Shipment Date" and the text "must not be in the past" (the platform adds the final period itself)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShipToCodeIsCheckedBeforeStatusAndShipmentDate()
    var
        SalesHeader: Record "Sales Header";
        Any: Codeunit Any;
        ActualText: Text;
    begin
        // [SCENARIO] When every check fails, the blank Ship-to Code is the one reported
        // [GIVEN] the work date pinned to 15 January 2024, and an open order with no Ship-to Code shipping some days before it
        WorkDate(20240115D);
        CreateOrder(SalesHeader, false, SalesHeader.Status::Open, WorkDate() - Any.IntegerInRange(1, 30));

        // [WHEN] running the release checklist
        ActualText := RefusedWith(SalesHeader, 'every check failing');

        // [THEN] the blank Ship-to Code message wins
        Assert.AreEqual(PlatformBlankShipToCodeText(SalesHeader), ActualText,
            'Expected the blank Ship-to Code to be reported before the status and the shipment date - the checklist runs in the order Ship-to Code, Status, Shipment Date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatusIsCheckedBeforeShipmentDate()
    var
        SalesHeader: Record "Sales Header";
        Any: Codeunit Any;
        ActualText: Text;
    begin
        // [SCENARIO] When both the status and the shipment date are wrong, the status is the one reported
        // [GIVEN] the work date pinned to 15 January 2024, and an unreleased order with a Ship-to Code shipping some days before it
        WorkDate(20240115D);
        CreateOrder(SalesHeader, true, RandomUnreleasedStatus(Any), WorkDate() - Any.IntegerInRange(1, 30));

        // [WHEN] running the release checklist
        ActualText := RefusedWith(SalesHeader, 'both the status and the shipment date wrong');

        // [THEN] the status message wins
        Assert.AreEqual(PlatformStatusMustBeReleasedText(SalesHeader), ActualText,
            'Expected the unreleased status to be reported before the shipment date - the checklist runs in the order Ship-to Code, Status, Shipment Date');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReadyDocumentPassesWithoutBeingChanged()
    var
        SalesHeader: Record "Sales Header";
        Snapshot: Record "Sales Header";
        Stored: Record "Sales Header";
    begin
        // [SCENARIO] A released order with a Ship-to Code shipping on the work date passes, untouched
        // [GIVEN] the work date pinned to 15 January 2024, and such an order exactly as stored in the database
        WorkDate(20240115D);
        CreateOrder(SalesHeader, true, SalesHeader.Status::Released, WorkDate());
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Snapshot := SalesHeader;

        // [WHEN] running the release checklist
        Assert.IsTrue(TryCheckReadyToShip(SalesHeader),
            StrSubstNo('Expected a released order with a Ship-to Code shipping on the work date (%1) to pass the checklist - the work date itself is not in the past, and the check must compare against the work date rather than the calendar date - but it was refused with: %2', WorkDate(), GetLastErrorText()));

        // [THEN] neither the record passed in nor the stored document changed
        AssertUnchanged(Snapshot, SalesHeader, 'the record passed to CheckReadyToShip');
        Stored.Get(Snapshot."Document Type", Snapshot."No.");
        AssertUnchanged(Snapshot, Stored, 'the stored sales order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FutureShipmentDateIsNotInThePast()
    var
        SalesHeader: Record "Sales Header";
        Any: Codeunit Any;
    begin
        // [SCENARIO] A shipment date after the work date passes the checklist
        // [GIVEN] the work date pinned to 15 January 2024, and a released order with a Ship-to Code shipping some days after it
        WorkDate(20240115D);
        CreateOrder(SalesHeader, true, SalesHeader.Status::Released, WorkDate() + Any.IntegerInRange(1, 60));

        // [WHEN] running the release checklist
        // [THEN] it passes
        Assert.IsTrue(TryCheckReadyToShip(SalesHeader),
            StrSubstNo('Expected a released order with a Ship-to Code shipping on %1, after work date %2, to pass the checklist - the check must compare against the work date rather than the calendar date - but it was refused with: %3', SalesHeader."Shipment Date", WorkDate(), GetLastErrorText()));
    end;

    local procedure CreateOrder(var SalesHeader: Record "Sales Header"; WithShipToCode: Boolean; Status: Enum "Sales Document Status"; ShipmentDate: Date)
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader."Ship-to Code" := '';
        if WithShipToCode then begin
            LibrarySales.CreateShipToAddress(ShipToAddress, SalesHeader."Sell-to Customer No.");
            SalesHeader."Ship-to Code" := ShipToAddress.Code;
        end;
        SalesHeader.Status := Status;
        SalesHeader."Shipment Date" := ShipmentDate;
        SalesHeader.Modify();
    end;

    local procedure RandomUnreleasedStatus(var Any: Codeunit Any): Enum "Sales Document Status"
    begin
        case Any.IntegerInRange(1, 3) of
            1:
                exit("Sales Document Status"::Open);
            2:
                exit("Sales Document Status"::"Pending Approval");
            3:
                exit("Sales Document Status"::"Pending Prepayment");
        end;
    end;

    local procedure RefusedWith(var SalesHeader: Record "Sales Header"; Problem: Text): Text
    begin
        ClearLastError();
        if TryCheckReadyToShip(SalesHeader) then
            Assert.Fail(StrSubstNo('Expected CheckReadyToShip to refuse sales order %1 with %2, but it passed', SalesHeader."No.", Problem));
        exit(GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryCheckReadyToShip(var SalesHeader: Record "Sales Header")
    var
        ReleaseChecklist: Codeunit "Release Checklist";
    begin
        ReleaseChecklist.CheckReadyToShip(SalesHeader);
    end;

    // The expected wording is generated by the platform on a copy of the same document,
    // so only the platform's own field checks can produce a matching text.
    local procedure PlatformBlankShipToCodeText(Throwaway: Record "Sales Header"): Text
    begin
        asserterror Throwaway.TestField("Ship-to Code");
        exit(GetLastErrorText());
    end;

    local procedure PlatformStatusMustBeReleasedText(Throwaway: Record "Sales Header"): Text
    begin
        asserterror Throwaway.TestField(Status, Throwaway.Status::Released);
        exit(GetLastErrorText());
    end;

    local procedure PlatformPastShipmentDateText(Throwaway: Record "Sales Header"): Text
    begin
        asserterror Throwaway.FieldError("Shipment Date", PastShipmentDateTxt);
        exit(GetLastErrorText());
    end;

    local procedure AssertUnchanged(Expected: Record "Sales Header"; Actual: Record "Sales Header"; What: Text)
    var
        ExpectedRef: RecordRef;
        ActualRef: RecordRef;
        ExpectedField: FieldRef;
        Index: Integer;
    begin
        ExpectedRef.GetTable(Expected);
        ActualRef.GetTable(Actual);
        for Index := 1 to ExpectedRef.FieldCount() do begin
            ExpectedField := ExpectedRef.FieldIndex(Index);
            if IsComparable(ExpectedField) then
                Assert.AreEqual(Format(ExpectedField.Value()), Format(ActualRef.Field(ExpectedField.Number()).Value()),
                    StrSubstNo('Expected CheckReadyToShip to leave %1 untouched when the document passes, but "%2" changed', What, ExpectedField.Caption()));
        end;
    end;

    local procedure IsComparable(var FldRef: FieldRef): Boolean
    begin
        if FldRef.Class() <> FieldClass::Normal then
            exit(false);
        exit(not (FldRef.Type() in [FieldType::Blob, FieldType::Media, FieldType::MediaSet]));
    end;
}
