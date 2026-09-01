codeunit 50100 "Work Stack"
{
    var
        Items: List of [Text];

    procedure Push(Value: Text)
    begin
        // TODO: append Value at the back of Items.
    end;

    procedure Pop(var Value: Text): Boolean
    begin
        // TODO: hand out and remove the value at the back; false when nothing is stored.
    end;

    procedure Peek(): Text
    begin
        // TODO: return the value at the back without removing it; '' when nothing is stored.
    end;

    procedure Enqueue(Value: Text)
    begin
        // TODO: append Value at the back of Items.
    end;

    procedure Dequeue(var Value: Text): Boolean
    begin
        // TODO: hand out and remove the value at the front; false when nothing is stored.
    end;

    procedure Discard(Value: Text): Boolean
    begin
        // TODO: remove the first occurrence of Value counted from the front; false when absent.
    end;

    procedure Reverse()
    begin
        // TODO: reverse the order of the stored values in place.
    end;

    procedure Count(): Integer
    begin
        // TODO: return how many values are stored.
    end;
}
