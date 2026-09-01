codeunit 50900 "Item Priority Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EnumValuesHaveThePromisedOrdinals()
    begin
        Assert.AreEqual(0, OrdinalOf('Low'), 'Expected Low to be declared with ordinal 0');
        Assert.AreEqual(1, OrdinalOf('Normal'), 'Expected Normal to be declared with ordinal 1');
        Assert.AreEqual(2, OrdinalOf('High'), 'Expected High to be declared with ordinal 2');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RestockPriorityIsAnItemPriorityEnumField()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Names: List of [Text];
        Ordinals: List of [Integer];
        i: Integer;
    begin
        RecRef.Open(Database::Item);
        FldRef := FieldByName(RecRef, 'Restock Priority');

        Assert.IsTrue(FldRef.IsEnum(),
            'Expected "Restock Priority" to be declared as Enum "Item Priority", not as an Option field');
        Names := Enum::"Item Priority".Names();
        Ordinals := Enum::"Item Priority".Ordinals();
        for i := 1 to Names.Count() do
            Assert.AreEqual(Names.Get(i), FldRef.GetEnumValueNameFromOrdinalValue(Ordinals.Get(i)),
                StrSubstNo('Expected "Restock Priority" to be of type Enum "Item Priority" — its value at ordinal %1 should be %2', Ordinals.Get(i), Names.Get(i)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RestockPriorityStoresAndReturnsTheValue()
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        RecRef: RecordRef;
        ItemPriority: Enum "Item Priority";
    begin
        LibraryInventory.CreateItem(Item);
        ItemPriority := Enum::"Item Priority".FromInteger(OrdinalOf('High'));

        RecRef.GetTable(Item);
        FieldByName(RecRef, 'Restock Priority').Validate(ItemPriority);
        RecRef.Modify();

        Item.Get(Item."No.");
        RecRef.GetTable(Item);
        Assert.AreEqual(OrdinalOf('High'), StoredOrdinal(RecRef, 'Restock Priority'),
            StrSubstNo('Expected "Restock Priority" to store and return High (ordinal %1), got %2', OrdinalOf('High'), StoredOrdinal(RecRef, 'Restock Priority')));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NewItemsDefaultToNormalPriority()
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        RecRef: RecordRef;
    begin
        LibraryInventory.CreateItem(Item);

        RecRef.GetTable(Item);
        Assert.AreEqual(OrdinalOf('Normal'), StoredOrdinal(RecRef, 'Restock Priority'),
            StrSubstNo('Expected a freshly created item to default to Normal priority (InitValue, ordinal %1), got %2', OrdinalOf('Normal'), StoredOrdinal(RecRef, 'Restock Priority')));
    end;

    // The enum values and the field are looked up by name at run time so the tests
    // compile against the unchanged starter, which has neither Normal/High nor the field.
    local procedure OrdinalOf(ValueName: Text): Integer
    var
        Names: List of [Text];
        Ordinals: List of [Integer];
        i: Integer;
    begin
        Names := Enum::"Item Priority".Names();
        Ordinals := Enum::"Item Priority".Ordinals();
        for i := 1 to Names.Count() do
            if Names.Get(i) = ValueName then
                exit(Ordinals.Get(i));
        Assert.Fail(StrSubstNo('Expected enum "Item Priority" to have a value named %1', ValueName));
    end;

    local procedure StoredOrdinal(var RecRef: RecordRef; FieldName: Text): Integer
    var
        Ordinal: Integer;
    begin
        Evaluate(Ordinal, Format(FieldByName(RecRef, FieldName).Value(), 0, 2));
        exit(Ordinal);
    end;

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
