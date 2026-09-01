codeunit 50900 "Code Normalizer Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShortInputIsReturnedUppercased()
    var
        CodeNormalizer: Codeunit "Code Normalizer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Input: Text;
    begin
        Input := Any.AlphabeticText(10);

        Assert.AreEqual(UpperCase(Input), CodeNormalizer.ToCode20(Input),
            'Expected input shorter than 20 characters to come back unchanged apart from uppercasing');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OversizedInputIsTruncatedInsteadOfCrashing()
    var
        CodeNormalizer: Codeunit "Code Normalizer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Input: Text;
    begin
        Input := Any.AlphabeticText(40);

        Assert.AreEqual(UpperCase(CopyStr(Input, 1, 20)), CodeNormalizer.ToCode20(Input),
            'Expected input longer than 20 characters to be truncated to the first 20 — a plain assignment raises a runtime error here');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WhitespaceIsTrimmedBeforeTruncating()
    var
        CodeNormalizer: Codeunit "Code Normalizer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Input: Text;
    begin
        Input := '  ' + Any.AlphabeticText(25) + ' ';

        Assert.AreEqual(UpperCase(CopyStr(Input.Trim(), 1, 20)), CodeNormalizer.ToCode20(Input),
            'Expected leading and trailing whitespace to be removed BEFORE truncating to 20 characters');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyInputYieldsAnEmptyCode()
    var
        CodeNormalizer: Codeunit "Code Normalizer";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', CodeNormalizer.ToCode20(''),
            'Expected empty input to produce an empty code');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WhitespaceOnlyInputYieldsAnEmptyCode()
    var
        CodeNormalizer: Codeunit "Code Normalizer";
        Assert: Codeunit Assert;
        TabTxt: Text[1];
    begin
        TabTxt[1] := 9;

        Assert.AreEqual('', CodeNormalizer.ToCode20(' ' + TabTxt + ' '),
            'Expected whitespace-only input (spaces and a tab) to produce an empty code — tabs count as whitespace');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TabsAroundTheValueAreTrimmedToo()
    var
        CodeNormalizer: Codeunit "Code Normalizer";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        TabTxt: Text[1];
        Value: Text;
    begin
        TabTxt[1] := 9;
        Value := Any.AlphabeticText(8);

        Assert.AreEqual(UpperCase(Value), CodeNormalizer.ToCode20(TabTxt + Value + TabTxt),
            'Expected tabs to be trimmed from both ends — whitespace means more than spaces');
    end;
}
