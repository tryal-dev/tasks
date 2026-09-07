codeunit 50900 "Customer Welcome Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        WelcomeTermsCodeTok: Label 'WELCOME', Locked = true, MaxLength = 10;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApplyStampsTheWelcomeNoteOnTheCallersRecord()
    var
        Customer: Record Customer;
        Welcome: Codeunit "Customer Welcome";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Apply writes the welcome note onto the record it was handed
        // [GIVEN] a customer named Northwind Traders with no welcome note
        CreateCustomerNamed(Customer, 'Northwind Traders');

        // [WHEN] applying the welcome through the procedure
        Welcome.Apply(Customer);

        // [THEN] the caller's record carries the exact note
        Assert.AreEqual('Welcome aboard, Northwind Traders!', Customer."Welcome Note",
            'Expected Apply to set "Welcome Note" to "Welcome aboard, Northwind Traders!" on the record passed in — mind the comma, the space and the exclamation mark');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApplyBuildsTheNoteFromTheCustomersName()
    var
        Customer: Record Customer;
        Welcome: Codeunit "Customer Welcome";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        CustomerName: Text[100];
    begin
        // [SCENARIO] The note is built from the Name of the record, not from a fixed text
        // [GIVEN] a customer with a generated name
        CustomerName := CopyStr('TRYAL ' + Any.AlphabeticText(20), 1, MaxStrLen(CustomerName));
        CreateCustomerNamed(Customer, CustomerName);

        // [WHEN] applying the welcome through the procedure
        Welcome.Apply(Customer);

        // [THEN] the note quotes that name
        Assert.AreEqual('Welcome aboard, ' + CustomerName + '!', Customer."Welcome Note",
            StrSubstNo('Expected the welcome note to be built from the customer''s own Name (%1)', CustomerName));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApplyOverwritesAnExistingWelcomeNote()
    var
        Customer: Record Customer;
        Welcome: Codeunit "Customer Welcome";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The note is written every time, whatever the field held before
        // [GIVEN] a customer whose Welcome Note already holds other text
        CreateCustomerNamed(Customer, 'Litware Inc');
        Customer."Welcome Note" := 'Old note from an earlier onboarding';

        // [WHEN] applying the welcome through the procedure
        Welcome.Apply(Customer);

        // [THEN] the old text is replaced by the exact new note
        Assert.AreEqual('Welcome aboard, Litware Inc!', Customer."Welcome Note",
            'Expected Apply to overwrite a "Welcome Note" that already held other text — the note is written every time, whatever the field held before, so it must not be skipped when the field is filled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApplyAssignsTheWelcomePaymentTermsWhenBlank()
    var
        Customer: Record Customer;
        Welcome: Codeunit "Customer Welcome";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A customer without payment terms gets the introductory WELCOME terms
        // [GIVEN] a customer with a blank Payment Terms Code
        CreateCustomerNamed(Customer, 'Contoso Ltd');

        // [WHEN] applying the welcome through the procedure
        Welcome.Apply(Customer);

        // [THEN] the caller's record carries the WELCOME code
        Assert.AreEqual(WelcomeTermsCodeTok, Customer."Payment Terms Code",
            'Expected Apply to set a blank "Payment Terms Code" to WELCOME on the record passed in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApplyKeepsAnExistingPaymentTermsCode()
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        Welcome: Codeunit "Customer Welcome";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Payment terms somebody already chose are left alone
        // [GIVEN] a customer whose Payment Terms Code is already filled
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        CreateCustomerNamed(Customer, 'Adatum Corporation');
        Customer."Payment Terms Code" := PaymentTerms.Code;

        // [WHEN] applying the welcome through the procedure
        Welcome.Apply(Customer);

        // [THEN] the existing code survives
        Assert.AreEqual(PaymentTerms.Code, Customer."Payment Terms Code",
            'Expected Apply to keep a "Payment Terms Code" that was already filled — only a blank code is defaulted to WELCOME');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ApplyLeavesTheDatabaseRowUntouched()
    var
        Customer: Record Customer;
        StoredCustomer: Record Customer;
        Welcome: Codeunit "Customer Welcome";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Apply changes the record in memory and leaves saving to the caller
        // [GIVEN] a customer stored with a blank note and blank payment terms
        CreateCustomerNamed(Customer, 'Fabrikam Inc');

        // [WHEN] applying the welcome through the procedure
        Welcome.Apply(Customer);

        // [THEN] the row in the database is unchanged
        StoredCustomer.Get(Customer."No.");
        Assert.AreEqual('', StoredCustomer."Welcome Note",
            'Expected the customer''s row in the database to still have no welcome note after Apply — the procedure changes the record it was handed and leaves saving to the caller, so it must not call Modify');
        Assert.AreEqual('', StoredCustomer."Payment Terms Code",
            'Expected the customer''s row in the database to still have a blank "Payment Terms Code" after Apply — the procedure must not call Modify');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RunningTheCodeunitStampsTheWelcomeNoteOnTheCallersRecord()
    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Changes made to Rec inside OnRun are visible on the caller's variable
        // [GIVEN] a customer named Tailspin Toys with no welcome note
        CreateCustomerNamed(Customer, 'Tailspin Toys');

        // [WHEN] running the codeunit with that record, return value not captured
        Codeunit.Run(Codeunit::"Customer Welcome", Customer);

        // [THEN] the caller's own variable carries the note
        Assert.AreEqual('Welcome aboard, Tailspin Toys!', Customer."Welcome Note",
            'Expected the caller''s Customer variable to carry the welcome note after Codeunit.Run — OnRun receives that very record as Rec, so handing Rec to Apply changes it in place; a copy of Rec, or an Apply that takes the record by value, passes nothing back');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RunningTheCodeunitAssignsTheWelcomePaymentTermsWhenBlank()
    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The payment terms default reaches the caller through Rec as well
        // [GIVEN] a customer with a blank Payment Terms Code
        CreateCustomerNamed(Customer, 'Wide World Importers');

        // [WHEN] running the codeunit with that record, return value not captured
        Codeunit.Run(Codeunit::"Customer Welcome", Customer);

        // [THEN] the caller's own variable carries the WELCOME code
        Assert.AreEqual(WelcomeTermsCodeTok, Customer."Payment Terms Code",
            'Expected the caller''s Customer variable to hold WELCOME in "Payment Terms Code" after Codeunit.Run — the change made to Rec must reach the caller');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RunningTheCodeunitKeepsAnExistingPaymentTermsCode()
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] OnRun applies the same rules as Apply — an existing code is kept on this path too
        // [GIVEN] a customer whose Payment Terms Code is already filled
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        CreateCustomerNamed(Customer, 'Alpine Ski House');
        Customer."Payment Terms Code" := PaymentTerms.Code;

        // [WHEN] running the codeunit with that record, return value not captured
        Codeunit.Run(Codeunit::"Customer Welcome", Customer);

        // [THEN] the existing code survives
        Assert.AreEqual(PaymentTerms.Code, Customer."Payment Terms Code",
            'Expected Codeunit.Run to keep a "Payment Terms Code" that was already filled — OnRun must hand Rec to Apply and apply no rules of its own');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RunningTheCodeunitLeavesTheDatabaseRowUntouched()
    var
        Customer: Record Customer;
        StoredCustomer: Record Customer;
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] OnRun changes Rec in place and saves nothing — whether the changes are stored is the caller's decision
        // [GIVEN] a customer stored with a blank note and blank payment terms
        CreateCustomerNamed(Customer, 'Proseware Inc');

        // [WHEN] running the codeunit with that record, return value not captured
        Codeunit.Run(Codeunit::"Customer Welcome", Customer);

        // [THEN] the row in the database is unchanged
        StoredCustomer.Get(Customer."No.");
        Assert.AreEqual('', StoredCustomer."Welcome Note",
            'Expected the customer''s row in the database to still have no welcome note after Codeunit.Run — Rec is the caller''s own variable passed by reference, so OnRun needs no Modify to hand the changes back and must not call one');
        Assert.AreEqual('', StoredCustomer."Payment Terms Code",
            'Expected the customer''s row in the database to still have a blank "Payment Terms Code" after Codeunit.Run — OnRun hands Rec to Apply and does nothing else, so it must not call Modify');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WelcomeNoteIsDeclaredAsTextTwoHundredFifty()
    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The field declaration matches the statement
        Assert.AreEqual(250, MaxStrLen(Customer."Welcome Note"),
            'Expected "Welcome Note" to be declared as Text[250] — its maximum length must be exactly 250');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CodeunitDeclaresCustomerAsItsTableNo()
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] The codeunit is bound to the Customer table
        // [WHEN] reading the codeunit's metadata
        CodeunitMetadata.Get(Codeunit::"Customer Welcome");

        // [THEN] its TableNo is the Customer table
        Assert.AreEqual(Database::Customer, CodeunitMetadata.TableNo,
            'Expected the "Customer Welcome" codeunit to declare TableNo = Customer — without it OnRun has no Rec to hand over');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RunningTheCodeunitWithAnItemRecordIsRefused()
    var
        Item: Record Item;
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A codeunit bound to Customer cannot be run with a record from another table
        // [WHEN] running the codeunit with an Item record
        if TryRunWithItem(Item) then
            Assert.Fail('Expected the platform to refuse running "Customer Welcome" with an Item record — a codeunit whose TableNo is Customer only accepts Customer records');

        // [THEN] the platform's own incompatibility error is raised
        Assert.ExpectedError('is not compatible with Codeunit.Run');
    end;

    [TryFunction]
    local procedure TryRunWithItem(var Item: Record Item)
    begin
        Codeunit.Run(Codeunit::"Customer Welcome", Item);
    end;

    local procedure CreateCustomerNamed(var Customer: Record Customer; NewName: Text[100])
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        EnsureWelcomePaymentTermsExist();
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := NewName;
        Customer."Payment Terms Code" := '';
        Customer."Welcome Note" := '';
        Customer.Modify();
    end;

    // The statement promises the WELCOME payment terms exist, so a solution
    // that validates the field instead of assigning it must not be tripped up.
    local procedure EnsureWelcomePaymentTermsExist()
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PaymentTerms.Get(WelcomeTermsCodeTok) then
            exit;
        PaymentTerms.Init();
        PaymentTerms.Code := WelcomeTermsCodeTok;
        PaymentTerms.Description := 'Introductory terms for new customers';
        PaymentTerms.Insert();
    end;
}
