// Grading tests for basics-flowfield-formulas.
//
// Readings are inserted and deleted straight into "Lab Batch Reading" with
// Insert()/Delete() — no trigger runs — so every header figure must be
// computed on demand from the reading table, never stored.
//
// The header's calculated fields do not exist in the starter, so the tests
// reach them by name through RecordRef/FieldRef at run time.
codeunit 50900 "Lab Batch FlowField Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PromisedFieldsAreDeclaredAsFlowFieldsOfTheRightType()
    var
        RecRef: RecordRef;
    begin
        // [SCENARIO] The header declares the flow filter and the eight FlowFields exactly as promised
        RecRef.Open(Database::"Lab Batch Header");

        AssertFieldClassAndType(RecRef, 'Date Filter', FieldClass::FlowFilter, FieldType::Date);
        AssertFieldClassAndType(RecRef, 'Has Readings', FieldClass::FlowField, FieldType::Boolean);
        AssertFieldClassAndType(RecRef, 'No Readings', FieldClass::FlowField, FieldType::Boolean);
        AssertFieldClassAndType(RecRef, 'Reading Count', FieldClass::FlowField, FieldType::Integer);
        AssertFieldClassAndType(RecRef, 'Reading Total', FieldClass::FlowField, FieldType::Decimal);
        AssertFieldClassAndType(RecRef, 'Lowest Reading', FieldClass::FlowField, FieldType::Decimal);
        AssertFieldClassAndType(RecRef, 'Highest Reading', FieldClass::FlowField, FieldType::Decimal);
        AssertFieldClassAndType(RecRef, 'Average Reading', FieldClass::FlowField, FieldType::Decimal);
        AssertFieldClassAndType(RecRef, 'Customer Name', FieldClass::FlowField, FieldType::Text);
        Assert.AreEqual(100, FieldByName(RecRef, 'Customer Name').Length(),
            'Expected "Customer Name" to be declared as Text[100]');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasReadingsIsTrueWhenTheBatchHasReadings()
    var
        RecRef: RecordRef;
        Any: Codeunit Any;
        HasReadings: Boolean;
    begin
        // [SCENARIO] The exist FlowField reports that a batch carries readings
        CreateBatch(RecRef, 'TRYAL-F01', '');
        AddReading('TRYAL-F01', 10000, BaseDate(), Any.DecimalInRange(10, 99, 2));

        HasReadings := CalcValue(RecRef, 'Has Readings');

        Assert.AreEqual(true, HasReadings,
            'Expected "Has Readings" to be TRUE for a batch that has at least one reading');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HasReadingsIsFalseWhenTheBatchHasNoReadings()
    var
        RecRef: RecordRef;
        Any: Codeunit Any;
        HasReadings: Boolean;
    begin
        // [SCENARIO] Readings of another batch never make an empty batch look filled
        CreateBatch(RecRef, 'TRYAL-F02', '');
        AddReading('TRYAL-F02X', 10000, BaseDate(), Any.DecimalInRange(10, 99, 2));

        HasReadings := CalcValue(RecRef, 'Has Readings');

        Assert.AreEqual(false, HasReadings,
            'Expected "Has Readings" to be FALSE for a batch without readings of its own — readings of another batch must not count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoReadingsIsTrueWhenTheBatchHasNoReadings()
    var
        RecRef: RecordRef;
        Any: Codeunit Any;
        NoReadings: Boolean;
    begin
        // [SCENARIO] The negated exist FlowField reports an empty batch
        CreateBatch(RecRef, 'TRYAL-F03', '');
        AddReading('TRYAL-F03X', 10000, BaseDate(), Any.DecimalInRange(10, 99, 2));

        NoReadings := CalcValue(RecRef, 'No Readings');

        Assert.AreEqual(true, NoReadings,
            'Expected "No Readings" to be TRUE for a batch without readings of its own');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoReadingsIsFalseWhenTheBatchHasReadings()
    var
        RecRef: RecordRef;
        Any: Codeunit Any;
        NoReadings: Boolean;
    begin
        // [SCENARIO] "No Readings" is the exact opposite of "Has Readings"
        CreateBatch(RecRef, 'TRYAL-F04', '');
        AddReading('TRYAL-F04', 10000, BaseDate(), Any.DecimalInRange(10, 99, 2));

        NoReadings := CalcValue(RecRef, 'No Readings');

        Assert.AreEqual(false, NoReadings,
            'Expected "No Readings" to be FALSE for a batch that has readings — it is the negation of "Has Readings", not a copy of it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReadingCountCountsOnlyTheBatchOwnReadings()
    var
        RecRef: RecordRef;
        Any: Codeunit Any;
        ReadingCount: Integer;
    begin
        // [SCENARIO] The count FlowField counts the rows of this batch only
        CreateBatch(RecRef, 'TRYAL-F05', '');
        AddReading('TRYAL-F05', 10000, BaseDate(), Any.DecimalInRange(10, 99, 2));
        AddReading('TRYAL-F05', 20000, BaseDate() + 3, Any.DecimalInRange(10, 99, 2));
        AddReading('TRYAL-F05', 30000, BaseDate() + 9, Any.DecimalInRange(10, 99, 2));
        AddReading('TRYAL-F05X', 10000, BaseDate(), Any.DecimalInRange(10, 99, 2));
        AddReading('TRYAL-F05X', 20000, BaseDate(), Any.DecimalInRange(10, 99, 2));

        ReadingCount := CalcValue(RecRef, 'Reading Count');

        Assert.AreEqual(3, ReadingCount,
            'Expected "Reading Count" to count the three readings of this batch and none of the readings of another batch');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReadingTotalSumsTheReadingValues()
    var
        RecRef: RecordRef;
        Any: Codeunit Any;
        FirstValue: Decimal;
        SecondValue: Decimal;
        NegativeValue: Decimal;
        ReadingTotal: Decimal;
    begin
        // [SCENARIO] The sum FlowField adds the values of this batch, signs included
        FirstValue := Any.DecimalInRange(10, 99, 2);
        SecondValue := Any.DecimalInRange(100, 200, 2);
        NegativeValue := -Any.DecimalInRange(1, 9, 2);

        CreateBatch(RecRef, 'TRYAL-F06', '');
        AddReading('TRYAL-F06', 10000, BaseDate(), FirstValue);
        AddReading('TRYAL-F06', 20000, BaseDate() + 2, SecondValue);
        AddReading('TRYAL-F06', 30000, BaseDate() + 4, NegativeValue);
        AddReading('TRYAL-F06X', 10000, BaseDate(), Any.DecimalInRange(500, 900, 2));

        ReadingTotal := CalcValue(RecRef, 'Reading Total');

        Assert.AreEqual(FirstValue + SecondValue + NegativeValue, ReadingTotal,
            'Expected "Reading Total" to be the signed sum of this batch''s reading values — a negative reading lowers the total, and another batch''s reading never enters it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LowestReadingReturnsTheSmallestValue()
    var
        RecRef: RecordRef;
        Any: Codeunit Any;
        SmallestValue: Decimal;
        LowestReading: Decimal;
    begin
        // [SCENARIO] The min FlowField returns the smallest value in the batch
        SmallestValue := -Any.DecimalInRange(50, 99, 2);

        CreateBatch(RecRef, 'TRYAL-F07', '');
        AddReading('TRYAL-F07', 10000, BaseDate(), Any.DecimalInRange(10, 99, 2));
        AddReading('TRYAL-F07', 20000, BaseDate() + 2, SmallestValue);
        AddReading('TRYAL-F07', 30000, BaseDate() + 4, Any.DecimalInRange(100, 200, 2));
        AddReading('TRYAL-F07X', 10000, BaseDate(), -Any.DecimalInRange(500, 900, 2));

        LowestReading := CalcValue(RecRef, 'Lowest Reading');

        Assert.AreEqual(SmallestValue, LowestReading,
            'Expected "Lowest Reading" to be the smallest reading value of this batch — negative values are smaller than positive ones, and another batch''s reading is not a candidate');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HighestReadingReturnsTheLargestValue()
    var
        RecRef: RecordRef;
        Any: Codeunit Any;
        LargestValue: Decimal;
        HighestReading: Decimal;
    begin
        // [SCENARIO] The max FlowField returns the largest value in the batch
        LargestValue := Any.DecimalInRange(100, 200, 2);

        CreateBatch(RecRef, 'TRYAL-F08', '');
        AddReading('TRYAL-F08', 10000, BaseDate(), Any.DecimalInRange(10, 99, 2));
        AddReading('TRYAL-F08', 20000, BaseDate() + 2, LargestValue);
        AddReading('TRYAL-F08', 30000, BaseDate() + 4, -Any.DecimalInRange(10, 99, 2));
        AddReading('TRYAL-F08X', 10000, BaseDate(), Any.DecimalInRange(500, 900, 2));

        HighestReading := CalcValue(RecRef, 'Highest Reading');

        Assert.AreEqual(LargestValue, HighestReading,
            'Expected "Highest Reading" to be the largest reading value of this batch — another batch''s larger reading must not win');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AverageReadingIsTheMeanOfTheReadings()
    var
        RecRef: RecordRef;
        Any: Codeunit Any;
        FirstValue: Decimal;
        AverageReading: Decimal;
    begin
        // [SCENARIO] The average FlowField returns sum divided by number of readings
        FirstValue := Any.DecimalInRange(10, 90, 2);

        CreateBatch(RecRef, 'TRYAL-F09', '');
        AddReading('TRYAL-F09', 10000, BaseDate(), FirstValue);
        AddReading('TRYAL-F09', 20000, BaseDate() + 2, FirstValue + 5);
        AddReading('TRYAL-F09X', 10000, BaseDate(), Any.DecimalInRange(500, 900, 2));

        AverageReading := CalcValue(RecRef, 'Average Reading');

        Assert.AreNearlyEqual(FirstValue + 2.5, AverageReading, 0.01,
            'Expected "Average Reading" to be the mean of this batch''s two reading values');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AggregatesOverABatchWithoutReadingsAreZero()
    var
        RecRef: RecordRef;
        Any: Codeunit Any;
        ReadingCount: Integer;
        ReadingTotal: Decimal;
        LowestReading: Decimal;
        HighestReading: Decimal;
    begin
        // [SCENARIO] Aggregating over an empty set yields zero, not an error
        CreateBatch(RecRef, 'TRYAL-F10', '');
        AddReading('TRYAL-F10X', 10000, BaseDate(), Any.DecimalInRange(10, 99, 2));

        ReadingCount := CalcValue(RecRef, 'Reading Count');
        ReadingTotal := CalcValue(RecRef, 'Reading Total');
        LowestReading := CalcValue(RecRef, 'Lowest Reading');
        HighestReading := CalcValue(RecRef, 'Highest Reading');

        Assert.AreEqual(0, ReadingCount, 'Expected "Reading Count" to be 0 for a batch without readings');
        Assert.AreEqual(0.0, ReadingTotal, 'Expected "Reading Total" to be 0 for a batch without readings');
        Assert.AreEqual(0.0, LowestReading, 'Expected "Lowest Reading" to be 0 for a batch without readings');
        Assert.AreEqual(0.0, HighestReading, 'Expected "Highest Reading" to be 0 for a batch without readings');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AverageOverABatchWithoutReadingsIsZero()
    var
        RecRef: RecordRef;
        Any: Codeunit Any;
        AverageReading: Decimal;
    begin
        // [SCENARIO] The average over an empty set is zero, not a division error
        CreateBatch(RecRef, 'TRYAL-F11', '');
        AddReading('TRYAL-F11X', 10000, BaseDate(), Any.DecimalInRange(10, 99, 2));

        AverageReading := CalcValue(RecRef, 'Average Reading');

        Assert.AreEqual(0.0, AverageReading,
            'Expected "Average Reading" to be 0 for a batch without readings');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FlowFieldsAreBlankBeforeCalcFieldsIsCalled()
    var
        Header: Record "Lab Batch Header";
        Customer: Record Customer;
        RecRef: RecordRef;
        Any: Codeunit Any;
        HasReadings: Boolean;
        ReadingCount: Integer;
        ReadingTotal: Decimal;
        CustomerName: Text;
    begin
        // [SCENARIO] A freshly read record carries no calculated values yet
        CreateCustomerNamed(Customer, CopyStr('TRYAL-F12 ' + Any.AlphabeticText(10), 1, 100));
        CreateBatch(RecRef, 'TRYAL-F12', Customer."No.");
        AddReading('TRYAL-F12', 10000, BaseDate(), Any.DecimalInRange(10, 99, 2));

        Header.Get('TRYAL-F12');
        RecRef.GetTable(Header);
        HasReadings := FieldByName(RecRef, 'Has Readings').Value();
        ReadingCount := FieldByName(RecRef, 'Reading Count').Value();
        ReadingTotal := FieldByName(RecRef, 'Reading Total').Value();
        CustomerName := FieldByName(RecRef, 'Customer Name').Value();

        Assert.AreEqual(false, HasReadings, 'Expected "Has Readings" to be FALSE on a record that was read but not calculated');
        Assert.AreEqual(0, ReadingCount, 'Expected "Reading Count" to be 0 on a record that was read but not calculated');
        Assert.AreEqual(0.0, ReadingTotal, 'Expected "Reading Total" to be 0 on a record that was read but not calculated');
        Assert.AreEqual('', CustomerName, 'Expected "Customer Name" to be blank on a record that was read but not calculated');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AggregatesFollowReadingsDeletedDirectly()
    var
        Reading: Record "Lab Batch Reading";
        RecRef: RecordRef;
        Any: Codeunit Any;
        KeptValue: Decimal;
        RemovedValue: Decimal;
        ReadingCount: Integer;
        ReadingTotal: Decimal;
    begin
        // [SCENARIO] A recalculation after a direct delete reports the new figures
        KeptValue := Any.DecimalInRange(10, 99, 2);
        RemovedValue := Any.DecimalInRange(100, 200, 2);

        CreateBatch(RecRef, 'TRYAL-F13', '');
        AddReading('TRYAL-F13', 10000, BaseDate(), KeptValue);
        AddReading('TRYAL-F13', 20000, BaseDate() + 2, RemovedValue);
        ReadingCount := CalcValue(RecRef, 'Reading Count');
        ReadingTotal := CalcValue(RecRef, 'Reading Total');

        Reading.Get('TRYAL-F13', 20000);
        Reading.Delete();

        ReadingCount := CalcValue(RecRef, 'Reading Count');
        ReadingTotal := CalcValue(RecRef, 'Reading Total');
        Assert.AreEqual(1, ReadingCount, 'Expected "Reading Count" to drop to 1 after one reading was deleted directly in the table');
        Assert.AreEqual(KeptValue, ReadingTotal, 'Expected "Reading Total" to be recalculated from the remaining reading after a direct delete — a stored total goes stale');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AggregatesHonorTheDateFilterWindow()
    var
        RecRef: RecordRef;
        Any: Codeunit Any;
        BeforeWindow: Decimal;
        InWindowLow: Decimal;
        InWindowHigh: Decimal;
        AfterWindow: Decimal;
        ReadingCount: Integer;
        ReadingTotal: Decimal;
        LowestReading: Decimal;
        HighestReading: Decimal;
        AverageReading: Decimal;
    begin
        // [SCENARIO] A date window set on the FlowFilter narrows every aggregate
        BeforeWindow := Any.IntegerInRange(1, 50) + 10;
        InWindowLow := BeforeWindow + 10;
        InWindowHigh := BeforeWindow + 20;
        AfterWindow := BeforeWindow + 30;

        CreateBatch(RecRef, 'TRYAL-F14', '');
        AddReading('TRYAL-F14', 10000, BaseDate(), BeforeWindow);
        AddReading('TRYAL-F14', 20000, BaseDate() + 5, InWindowLow);
        AddReading('TRYAL-F14', 30000, BaseDate() + 6, InWindowHigh);
        AddReading('TRYAL-F14', 40000, BaseDate() + 10, AfterWindow);
        FieldByName(RecRef, 'Date Filter').SetRange(BaseDate() + 1, BaseDate() + 7);

        ReadingCount := CalcValue(RecRef, 'Reading Count');
        ReadingTotal := CalcValue(RecRef, 'Reading Total');
        LowestReading := CalcValue(RecRef, 'Lowest Reading');
        HighestReading := CalcValue(RecRef, 'Highest Reading');
        AverageReading := CalcValue(RecRef, 'Average Reading');

        Assert.AreEqual(2, ReadingCount, 'Expected "Reading Count" to count only the two readings inside the "Date Filter" window');
        Assert.AreEqual(InWindowLow + InWindowHigh, ReadingTotal, 'Expected "Reading Total" to add only the readings inside the "Date Filter" window');
        Assert.AreEqual(InWindowLow, LowestReading, 'Expected "Lowest Reading" to ignore the earlier reading outside the "Date Filter" window');
        Assert.AreEqual(InWindowHigh, HighestReading, 'Expected "Highest Reading" to ignore the later reading outside the "Date Filter" window');
        Assert.AreNearlyEqual((InWindowLow + InWindowHigh) / 2, AverageReading, 0.01, 'Expected "Average Reading" to average only the readings inside the "Date Filter" window');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExistenceFieldsHonorTheDateFilterWindow()
    var
        RecRef: RecordRef;
        Any: Codeunit Any;
        HasReadings: Boolean;
        NoReadings: Boolean;
    begin
        // [SCENARIO] A window without readings makes a filled batch look empty
        CreateBatch(RecRef, 'TRYAL-F15', '');
        AddReading('TRYAL-F15', 10000, BaseDate(), Any.DecimalInRange(10, 99, 2));
        AddReading('TRYAL-F15', 20000, BaseDate() + 10, Any.DecimalInRange(10, 99, 2));
        FieldByName(RecRef, 'Date Filter').SetRange(BaseDate() + 2, BaseDate() + 4);

        HasReadings := CalcValue(RecRef, 'Has Readings');
        NoReadings := CalcValue(RecRef, 'No Readings');

        Assert.AreEqual(false, HasReadings, 'Expected "Has Readings" to be FALSE when the "Date Filter" window holds no reading, even though the batch has readings outside it');
        Assert.AreEqual(true, NoReadings, 'Expected "No Readings" to be TRUE when the "Date Filter" window holds no reading');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssigningTheDateFilterFieldNarrowsNothing()
    var
        RecRef: RecordRef;
        Any: Codeunit Any;
        EarlyValue: Decimal;
        LateValue: Decimal;
        ReadingTotal: Decimal;
    begin
        // [SCENARIO] A value assigned to a FlowFilter field is not a filter
        EarlyValue := Any.DecimalInRange(10, 99, 2);
        LateValue := Any.DecimalInRange(100, 200, 2);

        CreateBatch(RecRef, 'TRYAL-F16', '');
        AddReading('TRYAL-F16', 10000, BaseDate(), EarlyValue);
        AddReading('TRYAL-F16', 20000, BaseDate() + 10, LateValue);
        FieldByName(RecRef, 'Date Filter').Value := BaseDate();

        ReadingTotal := CalcValue(RecRef, 'Reading Total');

        Assert.AreEqual(EarlyValue + LateValue, ReadingTotal,
            'Expected "Date Filter" to be a real FlowFilter: assigning a date to it filters nothing, so the total still covers every reading of the batch');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerNameLooksUpTheLinkedCustomer()
    var
        Customer: Record Customer;
        OtherCustomer: Record Customer;
        RecRef: RecordRef;
        Any: Codeunit Any;
        ExpectedName: Text[100];
        CustomerName: Text;
    begin
        // [SCENARIO] The lookup FlowField reads the name of the linked customer
        ExpectedName := CopyStr('TRYAL-F17 ' + Any.AlphabeticText(10), 1, 100);
        CreateCustomerNamed(Customer, ExpectedName);
        CreateCustomerNamed(OtherCustomer, CopyStr('TRYAL-F17 ' + Any.AlphabeticText(10), 1, 100));
        CreateBatch(RecRef, 'TRYAL-F17', Customer."No.");
        FieldByName(RecRef, 'Date Filter').SetRange(BaseDate() + 1, BaseDate() + 2);

        CustomerName := CalcValue(RecRef, 'Customer Name');

        Assert.AreEqual(ExpectedName, CustomerName,
            'Expected "Customer Name" to return the Name of the customer in "Customer No.", regardless of any "Date Filter" the caller set');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerNameFollowsALaterCustomerNameChange()
    var
        Customer: Record Customer;
        RecRef: RecordRef;
        Any: Codeunit Any;
        RenamedTo: Text[100];
        CustomerName: Text;
    begin
        // [SCENARIO] The looked-up name is read at calculation time, never copied
        CreateCustomerNamed(Customer, CopyStr('TRYAL-F18 ' + Any.AlphabeticText(10), 1, 100));
        CreateBatch(RecRef, 'TRYAL-F18', Customer."No.");
        RenamedTo := CopyStr('TRYAL-F18 ' + Any.AlphabeticText(12), 1, 100);

        Customer.Validate(Name, RenamedTo);
        Customer.Modify(true);

        CustomerName := CalcValue(RecRef, 'Customer Name');
        Assert.AreEqual(RenamedTo, CustomerName,
            'Expected "Customer Name" to return the customer''s current Name — a name copied onto the batch when it was created goes stale');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerNameIsBlankWhenNoCustomerIsLinked()
    var
        RecRef: RecordRef;
        CustomerName: Text;
    begin
        // [SCENARIO] A lookup that matches no record yields a blank value
        CreateBatch(RecRef, 'TRYAL-F19', '');

        CustomerName := CalcValue(RecRef, 'Customer Name');

        Assert.AreEqual('', CustomerName,
            'Expected "Customer Name" to be blank when "Customer No." is empty — a lookup that finds no record returns nothing, it does not fail');
    end;

    local procedure BaseDate(): Date
    begin
        exit(DMY2Date(4, 3, 2024));
    end;

    local procedure CreateBatch(var RecRef: RecordRef; BatchNo: Code[20]; CustomerNo: Code[20])
    var
        Header: Record "Lab Batch Header";
    begin
        Header.Init();
        Header."Batch No." := BatchNo;
        Header."Customer No." := CustomerNo;
        Header.Insert();
        RecRef.GetTable(Header);
    end;

    local procedure AddReading(BatchNo: Code[20]; LineNo: Integer; ReadingDate: Date; ReadingValue: Decimal)
    var
        Reading: Record "Lab Batch Reading";
    begin
        Reading.Init();
        Reading."Batch No." := BatchNo;
        Reading."Line No." := LineNo;
        Reading."Reading Date" := ReadingDate;
        Reading."Reading Value" := ReadingValue;
        Reading.Insert();
    end;

    local procedure CreateCustomerNamed(var Customer: Record Customer; NewName: Text[100])
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, NewName);
        Customer.Modify(true);
    end;

    local procedure CalcValue(var RecRef: RecordRef; FieldName: Text): Variant
    var
        FldRef: FieldRef;
    begin
        FldRef := FieldByName(RecRef, FieldName);
        FldRef.CalcField();
        exit(FldRef.Value());
    end;

    local procedure AssertFieldClassAndType(var RecRef: RecordRef; FieldName: Text; ExpectedClass: FieldClass; ExpectedType: FieldType)
    var
        FldRef: FieldRef;
    begin
        FldRef := FieldByName(RecRef, FieldName);
        Assert.AreEqual(Format(ExpectedClass), Format(FldRef.Class()),
            StrSubstNo('Expected "%1" to be declared with FieldClass = %2, not %3', FieldName, ExpectedClass, FldRef.Class()));
        Assert.AreEqual(Format(ExpectedType), Format(FldRef.Type()),
            StrSubstNo('Expected "%1" to be of type %2, not %3', FieldName, ExpectedType, FldRef.Type()));
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
