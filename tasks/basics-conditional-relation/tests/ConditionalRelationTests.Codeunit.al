codeunit 50900 "Conditional Relation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Conditional Table Relation]

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ItemNoDefaultsTheDescriptionFromTheItem()
    var
        EstimateLine: Record "Estimate Line";
        Item: Record Item;
    begin
        // [SCENARIO] An item code on a line of Type Item is accepted and brings the item's description along
        // [GIVEN] a line of Type Item and an item carrying a generated description
        CreateItemWithDescription(Item);
        CreateLine(EstimateLine, 'TRYAL-CR01');
        EstimateLine.Validate(Type, EstimateLine.Type::Item);

        // [WHEN] validating "No." with the item's code
        EstimateLine.Validate("No.", Item."No.");

        // [THEN] the line keeps the code and shows the item's description
        Assert.AreEqual(Item."No.", EstimateLine."No.",
            'Expected an existing item code to be accepted on a line of Type Item');
        Assert.AreEqual(Item.Description, EstimateLine.Description,
            'Expected validating "No." on a line of Type Item to copy the item''s Description onto the line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResourceNoDefaultsTheDescriptionFromTheResourceName()
    var
        EstimateLine: Record "Estimate Line";
        Resource: Record Resource;
    begin
        // [SCENARIO] A resource code on a line of Type Resource is accepted and brings the resource's name along
        // [GIVEN] a line of Type Resource and a resource carrying a generated name
        CreateResourceWithName(Resource);
        CreateLine(EstimateLine, 'TRYAL-CR02');
        EstimateLine.Validate(Type, EstimateLine.Type::Resource);

        // [WHEN] validating "No." with the resource's code
        EstimateLine.Validate("No.", Resource."No.");

        // [THEN] the line keeps the code and shows the resource's name
        Assert.AreEqual(Resource."No.", EstimateLine."No.",
            'Expected an existing resource code to be accepted on a line of Type Resource');
        Assert.AreEqual(Resource.Name, EstimateLine.Description,
            'Expected validating "No." on a line of Type Resource to copy the resource''s Name into Description');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GLAccountNoDefaultsTheDescriptionFromTheAccountName()
    var
        EstimateLine: Record "Estimate Line";
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO] A G/L account code on a line of Type G/L Account is accepted and brings the account's name along
        // [GIVEN] a line of Type G/L Account and an account carrying a generated name
        CreateGLAccountWithName(GLAccount);
        CreateLine(EstimateLine, 'TRYAL-CR03');
        EstimateLine.Validate(Type, EstimateLine.Type::"G/L Account");

        // [WHEN] validating "No." with the account's code
        EstimateLine.Validate("No.", GLAccount."No.");

        // [THEN] the line keeps the code and shows the account's name
        Assert.AreEqual(GLAccount."No.", EstimateLine."No.",
            'Expected an existing G/L account code to be accepted on a line of Type G/L Account');
        Assert.AreEqual(GLAccount.Name, EstimateLine.Description,
            'Expected validating "No." on a line of Type G/L Account to copy the account''s Name into Description');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ItemCodeIsRejectedWhenTypeIsResource()
    var
        EstimateLine: Record "Estimate Line";
        Item: Record Item;
    begin
        // [SCENARIO] The very same code that Type Item accepts is refused under Type Resource
        // [GIVEN] a line of Type Resource and an existing item
        CreateItemWithDescription(Item);
        CreateLine(EstimateLine, 'TRYAL-CR04');
        EstimateLine.Validate(Type, EstimateLine.Type::Resource);

        // [WHEN] validating "No." with the item's code
        asserterror EstimateLine.Validate("No.", Item."No.");

        // [THEN] the relation check itself fails, naming the Resource table the value was looked for in
        Assert.ExpectedError('cannot be found in the related table');
        Assert.ExpectedError('Resource');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownCodeIsRejectedWhenTypeIsItem()
    var
        EstimateLine: Record "Estimate Line";
    begin
        // [SCENARIO] A code that belongs to no item is refused under Type Item
        // [GIVEN] a line of Type Item
        CreateLine(EstimateLine, 'TRYAL-CR05');
        EstimateLine.Validate(Type, EstimateLine.Type::Item);

        // [WHEN] validating "No." with a generated code that no item carries
        asserterror EstimateLine.Validate("No.", UnusedCode());

        // [THEN] the relation check itself fails, naming the Item table the value was looked for in
        Assert.ExpectedError('cannot be found in the related table');
        Assert.ExpectedError('Item');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnknownCodeIsRejectedWhenTypeIsGLAccount()
    var
        EstimateLine: Record "Estimate Line";
    begin
        // [SCENARIO] A code that belongs to no G/L account is refused under Type G/L Account
        // [GIVEN] a line of Type G/L Account
        CreateLine(EstimateLine, 'TRYAL-CR06');
        EstimateLine.Validate(Type, EstimateLine.Type::"G/L Account");

        // [WHEN] validating "No." with a generated code that no account carries
        asserterror EstimateLine.Validate("No.", UnusedCode());

        // [THEN] the relation check itself fails, naming the G/L Account table the value was looked for in
        Assert.ExpectedError('cannot be found in the related table');
        Assert.ExpectedError('G/L Account');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankTypeAcceptsACodeFromNoTable()
    var
        EstimateLine: Record "Estimate Line";
        FreeCode: Code[20];
    begin
        // [SCENARIO] No branch of the relation applies to a blank Type, so nothing is checked
        // [GIVEN] a line whose Type is still blank
        CreateLine(EstimateLine, 'TRYAL-CR07');
        FreeCode := UnusedCode();

        // [WHEN] validating "No." with a code that exists in none of the three tables
        EstimateLine.Validate("No.", FreeCode);

        // [THEN] the code is stored as typed
        Assert.AreEqual(FreeCode, EstimateLine."No.",
            'Expected "No." to accept any code while Type is blank — no branch of the conditional relation applies, so there is nothing to check against');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankingTheNoClearsTheDescription()
    var
        EstimateLine: Record "Estimate Line";
        Item: Record Item;
    begin
        // [SCENARIO] Emptying "No." empties the description it brought along, without erroring
        // [GIVEN] a line of Type Item filled with an item
        CreateItemWithDescription(Item);
        CreateLine(EstimateLine, 'TRYAL-CR08');
        EstimateLine.Validate(Type, EstimateLine.Type::Item);
        EstimateLine.Validate("No.", Item."No.");

        // [WHEN] validating "No." with a blank value
        EstimateLine.Validate("No.", '');

        // [THEN] the description is gone and no error was raised
        Assert.AreEqual('', Format(EstimateLine.Description),
            'Expected validating "No." with a blank value to clear Description and raise no error — the relation check always lets a blank value through');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChangingTypeBlanksTheNo()
    var
        EstimateLine: Record "Estimate Line";
        Item: Record Item;
    begin
        // [SCENARIO] Switching Type must not leave the line pointing at a record of the old type
        // [GIVEN] a stored line of Type Item that carries an item code
        CreateItemWithDescription(Item);
        CreateStoredItemLine(EstimateLine, 'TRYAL-CR09', Item."No.");

        // [WHEN] validating Type with a different value
        EstimateLine.Validate(Type, EstimateLine.Type::Resource);

        // [THEN] "No." is blank again
        Assert.AreEqual('', Format(EstimateLine."No."),
            'Expected validating Type with a different value to blank "No." — otherwise the line keeps a code that no longer resolves under the new type');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ChangingTypeBlanksTheDescription()
    var
        EstimateLine: Record "Estimate Line";
        Item: Record Item;
    begin
        // [SCENARIO] The description defaulted from the old record goes away with it
        // [GIVEN] a stored line of Type Item that carries an item code and its description
        CreateItemWithDescription(Item);
        CreateStoredItemLine(EstimateLine, 'TRYAL-CR10', Item."No.");

        // [WHEN] validating Type with a different value
        EstimateLine.Validate(Type, EstimateLine.Type::"G/L Account");

        // [THEN] Description is blank again
        Assert.AreEqual('', Format(EstimateLine.Description),
            'Expected validating Type with a different value to blank Description as well — it belonged to the record "No." pointed at');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RevalidatingTheSameTypeKeepsTheNoAndDescription()
    var
        EstimateLine: Record "Estimate Line";
        Item: Record Item;
    begin
        // [SCENARIO] Re-validating Type with the value the line already carries changes nothing
        // [GIVEN] a stored line of Type Item that carries an item code
        CreateItemWithDescription(Item);
        CreateStoredItemLine(EstimateLine, 'TRYAL-CR11', Item."No.");

        // [WHEN] validating Type with the value it already has
        EstimateLine.Validate(Type, EstimateLine.Type::Item);

        // [THEN] the item code and the description it brought along are still there
        Assert.AreEqual(Item."No.", EstimateLine."No.",
            'Expected validating Type with the value the line already carries to leave "No." alone — only a real change may blank it');
        Assert.AreEqual(Item.Description, EstimateLine.Description,
            'Expected validating Type with the value the line already carries to leave Description alone — only a real change may blank it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CatalogRefAcceptsACodeThatIsNoItem()
    var
        EstimateLine: Record "Estimate Line";
        FreeCode: Code[20];
    begin
        // [SCENARIO] "Catalog Ref." relates to Item but does not validate the relation
        // [GIVEN] a line and a generated code that no item carries
        CreateLine(EstimateLine, 'TRYAL-CR12');
        FreeCode := UnusedCode();

        // [WHEN] validating "Catalog Ref." with that code
        EstimateLine.Validate("Catalog Ref.", FreeCode);

        // [THEN] the code is stored as typed
        Assert.AreEqual(FreeCode, EstimateLine."Catalog Ref.",
            'Expected "Catalog Ref." to accept free text — its table relation must not be validated');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CatalogRefStillRelatesToTheItemTable()
    var
        FieldRec: Record Field;
    begin
        // [SCENARIO] Switching validation off does not mean dropping the relation
        // [GIVEN] the "Estimate Line" table
        FieldRec.SetRange(TableNo, Database::"Estimate Line");
        FieldRec.SetRange(FieldName, 'Catalog Ref.');

        // [WHEN] reading the field's metadata
        Assert.IsTrue(FieldRec.FindFirst(),
            'Expected the "Estimate Line" table to carry a field named exactly "Catalog Ref."');

        // [THEN] the table it relates to is Item
        Assert.AreEqual(Database::Item, FieldRec.RelationTableNo,
            'Expected "Catalog Ref." to keep its table relation to Item — only the validation of that relation is switched off');
    end;

    local procedure CreateLine(var EstimateLine: Record "Estimate Line"; DocumentNo: Code[20])
    begin
        EstimateLine.Init();
        EstimateLine."Document No." := DocumentNo;
        EstimateLine."Line No." := 10000;
        EstimateLine.Insert();
    end;

    local procedure CreateStoredItemLine(var EstimateLine: Record "Estimate Line"; DocumentNo: Code[20]; ItemNo: Code[20])
    begin
        CreateLine(EstimateLine, DocumentNo);
        EstimateLine.Validate(Type, EstimateLine.Type::Item);
        EstimateLine.Validate("No.", ItemNo);
        EstimateLine.Modify();
        EstimateLine.Get(DocumentNo, 10000);
    end;

    local procedure CreateItemWithDescription(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Description := GeneratedText('TRYAL item ', MaxStrLen(Item.Description));
        Item.Modify();
    end;

    local procedure CreateResourceWithName(var Resource: Record Resource)
    begin
        LibraryResource.CreateResourceNew(Resource);
        Resource.Name := GeneratedText('TRYAL resource ', MaxStrLen(Resource.Name));
        Resource.Modify();
    end;

    local procedure CreateGLAccountWithName(var GLAccount: Record "G/L Account")
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Name := GeneratedText('TRYAL account ', MaxStrLen(GLAccount.Name));
        GLAccount.Modify();
    end;

    // The prefix keeps the three master records distinguishable even when the
    // generator repeats itself, so copying from the wrong table cannot pass.
    local procedure GeneratedText(Prefix: Text; MaxLength: Integer): Text[100]
    var
        Any: Codeunit Any;
    begin
        exit(CopyStr(Prefix + Any.AlphabeticText(20), 1, MaxLength));
    end;

    local procedure UnusedCode(): Code[20]
    var
        Any: Codeunit Any;
    begin
        exit(CopyStr('TRYAL' + UpperCase(Any.AlphabeticText(12)), 1, 20));
    end;
}
