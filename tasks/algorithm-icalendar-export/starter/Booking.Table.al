table 50100 Booking
{
    Caption = 'Booking';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; Location; Text[100])
        {
            Caption = 'Location';
        }
        field(4; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(5; "Start Time"; Time)
        {
            Caption = 'Start Time';
        }
        field(6; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(7; "End Time"; Time)
        {
            Caption = 'End Time';
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
