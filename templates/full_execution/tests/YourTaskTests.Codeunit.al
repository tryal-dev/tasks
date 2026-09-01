// Grading tests. Trusted code executed in the platform's containers — every
// task PR gets human review before merge.
//
// - Reference the user's objects BY NAME ("Your Codeunit Name"), never by ID:
//   all object IDs are remapped at run time. Any 50000+ id is fine here.
// - All standard Microsoft test libraries are available (Assert,
//   "Library - Dialog Handler", "Library - Sales", "Library - Random", Any,
//   "Library - Variable Storage", ...) — reference them by exact object
//   name. APIs: .claude/skills/create-task/references/test-libraries.md
// - One behavior per [Test] with a message that tells the user WHAT failed —
//   per-test pass/fail is shown to them.
codeunit 50900 "Your Task Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DescribeExpectedBehaviorHere()
    var
        Impl: Codeunit "Your Codeunit Name";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(42.0, Impl.YourProcedure(21), 'Expected the result to be doubled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DescribeAnEdgeCaseHere()
    var
        Impl: Codeunit "Your Codeunit Name";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(0.0, Impl.YourProcedure(0), 'Expected zero input to yield zero');
    end;
}
