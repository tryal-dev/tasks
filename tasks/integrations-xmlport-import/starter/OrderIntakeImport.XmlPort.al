xmlport 50102 "Order Intake Import"
{
    Caption = 'Order Intake Import';
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(OrderIntake)
        {
            // TODO: mirror the document below this root element — the batch id, then
            // one element per order staged into "Order Intake Header", each carrying
            // its lines staged into "Order Intake Line".
        }
    }
}
