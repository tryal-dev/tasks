codeunit 50900 "Filter Expression Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleTokenIsValid()
    begin
        VerifyValid('4711');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TokenAlternativesAreValid()
    begin
        VerifyValid('BLUE|RED|GREEN');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RangeWithAlternativeIsValid()
    begin
        VerifyValid('1000..2000|3000');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RangeWithOnlyUpperBoundIsValid()
    begin
        VerifyValid('..2000');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RangeWithOnlyLowerBoundIsValid()
    begin
        VerifyValid('1000..');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QuotedValueTreatsOperatorsAsData()
    begin
        VerifyValid('''A|B (x..y)''');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DoubledQuoteIsALiteralQuote()
    begin
        VerifyValid('''O''''Brien''');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyQuotedValueIsValid()
    begin
        VerifyValid('''''');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QuotedBoundsFormAValidRange()
    begin
        VerifyValid('''A''..''M''');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GroupedExpressionIsValid()
    begin
        VerifyValid('(1000..2000|3000)|9000');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NestedGroupsAreValid()
    begin
        VerifyValid('((1|2)|3)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ParenthesisInsideQuotesDoesNotCount()
    begin
        VerifyValid('(''a(b''|c)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomizedExpressionIsValid()
    var
        Any: Codeunit Any;
    begin
        VerifyValid(StrSubstNo('%1..%2|''%3|%4''|%5', Any.AlphabeticText(6), Any.AlphabeticText(6), Any.AlphabeticText(4), Any.AlphabeticText(4), Any.AlphanumericText(8)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyExpressionIsInvalid()
    begin
        VerifyInvalid('');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeadingPipeIsInvalid()
    begin
        VerifyInvalid('|1000');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TrailingPipeIsInvalid()
    begin
        VerifyInvalid('1000|');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DoubledPipeIsInvalid()
    begin
        VerifyInvalid('1000||2000');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BareRangeOperatorIsInvalid()
    begin
        VerifyInvalid('..');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SecondRangeOperatorIsInvalid()
    begin
        VerifyInvalid('1..2..3');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SpaceOutsideQuotesIsInvalid()
    begin
        VerifyInvalid('1000 .. 2000');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HyphenOutsideQuotesIsInvalid()
    begin
        VerifyInvalid('A-1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WildcardIsInvalid()
    begin
        VerifyInvalid('10*');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AtSignIsInvalid()
    begin
        VerifyInvalid('@abc');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AmpersandIsInvalid()
    begin
        VerifyInvalid('1000&2000');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LoneDotIsInvalid()
    begin
        VerifyInvalid('1.5');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnclosedParenthesisIsInvalid()
    begin
        VerifyInvalid('(1000..2000');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StrayClosingParenthesisIsInvalid()
    begin
        VerifyInvalid('1000)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyGroupIsInvalid()
    begin
        VerifyInvalid('()');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SwappedParenthesesAreInvalid()
    begin
        VerifyInvalid(')(');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnterminatedQuoteIsInvalid()
    begin
        VerifyInvalid('''abc');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure QuoteClosedOnlyByEscapeIsInvalid()
    begin
        VerifyInvalid('''a''''');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TextAfterClosingQuoteIsInvalid()
    begin
        VerifyInvalid('''a''b''c''');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GroupAsRangeBoundIsInvalid()
    begin
        VerifyInvalid('(1|2)..5');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomizedCorruptedExpressionIsInvalid()
    var
        Any: Codeunit Any;
    begin
        VerifyInvalid(StrSubstNo('%1..%2|%3|', Any.AlphabeticText(6), Any.AlphabeticText(6), Any.AlphabeticText(5)));
    end;

    local procedure VerifyValid(Expression: Text)
    var
        FilterExpressionCheck: Codeunit "Filter Expression Check";
        Assert: Codeunit Assert;
    begin
        Assert.IsTrue(FilterExpressionCheck.IsValid(Expression), StrSubstNo('Expected <%1> to be accepted as a valid filter expression, but IsValid returned false', Expression));
    end;

    local procedure VerifyInvalid(Expression: Text)
    var
        FilterExpressionCheck: Codeunit "Filter Expression Check";
        Assert: Codeunit Assert;
    begin
        Assert.IsFalse(FilterExpressionCheck.IsValid(Expression), StrSubstNo('Expected <%1> to be rejected as invalid, but IsValid returned true', Expression));
    end;
}
