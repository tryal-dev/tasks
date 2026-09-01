codeunit 50900 "Loyalty Classification Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LoyaltyDataClassification: Codeunit "Loyalty Data Classification";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        Unclassified: Integer;
        Sensitive: Integer;
        Personal: Integer;
        CompanyConfidential: Integer;
        Normal: Integer;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheShippedTablesKeepTheirDataClassification()
    var
        LoyaltyMember: Record "Loyalty Member";
        LoyaltyVisit: Record "Loyalty Visit";
        FieldMetadata: Record "Field";
    begin
        // [SCENARIO] The two tables are submitted exactly as they ship — relaxing a
        // DataClassification would let the Normal baseline do the work the codeunit owes
        Initialize();

        // [WHEN] the shipped field metadata is read back
        // [THEN] every field the exercise turns on still carries the DataClassification it shipped with
        FieldMetadata.Get(Database::"Loyalty Visit", LoyaltyVisit.FieldNo("Partner Store Code"));
        Assert.AreEqual(FieldMetadata.DataClassification::OrganizationIdentifiableInformation, FieldMetadata.DataClassification,
            'Expected "Partner Store Code" to still be OrganizationIdentifiableInformation — the task is to classify that field, not to relax the table');
        FieldMetadata.Get(Database::"Loyalty Visit", LoyaltyVisit.FieldNo("Device Id"));
        Assert.AreEqual(FieldMetadata.DataClassification::EndUserPseudonymousIdentifiers, FieldMetadata.DataClassification,
            'Expected "Device Id" to still be EndUserPseudonymousIdentifiers — the starter tables must be submitted unchanged');
        FieldMetadata.Get(Database::"Loyalty Member", LoyaltyMember.FieldNo("Health Notes"));
        Assert.AreEqual(FieldMetadata.DataClassification::EndUserIdentifiableInformation, FieldMetadata.DataClassification,
            'Expected "Health Notes" to still be EndUserIdentifiableInformation — the starter tables must be submitted unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheVisitCountFieldIsStillAFlowField()
    var
        LoyaltyMember: Record "Loyalty Member";
        FieldMetadata: Record "Field";
    begin
        // [SCENARIO] "Visit Count" is still the FlowField the classification has to leave alone
        Initialize();

        // [WHEN] the shipped field metadata is read back
        FieldMetadata.Get(Database::"Loyalty Member", LoyaltyMember.FieldNo("Visit Count"));

        // [THEN] the field is still a FlowField
        Assert.AreEqual(FieldMetadata.Class::FlowField, FieldMetadata.Class,
            'Expected "Visit Count" to still be a FlowField — the task is to leave it out of the classification, not to turn it into a stored field');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClassifyTableReportsSuccessForTheMemberTable()
    begin
        // [SCENARIO] Classifying a table the extension owns reports that it did the work
        Initialize();

        // [WHEN] the member table is classified
        // [THEN] the call reports success
        Assert.IsTrue(LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Member"),
            'Expected ClassifyTable to return true for the "Loyalty Member" table, which the extension owns');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClassifyTableReportsSuccessForTheVisitTable()
    begin
        // [SCENARIO] Both of the extension's tables report success, not just the first one
        Initialize();

        // [WHEN] the visit table is classified
        // [THEN] the call reports success
        Assert.IsTrue(LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Visit"),
            'Expected ClassifyTable to return true for the "Loyalty Visit" table, which the extension owns');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure MemberNoIsClassifiedAsNormal()
    var
        LoyaltyMember: Record "Loyalty Member";
    begin
        // [SCENARIO] A plain business field ends up on the Normal baseline
        Initialize();

        // [WHEN] the member table is classified
        LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Member");

        // [THEN] "Member No." carries the Normal sensitivity
        Assert.AreEqual(SensitivityName(Normal),
            SensitivityOf(Database::"Loyalty Member", LoyaltyMember.FieldNo("Member No.")),
            'Expected "Member No." to be left on the Normal baseline');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure IdentityFieldsAreClassifiedAsPersonal()
    var
        LoyaltyMember: Record "Loyalty Member";
    begin
        // [SCENARIO] The fields that identify a member are classified as Personal
        Initialize();

        // [WHEN] the member table is classified
        LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Member");

        // [THEN] both identifying fields carry the Personal sensitivity
        Assert.AreEqual(SensitivityName(Personal),
            SensitivityOf(Database::"Loyalty Member", LoyaltyMember.FieldNo("Full Name")),
            'Expected "Full Name" to be classified as Personal');
        Assert.AreEqual(SensitivityName(Personal),
            SensitivityOf(Database::"Loyalty Member", LoyaltyMember.FieldNo("E-Mail")),
            'Expected "E-Mail" to be classified as Personal');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure HealthNotesAreClassifiedAsSensitive()
    var
        LoyaltyMember: Record "Loyalty Member";
    begin
        // [SCENARIO] Health information is classified as Sensitive, not merely Personal
        Initialize();

        // [WHEN] the member table is classified
        LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Member");

        // [THEN] "Health Notes" carries the Sensitive sensitivity
        Assert.AreEqual(SensitivityName(Sensitive),
            SensitivityOf(Database::"Loyalty Member", LoyaltyMember.FieldNo("Health Notes")),
            'Expected "Health Notes" to be classified as Sensitive');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure LoyaltyDiscountIsClassifiedAsCompanyConfidential()
    var
        LoyaltyMember: Record "Loyalty Member";
    begin
        // [SCENARIO] A negotiated commercial term is company confidential
        Initialize();

        // [WHEN] the member table is classified
        LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Member");

        // [THEN] "Loyalty Discount" carries the Company Confidential sensitivity
        Assert.AreEqual(SensitivityName(CompanyConfidential),
            SensitivityOf(Database::"Loyalty Member", LoyaltyMember.FieldNo("Loyalty Discount")),
            'Expected "Loyalty Discount" to be classified as Company Confidential');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure TheVisitCountFlowFieldIsNotClassified()
    var
        LoyaltyMember: Record "Loyalty Member";
    begin
        // [SCENARIO] A FlowField stores nothing, so it gets no Data Sensitivity row
        Initialize();

        // [WHEN] the member table is classified
        LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Member");

        // [THEN] the "Visit Count" FlowField has no Data Sensitivity row at all
        Assert.AreEqual('',
            SensitivityOf(Database::"Loyalty Member", LoyaltyMember.FieldNo("Visit Count")),
            'Expected no Data Sensitivity row for the "Visit Count" FlowField');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure SystemFieldsAreNotClassified()
    var
        LoyaltyMember: Record "Loyalty Member";
    begin
        // [SCENARIO] The platform's own system fields stay out of the classification
        Initialize();

        // [WHEN] the member table is classified
        LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Member");

        // [THEN] the SystemId system field has no Data Sensitivity row
        Assert.AreEqual('',
            SensitivityOf(Database::"Loyalty Member", LoyaltyMember.FieldNo(SystemId)),
            'Expected no Data Sensitivity row for the SystemId system field');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure PlainVisitFieldsAreClassifiedAsNormal()
    var
        LoyaltyVisit: Record "Loyalty Visit";
    begin
        // [SCENARIO] Visit fields with no override stay on the Normal baseline
        Initialize();

        // [WHEN] the visit table is classified
        LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Visit");

        // [THEN] the three fields with no override carry the Normal sensitivity
        Assert.AreEqual(SensitivityName(Normal),
            SensitivityOf(Database::"Loyalty Visit", LoyaltyVisit.FieldNo("Entry No.")),
            'Expected "Entry No." to be left on the Normal baseline');
        Assert.AreEqual(SensitivityName(Normal),
            SensitivityOf(Database::"Loyalty Visit", LoyaltyVisit.FieldNo("Member No.")),
            'Expected "Member No." to be left on the Normal baseline');
        Assert.AreEqual(SensitivityName(Normal),
            SensitivityOf(Database::"Loyalty Visit", LoyaltyVisit.FieldNo("Visit Date")),
            'Expected "Visit Date" to be left on the Normal baseline');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure VisitAmountIsClassifiedAsCompanyConfidential()
    var
        LoyaltyVisit: Record "Loyalty Visit";
    begin
        // [SCENARIO] What a member spent is company confidential
        Initialize();

        // [WHEN] the visit table is classified
        LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Visit");

        // [THEN] Amount carries the Company Confidential sensitivity
        Assert.AreEqual(SensitivityName(CompanyConfidential),
            SensitivityOf(Database::"Loyalty Visit", LoyaltyVisit.FieldNo(Amount)),
            'Expected Amount to be classified as Company Confidential');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure DeviceIdIsClassifiedAsPersonal()
    var
        LoyaltyVisit: Record "Loyalty Visit";
    begin
        // [SCENARIO] A pseudonymous device identifier still points at one person
        Initialize();

        // [WHEN] the visit table is classified
        LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Visit");

        // [THEN] "Device Id" carries the Personal sensitivity
        Assert.AreEqual(SensitivityName(Personal),
            SensitivityOf(Database::"Loyalty Visit", LoyaltyVisit.FieldNo("Device Id")),
            'Expected "Device Id" to be classified as Personal');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure PartnerStoreCodeIsClassifiedAlthoughThePlatformSyncSkipsIt()
    var
        LoyaltyVisit: Record "Loyalty Visit";
    begin
        // [SCENARIO] The platform's own sync never creates a row for an
        // OrganizationIdentifiableInformation field, so it has to be classified explicitly
        Initialize();

        // [WHEN] the visit table is classified
        LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Visit");

        // [THEN] "Partner Store Code" carries the Company Confidential sensitivity
        Assert.AreEqual(SensitivityName(CompanyConfidential),
            SensitivityOf(Database::"Loyalty Visit", LoyaltyVisit.FieldNo("Partner Store Code")),
            'Expected "Partner Store Code" to be classified as Company Confidential — the platform''s own sync skips it, so it needs a row of its own');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure ClassifyingTheSameTableTwiceKeepsTheClassification()
    var
        LoyaltyVisit: Record "Loyalty Visit";
    begin
        // [SCENARIO] The classification is a chore that gets re-run, so it must be repeatable
        // [GIVEN] the visit table has already been classified once
        Initialize();
        LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Visit");

        // [WHEN] the very same classification runs a second time
        LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Visit");

        // [THEN] the run succeeds and the explicitly classified field still holds its sensitivity
        Assert.AreEqual(SensitivityName(CompanyConfidential),
            SensitivityOf(Database::"Loyalty Visit", LoyaltyVisit.FieldNo("Partner Store Code")),
            'Expected a second classification run to leave "Partner Store Code" as Company Confidential instead of failing on an existing row');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure NoLoyaltyFieldIsLeftUnclassified()
    var
        Worksheet: TestPage "Data Classification Worksheet";
        SeenAny: Boolean;
    begin
        // [SCENARIO] Both loyalty tables come out fully classified
        // [GIVEN] the member table has been classified
        Initialize();
        LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Member");

        // [WHEN] the visit table is classified as well
        LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Visit");

        // [THEN] not one row of either table is left Unclassified
        Worksheet.OpenView();
        Worksheet.Filter.SetFilter("Table No",
            Format(Database::"Loyalty Member") + '|' + Format(Database::"Loyalty Visit"));
        SeenAny := Worksheet.First();
        if SeenAny then
            repeat
                Assert.AreNotEqual(SensitivityName(Unclassified), Worksheet."Data Sensitivity".Value,
                    StrSubstNo('Expected every classified loyalty field to carry a sensitivity, but field %1 of table %2 is still unclassified',
                        Worksheet."Field No".Value, Worksheet."Table No".Value));
            until not Worksheet.Next();
        Worksheet.Close();

        Assert.IsTrue(SeenAny, 'Expected the loyalty tables to have Data Sensitivity rows after classification, but the worksheet showed none');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClassifyTableReportsFailureForATableThatDoesNotExist()
    begin
        // [SCENARIO] A table number that is not a supported table is refused
        Initialize();

        // [WHEN] a table number no object uses is classified
        // [THEN] the call reports that nothing was classified
        Assert.IsFalse(LoyaltyDataClassification.ClassifyTable(MissingTableNo()),
            'Expected ClassifyTable to return false for a table number that is not a supported table');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure ClassifyTableLeavesATableTheExtensionDoesNotOwnUntouched()
    var
        Customer: Record Customer;
        SensitivityBefore: Text;
        Classified: Boolean;
    begin
        // [SCENARIO] The chore covers this extension's tables only
        // [GIVEN] the loyalty tables are classified and Customer has whatever it had
        Initialize();
        LoyaltyDataClassification.ClassifyTable(Database::"Loyalty Member");
        SensitivityBefore := SensitivityOf(Database::Customer, Customer.FieldNo(Name));

        // [WHEN] the Customer table is handed to the classification
        Classified := LoyaltyDataClassification.ClassifyTable(Database::Customer);

        // [THEN] nothing is reported and the Customer classification is unchanged
        Assert.IsFalse(Classified, 'Expected ClassifyTable to return false for Customer, a table the extension does not own');
        Assert.AreEqual(SensitivityBefore, SensitivityOf(Database::Customer, Customer.FieldNo(Name)),
            'Expected the classification of the Customer Name field to be left exactly as it was');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure ClassifyFieldAppliesSensitive()
    begin
        // [SCENARIO] One field can be classified as Sensitive on its own
        Initialize();

        // [WHEN] a single field is classified as Sensitive
        // [THEN] the field carries the Sensitive sensitivity
        VerifyClassifyFieldApplies(Sensitive);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure ClassifyFieldAppliesPersonal()
    begin
        // [SCENARIO] One field can be classified as Personal on its own
        Initialize();

        // [WHEN] a single field is classified as Personal
        // [THEN] the field carries the Personal sensitivity
        VerifyClassifyFieldApplies(Personal);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure ClassifyFieldAppliesCompanyConfidential()
    begin
        // [SCENARIO] One field can be classified as Company Confidential on its own
        Initialize();

        // [WHEN] a single field is classified as Company Confidential
        // [THEN] the field carries the Company Confidential sensitivity
        VerifyClassifyFieldApplies(CompanyConfidential);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure ClassifyFieldAppliesNormal()
    begin
        // [SCENARIO] One field can be classified as Normal on its own
        Initialize();

        // [WHEN] a single field is classified as Normal
        // [THEN] the field carries the Normal sensitivity
        VerifyClassifyFieldApplies(Normal);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('LegalDisclaimerNotification')]
    procedure ClassifyFieldReclassifiesAFieldThatAlreadyHasASensitivity()
    var
        LoyaltyVisit: Record "Loyalty Visit";
    begin
        // [SCENARIO] The sensitivity lands on the field whether or not it already had a row
        // [GIVEN] "Visit Date" already carries a Data Sensitivity row
        Initialize();
        DataClassificationMgt.InsertDataSensitivityForField(
            Database::"Loyalty Visit", LoyaltyVisit.FieldNo("Visit Date"), Unclassified);

        // [WHEN] that same field is classified as Personal
        LoyaltyDataClassification.ClassifyField(
            Database::"Loyalty Visit", LoyaltyVisit.FieldNo("Visit Date"), 'Personal');

        // [THEN] the row it already had now carries the Personal sensitivity
        Assert.AreEqual(SensitivityName(Personal),
            SensitivityOf(Database::"Loyalty Visit", LoyaltyVisit.FieldNo("Visit Date")),
            'Expected ClassifyField to reclassify "Visit Date" to Personal instead of failing on the row the field already had');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClassifyFieldRejectsAFieldNumberThatDoesNotExist()
    begin
        // [SCENARIO] Classifying a field the table does not have is an error, not a silent no-op
        Initialize();

        // [WHEN] a field number the member table does not have is classified
        asserterror LoyaltyDataClassification.ClassifyField(Database::"Loyalty Member", MissingFieldNo(), 'Personal');

        // [THEN] the error names the field and the table
        Assert.ExpectedError(
            StrSubstNo('Field %1 does not exist in table %2', MissingFieldNo(), Database::"Loyalty Member"));
    end;

    local procedure VerifyClassifyFieldApplies(Ordinal: Integer)
    var
        LoyaltyVisit: Record "Loyalty Visit";
    begin
        LoyaltyDataClassification.ClassifyField(
            Database::"Loyalty Visit", LoyaltyVisit.FieldNo("Visit Date"), SensitivityArgument(Ordinal));

        Assert.AreEqual(SensitivityName(Ordinal),
            SensitivityOf(Database::"Loyalty Visit", LoyaltyVisit.FieldNo("Visit Date")),
            StrSubstNo('Expected ClassifyField to record the sensitivity %1 it was given for "Visit Date"',
                SensitivityArgument(Ordinal)));
    end;

    local procedure Initialize()
    begin
        Unclassified := 0;
        Sensitive := 1;
        Personal := 2;
        CompanyConfidential := 3;
        Normal := 4;

        // Opening the Data Classification Worksheet populates the whole Data Sensitivity
        // table when the company has no row at all — an expensive path that has nothing to
        // do with what is graded. One row for a field number that exists nowhere keeps it
        // out: the worksheet only shows rows whose field has a caption, so it stays hidden.
        DataClassificationMgt.InsertDataSensitivityForField(Database::Customer, MissingFieldNo(), Unclassified);
    end;

    // The sensitivity as the Data Classification Worksheet spells it, taken from the
    // platform so the comparison does not depend on the container's language.
    local procedure SensitivityName(Ordinal: Integer): Text
    begin
        exit(SelectStr(Ordinal + 1, DataClassificationMgt.GetDataSensitivityOptionString()));
    end;

    // The sensitivity as the task statement spells it — what ClassifyField takes.
    local procedure SensitivityArgument(Ordinal: Integer): Text
    begin
        case Ordinal of
            1:
                exit('Sensitive');
            2:
                exit('Personal');
            3:
                exit('Company Confidential');
            4:
                exit('Normal');
        end;
    end;

    local procedure SensitivityOf(TableNo: Integer; FieldNo: Integer): Text
    var
        Worksheet: TestPage "Data Classification Worksheet";
        Result: Text;
    begin
        Worksheet.OpenView();
        Worksheet.Filter.SetFilter("Table No", Format(TableNo));
        Worksheet.Filter.SetFilter("Field No", Format(FieldNo));
        if Worksheet.First() then
            Result := Worksheet."Data Sensitivity".Value;
        Worksheet.Close();
        exit(Result);
    end;

    local procedure MissingTableNo(): Integer
    begin
        exit(1999999999);
    end;

    local procedure MissingFieldNo(): Integer
    begin
        exit(1999999999);
    end;

    [SendNotificationHandler]
    procedure LegalDisclaimerNotification(var TheNotification: Notification): Boolean
    begin
        exit(true);
    end;
}
