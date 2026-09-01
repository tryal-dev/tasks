codeunit 50900 "Contract Archiver Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveRowCarriesTheContractFields()
    var
        ContractArchiver: Codeunit "Contract Archiver";
        Any: Codeunit Any;
        ArchiveRef: RecordRef;
        CustomerName: Text[100];
        MonthlyFee: Decimal;
        StartDate: Date;
        ArchivedName: Text[100];
        ArchivedFee: Decimal;
        ArchivedStart: Date;
    begin
        // [SCENARIO] Archiving copies the contract's stored fields into the archive row
        // Fill the field to MaxStrLen so an archive "Customer Name" shorter
        // than Text[100] fails (overflow error or truncated-value mismatch).
        CustomerName := CopyStr('TRYAL-A1 ' + Any.AlphabeticText(MaxStrLen(CustomerName)), 1, MaxStrLen(CustomerName));
        MonthlyFee := Any.DecimalInRange(100, 2000, 2);
        StartDate := Any.DateInRange(20240101D, 1, 300);
        CreateContract('TRYAL-A1', CustomerName, MonthlyFee, StartDate);

        ContractArchiver.Archive('TRYAL-A1', 20250601D);

        OpenArchiveRow(ArchiveRef, 'TRYAL-A1');
        ArchivedName := FieldByName(ArchiveRef, 'Customer Name').Value();
        ArchivedFee := FieldByName(ArchiveRef, 'Monthly Fee').Value();
        ArchivedStart := FieldByName(ArchiveRef, 'Start Date').Value();
        Assert.AreEqual(CustomerName, ArchivedName,
            'Expected "Customer Name" to be copied onto the archive row');
        Assert.AreEqual(MonthlyFee, ArchivedFee,
            'Expected "Monthly Fee" to be copied onto the archive row');
        Assert.AreEqual(StartDate, ArchivedStart,
            'Expected "Start Date" to be copied onto the archive row');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveStoresTheCalculatedChargeTotal()
    var
        ContractArchiver: Codeunit "Contract Archiver";
        Any: Codeunit Any;
        ArchiveRef: RecordRef;
        ChargeAmount: Decimal;
        ExpectedTotal: Decimal;
        ArchivedTotal: Decimal;
        LineNo: Integer;
    begin
        // [SCENARIO] The archive row holds the contract's calculated Total Charges at archive time
        CreateContract('TRYAL-A2', 'TRYAL-A2 Freight', 100, 20240101D);
        for LineNo := 1 to 3 do begin
            ChargeAmount := Any.DecimalInRange(10, 500, 2);
            AddCharge('TRYAL-A2', LineNo * 10000, ChargeAmount);
            ExpectedTotal += ChargeAmount;
        end;

        ContractArchiver.Archive('TRYAL-A2', 20250601D);

        OpenArchiveRow(ArchiveRef, 'TRYAL-A2');
        ArchivedTotal := FieldByName(ArchiveRef, 'Total Charges').Value();
        Assert.AreEqual(ExpectedTotal, ArchivedTotal,
            'Expected the archive row to hold the contract''s calculated "Total Charges" — TransferFields does not calculate a FlowField, a freshly read record carries 0 in it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchivedTotalStaysFrozenWhenChargesChangeAfterwards()
    var
        ContractArchiver: Codeunit "Contract Archiver";
        Any: Codeunit Any;
        ArchiveRef: RecordRef;
        FirstAmount: Decimal;
        SecondAmount: Decimal;
        ArchivedTotal: Decimal;
    begin
        // [SCENARIO] The archived total is a stored snapshot, not a live calculation over the charge lines
        FirstAmount := Any.DecimalInRange(10, 500, 2);
        SecondAmount := Any.DecimalInRange(10, 500, 2);
        CreateContract('TRYAL-A3', 'TRYAL-A3 Cranes', 100, 20240101D);
        AddCharge('TRYAL-A3', 10000, FirstAmount);
        AddCharge('TRYAL-A3', 20000, SecondAmount);

        ContractArchiver.Archive('TRYAL-A3', 20250601D);

        AddCharge('TRYAL-A3', 30000, 999.99);
        OpenArchiveRow(ArchiveRef, 'TRYAL-A3');
        ArchivedTotal := FieldByName(ArchiveRef, 'Total Charges').Value();
        Assert.AreEqual(FirstAmount + SecondAmount, ArchivedTotal,
            'Expected "Total Charges" on the archive to stay frozen at its archive-time value — it must be a normal field storing a snapshot, not a FlowField recalculated from the charge lines');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveStampsTheArchivedOnDate()
    var
        ContractArchiver: Codeunit "Contract Archiver";
        Any: Codeunit Any;
        ArchiveRef: RecordRef;
        ArchivedOn: Date;
        StampedOn: Date;
    begin
        // [SCENARIO] The date passed to Archive lands in the archive-only "Archived On" field
        ArchivedOn := Any.DateInRange(20250101D, 1, 500);
        CreateContract('TRYAL-A4', 'TRYAL-A4 Scaffolds', 100, 20240101D);

        ContractArchiver.Archive('TRYAL-A4', ArchivedOn);

        OpenArchiveRow(ArchiveRef, 'TRYAL-A4');
        StampedOn := FieldByName(ArchiveRef, 'Archived On').Value();
        Assert.AreEqual(ArchivedOn, StampedOn,
            'Expected "Archived On" to hold the date passed to Archive — TransferFields cannot fill an archive-only field, it must be set explicitly');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchivingRemovesTheOriginalContract()
    var
        RentalContract: Record "Rental Contract";
        ContractArchiver: Codeunit "Contract Archiver";
    begin
        // [SCENARIO] Archiving moves the contract: after the copy, the original row is gone
        CreateContract('TRYAL-A5', 'TRYAL-A5 Pumps', 100, 20240101D);

        ContractArchiver.Archive('TRYAL-A5', 20250601D);

        Assert.IsFalse(RentalContract.Get('TRYAL-A5'),
            'Expected the original "Rental Contract" row to be deleted after archiving — archiving moves the record, it does not duplicate it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchivingLeavesTheChargeLinesUntouched()
    var
        RentalCharge: Record "Rental Charge";
        ContractArchiver: Codeunit "Contract Archiver";
    begin
        // [SCENARIO] Only the contract moves — its charge lines stay in place
        CreateContract('TRYAL-A6', 'TRYAL-A6 Depot', 100, 20240101D);
        AddCharge('TRYAL-A6', 10000, 50);
        AddCharge('TRYAL-A6', 20000, 75);

        ContractArchiver.Archive('TRYAL-A6', 20250601D);

        RentalCharge.SetRange("Contract No.", 'TRYAL-A6');
        Assert.AreEqual(2, RentalCharge.Count(),
            'Expected both "Rental Charge" lines to survive archiving — the archiver moves only the contract, a separate cleanup job owns the lines');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchiveCopiesLegacyDataWithoutRunningValidation()
    var
        RentalContractArchive: Record "Rental Contract Archive";
        ContractArchiver: Codeunit "Contract Archiver";
        ArchiveRef: RecordRef;
        ArchivedFee: Decimal;
    begin
        // [SCENARIO] A stored value today's OnValidate would reject is archived exactly as it is
        CreateContract('TRYAL-A7', 'TRYAL-A7 Legacy Ltd', -250.75, 20200101D);

        ContractArchiver.Archive('TRYAL-A7', 20250601D);

        Assert.IsTrue(RentalContractArchive.Get('TRYAL-A7'),
            'Expected the legacy contract to be archived even though its "Monthly Fee" would fail today''s validation — the copy must be raw, no OnValidate runs');
        ArchiveRef.GetTable(RentalContractArchive);
        ArchivedFee := FieldByName(ArchiveRef, 'Monthly Fee').Value();
        Assert.AreEqual(-250.75, ArchivedFee,
            'Expected the negative legacy "Monthly Fee" to be archived exactly as stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ArchivingAMissingContractErrorsAndWritesNothing()
    var
        RentalContractArchive: Record "Rental Contract Archive";
        ContractArchiver: Codeunit "Contract Archiver";
    begin
        // [SCENARIO] Archiving a contract number that does not exist fails and leaves no archive row
        asserterror ContractArchiver.Archive('TRYAL-A8', 20250601D);

        Assert.IsFalse(RentalContractArchive.Get('TRYAL-A8'),
            'Expected no archive row for a contract number that does not exist — Archive must fail with an error and write nothing');
    end;

    local procedure CreateContract(ContractNo: Code[20]; CustomerName: Text[100]; MonthlyFee: Decimal; StartDate: Date)
    var
        RentalContract: Record "Rental Contract";
    begin
        RentalContract.Init();
        RentalContract."No." := ContractNo;
        RentalContract."Customer Name" := CustomerName;
        // Direct assignment on purpose: legacy rows may hold values today's
        // OnValidate would reject.
        RentalContract."Monthly Fee" := MonthlyFee;
        RentalContract."Start Date" := StartDate;
        RentalContract.Insert();
    end;

    local procedure AddCharge(ContractNo: Code[20]; LineNo: Integer; ChargeAmount: Decimal)
    var
        RentalCharge: Record "Rental Charge";
    begin
        RentalCharge.Init();
        RentalCharge."Contract No." := ContractNo;
        RentalCharge."Line No." := LineNo;
        RentalCharge.Amount := ChargeAmount;
        RentalCharge.Insert();
    end;

    local procedure OpenArchiveRow(var ArchiveRef: RecordRef; ContractNo: Code[20])
    var
        RentalContractArchive: Record "Rental Contract Archive";
    begin
        Assert.IsTrue(RentalContractArchive.Get(ContractNo),
            StrSubstNo('Expected an archive row whose "No." equals %1, the archived contract''s number', ContractNo));
        ArchiveRef.GetTable(RentalContractArchive);
    end;

    // The tests compile against the starter, whose archive table has only "No.",
    // so the fields the task asks for are reached by name at run time.
    local procedure FieldByName(var RecRef: RecordRef; FieldName: Text): FieldRef
    var
        FldRef: FieldRef;
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            if FldRef.Name() = FieldName then
                exit(FldRef);
        end;
        Assert.Fail(StrSubstNo('Expected table %1 to have a field named "%2"', RecRef.Name(), FieldName));
    end;
}
