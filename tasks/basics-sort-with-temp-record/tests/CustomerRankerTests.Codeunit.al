codeunit 50900 "Customer Ranker Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure HighestScoreComesFirst()
    var
        CustomerRanker: Codeunit "Customer Ranker";
        Scores: Dictionary of [Code[20], Decimal];
    begin
        // [SCENARIO] Three distinct scores come back highest first, whatever order they were added in
        Scores.Add('TRYAL-D1A', 10);
        Scores.Add('TRYAL-D1B', 30);
        Scores.Add('TRYAL-D1C', 20);

        Assert.AreEqual('TRYAL-D1B,TRYAL-D1C,TRYAL-D1A', Join(CustomerRanker.RankCustomers(Scores)),
            'Expected the customers ordered by score, highest first (30, 20, 10) — not in the order they were added');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GeneratedScoresComeBackFromHighestToLowest()
    var
        CustomerRanker: Codeunit "Customer Ranker";
        Any: Codeunit Any;
        Scores: Dictionary of [Code[20], Decimal];
        i: Integer;
    begin
        // [SCENARIO] Nine generated scores are ranked exactly as an independent sort of the same dictionary
        for i := 1 to 9 do
            Scores.Add(GeneratedCustomerNo(i), Any.DecimalInRange(1, 1000, 2));

        Assert.AreEqual(ExpectedRanking(Scores), Join(CustomerRanker.RankCustomers(Scores)),
            'Expected the generated scores ranked from highest to lowest — every customer exactly once, in that order');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EqualScoresAreOrderedByCustomerNoAscending()
    var
        CustomerRanker: Codeunit "Customer Ranker";
        Scores: Dictionary of [Code[20], Decimal];
    begin
        // [SCENARIO] Customers sharing a score come out in ascending customer number, in the right place of the ranking
        Scores.Add('TRYAL-T1C', 40);
        Scores.Add('TRYAL-T1A', 40);
        Scores.Add('TRYAL-T1Z', 55);
        Scores.Add('TRYAL-T1B', 40);
        Scores.Add('TRYAL-T1Y', 12);

        Assert.AreEqual('TRYAL-T1Z,TRYAL-T1A,TRYAL-T1B,TRYAL-T1C,TRYAL-T1Y', Join(CustomerRanker.RankCustomers(Scores)),
            'Expected the three customers scoring 40 in ascending customer number (A, B, C) between the 55 and the 12 — Ascending(false) reverses the tiebreaker too, so only Score may run descending');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroAndNegativeScoresRankBelowPositiveOnes()
    var
        CustomerRanker: Codeunit "Customer Ranker";
        Scores: Dictionary of [Code[20], Decimal];
    begin
        // [SCENARIO] Zero and negative scores are ranked like any other value, below every positive score
        Scores.Add('TRYAL-Z1A', 0);
        Scores.Add('TRYAL-Z1B', -5);
        Scores.Add('TRYAL-Z1C', 12.5);
        Scores.Add('TRYAL-Z1D', -0.01);
        Scores.Add('TRYAL-Z1E', 3);

        Assert.AreEqual('TRYAL-Z1C,TRYAL-Z1E,TRYAL-Z1A,TRYAL-Z1D,TRYAL-Z1B', Join(CustomerRanker.RankCustomers(Scores)),
            'Expected 12.5, 3, 0, -0.01, -5 in that order — a zero or negative score is still a score and must be neither skipped nor moved');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyDictionaryYieldsAnEmptyList()
    var
        CustomerRanker: Codeunit "Customer Ranker";
        Scores: Dictionary of [Code[20], Decimal];
        Ranked: List of [Code[20]];
    begin
        // [SCENARIO] No scores rank to an empty list without raising an error
        Ranked := CustomerRanker.RankCustomers(Scores);

        Assert.AreEqual(0, Ranked.Count(),
            'Expected an empty dictionary to rank to a list with zero entries');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RankingTheSameScoresTwiceOnOneInstanceSucceeds()
    var
        CustomerRanker: Codeunit "Customer Ranker";
        Scores: Dictionary of [Code[20], Decimal];
    begin
        // [SCENARIO] A second call with the same customers on the same instance ranks them again without an error
        // [GIVEN] one Customer Ranker instance that has already ranked these scores once
        Scores.Add('TRYAL-R1A', 5);
        Scores.Add('TRYAL-R1B', 7);
        CustomerRanker.RankCustomers(Scores);

        // [WHEN] the same scores are ranked again on that instance
        // [THEN] the ranking is the same and nothing fails
        Assert.AreEqual('TRYAL-R1B,TRYAL-R1A', Join(CustomerRanker.RankCustomers(Scores)),
            'Expected the second call on the same instance to rank the same two customers again — a buffer still holding the first call''s rows refuses the insert or doubles the result');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SecondCallOnOneInstanceRanksOnlyItsOwnCustomers()
    var
        CustomerRanker: Codeunit "Customer Ranker";
        FirstScores: Dictionary of [Code[20], Decimal];
        SecondScores: Dictionary of [Code[20], Decimal];
    begin
        // [SCENARIO] Customers from an earlier call never appear in a later call's ranking
        // [GIVEN] one Customer Ranker instance that has already ranked three other customers
        FirstScores.Add('TRYAL-R2A', 50);
        FirstScores.Add('TRYAL-R2B', 20);
        FirstScores.Add('TRYAL-R2C', 80);
        CustomerRanker.RankCustomers(FirstScores);

        // [WHEN] two different customers are ranked on that instance
        SecondScores.Add('TRYAL-R2D', 10);
        SecondScores.Add('TRYAL-R2E', 30);

        // [THEN] only those two come back
        Assert.AreEqual('TRYAL-R2E,TRYAL-R2D', Join(CustomerRanker.RankCustomers(SecondScores)),
            'Expected the second call to rank only the two customers it was given — rows left in the buffer by the first call must not leak into the result');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BufferTableDeclaresTheRankingKey()
    var
        TempBuffer: Record "Customer Score Buffer";
        RecRef: RecordRef;
        BufferKey: KeyRef;
        i: Integer;
    begin
        // [SCENARIO] The buffer table declares a key starting with Score, "Customer No." — the order the ranking is read in
        RecRef.GetTable(TempBuffer);
        for i := 1 to RecRef.KeyCount() do begin
            BufferKey := RecRef.KeyIndex(i);
            if BufferKey.FieldCount() >= 2 then
                if (BufferKey.FieldIndex(1).Name() = 'Score') and (BufferKey.FieldIndex(2).Name() = 'Customer No.') then
                    exit;
        end;
        Assert.Fail('Expected table "Customer Score Buffer" to declare a secondary key on Score, "Customer No." (in that order) — the primary key alone cannot sort the ranking');
    end;

    local procedure GeneratedCustomerNo(Index: Integer): Code[20]
    begin
        exit(CopyStr('TRYAL-G' + Format(Index), 1, 20));
    end;

    local procedure Join(Ranked: List of [Code[20]]) Joined: Text
    var
        CustomerNo: Code[20];
    begin
        foreach CustomerNo in Ranked do begin
            if Joined <> '' then
                Joined += ',';
            Joined += CustomerNo;
        end;
    end;

    // A selection sort with the task's own rule, so the expected order never comes from the code under test.
    local procedure ExpectedRanking(Scores: Dictionary of [Code[20], Decimal]) Joined: Text
    var
        Remaining: List of [Code[20]];
        Best: Code[20];
        Candidate: Code[20];
    begin
        foreach Candidate in Scores.Keys() do
            Remaining.Add(Candidate);
        while Remaining.Count() > 0 do begin
            Best := Remaining.Get(1);
            foreach Candidate in Remaining do
                if RanksAbove(Candidate, Best, Scores) then
                    Best := Candidate;
            Remaining.Remove(Best);
            if Joined <> '' then
                Joined += ',';
            Joined += Best;
        end;
    end;

    local procedure RanksAbove(A: Code[20]; B: Code[20]; Scores: Dictionary of [Code[20], Decimal]): Boolean
    begin
        if Scores.Get(A) <> Scores.Get(B) then
            exit(Scores.Get(A) > Scores.Get(B));
        exit(A < B);
    end;
}
