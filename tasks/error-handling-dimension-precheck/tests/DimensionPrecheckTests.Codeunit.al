codeunit 50900 "Dimension Precheck Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Dimensions] [Value Posting]

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FlagsALineWhoseCodeMandatoryDimensionIsMissing()
    var
        Customer: Record Customer;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        Reported: Integer;
        Dump: Text;
    begin
        // [SCENARIO] A line whose dimension set has no value for a Code Mandatory dimension is reported
        // [GIVEN] an item with a Code Mandatory rule, on an order line that carries no value for that dimension
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryInventory.CreateItem(Item);
        SetValuePostingRule(
            Database::Item, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code,
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory");
        LibrarySales.CreateCustomer(Customer);
        CreateOrderWithItemLine(SalesHeader, SalesLine, Customer."No.", Item."No.");
        RemoveDimensionFromLine(SalesLine, DimensionValue."Dimension Code");

        // [WHEN] prechecking the document
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);

        // [THEN] that line is reported once, naming the dimension and the Code Mandatory rule
        Dump := ViolationsAsText(Violation);
        Assert.AreEqual(1, Reported,
            'Expected exactly one violation: the line lost the value of a Code Mandatory dimension. The precheck reported: ' + Dump);
        AssertViolation(
            Violation, SalesLine."Line No.", DimensionValue."Dimension Code",
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory", Dump,
            'A Code Mandatory rule is broken when the line''s dimension set holds no value for that dimension');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsALineThatCarriesTheMandatoryDimensionValue()
    var
        Customer: Record Customer;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        Reported: Integer;
    begin
        // [SCENARIO] A Code Mandatory rule is satisfied by any non-blank value in the line's dimension set
        // [GIVEN] an item with a Code Mandatory rule, on an order line that inherited that dimension value
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryInventory.CreateItem(Item);
        SetValuePostingRule(
            Database::Item, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code,
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory");
        LibrarySales.CreateCustomer(Customer);
        CreateOrderWithItemLine(SalesHeader, SalesLine, Customer."No.", Item."No.");

        // [WHEN] prechecking the document
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);

        // [THEN] nothing is reported
        AssertNothingReported(Violation, Reported,
            'A Code Mandatory rule is satisfied when the line''s dimension set carries a value for that dimension');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FlagsSameCodeWhenTheLineCarriesADifferentValue()
    var
        Customer: Record Customer;
        Item: Record Item;
        RequiredValue: Record "Dimension Value";
        OtherValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        Reported: Integer;
        Dump: Text;
    begin
        // [SCENARIO] A Same Code rule is broken by any value other than the one the rule names
        // [GIVEN] an item with a Same Code rule, on a line whose dimension set was changed to another value
        LibraryDimension.CreateDimWithDimValue(RequiredValue);
        LibraryDimension.CreateDimensionValue(OtherValue, RequiredValue."Dimension Code");
        LibraryInventory.CreateItem(Item);
        SetValuePostingRule(
            Database::Item, Item."No.", RequiredValue."Dimension Code", RequiredValue.Code,
            Enum::"Default Dimension Value Posting Type"::"Same Code");
        LibrarySales.CreateCustomer(Customer);
        CreateOrderWithItemLine(SalesHeader, SalesLine, Customer."No.", Item."No.");
        SetDimensionOnLine(SalesLine, OtherValue."Dimension Code", OtherValue.Code);

        // [WHEN] prechecking the document
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);

        // [THEN] the line is reported once, naming the Same Code rule
        Dump := ViolationsAsText(Violation);
        Assert.AreEqual(1, Reported,
            'Expected exactly one violation: the line carries a value the Same Code rule does not allow. The precheck reported: ' + Dump);
        AssertViolation(
            Violation, SalesLine."Line No.", RequiredValue."Dimension Code",
            Enum::"Default Dimension Value Posting Type"::"Same Code", Dump,
            'A Same Code rule is broken when the line''s value differs from the rule''s "Dimension Value Code"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FlagsSameCodeWhenTheLineLostTheRequiredValue()
    var
        Customer: Record Customer;
        Item: Record Item;
        RequiredValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        Reported: Integer;
        Dump: Text;
    begin
        // [SCENARIO] A Same Code rule naming a value is broken when the line holds no value for that dimension
        // [GIVEN] an item with a Same Code rule, on a line whose dimension set lost that dimension entirely
        LibraryDimension.CreateDimWithDimValue(RequiredValue);
        LibraryInventory.CreateItem(Item);
        SetValuePostingRule(
            Database::Item, Item."No.", RequiredValue."Dimension Code", RequiredValue.Code,
            Enum::"Default Dimension Value Posting Type"::"Same Code");
        LibrarySales.CreateCustomer(Customer);
        CreateOrderWithItemLine(SalesHeader, SalesLine, Customer."No.", Item."No.");
        RemoveDimensionFromLine(SalesLine, RequiredValue."Dimension Code");

        // [WHEN] prechecking the document
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);

        // [THEN] the line is reported once, naming the Same Code rule
        Dump := ViolationsAsText(Violation);
        Assert.AreEqual(1, Reported,
            'Expected exactly one violation: a Same Code rule that names a value is broken when the line carries no value at all for that dimension. The precheck reported: ' + Dump);
        AssertViolation(
            Violation, SalesLine."Line No.", RequiredValue."Dimension Code",
            Enum::"Default Dimension Value Posting Type"::"Same Code", Dump,
            'A Same Code rule naming a value is broken when the line''s dimension set holds no value for that dimension — a missing entry is not a match');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsSameCodeWhenTheLineCarriesTheRequiredValue()
    var
        Customer: Record Customer;
        Item: Record Item;
        RequiredValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        Reported: Integer;
    begin
        // [SCENARIO] A Same Code rule is satisfied by exactly the value it names
        // [GIVEN] an item with a Same Code rule, on a line that inherited exactly that value
        LibraryDimension.CreateDimWithDimValue(RequiredValue);
        LibraryInventory.CreateItem(Item);
        SetValuePostingRule(
            Database::Item, Item."No.", RequiredValue."Dimension Code", RequiredValue.Code,
            Enum::"Default Dimension Value Posting Type"::"Same Code");
        LibrarySales.CreateCustomer(Customer);
        CreateOrderWithItemLine(SalesHeader, SalesLine, Customer."No.", Item."No.");

        // [WHEN] prechecking the document
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);

        // [THEN] nothing is reported
        AssertNothingReported(Violation, Reported,
            'A Same Code rule is satisfied when the line carries exactly the value the rule names');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FlagsBlankSameCodeWhenTheLineCarriesAValue()
    var
        Customer: Record Customer;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        Reported: Integer;
        Dump: Text;
    begin
        // [SCENARIO] A Same Code rule with a blank "Dimension Value Code" demands a blank value on the line
        // [GIVEN] an item with a blank Same Code rule, on a line whose dimension set was given a value
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryInventory.CreateItem(Item);
        SetValuePostingRule(
            Database::Item, Item."No.", DimensionValue."Dimension Code", '',
            Enum::"Default Dimension Value Posting Type"::"Same Code");
        LibrarySales.CreateCustomer(Customer);
        CreateOrderWithItemLine(SalesHeader, SalesLine, Customer."No.", Item."No.");
        SetDimensionOnLine(SalesLine, DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] prechecking the document
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);

        // [THEN] the line is reported once, naming the Same Code rule
        Dump := ViolationsAsText(Violation);
        Assert.AreEqual(1, Reported,
            'Expected exactly one violation: a Same Code rule whose "Dimension Value Code" is blank means the line must carry no value for that dimension. The precheck reported: ' + Dump);
        AssertViolation(
            Violation, SalesLine."Line No.", DimensionValue."Dimension Code",
            Enum::"Default Dimension Value Posting Type"::"Same Code", Dump,
            'A blank Same Code rule is broken by any value on the line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FlagsNoCodeWhenTheLineCarriesAValue()
    var
        Customer: Record Customer;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        Reported: Integer;
        Dump: Text;
    begin
        // [SCENARIO] A No Code rule is broken by any value for that dimension on the line
        // [GIVEN] an item with a No Code rule, on a line whose dimension set was given a value
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryInventory.CreateItem(Item);
        SetValuePostingRule(
            Database::Item, Item."No.", DimensionValue."Dimension Code", '',
            Enum::"Default Dimension Value Posting Type"::"No Code");
        LibrarySales.CreateCustomer(Customer);
        CreateOrderWithItemLine(SalesHeader, SalesLine, Customer."No.", Item."No.");
        SetDimensionOnLine(SalesLine, DimensionValue."Dimension Code", DimensionValue.Code);

        // [WHEN] prechecking the document
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);

        // [THEN] the line is reported once, naming the No Code rule
        Dump := ViolationsAsText(Violation);
        Assert.AreEqual(1, Reported,
            'Expected exactly one violation: the line carries a value for a dimension the No Code rule forbids. The precheck reported: ' + Dump);
        AssertViolation(
            Violation, SalesLine."Line No.", DimensionValue."Dimension Code",
            Enum::"Default Dimension Value Posting Type"::"No Code", Dump,
            'A No Code rule is broken by any value for that dimension on the line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcceptsNoCodeWhenTheLineHasNoValueForThatDimension()
    var
        Customer: Record Customer;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        Reported: Integer;
    begin
        // [SCENARIO] A No Code rule is satisfied while the line holds no value for that dimension
        // [GIVEN] an item with a No Code rule, on a line that never received a value for that dimension
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryInventory.CreateItem(Item);
        SetValuePostingRule(
            Database::Item, Item."No.", DimensionValue."Dimension Code", '',
            Enum::"Default Dimension Value Posting Type"::"No Code");
        LibrarySales.CreateCustomer(Customer);
        CreateOrderWithItemLine(SalesHeader, SalesLine, Customer."No.", Item."No.");

        // [WHEN] prechecking the document
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);

        // [THEN] nothing is reported
        AssertNothingReported(Violation, Reported,
            'A No Code rule is satisfied while the line holds no value for that dimension');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChecksTheGLAccountsOwnRulesOnAGLAccountLine()
    var
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        GLAccountNo: Code[20];
        Reported: Integer;
        Dump: Text;
    begin
        // [SCENARIO] A G/L account line is checked against the G/L account's own default dimensions
        // [GIVEN] a G/L account with a Code Mandatory rule, on a line that carries no value for that dimension
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        SetValuePostingRule(
            Database::"G/L Account", GLAccountNo, DimensionValue."Dimension Code", DimensionValue.Code,
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory");
        LibrarySales.CreateCustomer(Customer);
        CreateOrderWithGLAccountLine(SalesHeader, SalesLine, Customer."No.", GLAccountNo);
        RemoveDimensionFromLine(SalesLine, DimensionValue."Dimension Code");

        // [WHEN] prechecking the document
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);

        // [THEN] the G/L account line is reported
        Dump := ViolationsAsText(Violation);
        Assert.AreEqual(1, Reported,
            'Expected exactly one violation from the G/L account''s own rule. The precheck reported: ' + Dump);
        AssertViolation(
            Violation, SalesLine."Line No.", DimensionValue."Dimension Code",
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory", Dump,
            'A G/L account line must be checked against the "G/L Account" record its "No." points at');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChecksTheResourcesOwnRulesOnAResourceLine()
    var
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        ResourceNo: Code[20];
        Reported: Integer;
        Dump: Text;
    begin
        // [SCENARIO] A resource line is checked against the resource's own default dimensions
        // [GIVEN] a resource with a Code Mandatory rule, on a line that carries no value for that dimension
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        ResourceNo := LibraryResource.CreateResourceNo();
        SetValuePostingRule(
            Database::Resource, ResourceNo, DimensionValue."Dimension Code", DimensionValue.Code,
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory");
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, ResourceNo, LibraryRandom.RandInt(5));
        RemoveDimensionFromLine(SalesLine, DimensionValue."Dimension Code");

        // [WHEN] prechecking the document
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);

        // [THEN] the resource line is reported
        Dump := ViolationsAsText(Violation);
        Assert.AreEqual(1, Reported,
            'Expected exactly one violation from the resource''s own rule. The precheck reported: ' + Dump);
        AssertViolation(
            Violation, SalesLine."Line No.", DimensionValue."Dimension Code",
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory", Dump,
            'Every line type has its own master table — a resource line is checked against the Resource record, not the customer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FlagsTheDocumentHeaderWithLineNoZero()
    var
        Customer: Record Customer;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        Reported: Integer;
        Dump: Text;
    begin
        // [SCENARIO] The document header is checked against the bill-to customer and reported with line no. 0
        // [GIVEN] a customer with a Code Mandatory rule and a document whose HEADER lost that dimension
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibrarySales.CreateCustomer(Customer);
        SetValuePostingRule(
            Database::Customer, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code,
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory");
        LibraryInventory.CreateItem(Item);
        CreateOrderWithItemLine(SalesHeader, SalesLine, Customer."No.", Item."No.");
        RemoveDimensionFromHeader(SalesHeader, DimensionValue."Dimension Code");

        // [WHEN] prechecking the document
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);

        // [THEN] the header is reported with line no. 0, and the line — which kept the value — is not
        Dump := ViolationsAsText(Violation);
        Assert.AreEqual(1, Reported,
            'Expected exactly one violation: the header''s own dimension set broke the customer''s rule while the line still satisfies it. The precheck reported: ' + Dump);
        AssertViolation(
            Violation, 0, DimensionValue."Dimension Code",
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory", Dump,
            'The document header is checked too, against "Bill-to Customer No." and the header''s own "Dimension Set ID", and reported with "Line No." 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AppliesTheCustomersRulesToEveryLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        FirstLine: Record "Sales Line";
        SecondLine: Record "Sales Line";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        Reported: Integer;
        Dump: Text;
    begin
        // [SCENARIO] The customer's rules are checked against every line, not only against the header
        // [GIVEN] a customer with a Code Mandatory rule and two lines that both lost that dimension
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibrarySales.CreateCustomer(Customer);
        SetValuePostingRule(
            Database::Customer, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code,
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory");
        LibraryInventory.CreateItem(Item);
        CreateOrderWithItemLine(SalesHeader, FirstLine, Customer."No.", Item."No.");
        LibrarySales.CreateSalesLine(SecondLine, SalesHeader, SecondLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));
        RemoveDimensionFromLine(FirstLine, DimensionValue."Dimension Code");
        RemoveDimensionFromLine(SecondLine, DimensionValue."Dimension Code");

        // [WHEN] prechecking the document
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);

        // [THEN] both lines are reported, and the header — which kept the value — is not
        Dump := ViolationsAsText(Violation);
        Assert.AreEqual(2, Reported,
            'Expected one violation per line: the customer''s rule applies to every line''s own dimension set. The precheck reported: ' + Dump);
        AssertViolation(
            Violation, FirstLine."Line No.", DimensionValue."Dimension Code",
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory", Dump,
            'The customer''s rules must be checked against the first line as well');
        AssertViolation(
            Violation, SecondLine."Line No.", DimensionValue."Dimension Code",
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory", Dump,
            'Every offending line gets its own row — the second line must be reported too');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportsEveryBrokenRuleOnTheSameLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        MandatoryValue: Record "Dimension Value";
        ForbiddenValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        Reported: Integer;
        Dump: Text;
    begin
        // [SCENARIO] One line breaking two rules produces two rows, one per dimension
        // [GIVEN] an item with a Code Mandatory rule and a No Code rule, both broken on the same line
        LibraryDimension.CreateDimWithDimValue(MandatoryValue);
        LibraryDimension.CreateDimWithDimValue(ForbiddenValue);
        LibraryInventory.CreateItem(Item);
        SetValuePostingRule(
            Database::Item, Item."No.", MandatoryValue."Dimension Code", MandatoryValue.Code,
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory");
        SetValuePostingRule(
            Database::Item, Item."No.", ForbiddenValue."Dimension Code", '',
            Enum::"Default Dimension Value Posting Type"::"No Code");
        LibrarySales.CreateCustomer(Customer);
        CreateOrderWithItemLine(SalesHeader, SalesLine, Customer."No.", Item."No.");
        RemoveDimensionFromLine(SalesLine, MandatoryValue."Dimension Code");
        SetDimensionOnLine(SalesLine, ForbiddenValue."Dimension Code", ForbiddenValue.Code);

        // [WHEN] prechecking the document
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);

        // [THEN] both broken rules are reported for that line
        Dump := ViolationsAsText(Violation);
        Assert.AreEqual(2, Reported,
            'Expected both broken rules on the line to be reported, not just the first one found. The precheck reported: ' + Dump);
        AssertViolation(
            Violation, SalesLine."Line No.", MandatoryValue."Dimension Code",
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory", Dump,
            'The missing mandatory dimension must be reported');
        AssertViolation(
            Violation, SalesLine."Line No.", ForbiddenValue."Dimension Code",
            Enum::"Default Dimension Value Posting Type"::"No Code", Dump,
            'The forbidden dimension on the same line must be reported as well — a precheck stops at nothing');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IgnoresDefaultDimensionsWithoutAValuePostingRule()
    var
        Customer: Record Customer;
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        Reported: Integer;
    begin
        // [SCENARIO] A plain default dimension carries no rule and can never be violated
        // [GIVEN] an item with a default dimension whose "Value Posting" is blank, removed from the line again
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryInventory.CreateItem(Item);
        LibraryDimension.CreateDefaultDimensionItem(
            DefaultDimension, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        LibrarySales.CreateCustomer(Customer);
        CreateOrderWithItemLine(SalesHeader, SalesLine, Customer."No.", Item."No.");
        RemoveDimensionFromLine(SalesLine, DimensionValue."Dimension Code");

        // [WHEN] prechecking the document
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);

        // [THEN] nothing is reported
        AssertNothingReported(Violation, Reported,
            'A default dimension whose "Value Posting" is blank only supplies a default value — it is not a rule and can never be broken');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SkipsLinesThatPointAtNoMasterRecord()
    var
        Customer: Record Customer;
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        Reported: Integer;
    begin
        // [SCENARIO] A description-only line has no dimensions of its own and is never reported
        // [GIVEN] a customer with a Code Mandatory rule, an item line that satisfies it, and a description-only line
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibrarySales.CreateCustomer(Customer);
        SetValuePostingRule(
            Database::Customer, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code,
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory");
        LibraryInventory.CreateItem(Item);
        CreateOrderWithItemLine(SalesHeader, SalesLine, Customer."No.", Item."No.");
        AddDescriptionOnlyLine(SalesHeader);

        // [WHEN] prechecking the document
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);

        // [THEN] nothing is reported
        AssertNothingReported(Violation, Reported,
            'A line with a blank Type and a blank "No." points at no master record: skip it entirely instead of checking its empty dimension set');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptiesTheBufferBeforeReportingAgain()
    var
        Customer: Record Customer;
        BrokenItem: Record Item;
        CleanItem: Record Item;
        DimensionValue: Record "Dimension Value";
        BrokenHeader: Record "Sales Header";
        CleanHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        Reported: Integer;
    begin
        // [SCENARIO] Each call starts from an empty buffer, so old findings never survive
        // [GIVEN] a buffer already filled by prechecking a document with a broken rule
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryInventory.CreateItem(BrokenItem);
        SetValuePostingRule(
            Database::Item, BrokenItem."No.", DimensionValue."Dimension Code", DimensionValue.Code,
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory");
        LibrarySales.CreateCustomer(Customer);
        CreateOrderWithItemLine(BrokenHeader, SalesLine, Customer."No.", BrokenItem."No.");
        RemoveDimensionFromLine(SalesLine, DimensionValue."Dimension Code");
        DimensionPrecheck.CheckSalesDocument(BrokenHeader, Violation);
        LibraryInventory.CreateItem(CleanItem);
        CreateOrderWithItemLine(CleanHeader, SalesLine, Customer."No.", CleanItem."No.");

        // [WHEN] prechecking a document that breaks no rule with the same buffer
        Reported := DimensionPrecheck.CheckSalesDocument(CleanHeader, Violation);

        // [THEN] nothing is reported and the buffer holds nothing
        AssertNothingReported(Violation, Reported,
            'The buffer must be emptied at the start of every call — findings from an earlier document must not survive');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FlagsTheLineThatStandardPostingRefuses()
    var
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        SalesPost: Codeunit "Sales-Post";
        GLAccountNo: Code[20];
        Reported: Integer;
        Dump: Text;
    begin
        // [SCENARIO] What the precheck reports is what standard posting refuses
        // [GIVEN] an order whose G/L account line breaks a Code Mandatory rule, which Sales-Post refuses to post
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        SetValuePostingRule(
            Database::"G/L Account", GLAccountNo, DimensionValue."Dimension Code", DimensionValue.Code,
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory");
        LibrarySales.CreateCustomer(Customer);
        CreateOrderWithGLAccountLine(SalesHeader, SalesLine, Customer."No.", GLAccountNo);
        RemoveDimensionFromLine(SalesLine, DimensionValue."Dimension Code");
        PrepareForPosting(SalesHeader, SalesPost);
        // The refused posting rolls the database back to the last commit; without this the
        // order itself would vanish together with posting's half-done work.
        Commit();
        asserterror SalesPost.Run(SalesHeader);
        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.IsTrue(SalesInvoiceHeader.IsEmpty(),
            StrSubstNo('Expected order %1 to be refused by standard posting because of its dimensions', SalesHeader."No."));
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");

        // [WHEN] prechecking that same document
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);

        // [THEN] the precheck names the line posting stumbled over
        Dump := ViolationsAsText(Violation);
        Assert.AreEqual(1, Reported,
            'Expected the precheck to report the one line standard posting refuses. The precheck reported: ' + Dump);
        AssertViolation(
            Violation, SalesLine."Line No.", DimensionValue."Dimension Code",
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory", Dump,
            'The precheck must find, before posting, exactly the broken rule that made posting fail');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ADocumentThePrecheckAcceptsReallyPosts()
    var
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Violation: Record "Dimension Precheck Violation";
        DimensionPrecheck: Codeunit "Dimension Precheck";
        SalesPost: Codeunit "Sales-Post";
        GLAccountNo: Code[20];
        Reported: Integer;
    begin
        // [SCENARIO] A document the precheck accepts posts without a dimension error
        // [GIVEN] an order whose G/L account line satisfies its Code Mandatory rule, and a precheck that reports nothing
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        SetValuePostingRule(
            Database::"G/L Account", GLAccountNo, DimensionValue."Dimension Code", DimensionValue.Code,
            Enum::"Default Dimension Value Posting Type"::"Code Mandatory");
        LibrarySales.CreateCustomer(Customer);
        CreateOrderWithGLAccountLine(SalesHeader, SalesLine, Customer."No.", GLAccountNo);
        Reported := DimensionPrecheck.CheckSalesDocument(SalesHeader, Violation);
        AssertNothingReported(Violation, Reported,
            'The line carries the value its Code Mandatory rule asks for, so the precheck must accept the document');

        // [WHEN] posting the document
        PrepareForPosting(SalesHeader, SalesPost);
        SalesPost.Run(SalesHeader);

        // [THEN] the order posted
        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        Assert.IsFalse(SalesInvoiceHeader.IsEmpty(),
            StrSubstNo('Expected order %1 to post into a sales invoice — a document the precheck accepts must not be refused for its dimensions', SalesHeader."No."));
    end;

    local procedure SetValuePostingRule(TableID: Integer; No: Code[20]; DimensionCode: Code[20]; DimensionValueCode: Code[20]; ValuePosting: Enum "Default Dimension Value Posting Type")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDefaultDimension(DefaultDimension, TableID, No, DimensionCode, DimensionValueCode);
        // Direct assignment on purpose: validating "Value Posting" runs the master-data
        // update machinery, which can ask whether to change existing documents.
        DefaultDimension."Value Posting" := ValuePosting;
        DefaultDimension.Modify();
    end;

    local procedure CreateOrderWithItemLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(5));
    end;

    local procedure CreateOrderWithGLAccountLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; GLAccountNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandInt(5));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 1000, 2));
        SalesLine.Modify(true);
    end;

    local procedure AddDescriptionOnlyLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        // Inserted without the table trigger so the line stays exactly what the
        // scenario needs: no type, no number, no dimension set.
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 90000;
        SalesLine.Description := 'TRYAL description line';
        SalesLine.Insert();
    end;

    local procedure RemoveDimensionFromLine(var SalesLine: Record "Sales Line"; DimensionCode: Code[20])
    begin
        if not DimensionIsInSet(SalesLine."Dimension Set ID", DimensionCode) then
            exit;
        SalesLine."Dimension Set ID" := LibraryDimension.DeleteDimSet(SalesLine."Dimension Set ID", DimensionCode);
        SalesLine.Modify();
    end;

    local procedure SetDimensionOnLine(var SalesLine: Record "Sales Line"; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    begin
        // EditDimSet only changes a pair the set already holds; a rule whose
        // "Dimension Value Code" is blank never seeds one, so add it instead.
        if DimensionIsInSet(SalesLine."Dimension Set ID", DimensionCode) then
            SalesLine."Dimension Set ID" := LibraryDimension.EditDimSet(SalesLine."Dimension Set ID", DimensionCode, DimensionValueCode)
        else
            SalesLine."Dimension Set ID" := LibraryDimension.CreateDimSet(SalesLine."Dimension Set ID", DimensionCode, DimensionValueCode);
        SalesLine.Modify();
    end;

    local procedure RemoveDimensionFromHeader(var SalesHeader: Record "Sales Header"; DimensionCode: Code[20])
    begin
        if not DimensionIsInSet(SalesHeader."Dimension Set ID", DimensionCode) then
            exit;
        SalesHeader."Dimension Set ID" := LibraryDimension.DeleteDimSet(SalesHeader."Dimension Set ID", DimensionCode);
        SalesHeader.Modify();
    end;

    local procedure DimensionIsInSet(DimSetID: Integer; DimensionCode: Code[20]): Boolean
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        exit(DimensionSetEntry.Get(DimSetID, DimensionCode));
    end;

    local procedure PrepareForPosting(var SalesHeader: Record "Sales Header"; var SalesPost: Codeunit "Sales-Post")
    begin
        SalesHeader.Validate(Ship, true);
        SalesHeader.Validate(Invoice, true);
        SalesPost.SetPostingFlags(SalesHeader);
        // Suppress Sales-Post's internal commits so posting can run under AutoRollback.
        SalesPost.SetSuppressCommit(true);
    end;

    local procedure AssertViolation(var Violation: Record "Dimension Precheck Violation"; LineNo: Integer; DimensionCode: Code[20]; ValuePosting: Enum "Default Dimension Value Posting Type"; Dump: Text; Expectation: Text)
    begin
        Assert.IsTrue(
            Violation.Get(LineNo, DimensionCode),
            StrSubstNo('%1 — expected a violation row for line no. %2 and dimension %3, but the precheck reported: %4',
                Expectation, LineNo, DimensionCode, Dump));
        Assert.AreEqual(
            Format(ValuePosting), Format(Violation."Value Posting"),
            StrSubstNo('%1 — the row for line no. %2 and dimension %3 names the wrong rule in "Value Posting"',
                Expectation, LineNo, DimensionCode));
    end;

    local procedure AssertNothingReported(var Violation: Record "Dimension Precheck Violation"; Reported: Integer; Expectation: Text)
    var
        Dump: Text;
    begin
        Dump := ViolationsAsText(Violation);
        Assert.AreEqual(0, Reported, StrSubstNo('%1 — the precheck reported: %2', Expectation, Dump));
        Assert.AreEqual(0, Violation.Count(),
            StrSubstNo('%1 — the returned count was 0 but the buffer still holds: %2', Expectation, Dump));
    end;

    local procedure ViolationsAsText(var Violation: Record "Dimension Precheck Violation"): Text
    var
        Result: Text;
    begin
        Violation.Reset();
        if Violation.FindSet() then
            repeat
                Result += StrSubstNo('[line %1 / %2 / %3] ',
                    Violation."Line No.", Violation."Dimension Code", Violation."Value Posting");
            until Violation.Next() = 0;
        if Result = '' then
            exit('an empty violation list');
        exit(Result);
    end;
}
