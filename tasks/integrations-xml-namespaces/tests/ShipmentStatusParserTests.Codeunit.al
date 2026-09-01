codeunit 50900 "Shipment Status Parser Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ShippingNsLbl: Label 'urn:tryal:freight:shipping:v2', Locked = true;
        TrackingNsLbl: Label 'urn:tryal:freight:tracking:v1', Locked = true;
        ForeignNsLbl: Label 'urn:partner:audit:v1', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetShipmentNoReadsTheHeaderUnderADefaultNamespace()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ShipmentNo: Text;
    begin
        ShipmentNo := 'SHP-' + UpperCase(Any.AlphanumericText(8));

        Assert.AreEqual(ShipmentNo,
            Parser.GetShipmentNo(DefaultNsDocument('<Header><ShipmentNo>' + ShipmentNo + '</ShipmentNo></Header><Packages/>')),
            'Expected the content of the ShipmentNo element — a default xmlns declaration puts it in the shipping namespace, so an unprefixed XPath name finds nothing');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetShipmentNoWorksWhenTheShippingNamespaceUsesAPrefix()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ShipmentNo: Text;
    begin
        ShipmentNo := 'SHP-' + UpperCase(Any.AlphanumericText(8));

        Assert.AreEqual(ShipmentNo,
            Parser.GetShipmentNo(
                '<?xml version="1.0" encoding="UTF-8"?>' +
                '<f:ShipmentStatus xmlns:f="' + ShippingNsLbl + '">' +
                '<f:Header><f:ShipmentNo>' + ShipmentNo + '</f:ShipmentNo></f:Header>' +
                '<f:Packages/>' +
                '</f:ShipmentStatus>'),
            'Expected the same ShipmentNo when the sender declares the shipping namespace under a prefix instead of as default — only the URI is stable, never the spelling of the document');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetShipmentNoIgnoresAForeignShipmentNo()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ShipmentNo: Text;
    begin
        ShipmentNo := 'SHP-' + UpperCase(Any.AlphanumericText(8));

        Assert.AreEqual(ShipmentNo,
            Parser.GetShipmentNo(DefaultNsDocument(
                '<aud:ShipmentNo xmlns:aud="' + ForeignNsLbl + '">AUDIT-COPY</aud:ShipmentNo>' +
                '<Header><ShipmentNo>' + ShipmentNo + '</ShipmentNo></Header>' +
                '<Packages/>')),
            'Expected the shipping-namespace ShipmentNo, not the partner''s AUDIT-COPY element that shares the local name but lives in a foreign namespace');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetShipmentNoReturnsEmptyWhenTheHeaderHasNoShipmentNo()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('',
            Parser.GetShipmentNo(DefaultNsDocument(
                '<aud:ShipmentNo xmlns:aud="' + ForeignNsLbl + '">AUDIT-ONLY</aud:ShipmentNo>' +
                '<Header/>' +
                '<Packages/>')),
            'Expected an empty text when the message carries no shipping-namespace ShipmentNo — the foreign AUDIT-ONLY element must not be mistaken for it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountPackagesCountsThePackages()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        PackagesXml: Text;
        PackageCount: Integer;
        i: Integer;
    begin
        PackageCount := Any.IntegerInRange(2, 5);
        for i := 1 to PackageCount do
            PackagesXml += '<Package><Weight unit="kg">1.5</Weight></Package>';

        Assert.AreEqual(PackageCount,
            Parser.CountPackages(DefaultNsDocument('<Header/><Packages>' + PackagesXml + '</Packages>')),
            'Expected one count per Package element in the shipping namespace');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountPackagesIgnoresForeignPackages()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(2,
            Parser.CountPackages(DefaultNsDocument(
                '<Header/>' +
                '<Packages>' +
                '<Package/>' +
                '<aud:Package xmlns:aud="' + ForeignNsLbl + '"/>' +
                '<Package/>' +
                '</Packages>' +
                '<aud:Package xmlns:aud="' + ForeignNsLbl + '"/>')),
            'Expected only the two shipping-namespace packages to count — foreign Package elements share the local name but not the namespace');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountPackagesReturnsZeroForAnEmptyShipment()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(0,
            Parser.CountPackages(DefaultNsDocument('<Header/><Packages/>')),
            'Expected zero for a shipment with no packages — not an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetTrackingNumbersReturnsAllNumbersInDocumentOrder()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TrackingNos: List of [Text];
        FirstNo: Text;
        SecondNo: Text;
        ThirdNo: Text;
    begin
        FirstNo := '1Z-' + UpperCase(Any.AlphanumericText(7));
        SecondNo := '1Z-' + UpperCase(Any.AlphanumericText(7));
        ThirdNo := '1Z-' + UpperCase(Any.AlphanumericText(7));

        TrackingNos := Parser.GetTrackingNumbers(DefaultNsDocument(
            '<Header/>' +
            '<Packages>' +
            '<Package>' + TrackingNoElement('trk', FirstNo) + '</Package>' +
            '<Package>' + TrackingNoElement('trk', SecondNo) + '</Package>' +
            '<Package>' + TrackingNoElement('trk', ThirdNo) + '</Package>' +
            '</Packages>'));

        Assert.AreEqual(3, TrackingNos.Count(),
            'Expected one entry per tracking-namespace TrackingNo element');
        Assert.AreEqual(FirstNo, TrackingNos.Get(1), 'Expected the first package''s tracking number first — document order');
        Assert.AreEqual(SecondNo, TrackingNos.Get(2), 'Expected the second package''s tracking number second — document order');
        Assert.AreEqual(ThirdNo, TrackingNos.Get(3), 'Expected the third package''s tracking number third — document order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetTrackingNumbersHonorsWhateverPrefixTheSenderChose()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TrackingNos: List of [Text];
        TrackingNo: Text;
        SenderPrefix: Text;
    begin
        TrackingNo := '1Z-' + UpperCase(Any.AlphanumericText(7));
        // Fixed first letter keeps the generated prefix clear of the
        // reserved xml* prefix range.
        SenderPrefix := 'p' + Any.AlphabeticText(3);

        TrackingNos := Parser.GetTrackingNumbers(DefaultNsDocument(
            '<Header/>' +
            '<Packages><Package>' + TrackingNoElement(SenderPrefix, TrackingNo) + '</Package></Packages>'));

        Assert.AreEqual(1, TrackingNos.Count(),
            StrSubstNo('Expected the tracking number to be found under the sender-chosen prefix %1 — prefixes are aliases, the namespace URI is the identity', SenderPrefix));
        Assert.AreEqual(TrackingNo, TrackingNos.Get(1),
            'Expected the tracking number''s text content regardless of the prefix the sender picked');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetTrackingNumbersHonorsADefaultNamespaceDeclaredOnTheElement()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TrackingNos: List of [Text];
        TrackingNo: Text;
    begin
        TrackingNo := '1Z-' + UpperCase(Any.AlphanumericText(7));

        TrackingNos := Parser.GetTrackingNumbers(DefaultNsDocument(
            '<Header/>' +
            '<Packages><Package>' +
            '<TrackingNo xmlns="' + TrackingNsLbl + '">' + TrackingNo + '</TrackingNo>' +
            '</Package></Packages>'));

        Assert.AreEqual(1, TrackingNos.Count(),
            'Expected the tracking number to be found when the sender declares the tracking namespace as default directly on the TrackingNo element — no prefix in sight, same namespace');
        Assert.AreEqual(TrackingNo, TrackingNos.Get(1),
            'Expected the text content of the default-namespace-declared TrackingNo element');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetTrackingNumbersIgnoresForeignTrackingNumbers()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TrackingNos: List of [Text];
        TrackingNo: Text;
    begin
        TrackingNo := '1Z-' + UpperCase(Any.AlphanumericText(7));

        TrackingNos := Parser.GetTrackingNumbers(DefaultNsDocument(
            '<Header/>' +
            '<Packages><Package>' +
            '<aud:TrackingNo xmlns:aud="' + ForeignNsLbl + '">AUDIT-TRK</aud:TrackingNo>' +
            TrackingNoElement('trk', TrackingNo) +
            '</Package></Packages>'));

        Assert.AreEqual(1, TrackingNos.Count(),
            'Expected only the tracking-namespace TrackingNo — the partner''s AUDIT-TRK element shares the local name but lives in a foreign namespace');
        Assert.AreEqual(TrackingNo, TrackingNos.Get(1),
            'Expected the real tracking number, not the foreign AUDIT-TRK decoy');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetTrackingNumbersReturnsAnEmptyListForAShipmentWithoutTracking()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
        TrackingNos: List of [Text];
    begin
        TrackingNos := Parser.GetTrackingNumbers(DefaultNsDocument(
            '<Header/>' +
            '<Packages><Package>' +
            '<aud:TrackingNo xmlns:aud="' + ForeignNsLbl + '">AUDIT-TRK</aud:TrackingNo>' +
            '<Weight unit="kg">2.5</Weight>' +
            '</Package></Packages>'));

        Assert.AreEqual(0, TrackingNos.Count(),
            'Expected an empty list when no tracking-namespace TrackingNo exists — the foreign AUDIT-TRK decoy must not sneak in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetWeightUnitReadsTheFirstUnitAttribute()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FirstUnit: Text;
        SecondUnit: Text;
    begin
        FirstUnit := Any.AlphabeticText(3);
        SecondUnit := Any.AlphabeticText(3) + 'x';

        Assert.AreEqual(FirstUnit,
            Parser.GetWeightUnit(DefaultNsDocument(
                '<Header/>' +
                '<Packages>' +
                '<Package><Weight unit="' + FirstUnit + '">12.5</Weight></Package>' +
                '<Package><Weight unit="' + SecondUnit + '">3.25</Weight></Package>' +
                '</Packages>')),
            'Expected the unit attribute of the first Weight element in document order — and note the attribute itself carries no namespace prefix');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetWeightUnitIgnoresAForeignWeightThatComesFirst()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ShippingUnit: Text;
    begin
        ShippingUnit := Any.AlphabeticText(3);

        Assert.AreEqual(ShippingUnit,
            Parser.GetWeightUnit(DefaultNsDocument(
                '<Header/>' +
                '<Packages><Package>' +
                '<aud:Weight xmlns:aud="' + ForeignNsLbl + '" unit="lb">99.9</aud:Weight>' +
                '<Weight unit="' + ShippingUnit + '">12.5</Weight>' +
                '</Package></Packages>')),
            'Expected the unit of the shipping-namespace Weight — the partner''s Weight element earlier in the document shares the local name and carries a unit attribute too, but lives in a foreign namespace and must not mask the real one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetWeightUnitSkipsAWeightWithoutAUnitAttribute()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SecondUnit: Text;
    begin
        SecondUnit := Any.AlphabeticText(3);

        Assert.AreEqual(SecondUnit,
            Parser.GetWeightUnit(DefaultNsDocument(
                '<Header/>' +
                '<Packages>' +
                '<Package><Weight>12.5</Weight></Package>' +
                '<Package><Weight unit="' + SecondUnit + '">3.25</Weight></Package>' +
                '</Packages>')),
            'Expected the first unit attribute found in document order — the first Weight carries none, so the second Weight''s unit is the answer, not an empty text');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetWeightUnitReturnsEmptyWhenNoWeightCarriesOne()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('',
            Parser.GetWeightUnit(DefaultNsDocument(
                '<Header/>' +
                '<Packages>' +
                '<Package><Weight>12.5</Weight></Package>' +
                '<Package><Weight>3.25</Weight></Package>' +
                '</Packages>')),
            'Expected an empty text when no Weight element carries a unit attribute — not an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetWeightUnitReturnsEmptyWhenThereAreNoPackages()
    var
        Parser: Codeunit "Shipment Status Parser";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('',
            Parser.GetWeightUnit(DefaultNsDocument('<Header/><Packages/>')),
            'Expected an empty text for a shipment with no Weight elements at all — not an error');
    end;

    local procedure DefaultNsDocument(InnerXml: Text): Text
    begin
        exit('<?xml version="1.0" encoding="UTF-8"?>' +
            '<ShipmentStatus xmlns="' + ShippingNsLbl + '">' + InnerXml + '</ShipmentStatus>');
    end;

    local procedure TrackingNoElement(Prefix: Text; Value: Text): Text
    begin
        exit(StrSubstNo('<%1:TrackingNo xmlns:%1="%2">%3</%1:TrackingNo>', Prefix, TrackingNsLbl, Value));
    end;
}
