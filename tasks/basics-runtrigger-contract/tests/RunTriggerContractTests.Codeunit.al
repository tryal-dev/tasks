codeunit 50900 "RunTrigger Contract Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RegisterMemberStampsEnrolledOnWithWorkDate()
    var
        Member: Record "Loyalty Member";
        Registration: Codeunit "Member Registration";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The normal registration path runs the OnInsert trigger, so a new member gets the enrollment stamp
        Member.Init();
        Member."Member No." := 'TRYAL-M601';

        Registration.RegisterMember(Member);

        Member.Get('TRYAL-M601');
        Assert.AreEqual(WorkDate(), Member."Enrolled On",
            'Expected RegisterMember to stamp "Enrolled On" with WorkDate() — the registration path must run the OnInsert trigger');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RegisterMemberOverwritesACallerSetEnrolledOn()
    var
        Member: Record "Loyalty Member";
        Registration: Codeunit "Member Registration";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] The OnInsert stamp is unconditional — a pre-filled enrollment date is overwritten on the registration path
        Member.Init();
        Member."Member No." := 'TRYAL-M602';
        Member."Enrolled On" := WorkDate() + Any.IntegerInRange(10, 200);

        Registration.RegisterMember(Member);

        Member.Get('TRYAL-M602');
        Assert.AreEqual(WorkDate(), Member."Enrolled On",
            'Expected RegisterMember to overwrite a caller-set "Enrolled On" with WorkDate() — the OnInsert trigger must stamp unconditionally, not only when the field is blank');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MigrateMemberKeepsTheImportedEnrolledOn()
    var
        Member: Record "Loyalty Member";
        Registration: Codeunit "Member Registration";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ImportedDate: Date;
    begin
        // [SCENARIO] The migration path skips the OnInsert trigger, so a historical enrollment date survives the import
        ImportedDate := WorkDate() - Any.IntegerInRange(30, 3000);
        Member.Init();
        Member."Member No." := 'TRYAL-M603';
        Member."Enrolled On" := ImportedDate;

        Registration.MigrateMember(Member);

        Member.Get('TRYAL-M603');
        Assert.AreEqual(ImportedDate, Member."Enrolled On",
            'Expected MigrateMember to keep the imported "Enrolled On" — the migration path must not run the OnInsert trigger');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdateMemberSavesTheChangedFields()
    var
        Member: Record "Loyalty Member";
        Registration: Codeunit "Member Registration";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The normal update path writes the caller's changes to the database
        SeedMember(Member, 'TRYAL-M604');
        Member.Description := 'Renamed by the update path';

        Registration.UpdateMember(Member);

        Member.Get('TRYAL-M604');
        Assert.AreEqual('Renamed by the update path', Member.Description,
            'Expected UpdateMember to save the changed fields to the database');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UpdateMemberStampsLastUpdatedOnWithWorkDate()
    var
        Member: Record "Loyalty Member";
        Registration: Codeunit "Member Registration";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The normal update path runs the OnModify trigger, so the change is stamped
        SeedMember(Member, 'TRYAL-M605');
        Member.Description := 'Touched by a user';

        Registration.UpdateMember(Member);

        Member.Get('TRYAL-M605');
        Assert.AreEqual(WorkDate(), Member."Last Updated On",
            'Expected UpdateMember to stamp "Last Updated On" with WorkDate() — the update path must run the OnModify trigger');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PatchMigratedMemberSavesTheChangedFields()
    var
        Member: Record "Loyalty Member";
        Registration: Codeunit "Member Registration";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The data-fix path still writes the corrected values to the database
        SeedMember(Member, 'TRYAL-M606');
        Member.Description := 'Corrected by the data fix';

        Registration.PatchMigratedMember(Member);

        Member.Get('TRYAL-M606');
        Assert.AreEqual('Corrected by the data fix', Member.Description,
            'Expected PatchMigratedMember to save the changed fields to the database');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PatchMigratedMemberKeepsTheImportedLastUpdatedOn()
    var
        Member: Record "Loyalty Member";
        Registration: Codeunit "Member Registration";
        Assert: Codeunit Assert;
        ImportedUpdateDate: Date;
    begin
        // [SCENARIO] The data-fix path skips the OnModify trigger, so the imported audit date survives the patch
        SeedMember(Member, 'TRYAL-M607');
        ImportedUpdateDate := Member."Last Updated On";
        Member.Description := 'Patched without an audit stamp';

        Registration.PatchMigratedMember(Member);

        Member.Get('TRYAL-M607');
        Assert.AreEqual(ImportedUpdateDate, Member."Last Updated On",
            'Expected PatchMigratedMember to keep the imported "Last Updated On" — the data-fix path must not run the OnModify trigger');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TableItselfStampsEnrolledOnWhenInsertRunsTriggers()
    var
        Member: Record "Loyalty Member";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
    begin
        // [SCENARIO] The enrollment stamp lives in the table's OnInsert trigger, not in the codeunit
        Member.Init();
        Member."Member No." := 'TRYAL-M608';
        Member."Enrolled On" := WorkDate() - Any.IntegerInRange(30, 3000);

        Member.Insert(true);

        Member.Get('TRYAL-M608');
        Assert.AreEqual(WorkDate(), Member."Enrolled On",
            'Expected the "Loyalty Member" table''s own OnInsert trigger to stamp "Enrolled On" with WorkDate() — the stamping must live in the table, not in the codeunit');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TableItselfStampsLastUpdatedOnWhenModifyRunsTriggers()
    var
        Member: Record "Loyalty Member";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The update stamp lives in the table's OnModify trigger, not in the codeunit
        SeedMember(Member, 'TRYAL-M609');
        Member.Description := 'Changed directly on the table';

        Member.Modify(true);

        Member.Get('TRYAL-M609');
        Assert.AreEqual(WorkDate(), Member."Last Updated On",
            'Expected the "Loyalty Member" table''s own OnModify trigger to stamp "Last Updated On" with WorkDate() — the stamping must live in the table, not in the codeunit');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FieldsAreDeclaredWithThePromisedLengths()
    var
        Member: Record "Loyalty Member";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The field declarations match the statement
        Assert.AreEqual(20, MaxStrLen(Member."Member No."),
            'Expected "Member No." to be declared as Code[20] — its maximum length must be exactly 20');
        Assert.AreEqual(100, MaxStrLen(Member.Description),
            'Expected Description to be declared as Text[100] — its maximum length must be exactly 100');
    end;

    local procedure SeedMember(var Member: Record "Loyalty Member"; MemberNo: Code[20])
    var
        Any: Codeunit Any;
    begin
        Member.Init();
        Member."Member No." := MemberNo;
        Member."Enrolled On" := WorkDate() - Any.IntegerInRange(30, 3000);
        Member."Last Updated On" := WorkDate() - Any.IntegerInRange(30, 3000);
        // Seeded without triggers so the seed itself never depends on the user's trigger code.
        Member.Insert(false);
    end;
}
