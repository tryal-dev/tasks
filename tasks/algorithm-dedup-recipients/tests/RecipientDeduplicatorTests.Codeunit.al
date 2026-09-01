codeunit 50900 "Recipient Deduplicator Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleRecipientComesBackUnchanged()
    var
        RecipientDeduplicator: Codeunit "Recipient Deduplicator";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('bob@contoso.com', RecipientDeduplicator.Dedupe('bob@contoso.com'),
            'Expected a list with one clean recipient to come back unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExactDuplicatesKeepOnlyTheFirstOccurrence()
    var
        RecipientDeduplicator: Codeunit "Recipient Deduplicator";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('anna@contoso.com; bob@contoso.com; carl@contoso.com',
            RecipientDeduplicator.Dedupe('anna@contoso.com;bob@contoso.com;anna@contoso.com;carl@contoso.com'),
            'Expected each recipient once, in the order recipients first appear, joined with a semicolon and one space');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CasingVariantsAreOneRecipientKeepingFirstSeenCasing()
    var
        RecipientDeduplicator: Codeunit "Recipient Deduplicator";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('Sales@Contoso.com; bob@contoso.com',
            RecipientDeduplicator.Dedupe('Sales@Contoso.com;bob@contoso.com;sales@contoso.com'),
            'Expected entries that differ only in casing to count as one recipient, keeping the first occurrence''s original casing');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SurroundingSpacesAreTrimmedBeforeComparing()
    var
        RecipientDeduplicator: Codeunit "Recipient Deduplicator";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('anna@contoso.com; bob@contoso.com',
            RecipientDeduplicator.Dedupe(' anna@contoso.com ;bob@contoso.com; anna@contoso.com'),
            'Expected spaces around entries to be trimmed, so a padded entry is a duplicate of its unpadded twin');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyEntriesAreDropped()
    var
        RecipientDeduplicator: Codeunit "Recipient Deduplicator";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('anna@contoso.com; bob@contoso.com',
            RecipientDeduplicator.Dedupe(';;anna@contoso.com; ;bob@contoso.com;'),
            'Expected entries that are empty after trimming to be dropped, leaving no leading, trailing, or doubled separators');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyInputReturnsEmptyText()
    var
        RecipientDeduplicator: Codeunit "Recipient Deduplicator";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', RecipientDeduplicator.Dedupe(''),
            'Expected an empty recipient list to come back as an empty text');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnlySeparatorsAndSpacesReturnEmptyText()
    var
        RecipientDeduplicator: Codeunit "Recipient Deduplicator";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', RecipientDeduplicator.Dedupe(' ; ;; '),
            'Expected a list holding only semicolons and spaces to come back as an empty text');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomizedListKeepsFirstSeenOrderAndCasing()
    var
        RecipientDeduplicator: Codeunit "Recipient Deduplicator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Addresses: List of [Text];
        Address: Text;
        Input: Text;
        Expected: Text;
        i: Integer;
    begin
        // [SCENARIO] every generated address reappears later in upper case with padding — a solution that pattern-matches the fixed examples, keeps last occurrences, or sorts the output fails here
        for i := 1 to 5 do
            Addresses.Add(Any.AlphabeticText(6) + Format(i) + '@contoso.com');
        foreach Address in Addresses do begin
            if Input <> '' then
                Input += ';';
            Input += Address;
        end;
        foreach Address in Addresses do
            Input += '; ' + Address.ToUpper() + ' ';
        foreach Address in Addresses do begin
            if Expected <> '' then
                Expected += '; ';
            Expected += Address;
        end;

        Assert.AreEqual(Expected, RecipientDeduplicator.Dedupe(Input),
            'Expected each randomized recipient once, in first-seen order with first-seen casing, even though every address reappears upper-cased with padding');
    end;
}
