codeunit 50900 "Raffle Draw Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SameSeedDrawsTheSameWinners()
    var
        RaffleDraw: Codeunit "Raffle Draw";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Entrants: List of [Code[20]];
        FirstDraw: List of [Code[20]];
        SecondDraw: List of [Code[20]];
        Seed: Integer;
    begin
        // [SCENARIO] Two draws with the same seed name the same winners in the same order
        Entrants := MakeEntrants('T1', 8);
        Seed := Any.IntegerInRange(1, 1000000);

        FirstDraw := RaffleDraw.DrawWinners(Seed, Entrants, 4);
        SecondDraw := RaffleDraw.DrawWinners(Seed, Entrants, 4);

        Assert.AreEqual(4, FirstDraw.Count(), StrSubstNo('Expected a draw of 4 winners from 8 entrants to return 4 winners, got: %1', Join(FirstDraw)));
        Assert.AreEqual(Join(FirstDraw), Join(SecondDraw),
            StrSubstNo('Expected a second draw with seed %1 to replay the first one exactly — Randomize(Seed) restarts the same sequence, so it must run once at the start of every draw', Seed));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DifferentSeedsDrawDifferentWinners()
    var
        RaffleDraw: Codeunit "Raffle Draw";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Entrants: List of [Code[20]];
        DrawA: List of [Code[20]];
        DrawB: List of [Code[20]];
        SeedA: Integer;
        SeedB: Integer;
    begin
        // [SCENARIO] Two seeds put all ten entrants in different orders
        Entrants := MakeEntrants('T2', 10);
        SeedA := Any.IntegerInRange(1, 1000000);
        SeedB := SeedA + Any.IntegerInRange(1, 1000);

        DrawA := RaffleDraw.DrawWinners(SeedA, Entrants, 10);
        DrawB := RaffleDraw.DrawWinners(SeedB, Entrants, 10);

        Assert.AreEqual(10, DrawA.Count(), StrSubstNo('Expected a draw of all 10 entrants to return 10 winners, got: %1', Join(DrawA)));
        Assert.AreNotEqual(Join(DrawA), Join(DrawB),
            StrSubstNo('Expected seeds %1 and %2 to order the ten entrants differently — the draw has to come out of Random, not out of the entrant list as it is', SeedA, SeedB));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EveryWinnerIsADistinctEntrant()
    var
        RaffleDraw: Codeunit "Raffle Draw";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Entrants: List of [Code[20]];
        Winners: List of [Code[20]];
    begin
        // [SCENARIO] Drawing fewer winners than entrants returns that many distinct entrants
        Entrants := MakeEntrants('T3', 7);

        Winners := RaffleDraw.DrawWinners(Any.IntegerInRange(1, 1000000), Entrants, 5);

        Assert.AreEqual(5, Winners.Count(), StrSubstNo('Expected exactly 5 winners from 7 entrants, got: %1', Join(Winners)));
        AssertWinnersAreDistinctEntrants(Entrants, Winners);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DrawingExactlyTheEntrantCountReturnsEveryoneOnce()
    var
        RaffleDraw: Codeunit "Raffle Draw";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Entrants: List of [Code[20]];
        Winners: List of [Code[20]];
    begin
        // [SCENARIO] A draw for as many winners as there are entrants names each entrant exactly once
        Entrants := MakeEntrants('T4', 5);

        Winners := RaffleDraw.DrawWinners(Any.IntegerInRange(1, 1000000), Entrants, 5);

        Assert.AreEqual(5, Winners.Count(), StrSubstNo('Expected all 5 entrants to win when 5 winners are drawn from 5, got: %1 — the last pick is made from a pool of one, where Random(1) is always 1', Join(Winners)));
        AssertWinnersAreDistinctEntrants(Entrants, Winners);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AskingForMoreWinnersThanEntrantsReturnsEveryone()
    var
        RaffleDraw: Codeunit "Raffle Draw";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Entrants: List of [Code[20]];
        Winners: List of [Code[20]];
    begin
        // [SCENARIO] A Count above the number of entrants makes everyone a winner, without an error
        Entrants := MakeEntrants('T5', 4);

        Winners := RaffleDraw.DrawWinners(Any.IntegerInRange(1, 1000000), Entrants, 10);

        Assert.AreEqual(4, Winners.Count(), StrSubstNo('Expected all 4 entrants (and nobody else) to win when 10 winners are requested from 4, got: %1 — stop when the pool runs empty', Join(Winners)));
        AssertWinnersAreDistinctEntrants(Entrants, Winners);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ASingleEntrantAlwaysWins()
    var
        RaffleDraw: Codeunit "Raffle Draw";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Entrants: List of [Code[20]];
        Winners: List of [Code[20]];
        OnlyEntrant: Code[20];
    begin
        // [SCENARIO] With one entrant in the pool, Random(1) is always 1 and that entrant wins
        OnlyEntrant := CopyStr('T6-' + UpperCase(Any.AlphabeticText(8)), 1, MaxStrLen(OnlyEntrant));
        Entrants.Add(OnlyEntrant);

        Winners := RaffleDraw.DrawWinners(Any.IntegerInRange(1, 1000000), Entrants, 1);

        Assert.AreEqual(OnlyEntrant, Join(Winners),
            'Expected the only entrant to be the one winner — Random(1) returns 1, the first and only position; it never returns 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroCountDrawsNobody()
    var
        RaffleDraw: Codeunit "Raffle Draw";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Entrants: List of [Code[20]];
        Winners: List of [Code[20]];
    begin
        // [SCENARIO] A Count of 0 returns an empty list
        Entrants := MakeEntrants('T7', 5);

        Winners := RaffleDraw.DrawWinners(Any.IntegerInRange(1, 1000000), Entrants, 0);

        Assert.AreEqual(0, Winners.Count(), StrSubstNo('Expected a Count of 0 to draw nobody, got: %1', Join(Winners)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoEntrantsDrawsNobody()
    var
        RaffleDraw: Codeunit "Raffle Draw";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Entrants: List of [Code[20]];
        Winners: List of [Code[20]];
    begin
        // [SCENARIO] An empty entrant list returns an empty list instead of raising
        Winners := RaffleDraw.DrawWinners(Any.IntegerInRange(1, 1000000), Entrants, 3);

        Assert.AreEqual(0, Winners.Count(), StrSubstNo('Expected a draw with no entrants to return an empty list without an error, got: %1', Join(Winners)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheCallersEntrantListIsLeftUntouched()
    var
        RaffleDraw: Codeunit "Raffle Draw";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Entrants: List of [Code[20]];
        EntrantsBefore: Text;
    begin
        // [SCENARIO] Drawing removes winners from a working copy, not from the caller's list
        Entrants := MakeEntrants('T8', 5);
        EntrantsBefore := Join(Entrants);

        RaffleDraw.DrawWinners(Any.IntegerInRange(1, 1000000), Entrants, 3);

        Assert.AreEqual(EntrantsBefore, Join(Entrants),
            'Expected the entrant list passed in to be exactly as it was after the draw — a List is a reference type, so remove winners from your own copy of it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WinnersFollowTheDocumentedDrawProcedure()
    var
        RaffleDraw: Codeunit "Raffle Draw";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Entrants: List of [Code[20]];
        Winners: List of [Code[20]];
        Seed: Integer;
    begin
        // [SCENARIO] The winners are exactly what the documented procedure produces for the seed
        Entrants := MakeEntrants('T9', 7);
        Seed := Any.IntegerInRange(1, 1000000);

        Winners := RaffleDraw.DrawWinners(Seed, Entrants, 5);

        Assert.AreEqual(Join(ReplayDocumentedProcedure(Seed, Entrants, 5)), Join(Winners),
            StrSubstNo('Expected the winners the documented procedure produces for seed %1: Randomize(Seed) once, then for every pick Random(pool size) is the 1-based position of the winner in the remaining pool, which is removed before the next pick', Seed));
    end;

    local procedure ReplayDocumentedProcedure(Seed: Integer; Entrants: List of [Code[20]]; Count: Integer) Expected: List of [Code[20]]
    var
        Pool: List of [Code[20]];
        Position: Integer;
    begin
        Pool.AddRange(Entrants);
        Randomize(Seed);
        while (Expected.Count() < Count) and (Pool.Count() > 0) do begin
            Position := Random(Pool.Count());
            Expected.Add(Pool.Get(Position));
            Pool.RemoveAt(Position);
        end;
    end;

    local procedure AssertWinnersAreDistinctEntrants(Entrants: List of [Code[20]]; Winners: List of [Code[20]])
    var
        Assert: Codeunit Assert;
        Winner: Code[20];
    begin
        foreach Winner in Winners do begin
            Assert.IsTrue(Entrants.Contains(Winner),
                StrSubstNo('Expected every winner to be one of the entrants, but "%1" is not — winners: %2', Winner, Join(Winners)));
            Assert.IsTrue(Winners.IndexOf(Winner) = Winners.LastIndexOf(Winner),
                StrSubstNo('Expected no entrant to win twice, but "%1" appears more than once in: %2 — remove each winner from the pool before the next pick', Winner, Join(Winners)));
        end;
    end;

    local procedure MakeEntrants(Prefix: Text; HowMany: Integer) Entrants: List of [Code[20]]
    var
        Any: Codeunit Any;
        Entrant: Code[20];
        i: Integer;
    begin
        for i := 1 to HowMany do begin
            Entrant := CopyStr(StrSubstNo('%1-%2-%3', Prefix, i, UpperCase(Any.AlphabeticText(4))), 1, MaxStrLen(Entrant));
            Entrants.Add(Entrant);
        end;
    end;

    local procedure Join(Values: List of [Code[20]]): Text
    var
        Value: Code[20];
        Joined: Text;
        i: Integer;
    begin
        foreach Value in Values do begin
            i += 1;
            if i > 1 then
                Joined += ',';
            Joined += Value;
        end;
        exit(Joined);
    end;
}
