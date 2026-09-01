codeunit 50900 "MCP Tool Surface Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [MCP] [Tool Surface]

    var
        Assert: Codeunit Assert;
        MCPConfig: Codeunit "MCP Config";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RegistersTheConfigurationUnderTheAgreedName()
    var
        MCPToolSurface: Codeunit "MCP Tool Surface";
        ConfigId: Guid;
    begin
        // [SCENARIO] The tool surface is registered under the name agents connect with

        // [WHEN] building the tool surface
        ConfigId := MCPToolSurface.EnsureConfiguration();

        // [THEN] the agreed name resolves back to the id that was returned
        Assert.IsFalse(IsNullGuid(ConfigId),
            'Expected EnsureConfiguration to return the id of the MCP configuration it set up, not an empty GUID');
        Assert.AreEqual(Format(ConfigId), Format(MCPConfig.GetConfigurationIdByName(ConfigurationName())),
            StrSubstNo('Expected an MCP configuration named %1 to exist and to carry the id EnsureConfiguration returned', ConfigurationName()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExposesExactlyTheThreeAgreedApiTools()
    var
        MCPToolSurface: Codeunit "MCP Tool Surface";
        ToolsArray: JsonArray;
        ConfigId: Guid;
    begin
        // [SCENARIO] The surface exposes the three agreed API pages and nothing else

        // [WHEN] building the tool surface
        ConfigId := MCPToolSurface.EnsureConfiguration();

        // [THEN] the exported snapshot lists exactly those three tools
        ToolsArray := ExportedTools(ConfigId);
        Assert.AreEqual(3, ToolsArray.Count(),
            'Expected the configuration to expose exactly one tool per agreed API page — no more, no fewer');
        AssertObjectTypeIsPage(ConfigId, Page::"TryAL Agent Customer API", 'TryAL Agent Customer API');
        AssertObjectTypeIsPage(ConfigId, Page::"TryAL Agent Item API", 'TryAL Agent Item API');
        AssertObjectTypeIsPage(ConfigId, Page::"TryAL Agent Contact API", 'TryAL Agent Contact API');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsTheCustomerLookupToolReadOnly()
    var
        MCPToolSurface: Codeunit "MCP Tool Surface";
        ConfigId: Guid;
    begin
        // [SCENARIO] The customer lookup tool may only read

        // [WHEN] building the tool surface
        ConfigId := MCPToolSurface.EnsureConfiguration();

        // [THEN] only allowRead is granted on the customer tool
        AssertToolFlags(ConfigId, Page::"TryAL Agent Customer API", 'TryAL Agent Customer API', true, false, false, false, false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsTheItemLookupToolReadOnly()
    var
        MCPToolSurface: Codeunit "MCP Tool Surface";
        ConfigId: Guid;
    begin
        // [SCENARIO] The item lookup tool may only read

        // [WHEN] building the tool surface
        ConfigId := MCPToolSurface.EnsureConfiguration();

        // [THEN] only allowRead is granted on the item tool
        AssertToolFlags(ConfigId, Page::"TryAL Agent Item API", 'TryAL Agent Item API', true, false, false, false, false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GrantsTheContactToolEverythingExceptDelete()
    var
        MCPToolSurface: Codeunit "MCP Tool Surface";
        ConfigId: Guid;
    begin
        // [SCENARIO] The contact tool may read, create, modify and run bound actions, but never delete

        // [WHEN] building the tool surface
        ConfigId := MCPToolSurface.EnsureConfiguration();

        // [THEN] every flag except allowDelete is granted on the contact tool
        AssertToolFlags(ConfigId, Page::"TryAL Agent Contact API", 'TryAL Agent Contact API', true, true, true, false, true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesDynamicToolModeAndObjectDiscoveryOff()
    var
        MCPToolSurface: Codeunit "MCP Tool Surface";
        ConfigJson: JsonObject;
        ConfigId: Guid;
    begin
        // [SCENARIO] The agent sees the configured tools only — nothing it can discover on its own

        // [WHEN] building the tool surface
        ConfigId := MCPToolSurface.EnsureConfiguration();

        // [THEN] neither dynamic tool mode nor read-only object discovery is switched on
        ConfigJson := ExportedConfiguration(ConfigId);
        Assert.AreEqual(false, BooleanProperty(ConfigJson, 'enableDynamicToolMode'),
            'Expected dynamic tool mode to stay switched off on the configuration');
        Assert.AreEqual(false, BooleanProperty(ConfigJson, 'discoverReadOnlyObjects'),
            'Expected discovery of read-only objects outside the configuration to stay switched off');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ActivatesTheConfiguration()
    var
        MCPToolSurface: Codeunit "MCP Tool Surface";
        ConfigId: Guid;
    begin
        // [SCENARIO] The finished configuration is active, so agents can actually connect to it

        // [WHEN] building the tool surface
        ConfigId := MCPToolSurface.EnsureConfiguration();

        // [THEN] the configuration can be designated the default one — Business Central refuses that for an
        // inactive configuration with "Only active configurations can be set as the default."
        MCPConfig.SetAsDefaultConfiguration(ConfigId);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTheExistingConfigurationOnASecondRun()
    var
        MCPToolSurface: Codeunit "MCP Tool Surface";
        FirstConfigId: Guid;
        SecondConfigId: Guid;
    begin
        // [GIVEN] the tool surface has already been built once
        FirstConfigId := MCPToolSurface.EnsureConfiguration();

        // [WHEN] building it again, as an install or upgrade codeunit would on every run
        SecondConfigId := MCPToolSurface.EnsureConfiguration();

        // [THEN] the same configuration is returned instead of a second one
        Assert.AreEqual(Format(FirstConfigId), Format(SecondConfigId),
            'Expected a second run to return the id of the existing configuration rather than creating another one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DoesNotAddTheToolsTwiceOnASecondRun()
    var
        MCPToolSurface: Codeunit "MCP Tool Surface";
        ToolsArray: JsonArray;
        ConfigId: Guid;
    begin
        // [GIVEN] the tool surface has already been built once
        MCPToolSurface.EnsureConfiguration();

        // [WHEN] building it again
        ConfigId := MCPToolSurface.EnsureConfiguration();

        // [THEN] the configuration still exposes the same three tools
        ToolsArray := ExportedTools(ConfigId);
        Assert.AreEqual(3, ToolsArray.Count(),
            'Expected a second run to leave the tool list untouched instead of adding the tools again');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BuildsAConfigurationBusinessCentralReportsAsWarningFree()
    var
        MCPToolSurface: Codeunit "MCP Tool Surface";
        TempMCPConfigWarning: Record "MCP Config Warning";
        ConfigId: Guid;
    begin
        // [SCENARIO] A freshly built surface has nothing for the platform to complain about

        // [WHEN] building the tool surface
        ConfigId := MCPToolSurface.EnsureConfiguration();

        // [THEN] the platform reports no warnings for it
        Assert.IsFalse(MCPConfig.FindWarningsForConfiguration(ConfigId, TempMCPConfigWarning),
            StrSubstNo('Expected the finished configuration to be free of warnings, got %1', WarningTypes(TempMCPConfigWarning)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RepairsAMissingReadToolWarning()
    var
        MCPToolSurface: Codeunit "MCP Tool Surface";
        ConfigId: Guid;
        Repaired: Integer;
    begin
        // [GIVEN] a surface whose contact tool lost its read permission
        ConfigId := MCPToolSurface.EnsureConfiguration();
        RevokeRead(ConfigId, Page::"TryAL Agent Contact API", 'TryAL Agent Contact API');
        AssertWarningCount(ConfigId, 1);

        // [WHEN] repairing the configuration
        Repaired := MCPToolSurface.RepairConfiguration(ConfigId);

        // [THEN] the one warning is reported as repaired
        Assert.AreEqual(1, Repaired,
            'Expected RepairConfiguration to report the single warning it applied a recommended action for');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RepairsEveryWarningTheConfigurationReports()
    var
        MCPToolSurface: Codeunit "MCP Tool Surface";
        ConfigId: Guid;
        Repaired: Integer;
    begin
        // [GIVEN] a surface with two tools that write but may no longer read
        ConfigId := MCPToolSurface.EnsureConfiguration();
        RevokeRead(ConfigId, Page::"TryAL Agent Contact API", 'TryAL Agent Contact API');
        GrantModifyAndRevokeRead(ConfigId, Page::"TryAL Agent Customer API", 'TryAL Agent Customer API');
        AssertWarningCount(ConfigId, 2);

        // [WHEN] repairing the configuration
        Repaired := MCPToolSurface.RepairConfiguration(ConfigId);

        // [THEN] both warnings are reported as repaired
        Assert.AreEqual(2, Repaired,
            'Expected RepairConfiguration to work through every warning the configuration reports, not just the first one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeavesNoWarningsBehindAfterARepair()
    var
        MCPToolSurface: Codeunit "MCP Tool Surface";
        TempMCPConfigWarning: Record "MCP Config Warning";
        ConfigId: Guid;
    begin
        // [GIVEN] a surface whose contact tool lost its read permission
        ConfigId := MCPToolSurface.EnsureConfiguration();
        RevokeRead(ConfigId, Page::"TryAL Agent Contact API", 'TryAL Agent Contact API');

        // [WHEN] repairing the configuration
        MCPToolSurface.RepairConfiguration(ConfigId);

        // [THEN] the platform no longer reports a warning for it
        Assert.IsFalse(MCPConfig.FindWarningsForConfiguration(ConfigId, TempMCPConfigWarning),
            StrSubstNo('Expected the repaired configuration to be free of warnings, got %1', WarningTypes(TempMCPConfigWarning)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RestoresReadAccessWithoutGrantingDelete()
    var
        MCPToolSurface: Codeunit "MCP Tool Surface";
        ConfigId: Guid;
    begin
        // [GIVEN] a surface whose contact tool lost its read permission
        ConfigId := MCPToolSurface.EnsureConfiguration();
        RevokeRead(ConfigId, Page::"TryAL Agent Contact API", 'TryAL Agent Contact API');

        // [WHEN] repairing the configuration
        MCPToolSurface.RepairConfiguration(ConfigId);

        // [THEN] the contact tool reads again and is otherwise unchanged
        AssertToolFlags(ConfigId, Page::"TryAL Agent Contact API", 'TryAL Agent Contact API', true, true, true, false, true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RepairsOnlyTheToolThePlatformWarnsAbout()
    var
        MCPToolSurface: Codeunit "MCP Tool Surface";
        ConfigId: Guid;
        Repaired: Integer;
    begin
        // [GIVEN] a surface with read switched off both on a write-enabled tool and on a lookup tool
        ConfigId := MCPToolSurface.EnsureConfiguration();
        RevokeRead(ConfigId, Page::"TryAL Agent Contact API", 'TryAL Agent Contact API');
        RevokeRead(ConfigId, Page::"TryAL Agent Item API", 'TryAL Agent Item API');
        AssertWarningCount(ConfigId, 1);

        // [WHEN] repairing the configuration
        Repaired := MCPToolSurface.RepairConfiguration(ConfigId);

        // [THEN] only the warned tool was acted on; the lookup tool keeps the permissions it had
        Assert.AreEqual(1, Repaired,
            'Expected RepairConfiguration to act on the one warning the platform reports, not on every tool in the configuration');
        AssertToolFlags(ConfigId, Page::"TryAL Agent Item API", 'TryAL Agent Item API', false, false, false, false, false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportsZeroRepairsForAHealthyConfiguration()
    var
        MCPToolSurface: Codeunit "MCP Tool Surface";
        ConfigId: Guid;
        Repaired: Integer;
    begin
        // [GIVEN] a freshly built, warning-free surface
        ConfigId := MCPToolSurface.EnsureConfiguration();

        // [WHEN] repairing the configuration
        Repaired := MCPToolSurface.RepairConfiguration(ConfigId);

        // [THEN] nothing was repaired
        Assert.AreEqual(0, Repaired,
            'Expected RepairConfiguration to report no repairs for a configuration the platform is happy with');
    end;

    local procedure ConfigurationName(): Text[100]
    begin
        exit('TryAL Agent Surface');
    end;

    local procedure ToolIdFor(ConfigId: Guid; APIPageId: Integer; PageName: Text): Guid
    var
        ObjectType: Option Page,Query;
        ToolId: Guid;
    begin
        ToolId := MCPConfig.GetAPIToolId(ConfigId, APIPageId, ObjectType::Page);
        Assert.IsFalse(IsNullGuid(ToolId),
            StrSubstNo('Expected the configuration to expose an API tool for page %1', PageName));
        exit(ToolId);
    end;

    local procedure RevokeRead(ConfigId: Guid; APIPageId: Integer; PageName: Text)
    begin
        MCPConfig.AllowRead(ToolIdFor(ConfigId, APIPageId, PageName), false);
    end;

    local procedure GrantModifyAndRevokeRead(ConfigId: Guid; APIPageId: Integer; PageName: Text)
    var
        ToolId: Guid;
    begin
        ToolId := ToolIdFor(ConfigId, APIPageId, PageName);
        MCPConfig.AllowModify(ToolId, true);
        MCPConfig.AllowRead(ToolId, false);
    end;

    local procedure AssertWarningCount(ConfigId: Guid; ExpectedCount: Integer)
    var
        TempMCPConfigWarning: Record "MCP Config Warning";
    begin
        MCPConfig.FindWarningsForConfiguration(ConfigId, TempMCPConfigWarning);
        Assert.AreEqual(ExpectedCount, TempMCPConfigWarning.Count(),
            StrSubstNo(
                'Expected switching a write tool''s read permission off to raise one Missing Read Tool warning per affected tool, got %1',
                WarningTypes(TempMCPConfigWarning)));
    end;

    local procedure WarningTypes(var TempMCPConfigWarning: Record "MCP Config Warning") Description: Text
    begin
        if not TempMCPConfigWarning.FindSet() then
            exit('no warnings');

        repeat
            if Description <> '' then
                Description += ', ';
            Description += Format(TempMCPConfigWarning."Warning Type");
        until TempMCPConfigWarning.Next() = 0;
    end;

    local procedure ExportedConfiguration(ConfigId: Guid) ConfigJson: JsonObject
    var
        TempBlob: Codeunit "Temp Blob";
        ConfigOutStream: OutStream;
        ConfigInStream: InStream;
    begin
        TempBlob.CreateOutStream(ConfigOutStream, TextEncoding::UTF8);
        MCPConfig.ExportConfiguration(ConfigId, ConfigOutStream);
        TempBlob.CreateInStream(ConfigInStream, TextEncoding::UTF8);
        Assert.IsTrue(ConfigJson.ReadFrom(ConfigInStream),
            'Expected the configuration to export as a readable JSON snapshot');
    end;

    local procedure ExportedTools(ConfigId: Guid) ToolsArray: JsonArray
    var
        ToolsToken: JsonToken;
    begin
        Assert.IsTrue(ExportedConfiguration(ConfigId).Get('tools', ToolsToken),
            'Expected the exported configuration snapshot to carry a "tools" array');
        ToolsArray := ToolsToken.AsArray();
    end;

    local procedure ExportedTool(ConfigId: Guid; APIPageId: Integer; PageName: Text) ToolJson: JsonObject
    var
        ToolsArray: JsonArray;
        ToolToken: JsonToken;
        ObjectIdToken: JsonToken;
        Candidate: JsonObject;
    begin
        ToolsArray := ExportedTools(ConfigId);
        foreach ToolToken in ToolsArray do begin
            Candidate := ToolToken.AsObject();
            if Candidate.Get('objectId', ObjectIdToken) then
                if ObjectIdToken.AsValue().AsInteger() = APIPageId then
                    exit(Candidate);
        end;

        Assert.Fail(StrSubstNo('Expected the configuration to expose an API tool for page %1', PageName));
    end;

    local procedure AssertObjectTypeIsPage(ConfigId: Guid; APIPageId: Integer; PageName: Text)
    var
        ObjectTypeToken: JsonToken;
        ToolJson: JsonObject;
    begin
        ToolJson := ExportedTool(ConfigId, APIPageId, PageName);
        Assert.IsTrue(ToolJson.Get('objectType', ObjectTypeToken),
            StrSubstNo('Expected the exported tool for %1 to carry an "objectType" property', PageName));
        Assert.AreEqual('Page', ObjectTypeToken.AsValue().AsText(),
            StrSubstNo('Expected %1 to be exposed as an API page tool', PageName));
    end;

    local procedure AssertToolFlags(ConfigId: Guid; APIPageId: Integer; PageName: Text; ExpectedRead: Boolean; ExpectedCreate: Boolean; ExpectedModify: Boolean; ExpectedDelete: Boolean; ExpectedBoundActions: Boolean)
    var
        ToolJson: JsonObject;
    begin
        ToolJson := ExportedTool(ConfigId, APIPageId, PageName);
        Assert.AreEqual(ExpectedRead, BooleanProperty(ToolJson, 'allowRead'),
            StrSubstNo('Expected allowRead on the %1 tool', PageName));
        Assert.AreEqual(ExpectedCreate, BooleanProperty(ToolJson, 'allowCreate'),
            StrSubstNo('Expected allowCreate on the %1 tool', PageName));
        Assert.AreEqual(ExpectedModify, BooleanProperty(ToolJson, 'allowModify'),
            StrSubstNo('Expected allowModify on the %1 tool', PageName));
        Assert.AreEqual(ExpectedDelete, BooleanProperty(ToolJson, 'allowDelete'),
            StrSubstNo('Expected allowDelete on the %1 tool', PageName));
        Assert.AreEqual(ExpectedBoundActions, BooleanProperty(ToolJson, 'allowBoundActions'),
            StrSubstNo('Expected allowBoundActions on the %1 tool', PageName));
    end;

    local procedure BooleanProperty(JsonObj: JsonObject; PropertyName: Text): Boolean
    var
        PropertyToken: JsonToken;
    begin
        Assert.IsTrue(JsonObj.Get(PropertyName, PropertyToken),
            StrSubstNo('Expected the exported snapshot to carry a "%1" property', PropertyName));
        exit(PropertyToken.AsValue().AsBoolean());
    end;
}
