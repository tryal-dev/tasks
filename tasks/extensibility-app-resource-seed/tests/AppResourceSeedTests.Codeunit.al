codeunit 50900 "App Resource Seed Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SeedsEveryRegionFromTheShippedFixture()
    var
        RegionSetup: Record "Region Setup";
        SetupSeeder: Codeunit "Setup Seeder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The first run seeds Region Setup with exactly the shipped fixture contents
        // [GIVEN] an empty Region Setup table
        RegionSetup.DeleteAll();

        // [WHEN] seeding from region-seed.json
        Assert.AreEqual(3, SetupSeeder.SeedFromResource('region-seed.json'),
            'Expected SeedFromResource to report one inserted record per region in region-seed.json');

        // [THEN] the table holds exactly the three regions from the fixture, field by field
        Assert.RecordCount(RegionSetup, 3);
        AssertRegion('NORTH', 'Northern district', 21.0);
        AssertRegion('SOUTH', 'Southern district', 19.5);
        AssertRegion('WEST', 'Western district', 17.25);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SeedsTheFixtureNamedInTheCall()
    var
        RegionSetup: Record "Region Setup";
        SetupSeeder: Codeunit "Setup Seeder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The seeder is driven by the resource name, not wired to one fixture
        // [GIVEN] an empty Region Setup table
        RegionSetup.DeleteAll();

        // [WHEN] seeding from region-seed-extra.json
        Assert.AreEqual(2, SetupSeeder.SeedFromResource('region-seed-extra.json'),
            'Expected SeedFromResource to seed the resource named in the call — region-seed-extra.json ships two regions');

        // [THEN] only the extra fixture's regions exist
        Assert.RecordCount(RegionSetup, 2);
        AssertRegion('EAST', 'Eastern district', 23.0);
        AssertRegion('CENTRAL', 'Central district', 20.0);
        Assert.IsFalse(RegionSetup.Get('NORTH'),
            'Expected no NORTH region after seeding region-seed-extra.json — it belongs to the other fixture');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RunningTheSeederTwiceInsertsNothingNew()
    var
        RegionSetup: Record "Region Setup";
        SetupSeeder: Codeunit "Setup Seeder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Seeding is idempotent: a second identical run is a no-op
        // [GIVEN] Region Setup already seeded from region-seed.json
        RegionSetup.DeleteAll();
        SetupSeeder.SeedFromResource('region-seed.json');

        // [WHEN] seeding from the same resource again
        Assert.AreEqual(0, SetupSeeder.SeedFromResource('region-seed.json'),
            'Expected the second run over region-seed.json to insert nothing — every region already exists');

        // [THEN] no duplicates appeared
        Assert.RecordCount(RegionSetup, 3);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReseedingPreservesEditedRecords()
    var
        RegionSetup: Record "Region Setup";
        SetupSeeder: Codeunit "Setup Seeder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A rerun never overwrites values an administrator changed after seeding
        // [GIVEN] a seeded table where NORTH was edited afterwards
        RegionSetup.DeleteAll();
        SetupSeeder.SeedFromResource('region-seed.json');
        RegionSetup.Get('NORTH');
        RegionSetup.Description := 'Renamed by the administrator';
        RegionSetup."Tax Rate" := 5.55;
        RegionSetup.Modify();

        // [WHEN] seeding from region-seed.json again
        SetupSeeder.SeedFromResource('region-seed.json');

        // [THEN] the edited record keeps its edited values
        RegionSetup.Get('NORTH');
        Assert.AreEqual('Renamed by the administrator', RegionSetup.Description,
            'Expected the reseed to leave the edited Description of NORTH untouched — existing records must never be overwritten');
        Assert.AreEqual(5.55, RegionSetup."Tax Rate",
            'Expected the reseed to leave the edited Tax Rate of NORTH untouched — existing records must never be overwritten');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReseedingRestoresOnlyTheMissingRegion()
    var
        RegionSetup: Record "Region Setup";
        SetupSeeder: Codeunit "Setup Seeder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] After a region was deleted, a rerun restores just that one from the fixture
        // [GIVEN] a seeded table where SOUTH was deleted afterwards
        RegionSetup.DeleteAll();
        SetupSeeder.SeedFromResource('region-seed.json');
        RegionSetup.Get('SOUTH');
        RegionSetup.Delete();

        // [WHEN] seeding from region-seed.json again
        Assert.AreEqual(1, SetupSeeder.SeedFromResource('region-seed.json'),
            'Expected the rerun to insert exactly one record — only SOUTH was missing');

        // [THEN] SOUTH is back with its fixture values and nothing was duplicated
        Assert.RecordCount(RegionSetup, 3);
        AssertRegion('SOUTH', 'Southern district', 19.5);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SeedingBothFixturesLayersTheirRegions()
    var
        RegionSetup: Record "Region Setup";
        SetupSeeder: Codeunit "Setup Seeder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The two shipped fixtures seed side by side into one table
        // [GIVEN] Region Setup already seeded from region-seed.json
        RegionSetup.DeleteAll();
        SetupSeeder.SeedFromResource('region-seed.json');

        // [WHEN] seeding from region-seed-extra.json on top
        Assert.AreEqual(2, SetupSeeder.SeedFromResource('region-seed-extra.json'),
            'Expected the extra fixture to add its two regions on top of the already-seeded ones');

        // [THEN] all five regions coexist
        Assert.RecordCount(RegionSetup, 5);
        AssertRegion('EAST', 'Eastern district', 23.0);
        AssertRegion('NORTH', 'Northern district', 21.0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownResourceNameRaisesAHelpfulError()
    var
        RegionSetup: Record "Region Setup";
        SetupSeeder: Codeunit "Setup Seeder";
        Assert: Codeunit Assert;
        ErrorText: Text;
    begin
        // [SCENARIO] Asking for a resource that never shipped fails with the available names listed
        // [GIVEN] an empty Region Setup table
        RegionSetup.DeleteAll();

        // [WHEN] seeding from a name the app does not ship
        asserterror SetupSeeder.SeedFromResource('does-not-exist.json');

        // [THEN] the error names the requested resource and every shipped one, and nothing was written
        ErrorText := GetLastErrorText();
        Assert.IsSubstring(ErrorText, 'does-not-exist.json');
        Assert.IsSubstring(ErrorText, 'region-seed.json');
        Assert.IsSubstring(ErrorText, 'region-seed-extra.json');
        Assert.RecordIsEmpty(RegionSetup);
    end;

    local procedure AssertRegion(RegionCode: Code[20]; ExpectedDescription: Text; ExpectedTaxRate: Decimal)
    var
        RegionSetup: Record "Region Setup";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(RegionSetup.Get(RegionCode),
            StrSubstNo('Expected a Region Setup record with Code %1 seeded from the fixture', RegionCode));
        Assert.AreEqual(ExpectedDescription, RegionSetup.Description,
            StrSubstNo('Expected the Description of %1 to match the shipped fixture exactly', RegionCode));
        Assert.AreEqual(ExpectedTaxRate, RegionSetup."Tax Rate",
            StrSubstNo('Expected the Tax Rate of %1 to match the shipped fixture exactly', RegionCode));
    end;
}
