codeunit 50100 "Chunk Partitioner"
{
    procedure Split(Items: List of [Text]; ChunkCount: Integer) Chunks: List of [List of [Text]]
    begin
        // TODO: reject a chunk count of zero or less, then deal the items,
        // in order, into exactly ChunkCount chunks whose sizes differ by
        // at most one — extras to the front.
        exit(Chunks);
    end;
}
