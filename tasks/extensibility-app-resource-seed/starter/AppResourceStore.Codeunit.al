codeunit 50101 "App Resource Store"
{
    // Stands in for NavApp.ListResources / NavApp.GetResourceAsJson: this platform
    // generates app.json itself and accepts only .al files, so a real
    // resourceFolders file cannot ship with the submission.

    var
        ResourceNotFoundErr: Label 'Resource ''%1'' not found.', Comment = '%1 = resource name';

    procedure ListResources(): List of [Text]
    var
        Names: List of [Text];
    begin
        Names.Add('region-seed.json');
        Names.Add('region-seed-extra.json');
        exit(Names);
    end;

    procedure GetResourceAsJson(ResourceName: Text): JsonObject
    var
        Fixture: JsonObject;
    begin
        Fixture.ReadFrom(GetResourceText(ResourceName));
        exit(Fixture);
    end;

    local procedure GetResourceText(ResourceName: Text): Text
    begin
        case ResourceName of
            'region-seed.json':
                exit('{"regions":[{"code":"NORTH","description":"Northern district","taxRate":21.0},{"code":"SOUTH","description":"Southern district","taxRate":19.5},{"code":"WEST","description":"Western district","taxRate":17.25}]}');
            'region-seed-extra.json':
                exit('{"regions":[{"code":"EAST","description":"Eastern district","taxRate":23.0},{"code":"CENTRAL","description":"Central district","taxRate":20.0}]}');
        end;
        Error(ResourceNotFoundErr, ResourceName);
    end;
}
