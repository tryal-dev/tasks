codeunit 50900 "Import Line Validator Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateLineAcceptsAFullyValidLine()
    var
        ImportOrderLine: Record "Import Order Line";
        ImportLineValidator: Codeunit "Import Line Validator";
        Any: Codeunit Any;
    begin
        // [SCENARIO] a line satisfying every rule validates silently
        // [GIVEN] a line with an item, a positive quantity and a positive price
        MakeLine(ImportOrderLine, Any.IntegerInRange(1, 99999), 'ITEM-001', Any.DecimalInRange(1, 100, 2), Any.DecimalInRange(1, 500, 2));

        // [WHEN] validating the single line
        // [THEN] it returns without raising — any error here fails the test
        ImportLineValidator.ValidateLine(ImportOrderLine);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateLineAcceptsAZeroUnitPrice()
    var
        ImportOrderLine: Record "Import Order Line";
        ImportLineValidator: Codeunit "Import Line Validator";
        Any: Codeunit Any;
    begin
        // [SCENARIO] a unit price of exactly 0 is valid — the rule forbids only negative prices
        // [GIVEN] an otherwise valid line whose price is exactly 0
        MakeLine(ImportOrderLine, Any.IntegerInRange(1, 99999), 'ITEM-002', Any.DecimalInRange(1, 100, 2), 0);

        // [WHEN] validating the single line
        // [THEN] it returns without raising — any error here fails the test
        ImportLineValidator.ValidateLine(ImportOrderLine);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateLineRejectsABlankItemNo()
    var
        ImportOrderLine: Record "Import Order Line";
        ImportLineValidator: Codeunit "Import Line Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        LineNo: Integer;
    begin
        // [SCENARIO] a blank Item No. raises the exact missing-item message
        // [GIVEN] a line with no Item No. and otherwise valid values
        LineNo := Any.IntegerInRange(1, 99999);
        MakeLine(ImportOrderLine, LineNo, '', Any.DecimalInRange(1, 100, 2), Any.DecimalInRange(1, 500, 2));

        // [WHEN] validating the single line
        asserterror ImportLineValidator.ValidateLine(ImportOrderLine);

        // [THEN] the error carries the exact promised message
        Assert.AreEqual(StrSubstNo('Line %1: Item No. is missing.', LineNo), GetLastErrorText(),
            'Expected a line without an Item No. to raise exactly the missing-item message from the statement');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateLineRejectsAZeroQuantity()
    var
        ImportOrderLine: Record "Import Order Line";
        ImportLineValidator: Codeunit "Import Line Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        LineNo: Integer;
    begin
        // [SCENARIO] a quantity of exactly 0 raises the quantity message — the rule is strictly greater than zero
        // [GIVEN] a line with quantity 0 and otherwise valid values
        LineNo := Any.IntegerInRange(1, 99999);
        MakeLine(ImportOrderLine, LineNo, 'ITEM-003', 0, Any.DecimalInRange(1, 500, 2));

        // [WHEN] validating the single line
        asserterror ImportLineValidator.ValidateLine(ImportOrderLine);

        // [THEN] the error carries the exact promised message
        Assert.AreEqual(StrSubstNo('Line %1: Quantity must be greater than zero.', LineNo), GetLastErrorText(),
            'Expected a zero quantity to raise exactly the quantity message — zero is not a valid quantity');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateLineRejectsANegativeQuantity()
    var
        ImportOrderLine: Record "Import Order Line";
        ImportLineValidator: Codeunit "Import Line Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        LineNo: Integer;
    begin
        // [SCENARIO] a negative quantity raises the quantity message
        // [GIVEN] a line with a negative quantity and otherwise valid values
        LineNo := Any.IntegerInRange(1, 99999);
        MakeLine(ImportOrderLine, LineNo, 'ITEM-004', -Any.DecimalInRange(1, 100, 2), Any.DecimalInRange(1, 500, 2));

        // [WHEN] validating the single line
        asserterror ImportLineValidator.ValidateLine(ImportOrderLine);

        // [THEN] the error carries the exact promised message
        Assert.AreEqual(StrSubstNo('Line %1: Quantity must be greater than zero.', LineNo), GetLastErrorText(),
            'Expected a negative quantity to raise exactly the quantity message');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateLineRejectsANegativeUnitPrice()
    var
        ImportOrderLine: Record "Import Order Line";
        ImportLineValidator: Codeunit "Import Line Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        LineNo: Integer;
    begin
        // [SCENARIO] a negative unit price raises the price message
        // [GIVEN] a line with a negative price and otherwise valid values
        LineNo := Any.IntegerInRange(1, 99999);
        MakeLine(ImportOrderLine, LineNo, 'ITEM-005', Any.DecimalInRange(1, 100, 2), -Any.DecimalInRange(1, 500, 2));

        // [WHEN] validating the single line
        asserterror ImportLineValidator.ValidateLine(ImportOrderLine);

        // [THEN] the error carries the exact promised message
        Assert.AreEqual(StrSubstNo('Line %1: Unit Price cannot be negative.', LineNo), GetLastErrorText(),
            'Expected a negative unit price to raise exactly the price message');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateLineReportsOnlyTheFirstBrokenRule()
    var
        ImportOrderLine: Record "Import Order Line";
        ImportLineValidator: Codeunit "Import Line Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        LineNo: Integer;
    begin
        // [SCENARIO] a line breaking all three rules raises the first rule's message
        // [GIVEN] a line with a blank item, a zero quantity and a negative price
        LineNo := Any.IntegerInRange(1, 99999);
        MakeLine(ImportOrderLine, LineNo, '', 0, -1);

        // [WHEN] validating the single line
        asserterror ImportLineValidator.ValidateLine(ImportOrderLine);

        // [THEN] only the Item No. rule — first in the promised order — is reported
        Assert.AreEqual(StrSubstNo('Line %1: Item No. is missing.', LineNo), GetLastErrorText(),
            'Expected a line breaking several rules to raise the FIRST broken rule in the promised order: Item No., then Quantity, then Unit Price');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateLineChecksQuantityBeforeUnitPrice()
    var
        ImportOrderLine: Record "Import Order Line";
        ImportLineValidator: Codeunit "Import Line Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        LineNo: Integer;
    begin
        // [SCENARIO] with a valid Item No., a line breaking both remaining rules raises the Quantity message — rule 2 precedes rule 3
        // [GIVEN] a line with a valid item, a zero quantity and a negative price
        LineNo := Any.IntegerInRange(1, 99999);
        MakeLine(ImportOrderLine, LineNo, 'ITEM-006', 0, -Any.DecimalInRange(1, 500, 2));

        // [WHEN] validating the single line
        asserterror ImportLineValidator.ValidateLine(ImportOrderLine);

        // [THEN] the Quantity rule — second in the promised order — is reported, not the Unit Price rule
        Assert.AreEqual(StrSubstNo('Line %1: Quantity must be greater than zero.', LineNo), GetLastErrorText(),
            'Expected a line with a valid item but both a bad quantity and a bad price to raise the Quantity message — Quantity is checked BEFORE Unit Price in the promised order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateBatchReturnsAnEmptyListForACleanBatch()
    var
        ImportLineValidator: Codeunit "Import Line Validator";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Problems: List of [Text];
    begin
        // [SCENARIO] a batch where every line is valid yields zero problems
        // [GIVEN] a batch of three valid lines
        InsertLine('TRYAL-B1', 10000, 'ITEM-101', Any.DecimalInRange(1, 100, 2), Any.DecimalInRange(1, 500, 2));
        InsertLine('TRYAL-B1', 20000, 'ITEM-102', Any.DecimalInRange(1, 100, 2), 0);
        InsertLine('TRYAL-B1', 30000, 'ITEM-103', Any.DecimalInRange(1, 100, 2), Any.DecimalInRange(1, 500, 2));

        // [WHEN] validating the batch
        ImportLineValidator.ValidateBatch('TRYAL-B1', Problems);

        // [THEN] the list is empty
        Assert.AreEqual(0, Problems.Count(),
            'Expected no problems for a batch where every line passes all three rules');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateBatchReportsEveryBrokenLineInLineOrder()
    var
        ImportLineValidator: Codeunit "Import Line Validator";
        Assert: Codeunit Assert;
        Problems: List of [Text];
    begin
        // [SCENARIO] a mixed batch yields exactly the broken lines' messages, ordered by line number
        // [GIVEN] five lines: valid, blank item, zero quantity, valid, negative price
        InsertLine('TRYAL-B2', 10000, 'ITEM-201', 5, 10);
        InsertLine('TRYAL-B2', 20000, '', 5, 10);
        InsertLine('TRYAL-B2', 30000, 'ITEM-203', 0, 10);
        InsertLine('TRYAL-B2', 40000, 'ITEM-204', 3, 0);
        InsertLine('TRYAL-B2', 50000, 'ITEM-205', 2, -1);

        // [WHEN] validating the batch
        ImportLineValidator.ValidateBatch('TRYAL-B2', Problems);

        // [THEN] all three broken lines are reported, none of the valid ones, in line order
        Assert.AreEqual(3, Problems.Count(),
            'Expected exactly the three broken lines to be reported — validation must not stop at the first failure and must not report valid lines');
        Assert.AreEqual('Line 20000: Item No. is missing.', Problems.Get(1),
            'Expected the first problem to be the blank Item No. on line 20000');
        Assert.AreEqual('Line 30000: Quantity must be greater than zero.', Problems.Get(2),
            'Expected the second problem to be the zero quantity on line 30000');
        Assert.AreEqual('Line 50000: Unit Price cannot be negative.', Problems.Get(3),
            'Expected the third problem to be the negative price on line 50000');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateBatchReturnsNormallyWhenEveryLineIsBroken()
    var
        ImportLineValidator: Codeunit "Import Line Validator";
        Assert: Codeunit Assert;
        Problems: List of [Text];
    begin
        // [SCENARIO] a batch with not a single valid line is still reported in full, without an error escaping
        // [GIVEN] three lines that each break a rule
        InsertLine('TRYAL-B3', 10000, '', 5, 10);
        InsertLine('TRYAL-B3', 20000, 'ITEM-302', -4, 10);
        InsertLine('TRYAL-B3', 30000, 'ITEM-303', 2, -0.01);

        // [WHEN] validating the batch — if an error escapes here, the test fails
        ImportLineValidator.ValidateBatch('TRYAL-B3', Problems);

        // [THEN] every line is reported
        Assert.AreEqual(3, Problems.Count(),
            'Expected all three broken lines to be reported and ValidateBatch to return normally even though no line is valid');
        Assert.AreEqual('Line 10000: Item No. is missing.', Problems.Get(1),
            'Expected the first problem to be the blank Item No. on line 10000');
        Assert.AreEqual('Line 20000: Quantity must be greater than zero.', Problems.Get(2),
            'Expected the second problem to be the negative quantity on line 20000');
        Assert.AreEqual('Line 30000: Unit Price cannot be negative.', Problems.Get(3),
            'Expected the third problem to be the negative price on line 30000');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateBatchReportsAMultiRuleLineExactlyOnce()
    var
        ImportLineValidator: Codeunit "Import Line Validator";
        Assert: Codeunit Assert;
        Problems: List of [Text];
    begin
        // [SCENARIO] a line breaking several rules contributes one entry — its first broken rule
        // [GIVEN] a valid line, a line breaking all three rules, and a line with a valid item breaking the other two
        InsertLine('TRYAL-B4', 10000, 'ITEM-401', 5, 10);
        InsertLine('TRYAL-B4', 20000, '', 0, -5);
        InsertLine('TRYAL-B4', 30000, 'ITEM-403', 0, -5);

        // [WHEN] validating the batch
        ImportLineValidator.ValidateBatch('TRYAL-B4', Problems);

        // [THEN] each multi-rule line shows up once, with its first broken rule's message
        Assert.AreEqual(2, Problems.Count(),
            'Expected each line breaking several rules to contribute exactly ONE problem — its first broken rule — not one per rule');
        Assert.AreEqual('Line 20000: Item No. is missing.', Problems.Get(1),
            'Expected the problem of the all-rules line to be its first broken rule: the missing Item No.');
        Assert.AreEqual('Line 30000: Quantity must be greater than zero.', Problems.Get(2),
            'Expected the problem of the valid-item line to be its first broken rule: Quantity comes before Unit Price');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateBatchIgnoresLinesOfOtherBatches()
    var
        ImportLineValidator: Codeunit "Import Line Validator";
        Assert: Codeunit Assert;
        Problems: List of [Text];
    begin
        // [SCENARIO] only the requested batch is validated
        // [GIVEN] two batches, each holding one broken line
        InsertLine('TRYAL-B5A', 10000, '', 5, 10);
        InsertLine('TRYAL-B5B', 20000, '', 5, 10);

        // [WHEN] validating the first batch
        ImportLineValidator.ValidateBatch('TRYAL-B5A', Problems);

        // [THEN] only the first batch's broken line is reported
        Assert.AreEqual(1, Problems.Count(),
            'Expected exactly one problem — the broken line of the OTHER batch must not leak into the result');
        Assert.AreEqual('Line 10000: Item No. is missing.', Problems.Get(1),
            'Expected the reported problem to belong to the requested batch (line 10000), not to the other batch');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ValidateBatchReplacesEarlierListContents()
    var
        ImportLineValidator: Codeunit "Import Line Validator";
        Assert: Codeunit Assert;
        Problems: List of [Text];
    begin
        // [SCENARIO] running the same validation twice leaves one run's findings, not two
        // [GIVEN] a batch with two broken lines, already validated once into the list
        InsertLine('TRYAL-B6', 10000, '', 5, 10);
        InsertLine('TRYAL-B6', 20000, 'ITEM-602', 0, 10);
        ImportLineValidator.ValidateBatch('TRYAL-B6', Problems);

        // [WHEN] validating the same batch again into the same list
        ImportLineValidator.ValidateBatch('TRYAL-B6', Problems);

        // [THEN] the list holds the two problems once, not accumulated
        Assert.AreEqual(2, Problems.Count(),
            'Expected the second run to replace the first run''s findings — Problems must be reset, and no collected errors may linger between calls');
        Assert.AreEqual('Line 10000: Item No. is missing.', Problems.Get(1),
            'Expected the first problem of the second run to be the blank Item No. on line 10000');
        Assert.AreEqual('Line 20000: Quantity must be greater than zero.', Problems.Get(2),
            'Expected the second problem of the second run to be the zero quantity on line 20000');
    end;

    local procedure MakeLine(var ImportOrderLine: Record "Import Order Line"; LineNo: Integer; ItemNo: Code[20]; NewQuantity: Decimal; NewUnitPrice: Decimal)
    begin
        ImportOrderLine.Init();
        ImportOrderLine."Batch Code" := 'TRYAL-MEM';
        ImportOrderLine."Line No." := LineNo;
        ImportOrderLine."Item No." := ItemNo;
        ImportOrderLine.Quantity := NewQuantity;
        ImportOrderLine."Unit Price" := NewUnitPrice;
    end;

    local procedure InsertLine(BatchCode: Code[20]; LineNo: Integer; ItemNo: Code[20]; NewQuantity: Decimal; NewUnitPrice: Decimal)
    var
        ImportOrderLine: Record "Import Order Line";
    begin
        ImportOrderLine.Init();
        ImportOrderLine."Batch Code" := BatchCode;
        ImportOrderLine."Line No." := LineNo;
        ImportOrderLine."Item No." := ItemNo;
        ImportOrderLine.Quantity := NewQuantity;
        ImportOrderLine."Unit Price" := NewUnitPrice;
        ImportOrderLine.Insert();
    end;
}
