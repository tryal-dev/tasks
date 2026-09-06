codeunit 50100 "Card Number Mask"
{
    procedure MaskDigits(Input: Text): Text
    begin
        // TODO: return Input with every digit except the last four replaced by *,
        // every other character left where it is. The simplest way is to copy
        // Input into a variable and overwrite the digits of that copy in place.
        exit(Input);
    end;

    procedure DigitCount(Input: Text): Integer
    begin
        // TODO: count the characters 0 to 9 in Input.
        exit(0);
    end;
}
