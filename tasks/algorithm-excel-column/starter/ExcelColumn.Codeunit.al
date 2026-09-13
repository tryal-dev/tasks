codeunit 50100 "Excel Column"
{
    procedure ColumnLetters(Index: Integer): Text
    begin
        // TODO: reject an index below 1, then spell the index as column
        // letters: 1 = A, 26 = Z, 27 = AA, 703 = AAA.
        exit('');
    end;

    procedure ColumnIndex(Letters: Text): Integer
    begin
        // TODO: reject anything that is not one or more letters, then turn
        // the letters (in any case) back into the 1-based column index.
        exit(0);
    end;
}
