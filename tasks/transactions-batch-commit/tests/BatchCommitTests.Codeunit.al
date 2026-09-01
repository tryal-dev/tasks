codeunit 50900 "Batch Commit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ImportsEveryPendingLineOfTheBatch()
    var
        OrderImportBatch: Codeunit "Order Import Batch";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] A batch of three valid lines yields three imported orders
        CreateLine('TBC-T01', 10, 'CUST-A', Any.DecimalInRange(1, 500, 2));
        CreateLine('TBC-T01', 20, 'CUST-B', Any.DecimalInRange(1, 500, 2));
        CreateLine('TBC-T01', 30, 'CUST-C', Any.DecimalInRange(1, 500, 2));

        OrderImportBatch.ImportBatch('TBC-T01');

        Assert.AreEqual(3, ImportedOrderCount('TBC-T01'),
            'Expected exactly one imported order per pending line of the batch');
        AssertLineHasStatus('TBC-T01', 10, "Order Import Status"::Imported);
        AssertLineHasStatus('TBC-T01', 20, "Order Import Status"::Imported);
        AssertLineHasStatus('TBC-T01', 30, "Order Import Status"::Imported);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ImportCopiesTheLineFieldsToTheImportedOrder()
    var
        ImportedOrder: Record "Imported Order";
        OrderImportBatch: Codeunit "Order Import Batch";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CustomerNo: Code[20];
        LineQuantity: Decimal;
    begin
        // [SCENARIO] Customer No. and Quantity travel line -> imported order
        CustomerNo := CopyStr('T02-' + UpperCase(Any.AlphabeticText(10)), 1, 20);
        LineQuantity := Any.DecimalInRange(1, 900, 2);
        CreateLine('TBC-T02', 10, CustomerNo, LineQuantity);

        OrderImportBatch.ImportBatch('TBC-T02');

        Assert.IsTrue(ImportedOrder.Get('TBC-T02', 10),
            'Expected an imported order with the batch code and line no. of the imported line');
        Assert.AreEqual(CustomerNo, ImportedOrder."Customer No.",
            'Expected the line''s customer no. on its imported order');
        Assert.AreEqual(LineQuantity, ImportedOrder.Quantity,
            'Expected the line''s quantity on its imported order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure BlankCustomerNoFailsWithTheFieldGuardError()
    var
        OrderImportBatch: Codeunit "Order Import Batch";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A line without a customer fails the run with the field-guard error
        CreateLine('TBC-T03', 10, '', 5);
        Commit();

        asserterror OrderImportBatch.ImportBatch('TBC-T03');

        AssertErrorContains('Customer No.');
        AssertErrorContains('must have a value');
        Assert.IsFalse(ImportedOrderExists('TBC-T03', 10),
            'Expected no imported order for a line that failed the Customer No. guard');
        AssertLineHasStatus('TBC-T03', 10, "Order Import Status"::Pending);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ZeroQuantityFailsWithMustBePositive()
    var
        OrderImportBatch: Codeunit "Order Import Batch";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A zero-quantity line fails the run with the quantity guard error
        CreateLine('TBC-T04', 10, 'CUST-A', 0);
        Commit();

        asserterror OrderImportBatch.ImportBatch('TBC-T04');

        AssertErrorContains('must be positive');
        Assert.IsFalse(ImportedOrderExists('TBC-T04', 10),
            'Expected no imported order for a line that failed the quantity guard');
        AssertLineHasStatus('TBC-T04', 10, "Order Import Status"::Pending);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure NegativeQuantityFailsWithMustBePositive()
    var
        OrderImportBatch: Codeunit "Order Import Batch";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] A negative-quantity line fails the run with the quantity guard error
        CreateLine('TBC-T05', 10, 'CUST-A', -Any.DecimalInRange(1, 500, 2));
        Commit();

        asserterror OrderImportBatch.ImportBatch('TBC-T05');

        AssertErrorContains('must be positive');
        Assert.IsFalse(ImportedOrderExists('TBC-T05', 10),
            'Expected no imported order for a line that failed the quantity guard');
        AssertLineHasStatus('TBC-T05', 10, "Order Import Status"::Pending);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure LinesImportedBeforeThePoisonLineSurviveTheFailure()
    var
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The two lines imported before the poison line are still imported after the run fails
        SeedPoisonedBatch('TBC-T06');

        asserterror ImportBatch('TBC-T06');

        AssertErrorContains('must have a value');
        Assert.IsTrue(ImportedOrderExists('TBC-T06', 10),
            'Expected the imported order of line 10 to still exist after the poison line failed — a failing line must not undo its predecessors');
        Assert.IsTrue(ImportedOrderExists('TBC-T06', 20),
            'Expected the imported order of line 20 to still exist after the poison line failed — a failing line must not undo its predecessors');
        AssertLineHasStatus('TBC-T06', 10, "Order Import Status"::Imported);
        AssertLineHasStatus('TBC-T06', 20, "Order Import Status"::Imported);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ThePoisonLineAndItsSuccessorsStayPending()
    var
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The poison line leaves nothing behind and the line after it is not touched
        SeedPoisonedBatch('TBC-T07');

        asserterror ImportBatch('TBC-T07');

        AssertErrorContains('must have a value');
        Assert.IsFalse(ImportedOrderExists('TBC-T07', 30),
            'Expected the failing line to leave no imported order behind');
        AssertLineHasStatus('TBC-T07', 30, "Order Import Status"::Pending);
        Assert.IsFalse(ImportedOrderExists('TBC-T07', 40),
            'Expected no imported order for the line after the poison line — the run stops at the failure');
        AssertLineHasStatus('TBC-T07', 40, "Order Import Status"::Pending);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure RepairedBatchResumesWithoutDuplicates()
    var
        OrderImportLine: Record "Order Import Line";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] After the poison line is repaired, a second run finishes the batch exactly once
        SeedPoisonedBatch('TBC-T08');
        asserterror ImportBatch('TBC-T08');
        OrderImportLine.Get('TBC-T08', 30);
        OrderImportLine."Customer No." := 'CUST-FIX';
        OrderImportLine.Modify();

        ImportBatch('TBC-T08');

        Assert.AreEqual(4, ImportedOrderCount('TBC-T08'),
            'Expected the rerun to import the repaired line and its successor exactly once — four imported orders in total, no duplicates for the lines imported first');
        AssertLineHasStatus('TBC-T08', 10, "Order Import Status"::Imported);
        AssertLineHasStatus('TBC-T08', 20, "Order Import Status"::Imported);
        AssertLineHasStatus('TBC-T08', 30, "Order Import Status"::Imported);
        AssertLineHasStatus('TBC-T08', 40, "Order Import Status"::Imported);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ImportRunsOnlyOnTheGivenBatch()
    var
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Importing one batch ignores a neighbour batch entirely
        // [GIVEN] the neighbour's only line is poison, so an unscoped run fails loudly
        CreateLine('TBC-T09A', 10, 'CUST-A', 10);
        CreateLine('TBC-T09A', 20, 'CUST-B', 20);
        CreateLine('TBC-T09B', 10, '', 5);

        ImportBatch('TBC-T09A');

        Assert.AreEqual(2, ImportedOrderCount('TBC-T09A'),
            'Expected both lines of the given batch to be imported');
        Assert.AreEqual(0, ImportedOrderCount('TBC-T09B'),
            'Expected no imported orders for the neighbour batch — importing one batch must not touch another');
        AssertLineHasStatus('TBC-T09B', 10, "Order Import Status"::Pending);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AlreadyImportedLinesAreNotImportedAgain()
    var
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A line already marked Imported is invisible to the run
        CreateLine('TBC-T10', 10, 'CUST-A', 5, "Order Import Status"::Imported);
        CreateLine('TBC-T10', 20, 'CUST-B', 7);

        ImportBatch('TBC-T10');

        Assert.IsFalse(ImportedOrderExists('TBC-T10', 10),
            'Expected no imported order for a line already marked Imported — the run must only pick up pending lines');
        Assert.IsTrue(ImportedOrderExists('TBC-T10', 20),
            'Expected the pending line to be imported');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure EmptyBatchIsAQuietNoOp()
    var
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A batch with no pending lines raises no error and writes nothing
        ImportBatch('TBC-T11');

        Assert.AreEqual(0, ImportedOrderCount('TBC-T11'),
            'Expected a batch with no pending lines to import nothing');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ALineFailingAtInsertTimeStillSparesItsPredecessors()
    var
        ImportedOrder: Record "Imported Order";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A crash while writing line 30 — not a guard error — must still leave lines 10 and 20 imported
        // [GIVEN] a stray imported order already occupies line 30's key, so its Insert fails mid-run
        CreateLine('TBC-T12', 10, 'CUST-A', 10);
        CreateLine('TBC-T12', 20, 'CUST-B', 20);
        CreateLine('TBC-T12', 30, 'CUST-C', 30);
        CreateLine('TBC-T12', 40, 'CUST-D', 40);
        ImportedOrder.Init();
        ImportedOrder."Batch Code" := 'TBC-T12';
        ImportedOrder."Line No." := 30;
        ImportedOrder."Customer No." := 'STRAY';
        ImportedOrder.Quantity := 1;
        ImportedOrder.Insert();
        Commit();

        asserterror ImportBatch('TBC-T12');

        AssertErrorContains('already exists');
        Assert.IsTrue(ImportedOrderExists('TBC-T12', 10),
            'Expected the imported order of line 10 to still exist after a later line crashed at insert time — every line must be made permanent as soon as it is imported');
        Assert.IsTrue(ImportedOrderExists('TBC-T12', 20),
            'Expected the imported order of line 20 to still exist after a later line crashed at insert time — every line must be made permanent as soon as it is imported');
        AssertLineHasStatus('TBC-T12', 30, "Order Import Status"::Pending);
        Assert.IsFalse(ImportedOrderExists('TBC-T12', 40),
            'Expected no imported order for the line after the crashing line — the run stops at the failure');
    end;

    local procedure ImportBatch(BatchCode: Code[20])
    var
        OrderImportBatch: Codeunit "Order Import Batch";
    begin
        OrderImportBatch.ImportBatch(BatchCode);
    end;

    local procedure CreateLine(BatchCode: Code[20]; LineNo: Integer; CustomerNo: Code[20]; LineQuantity: Decimal)
    begin
        CreateLine(BatchCode, LineNo, CustomerNo, LineQuantity, "Order Import Status"::Pending);
    end;

    local procedure CreateLine(BatchCode: Code[20]; LineNo: Integer; CustomerNo: Code[20]; LineQuantity: Decimal; LineStatus: Enum "Order Import Status")
    var
        OrderImportLine: Record "Order Import Line";
    begin
        OrderImportLine.Init();
        OrderImportLine."Batch Code" := BatchCode;
        OrderImportLine."Line No." := LineNo;
        OrderImportLine."Customer No." := CustomerNo;
        OrderImportLine.Quantity := LineQuantity;
        OrderImportLine.Status := LineStatus;
        OrderImportLine.Insert();
    end;

    local procedure SeedPoisonedBatch(BatchCode: Code[20])
    var
        Any: Codeunit Any;
    begin
        CreateLine(BatchCode, 10, 'CUST-A', Any.DecimalInRange(1, 500, 2));
        CreateLine(BatchCode, 20, 'CUST-B', Any.DecimalInRange(1, 500, 2));
        CreateLine(BatchCode, 30, '', Any.DecimalInRange(1, 500, 2));
        CreateLine(BatchCode, 40, 'CUST-D', Any.DecimalInRange(1, 500, 2));
        // The seeded lines are committed so the poison error can only roll
        // back the run's own writes, never the test's arrangement.
        Commit();
    end;

    local procedure ImportedOrderCount(BatchCode: Code[20]): Integer
    var
        ImportedOrder: Record "Imported Order";
    begin
        ImportedOrder.SetRange("Batch Code", BatchCode);
        exit(ImportedOrder.Count());
    end;

    local procedure ImportedOrderExists(BatchCode: Code[20]; LineNo: Integer): Boolean
    var
        ImportedOrder: Record "Imported Order";
    begin
        exit(ImportedOrder.Get(BatchCode, LineNo));
    end;

    local procedure AssertLineHasStatus(BatchCode: Code[20]; LineNo: Integer; ExpectedStatus: Enum "Order Import Status")
    var
        OrderImportLine: Record "Order Import Line";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(OrderImportLine.Get(BatchCode, LineNo),
            StrSubstNo('Expected line %1 of batch %2 to still exist in the import table', LineNo, BatchCode));
        Assert.AreEqual(Format(ExpectedStatus), Format(OrderImportLine.Status),
            StrSubstNo('Expected line %1 of batch %2 to have status %3', LineNo, BatchCode, ExpectedStatus));
    end;

    local procedure AssertErrorContains(Fragment: Text)
    var
        Assert: Codeunit Assert;
        ActualError: Text;
    begin
        ActualError := GetLastErrorText();
        Assert.IsTrue(LowerCase(ActualError).Contains(LowerCase(Fragment)),
            StrSubstNo('Expected the import error to contain "%1", got: %2', Fragment, ActualError));
    end;
}
