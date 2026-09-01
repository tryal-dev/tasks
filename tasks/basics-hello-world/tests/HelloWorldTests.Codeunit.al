codeunit 50900 "Hello World Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GreetsTheWorldWhenNoNameIsGiven()
    var
        HelloWorld: Codeunit "Hello World";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('Hello, World!', HelloWorld.Greet(''), 'Expected an empty name to produce the classic greeting "Hello, World!"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GreetsAPersonByName()
    var
        HelloWorld: Codeunit "Hello World";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('Hello, Taylor!', HelloWorld.Greet('Taylor'), 'Expected the name to be greeted as "Hello, <Name>!"');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GreetsAnyName()
    var
        HelloWorld: Codeunit "Hello World";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Name: Text;
    begin
        Name := Any.AlphabeticText(8);
        Assert.AreEqual('Hello, ' + Name + '!', HelloWorld.Greet(Name), 'Expected the greeting to work for any name, not just the examples from the statement');
    end;
}
