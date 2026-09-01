codeunit 50900 "Pick Validator Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ShortMessageLbl: Label 'Cannot pick %1 units of item %2.', Locked = true;
        DetailedMessageLbl: Label 'Requested %1 units of item %2, but only %3 units are available.', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoErrorWhenStockCoversTheRequest()
    var
        PickValidator: Codeunit "Pick Validator";
        Any: Codeunit Any;
        RequestedQty: Integer;
    begin
        // [SCENARIO] A pick below the available quantity is allowed
        RequestedQty := Any.IntegerInRange(1, 40);

        // [WHEN] validating a pick with more stock than requested
        // [THEN] the call completes without any error
        PickValidator.ValidatePick('TRYAL-EH1', RequestedQty, RequestedQty + Any.IntegerInRange(1, 40));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoErrorWhenRequestedEqualsAvailable()
    var
        PickValidator: Codeunit "Pick Validator";
        Any: Codeunit Any;
        Quantity: Integer;
    begin
        // [SCENARIO] Picking exactly the available quantity is allowed
        Quantity := Any.IntegerInRange(1, 80);

        // [WHEN] validating a pick of exactly the available quantity
        // [THEN] the call completes without any error
        PickValidator.ValidatePick('TRYAL-EH2', Quantity, Quantity);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShortageRaisesTheExactUserFacingMessage()
    var
        PickValidator: Codeunit "Pick Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ItemCode: Code[20];
        RequestedQty: Integer;
        AvailableQty: Integer;
    begin
        // [SCENARIO] The shortage error's user-facing message names the requested quantity and the item
        ItemCode := CopyStr(UpperCase(Any.AlphabeticText(10)), 1, MaxStrLen(ItemCode));
        AvailableQty := Any.IntegerInRange(1, 40);
        RequestedQty := AvailableQty + Any.IntegerInRange(1, 40);

        // [WHEN] validating a pick that exceeds the available quantity
        asserterror PickValidator.ValidatePick(ItemCode, RequestedQty, AvailableQty);

        // [THEN] the raised error carries exactly the promised message
        Assert.AreEqual(StrSubstNo(ShortMessageLbl, RequestedQty, ItemCode), GetLastErrorText(),
            'Expected the shortage error''s user-facing message to be built from the actual quantity and item code — mind the exact wording and the final period');
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShortageErrorIsCollectible()
    var
        PickValidator: Codeunit "Pick Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        AvailableQty: Integer;
    begin
        // [SCENARIO] Inside an error-collection scope the shortage error is gathered, not thrown
        AvailableQty := Any.IntegerInRange(1, 40);

        // [WHEN] validating a failing pick inside a collection scope
        PickValidator.ValidatePick('TRYAL-EH4', AvailableQty + Any.IntegerInRange(1, 40), AvailableQty);

        // [THEN] execution continued past the error and the error was collected
        Assert.IsTrue(HasCollectedErrors(),
            'Expected the shortage error to be marked collectible so a validation run in an error-collection scope can gather it and continue — if this test failed with your own error message instead, the error stopped execution because it is not collectible');
        ClearCollectedErrors();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CollectedErrorCarriesTheExactDetailedMessage()
    var
        PickValidator: Codeunit "Pick Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CollectedErrors: List of [ErrorInfo];
        ShortageErrorInfo: ErrorInfo;
        ItemCode: Code[20];
        RequestedQty: Integer;
        AvailableQty: Integer;
    begin
        // [SCENARIO] The collected error's detailed message spells out both quantities for troubleshooters
        ItemCode := CopyStr(UpperCase(Any.AlphabeticText(10)), 1, MaxStrLen(ItemCode));
        AvailableQty := Any.IntegerInRange(1, 40);
        RequestedQty := AvailableQty + Any.IntegerInRange(1, 40);

        // [WHEN] validating a failing pick inside a collection scope
        PickValidator.ValidatePick(ItemCode, RequestedQty, AvailableQty);

        // [THEN] exactly one error was collected and its detailed message matches the promised text
        CollectedErrors := GetCollectedErrors(true);
        Assert.AreEqual(1, CollectedErrors.Count(),
            'Expected exactly one collected error for a single failing pick');
        ShortageErrorInfo := CollectedErrors.Get(1);
        Assert.AreEqual(StrSubstNo(DetailedMessageLbl, RequestedQty, ItemCode, AvailableQty), ShortageErrorInfo.DetailedMessage,
            'Expected the detailed message to be built from the actual quantities and item code — mind the exact wording and the final period');
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CollectedErrorCarriesTheThreeCustomDimensions()
    var
        PickValidator: Codeunit "Pick Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CollectedErrors: List of [ErrorInfo];
        Dimensions: Dictionary of [Text, Text];
        ItemCode: Code[20];
        RequestedQty: Integer;
        AvailableQty: Integer;
    begin
        // [SCENARIO] The collected error carries ItemCode, RequestedQty and AvailableQty as custom dimensions
        ItemCode := CopyStr(UpperCase(Any.AlphabeticText(10)), 1, MaxStrLen(ItemCode));
        AvailableQty := Any.IntegerInRange(1, 40);
        RequestedQty := AvailableQty + Any.IntegerInRange(1, 40);

        // [WHEN] validating a failing pick inside a collection scope
        PickValidator.ValidatePick(ItemCode, RequestedQty, AvailableQty);

        // [THEN] the collected error exposes the three promised key/value dimensions
        CollectedErrors := GetCollectedErrors(true);
        Assert.AreEqual(1, CollectedErrors.Count(),
            'Expected exactly one collected error for a single failing pick');
        Dimensions := CollectedErrors.Get(1).CustomDimensions;

        Assert.IsTrue(Dimensions.ContainsKey('ItemCode'),
            StrSubstNo('Expected a custom dimension with key ItemCode on the shortage error, found %1 dimension(s)', Dimensions.Count()));
        Assert.AreEqual(Format(ItemCode), Dimensions.Get('ItemCode'),
            'Expected the ItemCode custom dimension to hold the item code passed to ValidatePick');

        Assert.IsTrue(Dimensions.ContainsKey('RequestedQty'),
            StrSubstNo('Expected a custom dimension with key RequestedQty on the shortage error, found %1 dimension(s)', Dimensions.Count()));
        Assert.AreEqual(Format(RequestedQty), Dimensions.Get('RequestedQty'),
            'Expected the RequestedQty custom dimension to hold the requested quantity as plain digits');

        Assert.IsTrue(Dimensions.ContainsKey('AvailableQty'),
            StrSubstNo('Expected a custom dimension with key AvailableQty on the shortage error, found %1 dimension(s)', Dimensions.Count()));
        Assert.AreEqual(Format(AvailableQty), Dimensions.Get('AvailableQty'),
            'Expected the AvailableQty custom dimension to hold the available quantity as plain digits');
    end;
}
