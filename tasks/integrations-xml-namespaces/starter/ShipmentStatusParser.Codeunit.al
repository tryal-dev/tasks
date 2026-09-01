codeunit 50100 "Shipment Status Parser"
{
    // This is the parser that worked against the sandbox samples — the ones
    // without namespace declarations. Production messages declare namespaces,
    // and every query below silently stopped matching.

    procedure GetShipmentNo(XmlPayload: Text): Text
    var
        Doc: XmlDocument;
        ShipmentNoNode: XmlNode;
    begin
        XmlDocument.ReadFrom(XmlPayload, Doc);
        // TODO: finds nothing — an unprefixed XPath name means
        // "this element in NO namespace".
        if not Doc.SelectSingleNode('/ShipmentStatus/Header/ShipmentNo', ShipmentNoNode) then
            exit('');
        exit(ShipmentNoNode.AsXmlElement().InnerText());
    end;

    procedure CountPackages(XmlPayload: Text): Integer
    var
        Doc: XmlDocument;
        PackageNodes: XmlNodeList;
    begin
        XmlDocument.ReadFrom(XmlPayload, Doc);
        // TODO: same trap — zero matches on a namespaced document.
        Doc.SelectNodes('//Package', PackageNodes);
        exit(PackageNodes.Count());
    end;

    procedure GetTrackingNumbers(XmlPayload: Text): List of [Text]
    var
        Doc: XmlDocument;
        TrackingNode: XmlNode;
        TrackingNodes: XmlNodeList;
        TrackingNos: List of [Text];
    begin
        XmlDocument.ReadFrom(XmlPayload, Doc);
        // TODO: never matches the tracking-namespace elements.
        Doc.SelectNodes('//TrackingNo', TrackingNodes);
        foreach TrackingNode in TrackingNodes do
            TrackingNos.Add(TrackingNode.AsXmlElement().InnerText());
        exit(TrackingNos);
    end;

    procedure GetWeightUnit(XmlPayload: Text): Text
    var
        Doc: XmlDocument;
        UnitNode: XmlNode;
    begin
        XmlDocument.ReadFrom(XmlPayload, Doc);
        // TODO: the Weight element lives in a namespace too.
        if not Doc.SelectSingleNode('//Weight/@unit', UnitNode) then
            exit('');
        exit(UnitNode.AsXmlAttribute().Value());
    end;
}
