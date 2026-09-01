codeunit 50100 "Form Url Encoded Client"
{
    procedure BuildFormBody(Fields: Dictionary of [Text, Text]): Text
    begin
        // TODO: write every field as key=value with both halves percent-encoded,
        // and join the pairs with a single &.
    end;

    procedure ParseFormBody(FormText: Text): Dictionary of [Text, Text]
    begin
        // TODO: split on & and on the first = of each pair, then decode both
        // halves — remember what a raw + means and what %2B means.
    end;

    procedure PostForm(Url: Text; Fields: Dictionary of [Text, Text]; HttpClientHandler: Interface "Http Client Handler"; var ResponseFields: Dictionary of [Text, Text]): Boolean
    begin
        // TODO: POST the encoded form through HttpClientHandler with the form
        // media type on the content, then parse the response body.
    end;
}
