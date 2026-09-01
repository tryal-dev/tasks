codeunit 50100 "Thumbnail Generator"
{
    procedure GetDimensions(ImageBase64: Text; var Width: Integer; var Height: Integer)
    begin
        // TODO: load ImageBase64 as an image and return its pixel width and height.
    end;

    procedure CreateThumbnail(ImageBase64: Text; MaxDimension: Integer): Text
    begin
        // TODO: shrink the image proportionally so neither side exceeds MaxDimension,
        // and return the result as Base64 — still a PNG.
    end;
}
