codeunit 50900 "Change Dispenser Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExactDenominationTakesOneCoin()
    var
        ChangeDispenser: Codeunit "Change Dispenser";
        Assert: Codeunit Assert;
        Denominations: List of [Integer];
        Change: List of [Integer];
    begin
        // [SCENARIO] An amount that equals a loaded denomination is dispensed as that single coin
        AddAll(Denominations, 1, 5, 10, 25);

        Change := ChangeDispenser.FewestCoins(25, Denominations);

        Assert.AreEqual(1, Change.Count(), 'Expected a single coin when the amount equals a loaded denomination');
        Assert.AreEqual(25, Change.Get(1), 'Expected the one dispensed coin to be the 25 denomination itself');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShuffledDenominationsComeBackAscending()
    var
        ChangeDispenser: Codeunit "Change Dispenser";
        Denominations: List of [Integer];
        Change: List of [Integer];
        Expected: List of [Integer];
    begin
        // [SCENARIO] Denominations arrive in no particular order; the change comes back sorted ascending
        AddAll(Denominations, 10, 1, 25, 5);
        AddAll(Expected, 1, 5, 10, 25);

        Change := ChangeDispenser.FewestCoins(41, Denominations);

        VerifyExactCoins(Expected, Change);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LargestCoinFirstIsNotFewest()
    var
        ChangeDispenser: Codeunit "Change Dispenser";
        Denominations: List of [Integer];
        Change: List of [Integer];
        Expected: List of [Integer];
    begin
        // [SCENARIO] 63 from {1, 5, 10, 21, 25} is three 21-coins — starting with the 25 that fits first needs six coins
        AddAll(Denominations, 1, 5, 10, 21, 25);
        AddAll(Expected, 21, 21, 21);

        Change := ChangeDispenser.FewestCoins(63, Denominations);

        VerifyExactCoins(Expected, Change);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeadEndLargestCoinIsAvoided()
    var
        ChangeDispenser: Codeunit "Change Dispenser";
        Denominations: List of [Integer];
        Change: List of [Integer];
        Expected: List of [Integer];
    begin
        // [SCENARIO] 27 from {4, 5} needs three of each — grabbing 5s until nothing fits strands a remainder of 2
        AddAll(Denominations, 5, 4);
        AddAll(Expected, 4, 4, 4, 5, 5, 5);

        Change := ChangeDispenser.FewestCoins(27, Denominations);

        VerifyExactCoins(Expected, Change);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroAmountNeedsNoCoins()
    var
        ChangeDispenser: Codeunit "Change Dispenser";
        Assert: Codeunit Assert;
        Denominations: List of [Integer];
        Change: List of [Integer];
    begin
        // [SCENARIO] An amount of zero returns an empty list
        AddAll(Denominations, 1, 5, 10);

        Change := ChangeDispenser.FewestCoins(0, Denominations);

        Assert.AreEqual(0, Change.Count(), 'Expected no coins at all for an amount of 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AmountBelowEveryCoinIsImpossible()
    var
        ChangeDispenser: Codeunit "Change Dispenser";
        Assert: Codeunit Assert;
        Denominations: List of [Integer];
    begin
        // [SCENARIO] 3 from {5, 10} cannot be made — the smallest coin is already too big
        AddAll(Denominations, 5, 10);

        asserterror ChangeDispenser.FewestCoins(3, Denominations);

        Assert.ExpectedError('impossible');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnreachableAmountAboveTheCoinsIsImpossible()
    var
        ChangeDispenser: Codeunit "Change Dispenser";
        Assert: Codeunit Assert;
        Denominations: List of [Integer];
    begin
        // [SCENARIO] 13 from {4, 10} cannot be made even though coins fit into it
        AddAll(Denominations, 4, 10);

        asserterror ChangeDispenser.FewestCoins(13, Denominations);

        Assert.ExpectedError('impossible');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomAmountGetsTheFewestStandardCoins()
    var
        ChangeDispenser: Codeunit "Change Dispenser";
        Any: Codeunit Any;
        Denominations: List of [Integer];
        Change: List of [Integer];
        Amount: Integer;
    begin
        // [SCENARIO] A random amount against {1, 5, 10, 25} is dispensed with the provably minimal coin count
        AddAll(Denominations, 1, 5, 10, 25);
        Amount := Any.IntegerInRange(1, 99);

        Change := ChangeDispenser.FewestCoins(Amount, Denominations);

        VerifyMinimalChange(Amount, Denominations, Change, StandardCoinMinimum(Amount));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomGreedyTrapNeedsOnlyTwoCoins()
    var
        ChangeDispenser: Codeunit "Change Dispenser";
        Any: Codeunit Any;
        Denominations: List of [Integer];
        Change: List of [Integer];
        K: Integer;
    begin
        // [SCENARIO] For denominations {1, K, K+1} the amount 2*K is two K-coins —
        // grabbing the K+1 that fits first strands a remainder of K-1 in ones, K coins total
        K := Any.IntegerInRange(3, 9);
        AddAll(Denominations, 1, K, K + 1);

        Change := ChangeDispenser.FewestCoins(2 * K, Denominations);

        VerifyMinimalChange(2 * K, Denominations, Change, 2);
    end;

    local procedure VerifyExactCoins(Expected: List of [Integer]; Actual: List of [Integer])
    var
        Assert: Codeunit Assert;
        i: Integer;
    begin
        Assert.AreEqual(Expected.Count(), Actual.Count(), StrSubstNo('Expected the fewest possible coins — %1 of them — sorted ascending', Expected.Count()));
        for i := 1 to Expected.Count() do
            Assert.AreEqual(Expected.Get(i), Actual.Get(i), StrSubstNo('Expected coin %1 of the ascending change to be %2', i, Expected.Get(i)));
    end;

    local procedure VerifyMinimalChange(Amount: Integer; Denominations: List of [Integer]; Change: List of [Integer]; MinimalCount: Integer)
    var
        Assert: Codeunit Assert;
        Coin: Integer;
        Sum: Integer;
        i: Integer;
    begin
        Assert.AreEqual(MinimalCount, Change.Count(), StrSubstNo('Expected the fewest possible coins for amount %1', Amount));
        foreach Coin in Change do begin
            Assert.IsTrue(Denominations.Contains(Coin), StrSubstNo('Expected every dispensed coin to be a loaded denomination, got %1 for amount %2', Coin, Amount));
            Sum += Coin;
        end;
        Assert.AreEqual(Amount, Sum, 'Expected the dispensed coins to sum to exactly the amount');
        for i := 2 to Change.Count() do
            Assert.IsTrue(Change.Get(i) >= Change.Get(i - 1), StrSubstNo('Expected the coins in ascending order, got %1 before %2 at position %3', Change.Get(i - 1), Change.Get(i), i));
    end;

    // For the canonical set {1, 5, 10, 25} the greedy count is provably minimal,
    // so the test can compute the expected count without solving the task itself.
    local procedure StandardCoinMinimum(Amount: Integer): Integer
    var
        Remainder: Integer;
        Coins: Integer;
    begin
        Coins := Amount div 25;
        Remainder := Amount mod 25;
        Coins += Remainder div 10;
        Remainder := Remainder mod 10;
        Coins += Remainder div 5;
        exit(Coins + Remainder mod 5);
    end;

    local procedure AddAll(var Values: List of [Integer]; A: Integer; B: Integer)
    begin
        Values.Add(A);
        Values.Add(B);
    end;

    local procedure AddAll(var Values: List of [Integer]; A: Integer; B: Integer; C: Integer)
    begin
        AddAll(Values, A, B);
        Values.Add(C);
    end;

    local procedure AddAll(var Values: List of [Integer]; A: Integer; B: Integer; C: Integer; D: Integer)
    begin
        AddAll(Values, A, B, C);
        Values.Add(D);
    end;

    local procedure AddAll(var Values: List of [Integer]; A: Integer; B: Integer; C: Integer; D: Integer; E: Integer)
    begin
        AddAll(Values, A, B, C, D);
        Values.Add(E);
    end;

    local procedure AddAll(var Values: List of [Integer]; A: Integer; B: Integer; C: Integer; D: Integer; E: Integer; F: Integer)
    begin
        AddAll(Values, A, B, C, D, E);
        Values.Add(F);
    end;
}
