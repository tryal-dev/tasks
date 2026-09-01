codeunit 50900 "Chunk Partitioner Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SevenItemsInThreeChunksSplitAsThreeTwoTwo()
    var
        ChunkPartitioner: Codeunit "Chunk Partitioner";
        Assert: Codeunit Assert;
        Items: List of [Text];
        Chunks: List of [List of [Text]];
        Chunk: List of [Text];
    begin
        // [SCENARIO] 7 items into 3 chunks: the single extra item lands in the first chunk
        Items.Add('ALPHA');
        Items.Add('BRAVO');
        Items.Add('CHARLIE');
        Items.Add('DELTA');
        Items.Add('ECHO');
        Items.Add('FOXTROT');
        Items.Add('GOLF');

        Chunks := ChunkPartitioner.Split(Items, 3);

        Assert.AreEqual(3, Chunks.Count(), 'Expected 7 items in 3 chunks to come back as exactly 3 chunks');
        Chunk := Chunks.Get(1);
        Assert.AreEqual(3, Chunk.Count(), 'Expected the first chunk of 7 items in 3 chunks to hold 3 items — the extra item goes to the front, so the sizes are 3, 2, 2');
        Chunk := Chunks.Get(2);
        Assert.AreEqual(2, Chunk.Count(), 'Expected the second chunk of 7 items in 3 chunks to hold 2 items — the sizes are 3, 2, 2');
        Chunk := Chunks.Get(3);
        Assert.AreEqual(2, Chunk.Count(), 'Expected the third chunk of 7 items in 3 chunks to hold 2 items — the sizes are 3, 2, 2');
        VerifyPartition(Items, 3, Chunks);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EvenlyDivisibleItemsSplitIntoEqualChunks()
    var
        ChunkPartitioner: Codeunit "Chunk Partitioner";
        Assert: Codeunit Assert;
        Items: List of [Text];
        Chunks: List of [List of [Text]];
        Chunk: List of [Text];
    begin
        // [SCENARIO] 6 items into 3 chunks: no remainder, every chunk holds exactly 2 items
        Items.Add('INV-001');
        Items.Add('INV-002');
        Items.Add('INV-003');
        Items.Add('INV-004');
        Items.Add('INV-005');
        Items.Add('INV-006');

        Chunks := ChunkPartitioner.Split(Items, 3);

        Assert.AreEqual(3, Chunks.Count(), 'Expected 6 items in 3 chunks to come back as exactly 3 chunks');
        Chunk := Chunks.Get(2);
        Assert.AreEqual('INV-003', Chunk.Get(1), 'Expected the second chunk of 6 items in 3 chunks to start at the 3rd item — chunks carve the input in order');
        VerifyPartition(Items, 3, Chunks);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SingleChunkReturnsTheWholeListInOrder()
    var
        ChunkPartitioner: Codeunit "Chunk Partitioner";
        Assert: Codeunit Assert;
        Items: List of [Text];
        Chunks: List of [List of [Text]];
        Chunk: List of [Text];
    begin
        // [SCENARIO] a chunk count of 1 returns one chunk equal to the input
        Items.Add('NORTH');
        Items.Add('EAST');
        Items.Add('SOUTH');
        Items.Add('WEST');

        Chunks := ChunkPartitioner.Split(Items, 1);

        Assert.AreEqual(1, Chunks.Count(), 'Expected a chunk count of 1 to return exactly one chunk');
        Chunk := Chunks.Get(1);
        Assert.AreEqual(4, Chunk.Count(), 'Expected the single chunk to hold all 4 items');
        VerifyPartition(Items, 1, Chunks);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FewerItemsThanChunksLeavesTrailingChunksEmpty()
    var
        ChunkPartitioner: Codeunit "Chunk Partitioner";
        Assert: Codeunit Assert;
        Items: List of [Text];
        Chunks: List of [List of [Text]];
        Chunk: List of [Text];
        ChunkNo: Integer;
    begin
        // [SCENARIO] 2 items into 5 chunks: sizes 1, 1, 0, 0, 0 — the result still has 5 chunks
        Items.Add('FIRST');
        Items.Add('SECOND');

        Chunks := ChunkPartitioner.Split(Items, 5);

        Assert.AreEqual(5, Chunks.Count(), 'Expected 2 items in 5 chunks to still come back as exactly 5 chunks — chunks with nothing to do stay in the result, empty');
        Chunk := Chunks.Get(1);
        Assert.AreEqual('FIRST', Chunk.Get(1), 'Expected the first chunk to hold the first item when there are fewer items than chunks');
        Chunk := Chunks.Get(2);
        Assert.AreEqual('SECOND', Chunk.Get(1), 'Expected the second chunk to hold the second item when there are fewer items than chunks');
        for ChunkNo := 3 to 5 do begin
            Chunk := Chunks.Get(ChunkNo);
            Assert.AreEqual(0, Chunk.Count(), StrSubstNo('Expected chunk %1 of 5 to be empty when only 2 items were split — the sizes must be 1, 1, 0, 0, 0', ChunkNo));
        end;
        VerifyPartition(Items, 5, Chunks);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EmptyInputStillReturnsChunkCountEmptyChunks()
    var
        ChunkPartitioner: Codeunit "Chunk Partitioner";
        Assert: Codeunit Assert;
        Items: List of [Text];
        Chunks: List of [List of [Text]];
        Chunk: List of [Text];
        ChunkNo: Integer;
    begin
        // [SCENARIO] an empty input list still yields exactly ChunkCount chunks, all empty
        Chunks := ChunkPartitioner.Split(Items, 4);

        Assert.AreEqual(4, Chunks.Count(), 'Expected an empty input split into 4 chunks to return exactly 4 chunks');
        for ChunkNo := 1 to 4 do begin
            Chunk := Chunks.Get(ChunkNo);
            Assert.AreEqual(0, Chunk.Count(), StrSubstNo('Expected chunk %1 of 4 to be empty when the input list was empty', ChunkNo));
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroChunkCountRaisesError()
    var
        ChunkPartitioner: Codeunit "Chunk Partitioner";
        Assert: Codeunit Assert;
        Items: List of [Text];
        Chunks: List of [List of [Text]];
    begin
        // [SCENARIO] a chunk count of 0 is rejected with the promised error message
        Items.Add('ANYTHING');

        asserterror Chunks := ChunkPartitioner.Split(Items, 0);

        Assert.ExpectedError('Chunk count must be greater than zero');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NegativeChunkCountRaisesError()
    var
        ChunkPartitioner: Codeunit "Chunk Partitioner";
        Assert: Codeunit Assert;
        Items: List of [Text];
        Chunks: List of [List of [Text]];
    begin
        // [SCENARIO] a negative chunk count is rejected with the promised error message
        Items.Add('ANYTHING');

        asserterror Chunks := ChunkPartitioner.Split(Items, -3);

        Assert.ExpectedError('Chunk count must be greater than zero');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomWorkloadKeepsOrderAndBalance()
    var
        ChunkPartitioner: Codeunit "Chunk Partitioner";
        Any: Codeunit Any;
        Items: List of [Text];
        Chunks: List of [List of [Text]];
        ChunkCount: Integer;
        ItemCount: Integer;
        i: Integer;
    begin
        // [SCENARIO] a randomized workload keeps every promise, so hardcoding the fixed examples fails
        ChunkCount := Any.IntegerInRange(2, 9);
        ItemCount := Any.IntegerInRange(10, 60);
        for i := 1 to ItemCount do
            Items.Add(StrSubstNo('REC-%1-%2', i, Any.AlphabeticText(5)));

        Chunks := ChunkPartitioner.Split(Items, ChunkCount);

        VerifyPartition(Items, ChunkCount, Chunks);
    end;

    local procedure VerifyPartition(Items: List of [Text]; ChunkCount: Integer; Chunks: List of [List of [Text]])
    var
        Assert: Codeunit Assert;
        Chunk: List of [Text];
        BaseSize: Integer;
        LargerChunks: Integer;
        ExpectedSize: Integer;
        ChunkNo: Integer;
        ItemNo: Integer;
        i: Integer;
    begin
        Assert.AreEqual(ChunkCount, Chunks.Count(), StrSubstNo('Expected exactly %1 chunks for %2 items — the result always holds ChunkCount chunks', ChunkCount, Items.Count()));
        BaseSize := Items.Count() div ChunkCount;
        LargerChunks := Items.Count() mod ChunkCount;
        ItemNo := 0;
        for ChunkNo := 1 to Chunks.Count() do begin
            Chunk := Chunks.Get(ChunkNo);
            ExpectedSize := BaseSize;
            if ChunkNo <= LargerChunks then
                ExpectedSize += 1;
            Assert.AreEqual(ExpectedSize, Chunk.Count(), StrSubstNo('Expected chunk %1 of %2 to hold %3 of the %4 items — sizes may differ by at most one and the earliest chunks take the extras', ChunkNo, ChunkCount, ExpectedSize, Items.Count()));
            for i := 1 to Chunk.Count() do begin
                ItemNo += 1;
                Assert.AreEqual(Items.Get(ItemNo), Chunk.Get(i), StrSubstNo('Expected position %1 of chunk %2 to hold item %3 of the input — reading the chunks in order must reproduce the original list', i, ChunkNo, ItemNo));
            end;
        end;
        Assert.AreEqual(Items.Count(), ItemNo, 'Expected the chunks to contain every input item exactly once, nothing dropped and nothing invented');
    end;
}
