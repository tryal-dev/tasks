codeunit 50900 "Project Plan vs Actual Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PlannedQtySumsTheTasksBudgetLines()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        OtherJobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        LibraryJob: Codeunit "Library - Job";
        PlanVsActual: Codeunit "Project Plan vs Actual";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        QtyA: Decimal;
        QtyB: Decimal;
    begin
        // [SCENARIO] Planned quantity is the sum of the task's own budget lines
        QtyA := Any.IntegerInRange(5, 40);
        QtyB := Any.IntegerInRange(5, 40);
        CreateProjectWithTask(true, Job, JobTask);
        AddBudgetLine(JobTask, NewResourceNo(), QtyA, JobPlanningLine);
        AddBudgetLine(JobTask, NewResourceNo(), QtyB, JobPlanningLine);
        LibraryJob.CreateJobTask(Job, OtherJobTask);
        AddBudgetLine(OtherJobTask, NewResourceNo(), Any.IntegerInRange(5, 40), JobPlanningLine);

        Assert.AreEqual(QtyA + QtyB, PlanVsActual.PlannedQty(Job."No.", JobTask."Job Task No."),
            'Expected the planned quantity to be the sum of the budget planning lines of exactly this task — the other task''s plan must not leak in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PlannedQtyCountsBothTypeLinesButNotBillableLines()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        LibraryJob: Codeunit "Library - Job";
        PlanVsActual: Codeunit "Project Plan vs Actual";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        BudgetQty: Decimal;
        BothQty: Decimal;
    begin
        // [SCENARIO] Budget and Both Budget and Billable lines count toward the plan; Billable-only lines do not
        BudgetQty := Any.IntegerInRange(5, 40);
        BothQty := Any.IntegerInRange(5, 40);
        CreateProjectWithTask(false, Job, JobTask);
        AddBudgetLine(JobTask, NewResourceNo(), BudgetQty, JobPlanningLine);
        LibraryJob.CreateJobPlanningLine(
            JobTask, LibraryJob.PlanningLineTypeBoth(), LibraryJob.ResourceType(), NewResourceNo(), BothQty, JobPlanningLine);
        LibraryJob.CreateJobPlanningLine(
            JobTask, LibraryJob.PlanningLineTypeContract(), LibraryJob.ResourceType(), NewResourceNo(),
            Any.IntegerInRange(5, 40), JobPlanningLine);

        Assert.AreEqual(BudgetQty + BothQty, PlanVsActual.PlannedQty(Job."No.", JobTask."Job Task No."),
            'Expected Budget and Both Budget and Billable lines to count toward the plan, and the Billable-only line to be excluded');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PlannedQtyIsZeroForATaskWithUsageButNoPlan()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PlanVsActual: Codeunit "Project Plan vs Actual";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] A task where usage was posted without any planning lines has a planned quantity of 0
        CreateProjectWithTask(false, Job, JobTask);
        PostUsage(JobTask, NewResourceNo(), Any.IntegerInRange(3, 8));

        Assert.AreEqual(0, PlanVsActual.PlannedQty(Job."No.", JobTask."Job Task No."),
            'Expected a task with posted usage but no planning lines to report a planned quantity of 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostedQtySumsEveryUsagePostingOnTheTask()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        OtherJobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        OtherJobPlanningLine: Record "Job Planning Line";
        LibraryJob: Codeunit "Library - Job";
        PlanVsActual: Codeunit "Project Plan vs Actual";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        UsageA: Decimal;
        UsageB: Decimal;
    begin
        // [SCENARIO] Posted quantity adds up all usage postings of the task and only of the task
        UsageA := Any.IntegerInRange(3, 8);
        UsageB := Any.IntegerInRange(3, 8);
        CreateProjectWithTask(true, Job, JobTask);
        AddBudgetLine(JobTask, NewResourceNo(), Any.IntegerInRange(20, 40), JobPlanningLine);
        PostUsageAgainstPlan(JobPlanningLine, UsageA);
        PostUsageAgainstPlan(JobPlanningLine, UsageB);
        LibraryJob.CreateJobTask(Job, OtherJobTask);
        AddBudgetLine(OtherJobTask, NewResourceNo(), Any.IntegerInRange(20, 40), OtherJobPlanningLine);
        PostUsageAgainstPlan(OtherJobPlanningLine, Any.IntegerInRange(3, 8));

        Assert.AreEqual(UsageA + UsageB, PlanVsActual.PostedQty(Job."No.", JobTask."Job Task No."),
            'Expected the posted quantity to add up both usage postings on the task and to exclude the other task''s usage');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostedQtyIgnoresSaleLedgerEntries()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PlanVsActual: Codeunit "Project Plan vs Actual";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        UsageQty: Decimal;
    begin
        // [SCENARIO] Only Usage entries count as posted; Sale entries written by invoicing do not
        UsageQty := Any.IntegerInRange(3, 8);
        CreateProjectWithTask(false, Job, JobTask);
        PostUsage(JobTask, NewResourceNo(), UsageQty);
        // Sale decoys of both signs, so filtering on the quantity's sign instead
        // of on the entry type cannot reproduce the expected sum.
        InsertSaleLedgerEntry(JobTask, -Any.IntegerInRange(1, 5));
        InsertSaleLedgerEntry(JobTask, Any.IntegerInRange(1, 5));

        Assert.AreEqual(UsageQty, PlanVsActual.PostedQty(Job."No.", JobTask."Job Task No."),
            'Expected only Usage ledger entries to count as posted — the Sale entries written by invoicing must be ignored whatever their sign');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostedQtyShrinksWithANegativeCorrectionPosting()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PlanVsActual: Codeunit "Project Plan vs Actual";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ResourceNo: Code[20];
        UsageQty: Decimal;
        CorrectionQty: Decimal;
    begin
        // [SCENARIO] A negative usage posting (a correction) reduces the posted quantity
        UsageQty := Any.IntegerInRange(5, 10);
        CorrectionQty := Any.IntegerInRange(1, 4);
        CreateProjectWithTask(false, Job, JobTask);
        ResourceNo := NewResourceNo();
        PostUsage(JobTask, ResourceNo, UsageQty);
        PostUsage(JobTask, ResourceNo, -CorrectionQty);

        Assert.AreEqual(UsageQty - CorrectionQty, PlanVsActual.PostedQty(Job."No.", JobTask."Job Task No."),
            'Expected a negative usage posting — a correction — to reduce the posted quantity');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostedQtyComesFromTheLedgerOnAProjectWithoutUsageLink()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PlanVsActual: Codeunit "Project Plan vs Actual";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ResourceNo: Code[20];
        UsageQty: Decimal;
    begin
        // [SCENARIO] A project without "Apply Usage Link" still reports its posted usage
        UsageQty := Any.IntegerInRange(3, 8);
        CreateProjectWithTask(false, Job, JobTask);
        ResourceNo := NewResourceNo();
        AddBudgetLine(JobTask, ResourceNo, Any.IntegerInRange(20, 40), JobPlanningLine);
        PostUsage(JobTask, ResourceNo, UsageQty);

        Assert.AreEqual(UsageQty, PlanVsActual.PostedQty(Job."No.", JobTask."Job Task No."),
            'Expected the usage posted on the task to be reported even though the project does not apply a usage link — on such projects the planning line''s "Qty. Posted" stays 0 forever, so the posted figure has to come from the project ledger');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostedQtyIsZeroWhenNothingWasPosted()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PlanVsActual: Codeunit "Project Plan vs Actual";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] A planned task with no usage postings reports 0 posted
        CreateProjectWithTask(true, Job, JobTask);
        AddBudgetLine(JobTask, NewResourceNo(), Any.IntegerInRange(20, 40), JobPlanningLine);

        Assert.AreEqual(0, PlanVsActual.PostedQty(Job."No.", JobTask."Job Task No."),
            'Expected a planned task with no posted usage to report a posted quantity of 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemainingQtyIsPlanMinusPostedOnALinkedProject()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PlanVsActual: Codeunit "Project Plan vs Actual";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        PlanQty: Decimal;
        UsageQty: Decimal;
    begin
        // [SCENARIO] Remaining is planned minus posted after a partial usage posting
        PlanQty := Any.IntegerInRange(20, 40);
        UsageQty := Any.IntegerInRange(3, 8);
        CreateProjectWithTask(true, Job, JobTask);
        AddBudgetLine(JobTask, NewResourceNo(), PlanQty, JobPlanningLine);
        PostUsageAgainstPlan(JobPlanningLine, UsageQty);

        Assert.AreEqual(PlanQty - UsageQty, PlanVsActual.RemainingQty(Job."No.", JobTask."Job Task No."),
            'Expected the remaining quantity to be the planned quantity minus the posted usage');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemainingQtyIsCorrectOnAProjectWithoutUsageLink()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PlanVsActual: Codeunit "Project Plan vs Actual";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ResourceNo: Code[20];
        PlanQty: Decimal;
        UsageQty: Decimal;
    begin
        // [SCENARIO] Remaining still shrinks with posted usage when the project has no usage link
        PlanQty := Any.IntegerInRange(20, 40);
        UsageQty := Any.IntegerInRange(3, 8);
        CreateProjectWithTask(false, Job, JobTask);
        ResourceNo := NewResourceNo();
        AddBudgetLine(JobTask, ResourceNo, PlanQty, JobPlanningLine);
        PostUsage(JobTask, ResourceNo, UsageQty);

        Assert.AreEqual(PlanQty - UsageQty, PlanVsActual.RemainingQty(Job."No.", JobTask."Job Task No."),
            'Expected remaining = planned - posted even though the project does not apply a usage link — the planning line''s own "Remaining Qty." never moves on such projects');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemainingQtyGoesNegativeForUsageWithoutPlan()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PlanVsActual: Codeunit "Project Plan vs Actual";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        UsageQty: Decimal;
    begin
        // [SCENARIO] A task with usage but no plan reports minus its posted quantity
        UsageQty := Any.IntegerInRange(3, 8);
        CreateProjectWithTask(false, Job, JobTask);
        PostUsage(JobTask, NewResourceNo(), UsageQty);

        Assert.AreEqual(-UsageQty, PlanVsActual.RemainingQty(Job."No.", JobTask."Job Task No."),
            'Expected a task with usage but no plan to report a negative remainder: 0 planned minus the posted usage');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FiguresAreScopedToTheProjectNotJustTheTaskNo()
    var
        Job: Record Job;
        OtherJob: Record Job;
        JobTask: Record "Job Task";
        OtherJobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PlanVsActual: Codeunit "Project Plan vs Actual";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ResourceNo: Code[20];
        PlanQty: Decimal;
        UsageQty: Decimal;
    begin
        // [SCENARIO] Two projects share the same task number; each reports only its own figures
        PlanQty := Any.IntegerInRange(20, 40);
        UsageQty := Any.IntegerInRange(3, 8);
        CreateProject(false, Job);
        CreateTaskWithNo(Job, 'TRYAL-SHARED', JobTask);
        ResourceNo := NewResourceNo();
        AddBudgetLine(JobTask, ResourceNo, PlanQty, JobPlanningLine);
        PostUsage(JobTask, ResourceNo, UsageQty);
        CreateProject(false, OtherJob);
        CreateTaskWithNo(OtherJob, 'TRYAL-SHARED', OtherJobTask);
        AddBudgetLine(OtherJobTask, NewResourceNo(), Any.IntegerInRange(50, 90), JobPlanningLine);
        PostUsage(OtherJobTask, NewResourceNo(), Any.IntegerInRange(10, 15));

        Assert.AreEqual(PlanQty, PlanVsActual.PlannedQty(Job."No.", JobTask."Job Task No."),
            'Expected the planned quantity of the first project''s task only — the other project''s task with the identical task number must not leak in');
        Assert.AreEqual(UsageQty, PlanVsActual.PostedQty(Job."No.", JobTask."Job Task No."),
            'Expected the posted quantity of the first project''s task only — the other project''s usage on the identically numbered task must not leak in');
    end;

    local procedure CreateProject(ApplyUsageLink: Boolean; var Job: Record Job)
    var
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", ApplyUsageLink);
        Job.Modify(true);
    end;

    local procedure CreateProjectWithTask(ApplyUsageLink: Boolean; var Job: Record Job; var JobTask: Record "Job Task")
    var
        LibraryJob: Codeunit "Library - Job";
    begin
        CreateProject(ApplyUsageLink, Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateTaskWithNo(Job: Record Job; TaskNo: Code[20]; var JobTask: Record "Job Task")
    begin
        JobTask.Init();
        JobTask.Validate("Job No.", Job."No.");
        JobTask.Validate("Job Task No.", TaskNo);
        JobTask.Insert(true);
        JobTask.Validate("Job Task Type", JobTask."Job Task Type"::Posting);
        JobTask.Modify(true);
    end;

    local procedure NewResourceNo(): Code[20]
    var
        LibraryJob: Codeunit "Library - Job";
    begin
        exit(LibraryJob.FindConsumable(LibraryJob.ResourceType()));
    end;

    local procedure AddBudgetLine(JobTask: Record "Job Task"; ResourceNo: Code[20]; Qty: Decimal; var JobPlanningLine: Record "Job Planning Line")
    var
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJobPlanningLine(
            JobTask, LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ResourceType(), ResourceNo, Qty, JobPlanningLine);
    end;

    // Blank line type: posting must not create planning lines of its own,
    // and on a project without usage link nothing but the ledger entry is written.
    local procedure PostUsage(JobTask: Record "Job Task"; ResourceNo: Code[20]; Qty: Decimal)
    var
        JobJournalLine: Record "Job Journal Line";
        LibraryJob: Codeunit "Library - Job";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
    begin
        LibraryJob.CreateJobJournalLine(LibraryJob.UsageLineTypeBlank(), JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
        JobJournalLine.Validate("No.", ResourceNo);
        JobJournalLine.Validate(Quantity, Qty);
        JobJournalLine.Modify(true);
        JobJnlPostLine.RunWithCheck(JobJournalLine);
        // RunWithCheck posts but does not remove the journal line (batch posting does).
        // A stale line with a planning-line link would make the next posting's
        // Validate("Job Planning Line No.") raise an unhandled Confirm dialog.
        JobJournalLine.Delete(true);
    end;

    // Explicit link to the plan line makes the usage-link application deterministic
    // on linked projects: "Qty. Posted" moves and no extra planning line is created.
    local procedure PostUsageAgainstPlan(JobPlanningLine: Record "Job Planning Line"; Qty: Decimal)
    var
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        LibraryJob: Codeunit "Library - Job";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
    begin
        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        LibraryJob.CreateJobJournalLine(LibraryJob.UsageLineTypeBlank(), JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
        JobJournalLine.Validate("No.", JobPlanningLine."No.");
        JobJournalLine.Validate(Quantity, Qty);
        JobJournalLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        JobJournalLine.Modify(true);
        JobJnlPostLine.RunWithCheck(JobJournalLine);
        // See PostUsage: without this Delete a second posting against the same
        // planning line trips over the leftover line's link and shows a Confirm.
        JobJournalLine.Delete(true);
    end;

    local procedure InsertSaleLedgerEntry(JobTask: Record "Job Task"; Qty: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        LastJobLedgerEntry: Record "Job Ledger Entry";
    begin
        if LastJobLedgerEntry.FindLast() then;
        JobLedgerEntry.Init();
        JobLedgerEntry."Entry No." := LastJobLedgerEntry."Entry No." + 1;
        JobLedgerEntry."Job No." := JobTask."Job No.";
        JobLedgerEntry."Job Task No." := JobTask."Job Task No.";
        JobLedgerEntry."Entry Type" := JobLedgerEntry."Entry Type"::Sale;
        JobLedgerEntry."Posting Date" := WorkDate();
        JobLedgerEntry.Quantity := Qty;
        JobLedgerEntry.Insert();
    end;
}
