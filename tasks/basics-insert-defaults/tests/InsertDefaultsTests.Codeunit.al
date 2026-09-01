codeunit 50900 "Insert Defaults Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankRegistrationDateDefaultsToWorkDate()
    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
    begin
        Customer.Init();
        Customer."No." := 'TRYAL-T501';
        Customer.Insert(true);

        Customer.Get('TRYAL-T501');
        Assert.AreEqual(WorkDate(), Customer."First Registered On",
            'Expected a blank "First Registered On" to be stamped with WorkDate() on insert');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankStatusDefaultsToNew()
    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
    begin
        Customer.Init();
        Customer."No." := 'TRYAL-T502';
        Customer."Review Status" := '';
        Customer.Insert(true);

        Customer.Get('TRYAL-T502');
        Assert.AreEqual('NEW', Customer."Review Status",
            'Expected a blank "Review Status" to default to NEW on insert — even when the field was explicitly cleared');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExplicitStatusIsKept()
    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
    begin
        Customer.Init();
        Customer."No." := 'TRYAL-T503';
        Customer."Review Status" := 'VIP';
        Customer.Insert(true);

        Customer.Get('TRYAL-T503');
        Assert.AreEqual('VIP', Customer."Review Status",
            'Expected an explicitly set "Review Status" to survive insert unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExplicitDateIsKept()
    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExplicitDate: Date;
    begin
        ExplicitDate := Any.DateInRange(WorkDate(), 30, 300);

        Customer.Init();
        Customer."No." := 'TRYAL-T504';
        Customer."First Registered On" := ExplicitDate;
        Customer.Insert(true);

        Customer.Get('TRYAL-T504');
        Assert.AreEqual(ExplicitDate, Customer."First Registered On",
            'Expected an explicitly set "First Registered On" to survive insert unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReviewStatusIsDeclaredAsCodeTen()
    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
    begin
        Customer."Review Status" := 'abc';
        Assert.AreEqual('ABC', Customer."Review Status",
            'Expected "Review Status" to be a Code field — Code values are stored uppercase');
        Assert.AreEqual(10, MaxStrLen(Customer."Review Status"),
            'Expected "Review Status" to be declared as Code[10] — its maximum length must be exactly 10');
    end;
}
