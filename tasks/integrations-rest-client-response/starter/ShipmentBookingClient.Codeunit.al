codeunit 50100 "Shipment Booking Client"
{
    procedure GetShipmentStatus(ShipmentNo: Text; HttpClientHandler: Interface "Http Client Handler"): Text
    begin
        // TODO: send one GET request through HttpClientHandler to
        // https://ship.example.com/api/v1/shipments/<ShipmentNo> and return the
        // status of the shipment, or raise the error the statement describes.
    end;

    procedure BookShipment(CustomerNo: Text; HttpClientHandler: Interface "Http Client Handler"): Text
    begin
        // TODO: send one POST request through HttpClientHandler to
        // https://ship.example.com/api/v1/shipments and return the shipment
        // number the service assigned, or raise the error the statement describes.
    end;
}
