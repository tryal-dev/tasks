tableextension 50100 CustomerCertificateExt extends Customer
{
    fields
    {
        field(50100; "Certificate Expiry"; Date)
        {
            Caption = 'Certificate Expiry';
            DataClassification = CustomerContent;
        }
    }
}
