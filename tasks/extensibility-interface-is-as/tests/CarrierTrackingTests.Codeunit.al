codeunit 50900 "Carrier Tracking Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ExpressAirUrlTok: Label 'https://track.expressair.example/', Locked = true;
        DroneUrlTok: Label 'https://drone.tryal.test/track/', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsTrackableIsTrueForExpressAir()
    var
        CarrierTracking: Codeunit "Carrier Tracking";
    begin
        Assert.IsTrue(CarrierTracking.IsTrackable(Carrier::"Express Air"),
            'Expected IsTrackable to return true for Express Air — the codeunit wired to it implements ITrackable');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsTrackableIsFalseForGroundPost()
    var
        CarrierTracking: Codeunit "Carrier Tracking";
    begin
        Assert.IsFalse(CarrierTracking.IsTrackable(Carrier::"Ground Post"),
            'Expected IsTrackable to return false for Ground Post — the codeunit wired to it does not implement ITrackable');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsTrackableIsTrueForATrackingCarrierAddedByAnotherExtension()
    var
        CarrierTracking: Codeunit "Carrier Tracking";
    begin
        Assert.IsTrue(CarrierTracking.IsTrackable(Carrier::"Test Drone"),
            'Expected IsTrackable to return true for Test Drone, a carrier the tests add to the Carrier enum and wire to a codeunit that implements ITrackable — the answer must come from the carrier''s own codeunit, not from a list of known carriers');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsTrackableIsFalseForANonTrackingCarrierAddedByAnotherExtension()
    var
        CarrierTracking: Codeunit "Carrier Tracking";
    begin
        Assert.IsFalse(CarrierTracking.IsTrackable(Carrier::"Test Barge"),
            'Expected IsTrackable to return false for Test Barge, a carrier the tests add to the Carrier enum and wire to a codeunit that implements only "IShipping Carrier"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TrackingLinkOfExpressAirIsItsTrackingUrl()
    var
        CarrierTracking: Codeunit "Carrier Tracking";
        Any: Codeunit Any;
        TrackingNo: Text;
    begin
        TrackingNo := 'EA' + UpperCase(Any.AlphanumericText(10));

        Assert.AreEqual(ExpressAirUrlTok + TrackingNo, CarrierTracking.TrackingLink(Carrier::"Express Air", TrackingNo),
            StrSubstNo('Expected the tracking link of Express Air for tracking number %1 to be %2 immediately followed by the tracking number', TrackingNo, ExpressAirUrlTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TrackingLinkOfGroundPostIsEmpty()
    var
        CarrierTracking: Codeunit "Carrier Tracking";
        Any: Codeunit Any;
    begin
        Assert.AreEqual('', CarrierTracking.TrackingLink(Carrier::"Ground Post", 'GP' + UpperCase(Any.AlphanumericText(10))),
            'Expected an empty tracking link for Ground Post — it does not track parcels, so there is no URL to build');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TrackingLinkFollowsATrackingCarrierAddedByAnotherExtension()
    var
        CarrierTracking: Codeunit "Carrier Tracking";
        Any: Codeunit Any;
        TrackingNo: Text;
    begin
        TrackingNo := 'DR' + UpperCase(Any.AlphanumericText(10));

        Assert.AreEqual(DroneUrlTok + TrackingNo, CarrierTracking.TrackingLink(Carrier::"Test Drone", TrackingNo),
            StrSubstNo('Expected the tracking link of Test Drone, a carrier the tests add to the Carrier enum, to be its own codeunit''s TrackingUrl (%1 followed by the tracking number) — the dispatcher must not hardcode the built-in carriers', DroneUrlTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TrackingLinkIsEmptyForANonTrackingCarrierAddedByAnotherExtension()
    var
        CarrierTracking: Codeunit "Carrier Tracking";
        Any: Codeunit Any;
    begin
        Assert.AreEqual('', CarrierTracking.TrackingLink(Carrier::"Test Barge", 'TB' + UpperCase(Any.AlphanumericText(10))),
            'Expected an empty tracking link for Test Barge, a carrier the tests add to the Carrier enum and wire to a codeunit that implements only "IShipping Carrier" — TrackingLink must neither raise an error nor invent a URL for it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExpressAirsCodeunitAnswersAsITrackable()
    var
        Any: Codeunit Any;
        TrackingNo: Text;
        Url: Text;
    begin
        TrackingNo := 'EA' + UpperCase(Any.AlphanumericText(10));

        if not TryTrackingUrlThroughUncheckedCast(Carrier::"Express Air", TrackingNo, Url) then
            Assert.Fail(StrSubstNo('Expected the codeunit wired to Express Air to implement ITrackable itself, but treating it as ITrackable failed: %1', GetLastErrorText()));

        Assert.AreEqual(ExpressAirUrlTok + TrackingNo, Url,
            StrSubstNo('Expected the TrackingUrl of the codeunit wired to Express Air to be %1 immediately followed by the tracking number', ExpressAirUrlTok));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GroundPostsCodeunitCannotBeTreatedAsITrackable()
    var
        Url: Text;
    begin
        if TryTrackingUrlThroughUncheckedCast(Carrier::"Ground Post", 'GP-TRYAL-1', Url) then
            Assert.Fail(StrSubstNo('Expected treating the codeunit wired to Ground Post as ITrackable to raise an error — Ground Post does not track parcels, so its codeunit must not implement ITrackable, yet it answered "%1"', Url));
    end;

    // The cast is deliberately unguarded: the runtime refuses it for a codeunit that does not
    // implement ITrackable, which is what the design tests rely on.
    [TryFunction]
    local procedure TryTrackingUrlThroughUncheckedCast(CarrierValue: Enum Carrier; TrackingNo: Text; var Url: Text)
    var
        ShippingCarrier: Interface "IShipping Carrier";
    begin
        ShippingCarrier := CarrierValue;
        Url := (ShippingCarrier as ITrackable).TrackingUrl(TrackingNo);
    end;
}
