codeunit 50100 "JWT Claims Reader"
{
    procedure DecodePayload(Token: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        Segments: List of [Text];
    begin
        // TODO: this naive decode blows up on most real tokens — a JWT segment is
        // base64url, and the platform decoder only speaks the standard alphabet.
        // It also trusts that the token really has three segments.
        Segments := Token.Split('.');
        exit(Base64Convert.FromBase64(Segments.Get(2)));
    end;

    procedure GetClaim(Token: Text; ClaimName: Text): Text
    begin
        // TODO: read ClaimName out of the decoded payload; '' when it is not there.
    end;

    procedure ValidateToken(Token: Text; AsOf: DateTime; AllowedIssuers: List of [Text]; AllowedAudiences: List of [Text]): Text
    begin
        // TODO: return one of the six result codes listed in the task statement.
    end;
}
