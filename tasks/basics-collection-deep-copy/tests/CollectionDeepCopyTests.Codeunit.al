codeunit 50900 "Collection Deep Copy Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MatrixCopyContainsTheSameValues()
    var
        DeepCopy: Codeunit "Collection Deep Copy";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SourceMatrix: List of [List of [Integer]];
        CopiedMatrix: List of [List of [Integer]];
        CopiedRow: List of [Integer];
        FirstValue: Integer;
        SecondValue: Integer;
        ThirdValue: Integer;
    begin
        // [SCENARIO] The copy reproduces every inner list and every value in order
        FirstValue := Any.IntegerInRange(1, 1000);
        SecondValue := Any.IntegerInRange(1001, 2000);
        ThirdValue := Any.IntegerInRange(2001, 3000);
        AddRow(SourceMatrix, FirstValue, SecondValue);
        AddSingleValueRow(SourceMatrix, ThirdValue);

        CopiedMatrix := DeepCopy.CopyMatrix(SourceMatrix);

        Assert.AreEqual(2, CopiedMatrix.Count(), 'Expected the copy to contain the same number of inner lists as the source');
        CopiedRow := CopiedMatrix.Get(1);
        Assert.AreEqual(2, CopiedRow.Count(), 'Expected the first inner list of the copy to hold the same number of values as in the source');
        Assert.AreEqual(FirstValue, CopiedRow.Get(1), 'Expected the first value of the first inner list to be copied unchanged');
        Assert.AreEqual(SecondValue, CopiedRow.Get(2), 'Expected the second value of the first inner list to be copied unchanged');
        CopiedRow := CopiedMatrix.Get(2);
        Assert.AreEqual(1, CopiedRow.Count(), 'Expected the second inner list of the copy to hold the same number of values as in the source');
        Assert.AreEqual(ThirdValue, CopiedRow.Get(1), 'Expected the value of the second inner list to be copied unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MatrixCopyKeepsAnEmptyInnerListEmpty()
    var
        DeepCopy: Codeunit "Collection Deep Copy";
        Assert: Codeunit Assert;
        SourceMatrix: List of [List of [Integer]];
        CopiedMatrix: List of [List of [Integer]];
        CopiedRow: List of [Integer];
    begin
        // [SCENARIO] An empty inner list survives the copy as an empty inner list
        AddEmptyRow(SourceMatrix);
        AddSingleValueRow(SourceMatrix, 7);

        CopiedMatrix := DeepCopy.CopyMatrix(SourceMatrix);

        Assert.AreEqual(2, CopiedMatrix.Count(), 'Expected the copy to keep both inner lists, the empty one included');
        CopiedRow := CopiedMatrix.Get(1);
        Assert.AreEqual(0, CopiedRow.Count(), 'Expected the empty inner list of the source to come out empty in the copy');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddingToACopiedInnerListLeavesTheSourceUntouched()
    var
        DeepCopy: Codeunit "Collection Deep Copy";
        Assert: Codeunit Assert;
        SourceMatrix: List of [List of [Integer]];
        CopiedMatrix: List of [List of [Integer]];
        CopiedRow: List of [Integer];
        SourceRow: List of [Integer];
    begin
        // [SCENARIO] Mutating an inner list of the copy does not leak into the source
        AddRow(SourceMatrix, 10, 20);
        CopiedMatrix := DeepCopy.CopyMatrix(SourceMatrix);

        CopiedRow := CopiedMatrix.Get(1);
        CopiedRow.Add(999);

        SourceRow := SourceMatrix.Get(1);
        Assert.AreEqual(2, SourceRow.Count(), 'Expected the source inner list to keep exactly its 2 original values after a value was added to the copy''s inner list — the copy must not share inner lists with the source');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddingToASourceInnerListLeavesTheCopyUntouched()
    var
        DeepCopy: Codeunit "Collection Deep Copy";
        Assert: Codeunit Assert;
        SourceMatrix: List of [List of [Integer]];
        CopiedMatrix: List of [List of [Integer]];
        CopiedRow: List of [Integer];
        SourceRow: List of [Integer];
    begin
        // [SCENARIO] Mutating an inner list of the source does not leak into the copy
        AddRow(SourceMatrix, 30, 40);
        CopiedMatrix := DeepCopy.CopyMatrix(SourceMatrix);

        SourceRow := SourceMatrix.Get(1);
        SourceRow.Add(888);

        CopiedRow := CopiedMatrix.Get(1);
        Assert.AreEqual(2, CopiedRow.Count(), 'Expected the copy''s inner list to keep exactly its 2 copied values after a value was added to the source''s inner list — the copy must not share inner lists with the source');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddingToACopiedEmptyInnerListLeavesTheSourceEmpty()
    var
        DeepCopy: Codeunit "Collection Deep Copy";
        Assert: Codeunit Assert;
        SourceMatrix: List of [List of [Integer]];
        CopiedMatrix: List of [List of [Integer]];
        CopiedRow: List of [Integer];
        SourceRow: List of [Integer];
    begin
        // [SCENARIO] Even a previously empty inner list is independent after the copy
        AddEmptyRow(SourceMatrix);
        CopiedMatrix := DeepCopy.CopyMatrix(SourceMatrix);

        CopiedRow := CopiedMatrix.Get(1);
        CopiedRow.Add(1);

        SourceRow := SourceMatrix.Get(1);
        Assert.AreEqual(0, SourceRow.Count(), 'Expected the empty source inner list to stay empty after a value was added to the copy''s inner list — empty inner lists must be copied as new lists, not shared');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GroupsCopyContainsTheSameKeysAndTexts()
    var
        DeepCopy: Codeunit "Collection Deep Copy";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SourceGroups: Dictionary of [Code[20], List of [Text]];
        CopiedGroups: Dictionary of [Code[20], List of [Text]];
        CopiedEntries: List of [Text];
        FirstEntry: Text;
        SecondEntry: Text;
        ThirdEntry: Text;
    begin
        // [SCENARIO] The copy reproduces every key and every stored text in order
        FirstEntry := Any.AlphabeticText(12);
        SecondEntry := Any.AlphabeticText(12);
        ThirdEntry := Any.AlphabeticText(12);
        AddGroup(SourceGroups, 'ALPHA', FirstEntry, SecondEntry);
        AddSingleEntryGroup(SourceGroups, 'BETA', ThirdEntry);

        CopiedGroups := DeepCopy.CopyGroups(SourceGroups);

        Assert.AreEqual(2, CopiedGroups.Count(), 'Expected the copy to contain the same number of keys as the source');
        Assert.IsTrue(CopiedGroups.ContainsKey('ALPHA'), 'Expected the copy to contain the key ALPHA');
        Assert.IsTrue(CopiedGroups.ContainsKey('BETA'), 'Expected the copy to contain the key BETA');
        CopiedEntries := CopiedGroups.Get('ALPHA');
        Assert.AreEqual(2, CopiedEntries.Count(), 'Expected the list stored under ALPHA to keep both of its texts in the copy');
        Assert.AreEqual(FirstEntry, CopiedEntries.Get(1), 'Expected the first text stored under ALPHA to be copied in order');
        Assert.AreEqual(SecondEntry, CopiedEntries.Get(2), 'Expected the second text stored under ALPHA to be copied in order');
        CopiedEntries := CopiedGroups.Get('BETA');
        Assert.AreEqual(1, CopiedEntries.Count(), 'Expected the list stored under BETA to keep its single text in the copy');
        Assert.AreEqual(ThirdEntry, CopiedEntries.Get(1), 'Expected the text stored under BETA to be copied unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GroupsCopyKeepsAnEmptyGroupEmpty()
    var
        DeepCopy: Codeunit "Collection Deep Copy";
        Assert: Codeunit Assert;
        SourceGroups: Dictionary of [Code[20], List of [Text]];
        CopiedGroups: Dictionary of [Code[20], List of [Text]];
        CopiedEntries: List of [Text];
    begin
        // [SCENARIO] A key mapped to an empty list survives the copy with an empty list
        AddEmptyGroup(SourceGroups, 'EMPTY');
        AddSingleEntryGroup(SourceGroups, 'FULL', 'one entry');

        CopiedGroups := DeepCopy.CopyGroups(SourceGroups);

        Assert.IsTrue(CopiedGroups.ContainsKey('EMPTY'), 'Expected the copy to keep the key EMPTY even though its list holds no texts');
        CopiedEntries := CopiedGroups.Get('EMPTY');
        Assert.AreEqual(0, CopiedEntries.Count(), 'Expected the empty list stored under EMPTY to come out empty in the copy');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddingToACopiedGroupLeavesTheSourceUntouched()
    var
        DeepCopy: Codeunit "Collection Deep Copy";
        Assert: Codeunit Assert;
        SourceGroups: Dictionary of [Code[20], List of [Text]];
        CopiedGroups: Dictionary of [Code[20], List of [Text]];
        CopiedEntries: List of [Text];
        SourceEntries: List of [Text];
    begin
        // [SCENARIO] Mutating a group's list on the copy does not leak into the source
        AddSingleEntryGroup(SourceGroups, 'ALPHA', 'original entry');
        CopiedGroups := DeepCopy.CopyGroups(SourceGroups);

        CopiedEntries := CopiedGroups.Get('ALPHA');
        CopiedEntries.Add('added on the copy');

        SourceEntries := SourceGroups.Get('ALPHA');
        Assert.AreEqual(1, SourceEntries.Count(), 'Expected the source list under ALPHA to keep exactly its 1 original text after a text was added to the copy''s list — the copy must not share the stored lists with the source');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddingToASourceGroupLeavesTheCopyUntouched()
    var
        DeepCopy: Codeunit "Collection Deep Copy";
        Assert: Codeunit Assert;
        SourceGroups: Dictionary of [Code[20], List of [Text]];
        CopiedGroups: Dictionary of [Code[20], List of [Text]];
        CopiedEntries: List of [Text];
        SourceEntries: List of [Text];
    begin
        // [SCENARIO] Mutating a group's list on the source does not leak into the copy
        AddSingleEntryGroup(SourceGroups, 'BETA', 'original entry');
        CopiedGroups := DeepCopy.CopyGroups(SourceGroups);

        SourceEntries := SourceGroups.Get('BETA');
        SourceEntries.Add('added on the source');

        CopiedEntries := CopiedGroups.Get('BETA');
        Assert.AreEqual(1, CopiedEntries.Count(), 'Expected the copy''s list under BETA to keep exactly its 1 copied text after a text was added to the source''s list — the copy must not share the stored lists with the source');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddingToACopiedEmptyGroupLeavesTheSourceEmpty()
    var
        DeepCopy: Codeunit "Collection Deep Copy";
        Assert: Codeunit Assert;
        SourceGroups: Dictionary of [Code[20], List of [Text]];
        CopiedGroups: Dictionary of [Code[20], List of [Text]];
        CopiedEntries: List of [Text];
        SourceEntries: List of [Text];
    begin
        // [SCENARIO] Even a previously empty group's list is independent after the copy
        AddEmptyGroup(SourceGroups, 'EMPTY');
        CopiedGroups := DeepCopy.CopyGroups(SourceGroups);

        CopiedEntries := CopiedGroups.Get('EMPTY');
        CopiedEntries.Add('added on the copy');

        SourceEntries := SourceGroups.Get('EMPTY');
        Assert.AreEqual(0, SourceEntries.Count(), 'Expected the empty source list under EMPTY to stay empty after a text was added to the copy''s list — empty lists must be copied as new lists, not shared');
    end;

    // Each helper builds its row/group in a fresh local list, so the seeded
    // collections never share an inner list between entries.
    local procedure AddRow(var Matrix: List of [List of [Integer]]; FirstValue: Integer; SecondValue: Integer)
    var
        Row: List of [Integer];
    begin
        Row.Add(FirstValue);
        Row.Add(SecondValue);
        Matrix.Add(Row);
    end;

    local procedure AddSingleValueRow(var Matrix: List of [List of [Integer]]; Value: Integer)
    var
        Row: List of [Integer];
    begin
        Row.Add(Value);
        Matrix.Add(Row);
    end;

    local procedure AddEmptyRow(var Matrix: List of [List of [Integer]])
    var
        Row: List of [Integer];
    begin
        Matrix.Add(Row);
    end;

    local procedure AddGroup(var Groups: Dictionary of [Code[20], List of [Text]]; GroupCode: Code[20]; FirstEntry: Text; SecondEntry: Text)
    var
        Entries: List of [Text];
    begin
        Entries.Add(FirstEntry);
        Entries.Add(SecondEntry);
        Groups.Add(GroupCode, Entries);
    end;

    local procedure AddSingleEntryGroup(var Groups: Dictionary of [Code[20], List of [Text]]; GroupCode: Code[20]; Entry: Text)
    var
        Entries: List of [Text];
    begin
        Entries.Add(Entry);
        Groups.Add(GroupCode, Entries);
    end;

    local procedure AddEmptyGroup(var Groups: Dictionary of [Code[20], List of [Text]]; GroupCode: Code[20])
    var
        Entries: List of [Text];
    begin
        Groups.Add(GroupCode, Entries);
    end;
}
