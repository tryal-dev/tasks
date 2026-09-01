table 50101 "Lab Batch Reading"
{
    Caption = 'Lab Batch Reading';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            TableRelation = "Lab Batch Header"."Batch No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Reading Date"; Date)
        {
            Caption = 'Reading Date';
        }
        field(4; "Reading Value"; Decimal)
        {
            Caption = 'Reading Value';
        }
    }

    keys
    {
        key(PK; "Batch No.", "Line No.")
        {
            Clustered = true;
        }
        // The header's calculations filter on "Batch No." and "Reading Date";
        // a key covering those fields is what the aggregates run on.
        key(BatchDate; "Batch No.", "Reading Date")
        {
            SumIndexFields = "Reading Value";
        }
    }
}
