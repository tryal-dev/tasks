codeunit 50900 "Dispatch Rules Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CityCentrePostcodesAreZoneOne()
    begin
        AssertZone('EC1', 1);
        AssertZone('EC2', 1);
        AssertZone('EC3', 1);
        AssertZone('EC4', 1);
        AssertZone('WC1', 1);
        AssertZone('WC2', 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InnerRingPostcodesAreZoneTwo()
    begin
        AssertZone('E1', 2);
        AssertZone('N1', 2);
        AssertZone('NW1', 2);
        AssertZone('SE1', 2);
        AssertZone('SW1', 2);
        AssertZone('W1', 2);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostcodesOnNeitherListAreZoneThree()
    var
        Any: Codeunit Any;
    begin
        // EC5, SW19 and E10 start like a listed code; a prefix match would zone them wrongly.
        // EC1A and EC10 sort between 'EC1' and 'EC4' as text; a range arm would zone them wrongly.
        AssertZone('EC5', 3);
        AssertZone('SW19', 3);
        AssertZone('E10', 3);
        AssertZone('EC1A', 3);
        AssertZone('EC10', 3);
        AssertZone('BR1', 3);
        AssertZone(UpperCase(Any.AlphabeticText(6)), 3);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LowercaseAndMixedCasePostcodesLandInTheirZone()
    begin
        AssertZone('ec1', 1);
        AssertZone('Wc2', 1);
        AssertZone('sw1', 2);
        AssertZone('nW1', 2);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ScoresFromNinetyToOneHundredGradeA()
    var
        Any: Codeunit Any;
    begin
        AssertGrade(90, 'A');
        AssertGrade(100, 'A');
        AssertGrade(Any.IntegerInRange(91, 99), 'A');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ScoresFromSeventyFiveToEightyNineGradeB()
    var
        Any: Codeunit Any;
    begin
        AssertGrade(75, 'B');
        AssertGrade(89, 'B');
        AssertGrade(Any.IntegerInRange(76, 88), 'B');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ScoresFromSixtyToSeventyFourGradeC()
    var
        Any: Codeunit Any;
    begin
        AssertGrade(60, 'C');
        AssertGrade(74, 'C');
        AssertGrade(Any.IntegerInRange(61, 73), 'C');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ScoresFromFortyToFiftyNineGradeD()
    var
        Any: Codeunit Any;
    begin
        AssertGrade(40, 'D');
        AssertGrade(59, 'D');
        AssertGrade(Any.IntegerInRange(41, 58), 'D');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ScoresFromZeroToThirtyNineGradeF()
    var
        Any: Codeunit Any;
    begin
        AssertGrade(0, 'F');
        AssertGrade(39, 'F');
        AssertGrade(Any.IntegerInRange(1, 38), 'F');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ScoresAboveOneHundredAreInvalid()
    var
        Any: Codeunit Any;
    begin
        AssertGrade(101, 'Invalid');
        AssertGrade(Any.IntegerInRange(102, 999), 'Invalid');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeScoresAreInvalid()
    var
        Any: Codeunit Any;
    begin
        AssertGrade(-1, 'Invalid');
        AssertGrade(-Any.IntegerInRange(2, 999), 'Invalid');
    end;

    // The postcode travels as Text so the failure message shows what was typed,
    // not the uppercased value the Code[10] parameter turns it into.
    local procedure AssertZone(TypedPostCode: Text; ExpectedZone: Integer)
    var
        DispatchRules: Codeunit "Dispatch Rules";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(ExpectedZone, DispatchRules.ShippingZone(CopyStr(TypedPostCode, 1, 10)),
            StrSubstNo('Expected postcode %1 to be Zone %2 (%3). The Code[10] parameter has already uppercased the postcode, and case value sets are compared exactly as written',
                TypedPostCode, ExpectedZone, ZoneRule(ExpectedZone)));
    end;

    local procedure ZoneRule(Zone: Integer): Text
    begin
        case Zone of
            1:
                exit('city centre: EC1, EC2, EC3, EC4, WC1, WC2');
            2:
                exit('inner ring: E1, N1, NW1, SE1, SW1, W1');
            else
                exit('any postcode on neither list');
        end;
    end;

    local procedure AssertGrade(Score: Integer; ExpectedGrade: Text)
    var
        DispatchRules: Codeunit "Dispatch Rules";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual(ExpectedGrade, DispatchRules.Grade(Score),
            StrSubstNo('Expected a score of %1 to grade as %2 (%3)', Score, ExpectedGrade, GradeRule(ExpectedGrade)));
    end;

    local procedure GradeRule(ExpectedGrade: Text): Text
    begin
        case ExpectedGrade of
            'A':
                exit('90 to 100');
            'B':
                exit('75 to 89');
            'C':
                exit('60 to 74');
            'D':
                exit('40 to 59');
            'F':
                exit('0 to 39');
            else
                exit('outside every band: below 0 or above 100');
        end;
    end;
}
