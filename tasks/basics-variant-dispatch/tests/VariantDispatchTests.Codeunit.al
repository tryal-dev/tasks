codeunit 50900 "Variant Dispatch Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FormatsAnIntegerVariant()
    var
        VariantFormatter: Codeunit "Variant Formatter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Value: Variant;
        IntegerValue: Integer;
    begin
        // [SCENARIO] An Integer payload is rendered as plain digits behind the Integer tag
        IntegerValue := Any.IntegerInRange(100, 99999);
        Value := IntegerValue;

        Assert.AreEqual('Integer: ' + Format(IntegerValue), VariantFormatter.FormatValue(Value),
            'Expected an Integer payload to come back as "Integer: " followed by plain digits');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FormatsADecimalVariantWithItsFraction()
    var
        VariantFormatter: Codeunit "Variant Formatter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Value: Variant;
        WholePart: Integer;
        DecimalValue: Decimal;
    begin
        // [SCENARIO] A Decimal payload keeps its fraction behind a dot separator
        WholePart := Any.IntegerInRange(10, 999);
        DecimalValue := WholePart + 0.25;
        Value := DecimalValue;

        Assert.AreEqual('Decimal: ' + Format(WholePart) + '.25', VariantFormatter.FormatValue(Value),
            'Expected a Decimal payload to come back as "Decimal: " followed by the number with a dot as the decimal separator');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DecimalFormattingIgnoresRegionalSettings()
    var
        VariantFormatter: Codeunit "Variant Formatter";
        Assert: Codeunit Assert;
        Value: Variant;
        DecimalValue: Decimal;
    begin
        // [SCENARIO] A large Decimal is rendered with no thousands separators, whatever the server locale
        DecimalValue := 1234567.5;
        Value := DecimalValue;

        Assert.AreEqual('Decimal: 1234567.5', VariantFormatter.FormatValue(Value),
            'Expected the Decimal rendering to use a dot and no thousands separators regardless of the server''s regional settings');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FormatsADateVariantAsIso()
    var
        VariantFormatter: Codeunit "Variant Formatter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Value: Variant;
        DateValue: Date;
    begin
        // [SCENARIO] A randomly generated Date payload is rendered as yyyy-mm-dd
        DateValue := Any.DateInRange(DMY2Date(1, 1, 2020), 1, 4000);
        Value := DateValue;

        Assert.AreEqual('Date: ' + IsoDateText(DateValue), VariantFormatter.FormatValue(Value),
            'Expected a Date payload to come back as "Date: " followed by the yyyy-mm-dd shape, not the regional date format');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FormatsATrueBooleanVariant()
    var
        VariantFormatter: Codeunit "Variant Formatter";
        Assert: Codeunit Assert;
        Value: Variant;
        BooleanValue: Boolean;
    begin
        // [SCENARIO] A true Boolean payload is rendered lowercase
        BooleanValue := true;
        Value := BooleanValue;

        Assert.AreEqual('Boolean: true', VariantFormatter.FormatValue(Value),
            'Expected a true Boolean payload to come back as "Boolean: true" — lowercase, not Yes');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FormatsAFalseBooleanVariant()
    var
        VariantFormatter: Codeunit "Variant Formatter";
        Assert: Codeunit Assert;
        Value: Variant;
        BooleanValue: Boolean;
    begin
        // [SCENARIO] A false Boolean payload is rendered lowercase
        BooleanValue := false;
        Value := BooleanValue;

        Assert.AreEqual('Boolean: false', VariantFormatter.FormatValue(Value),
            'Expected a false Boolean payload to come back as "Boolean: false" — lowercase, not No');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FormatsAGuidVariant()
    var
        VariantFormatter: Codeunit "Variant Formatter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Value: Variant;
        GuidValue: Guid;
    begin
        // [SCENARIO] A randomly generated Guid payload keeps its default braces-and-uppercase rendering
        GuidValue := Any.GuidValue();
        Value := GuidValue;

        Assert.AreEqual('Guid: ' + Format(GuidValue), VariantFormatter.FormatValue(Value),
            'Expected a Guid payload to come back as "Guid: " followed by uppercase hex wrapped in braces');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FormatsAnOptionVariantAsItsOrdinal()
    var
        VariantFormatter: Codeunit "Variant Formatter";
        Assert: Codeunit Assert;
        Value: Variant;
        ColorValue: Option Red,Green,Blue;
    begin
        // [SCENARIO] An Option payload is rendered by zero-based position, tagged Option and not Integer
        ColorValue := ColorValue::Blue;
        Value := ColorValue;

        Assert.AreEqual('Option: 2', VariantFormatter.FormatValue(Value),
            'Expected the third option member to come back as "Option: 2" — the Option tag with the zero-based position, not an Integer tag or the member name');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FormatsTheFirstOptionMemberAsZero()
    var
        VariantFormatter: Codeunit "Variant Formatter";
        Assert: Codeunit Assert;
        Value: Variant;
        SizeValue: Option Small,Medium,Large,ExtraLarge;
    begin
        // [SCENARIO] The first member of a differently shaped option list is rendered as position zero
        SizeValue := SizeValue::Small;
        Value := SizeValue;

        Assert.AreEqual('Option: 0', VariantFormatter.FormatValue(Value),
            'Expected the first option member to come back as "Option: 0" — the zero-based position must be computed from the payload, not hardcoded');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FormatsACodeVariantAsStored()
    var
        VariantFormatter: Codeunit "Variant Formatter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Value: Variant;
        LowercaseText: Text;
        CodeValue: Code[20];
    begin
        // [SCENARIO] A Code payload assigned from lowercase is tagged Code and rendered as stored (uppercased)
        LowercaseText := Any.AlphabeticText(10);
        CodeValue := LowercaseText;
        Value := CodeValue;

        Assert.AreEqual('Code: ' + UpperCase(LowercaseText), VariantFormatter.FormatValue(Value),
            'Expected a Code payload to come back as "Code: " followed by its stored uppercase value — not tagged as Text');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FormatsATextVariantVerbatim()
    var
        VariantFormatter: Codeunit "Variant Formatter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Value: Variant;
        TextValue: Text;
    begin
        // [SCENARIO] A lowercase Text payload comes back byte-for-byte
        TextValue := Any.AlphabeticText(12);
        Value := TextValue;

        Assert.AreEqual('Text: ' + TextValue, VariantFormatter.FormatValue(Value),
            'Expected a Text payload to come back verbatim after "Text: " — routing it through a Code variable would uppercase it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FormatsACustomerRecordVariant()
    var
        Customer: Record Customer;
        VariantFormatter: Codeunit "Variant Formatter";
        Assert: Codeunit Assert;
        Value: Variant;
    begin
        // [SCENARIO] A Customer record payload is rendered with its table name
        Value := Customer;

        Assert.AreEqual('Record: Customer', VariantFormatter.FormatValue(Value),
            'Expected a Customer record payload to come back as "Record: Customer"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RecordFormattingUsesTheTableName()
    var
        Item: Record Item;
        VariantFormatter: Codeunit "Variant Formatter";
        Assert: Codeunit Assert;
        Value: Variant;
    begin
        // [SCENARIO] A record payload from another table is rendered with that table's name
        Value := Item;

        Assert.AreEqual('Record: Item', VariantFormatter.FormatValue(Value),
            'Expected an Item record payload to come back as "Record: Item" — the table name must be read from the payload, not hardcoded');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnsupportedTimeVariantRaisesTheContractError()
    var
        VariantFormatter: Codeunit "Variant Formatter";
        Assert: Codeunit Assert;
        Value: Variant;
        TimeValue: Time;
    begin
        // [SCENARIO] A Time payload is unsupported and fails with the contract message
        TimeValue := 123456T;
        Value := TimeValue;

        asserterror VariantFormatter.FormatValue(Value);

        Assert.AreEqual('Unsupported value type.', GetLastErrorText(),
            'Expected FormatValue to fail with exactly the contract message ''Unsupported value type.''');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TryFormatValueFormatsASupportedPayload()
    var
        VariantFormatter: Codeunit "Variant Formatter";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Value: Variant;
        IntegerValue: Integer;
        FormattedValue: Text;
        Succeeded: Boolean;
    begin
        // [SCENARIO] TryFormatValue succeeds on a supported payload and hands back the formatted text
        IntegerValue := -Any.IntegerInRange(1, 500);
        Value := IntegerValue;

        Succeeded := VariantFormatter.TryFormatValue(Value, FormattedValue);

        Assert.IsTrue(Succeeded,
            StrSubstNo('Expected TryFormatValue to return true for an Integer payload, got %1', Succeeded));
        Assert.AreEqual('Integer: ' + Format(IntegerValue), FormattedValue,
            'Expected TryFormatValue to hand back exactly what FormatValue returns — a negative Integer keeps its leading minus');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TryFormatValueRejectsAnUnsupportedPayload()
    var
        VariantFormatter: Codeunit "Variant Formatter";
        Assert: Codeunit Assert;
        Value: Variant;
        DateTimeValue: DateTime;
        FormattedValue: Text;
        Succeeded: Boolean;
    begin
        // [SCENARIO] TryFormatValue reports an unsupported payload without raising and clears the output
        DateTimeValue := CreateDateTime(DMY2Date(15, 1, 2026), 123456T);
        Value := DateTimeValue;
        FormattedValue := 'stale content from an earlier call';

        Succeeded := VariantFormatter.TryFormatValue(Value, FormattedValue);

        Assert.IsFalse(Succeeded,
            StrSubstNo('Expected TryFormatValue to return false for a DateTime payload instead of raising an error, got %1', Succeeded));
        Assert.AreEqual('', FormattedValue,
            'Expected TryFormatValue to clear the output text on failure, even when the variable already held content');
    end;

    local procedure IsoDateText(DateValue: Date): Text
    begin
        // Built from Date2DMY so the expected value never shares a code path with the solution's Format call
        exit(StrSubstNo('%1-%2-%3',
            Format(Date2DMY(DateValue, 3)),
            PadTwo(Date2DMY(DateValue, 2)),
            PadTwo(Date2DMY(DateValue, 1))));
    end;

    local procedure PadTwo(Value: Integer): Text
    begin
        exit(Format(Value).PadLeft(2, '0'));
    end;
}
