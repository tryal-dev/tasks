table 50100 "Customer Document Register"
{
    Caption = 'Customer Document Register';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Customer No.", "Document No.")
        {
            Clustered = true;
        }
    }

    // TODO: refuse any write that would give one customer the same non-blank
    // "External Document No." twice, on all three write paths — Insert(true),
    // Modify(true) and Rename. Blank external document nos. may repeat freely, other
    // customers are none of this record's business, and a record must never collide
    // with itself. The error has to name the document already carrying the number,
    // and the check must stay cheap on a customer with hundreds of documents.
}
