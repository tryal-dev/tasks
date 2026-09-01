codeunit 50900 "Import Order Planner Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NothingStagedEmptiesThePassedListAndAddsNothing()
    var
        ImportOrderPlanner: Codeunit "Import Order Planner";
        Assert: Codeunit Assert;
        ImportOrder: List of [Integer];
    begin
        // [SCENARIO] GetImportOrder empties whatever the caller's list held before filling it
        ImportOrder.Add(99999);

        ImportOrderPlanner.GetImportOrder(ImportOrder);

        Assert.AreEqual(0, ImportOrder.Count(),
            'Expected GetImportOrder to first empty the passed list, so with nothing staged it comes back empty');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleStagedTableIsTheWholeOrder()
    var
        ImportOrderPlanner: Codeunit "Import Order Planner";
        Assert: Codeunit Assert;
        ImportOrder: List of [Integer];
    begin
        ImportOrderPlanner.AddTable(50110);

        ImportOrderPlanner.GetImportOrder(ImportOrder);

        Assert.AreEqual('50110', OrderAsText(ImportOrder),
            'Expected the one staged table to be the entire import order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IndependentTablesComeOutByAscendingTableId()
    var
        ImportOrderPlanner: Codeunit "Import Order Planner";
        Assert: Codeunit Assert;
        ImportOrder: List of [Integer];
    begin
        // [SCENARIO] with no dependencies at all, the tie-break rule alone dictates the order
        ImportOrderPlanner.AddTable(50140);
        ImportOrderPlanner.AddTable(50110);
        ImportOrderPlanner.AddTable(50130);
        ImportOrderPlanner.AddTable(50120);

        ImportOrderPlanner.GetImportOrder(ImportOrder);

        Assert.AreEqual('50110,50120,50130,50140', OrderAsText(ImportOrder),
            'Expected tables without dependencies to come out in ascending table ID order, not in staging order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParentComesBeforeChildRegardlessOfStagingOrder()
    var
        ImportOrderPlanner: Codeunit "Import Order Planner";
        Assert: Codeunit Assert;
        ImportOrder: List of [Integer];
    begin
        // [SCENARIO] the child has the lower ID and is staged first — only the dependency can put the parent in front
        ImportOrderPlanner.AddTable(50110);
        ImportOrderPlanner.AddTable(50150);
        ImportOrderPlanner.AddDependency(50110, 50150);

        ImportOrderPlanner.GetImportOrder(ImportOrder);

        Assert.AreEqual('50150,50110', OrderAsText(ImportOrder),
            'Expected the depended-on table 50150 to be imported before 50110, even though 50110 has the lower ID and was staged first');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LowestReadyTableGoesFirstWhileBlockedTablesWait()
    var
        ImportOrderPlanner: Codeunit "Import Order Planner";
        Assert: Codeunit Assert;
        ImportOrder: List of [Integer];
    begin
        // [SCENARIO] 50110 must wait for 50140, so the ready tables 50120, 50130, 50140 go first, lowest ID each round
        ImportOrderPlanner.AddTable(50110);
        ImportOrderPlanner.AddTable(50120);
        ImportOrderPlanner.AddTable(50130);
        ImportOrderPlanner.AddTable(50140);
        ImportOrderPlanner.AddDependency(50110, 50140);

        ImportOrderPlanner.GetImportOrder(ImportOrder);

        Assert.AreEqual('50120,50130,50140,50110', OrderAsText(ImportOrder),
            'Expected 50110 to wait for 50140 while the other tables go first in ascending ID order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedDependencyChainPutsParentsFirst()
    var
        ImportOrderPlanner: Codeunit "Import Order Planner";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ImportOrder: List of [Integer];
        TableA: Integer;
        TableB: Integer;
        TableC: Integer;
        TableD: Integer;
        Expected: Text;
    begin
        // [SCENARIO] four generated table IDs (A < B < C < D); A depends on D, D depends on B — the only valid deterministic order is B, C, D, A
        TableA := Any.IntegerInRange(60000, 70000);
        TableB := TableA + Any.IntegerInRange(1, 100);
        TableC := TableB + Any.IntegerInRange(1, 100);
        TableD := TableC + Any.IntegerInRange(1, 100);
        ImportOrderPlanner.AddTable(TableA);
        ImportOrderPlanner.AddTable(TableB);
        ImportOrderPlanner.AddTable(TableC);
        ImportOrderPlanner.AddTable(TableD);
        ImportOrderPlanner.AddDependency(TableA, TableD);
        ImportOrderPlanner.AddDependency(TableD, TableB);

        ImportOrderPlanner.GetImportOrder(ImportOrder);

        Expected := StrSubstNo('%1,%2,%3,%4', TableB, TableC, TableD, TableA);
        Assert.AreEqual(Expected, OrderAsText(ImportOrder),
            'Expected the generated chain (lowest ID depends on highest, highest depends on second-lowest) to come out parents-first with the lowest ready ID each round');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SelfReferencingTableImportsInItsNormalPosition()
    var
        ImportOrderPlanner: Codeunit "Import Order Planner";
        Assert: Codeunit Assert;
        ImportOrder: List of [Integer];
    begin
        // [SCENARIO] an Item Category-style hierarchy: the table references itself, which is not a cycle
        ImportOrderPlanner.AddTable(50110);
        ImportOrderPlanner.AddTable(50120);
        ImportOrderPlanner.AddDependency(50110, 50110);

        ImportOrderPlanner.GetImportOrder(ImportOrder);

        Assert.AreEqual('50110,50120', OrderAsText(ImportOrder),
            'Expected a self-referencing table to import in its normal position — a table never waits for itself');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RestagingAndDuplicatePairsHaveNoExtraEffect()
    var
        ImportOrderPlanner: Codeunit "Import Order Planner";
        Assert: Codeunit Assert;
        ImportOrder: List of [Integer];
    begin
        ImportOrderPlanner.AddTable(50110);
        ImportOrderPlanner.AddTable(50110);
        ImportOrderPlanner.AddDependency(50110, 50120);
        ImportOrderPlanner.AddDependency(50110, 50120);
        ImportOrderPlanner.AddTable(50120);

        ImportOrderPlanner.GetImportOrder(ImportOrder);

        Assert.AreEqual('50120,50110', OrderAsText(ImportOrder),
            'Expected each table exactly once in the order, no matter how often it was staged or a pair was registered');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TwoTableCycleErrorsNamingBothTables()
    var
        ImportOrderPlanner: Codeunit "Import Order Planner";
        Assert: Codeunit Assert;
        ImportOrder: List of [Integer];
    begin
        ImportOrderPlanner.AddTable(50120);
        ImportOrderPlanner.AddTable(50110);
        ImportOrderPlanner.AddDependency(50110, 50120);
        ImportOrderPlanner.AddDependency(50120, 50110);

        asserterror ImportOrderPlanner.GetImportOrder(ImportOrder);

        Assert.AreEqual('No valid import order exists. Tables that cannot be imported: 50110, 50120.', GetLastErrorText(),
            'Expected the two-table cycle to fail with exactly the promised error message, naming both tables in ascending ID order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TablesStuckBehindACycleAreNamedButImportableOnesAreNot()
    var
        ImportOrderPlanner: Codeunit "Import Order Planner";
        Assert: Codeunit Assert;
        ImportOrder: List of [Integer];
        ActualError: Text;
    begin
        // [SCENARIO] 50111 and 50113 form a cycle, 50115 depends on 50113, 50117 is free — the error names exactly the first three
        ImportOrderPlanner.AddTable(50117);
        ImportOrderPlanner.AddTable(50115);
        ImportOrderPlanner.AddTable(50113);
        ImportOrderPlanner.AddTable(50111);
        ImportOrderPlanner.AddDependency(50111, 50113);
        ImportOrderPlanner.AddDependency(50113, 50111);
        ImportOrderPlanner.AddDependency(50115, 50113);

        asserterror ImportOrderPlanner.GetImportOrder(ImportOrder);

        ActualError := GetLastErrorText();
        Assert.IsFalse(ActualError.Contains('50117'),
            StrSubstNo('Expected the importable table 50117 not to be named among the tables that cannot be imported, got: %1', ActualError));
        Assert.AreEqual('No valid import order exists. Tables that cannot be imported: 50111, 50113, 50115.', ActualError,
            'Expected exactly the cycle tables and the table stuck behind them, in ascending ID order, and nothing else in the error message');
    end;

    local procedure OrderAsText(ImportOrder: List of [Integer]): Text
    var
        Result: TextBuilder;
        TableID: Integer;
    begin
        foreach TableID in ImportOrder do begin
            if Result.Length() > 0 then
                Result.Append(',');
            Result.Append(Format(TableID));
        end;
        exit(Result.ToText());
    end;
}
