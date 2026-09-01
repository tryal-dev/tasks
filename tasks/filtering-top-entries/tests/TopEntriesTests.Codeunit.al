codeunit 50900 "Top Entries Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTheFiveLargestAmountsLargestFirst()
    var
        Leaderboard: Codeunit "Sales Contest Leaderboard";
        Any: Codeunit Any;
        Amounts: List of [Decimal];
        BaseAmount: Decimal;
        Step: Integer;
    begin
        ClearEntries();
        BaseAmount := Any.DecimalInRange(100, 500, 2);
        for Step := 1 to 8 do
            Amounts.Add(BaseAmount + Step * 10);
        Shuffle(Amounts);
        SeedAll(Amounts);

        AssertLeaderboard(ExpectedTopEntryNos(Amounts, 5), Leaderboard.GetTopFiveEntryNos(),
            'With eight entries the leaderboard must hold the entry numbers of exactly the five largest amounts, largest amount first');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsAllEntriesLargestFirstWhenFewerThanFiveExist()
    var
        Leaderboard: Codeunit "Sales Contest Leaderboard";
        Any: Codeunit Any;
        Amounts: List of [Decimal];
    begin
        ClearEntries();
        Amounts.Add(-Any.DecimalInRange(10, 99, 2));
        Amounts.Add(Any.DecimalInRange(200, 400, 2));
        Amounts.Add(0);
        Shuffle(Amounts);
        SeedAll(Amounts);

        AssertLeaderboard(ExpectedTopEntryNos(Amounts, 5), Leaderboard.GetTopFiveEntryNos(),
            'With only three entries the leaderboard must hold all three, largest amount first — zero and negative amounts rank like any other value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsAnEmptyListWhenThereAreNoEntries()
    var
        Leaderboard: Codeunit "Sales Contest Leaderboard";
        Expected: List of [Integer];
    begin
        ClearEntries();

        AssertLeaderboard(Expected, Leaderboard.GetTopFiveEntryNos(),
            'With no entries at all the leaderboard must be an empty list, not an error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RanksTheNewerEntryFirstWhenAmountsAreEqual()
    var
        Leaderboard: Codeunit "Sales Contest Leaderboard";
        Amounts: List of [Decimal];
    begin
        ClearEntries();
        Amounts.Add(900);
        Amounts.Add(900);
        Amounts.Add(900);
        Amounts.Add(700);
        Amounts.Add(500);
        Amounts.Add(100);
        Shuffle(Amounts);
        SeedAll(Amounts);

        AssertLeaderboard(ExpectedTopEntryNos(Amounts, 5), Leaderboard.GetTopFiveEntryNos(),
            'Entries sharing the same amount must rank the newer entry (the higher entry number) first');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BreaksATieForFifthPlaceInFavourOfTheNewerEntry()
    var
        Leaderboard: Codeunit "Sales Contest Leaderboard";
        Amounts: List of [Decimal];
    begin
        ClearEntries();
        Amounts.Add(90);
        Amounts.Add(80);
        Amounts.Add(70);
        Amounts.Add(60);
        Amounts.Add(50);
        Amounts.Add(50);
        Shuffle(Amounts);
        SeedAll(Amounts);

        AssertLeaderboard(ExpectedTopEntryNos(Amounts, 5), Leaderboard.GetTopFiveEntryNos(),
            'When fifth place is a tie on amount, the newer entry must take the last spot and the older one must fall off the leaderboard');
    end;

    local procedure ClearEntries()
    var
        SalesContestEntry: Record "Sales Contest Entry";
    begin
        SalesContestEntry.DeleteAll();
    end;

    // Dealing the amounts to the entry numbers in a random order makes the
    // expected list different on every run, so a submission cannot pass by
    // returning constants.
    local procedure Shuffle(var Amounts: List of [Decimal])
    var
        Any: Codeunit Any;
        Shuffled: List of [Decimal];
        Pick: Integer;
    begin
        while Amounts.Count() > 0 do begin
            Pick := Any.IntegerInRange(1, Amounts.Count());
            Shuffled.Add(Amounts.Get(Pick));
            Amounts.RemoveAt(Pick);
        end;
        Amounts := Shuffled;
    end;

    local procedure SeedAll(Amounts: List of [Decimal])
    var
        SalesContestEntry: Record "Sales Contest Entry";
        EntryNo: Integer;
    begin
        for EntryNo := 1 to Amounts.Count() do begin
            SalesContestEntry.Init();
            SalesContestEntry."Entry No." := EntryNo;
            SalesContestEntry.Amount := Amounts.Get(EntryNo);
            SalesContestEntry.Insert();
        end;
    end;

    // Independent reference ranking: entry number = position in Amounts,
    // ordered by amount descending, ties broken by higher entry number.
    local procedure ExpectedTopEntryNos(Amounts: List of [Decimal]; TopCount: Integer) Expected: List of [Integer]
    var
        BestEntryNo: Integer;
        EntryNo: Integer;
    begin
        if TopCount > Amounts.Count() then
            TopCount := Amounts.Count();
        while Expected.Count() < TopCount do begin
            BestEntryNo := 0;
            // AL evaluates both operands of "or", so Amounts.Get(BestEntryNo)
            // must stay behind the BestEntryNo = 0 check.
            for EntryNo := 1 to Amounts.Count() do
                if not Expected.Contains(EntryNo) then
                    if BestEntryNo = 0 then
                        BestEntryNo := EntryNo
                    else
                        if RanksHigher(Amounts.Get(EntryNo), EntryNo, Amounts.Get(BestEntryNo), BestEntryNo) then
                            BestEntryNo := EntryNo;
            Expected.Add(BestEntryNo);
        end;
    end;

    local procedure RanksHigher(AmountA: Decimal; EntryNoA: Integer; AmountB: Decimal; EntryNoB: Integer): Boolean
    begin
        if AmountA <> AmountB then
            exit(AmountA > AmountB);
        exit(EntryNoA > EntryNoB);
    end;

    local procedure AssertLeaderboard(Expected: List of [Integer]; Actual: List of [Integer]; Message: Text)
    var
        Assert: Codeunit Assert;
    begin
        // Comparing the formatted lists makes a failure print both lists in
        // full — the user's only debugging surface on the platform.
        Assert.AreEqual(FormatList(Expected), FormatList(Actual), Message);
    end;

    local procedure FormatList(EntryNos: List of [Integer]): Text
    var
        ListText: TextBuilder;
        EntryNo: Integer;
    begin
        foreach EntryNo in EntryNos do begin
            if ListText.Length() > 0 then
                ListText.Append(', ');
            ListText.Append(Format(EntryNo));
        end;
        exit('[' + ListText.ToText() + ']');
    end;
}
