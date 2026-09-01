codeunit 50101 "Customer Bookmarks"
{
    procedure AddBookmark(CustomerNo: Code[20]): Integer
    var
        Customer: Record Customer;
        Bookmark: Record "Customer Bookmark";
    begin
        Customer.Get(CustomerNo);
        Bookmark."Entry No." := NextEntryNo();
        Bookmark."Customer No." := Customer."No.";
        // TODO: also capture the identity that a rename cannot change.
        Bookmark.Insert(true);
        exit(Bookmark."Entry No.");
    end;

    procedure ResolveCustomer(EntryNo: Integer; var Customer: Record Customer): Boolean
    var
        Bookmark: Record "Customer Bookmark";
    begin
        if not Bookmark.Get(EntryNo) then
            exit(false);
        // TODO: the stored number is a snapshot — it goes stale the moment the customer is renamed.
        exit(Customer.Get(Bookmark."Customer No."));
    end;

    procedure ImportBookmark(BookmarkId: Guid; CustomerNo: Code[20]): Integer
    begin
        // TODO: insert a bookmark whose own SystemId is exactly BookmarkId.
    end;

    procedure MigrateLegacyBookmarks(): Integer
    begin
        // TODO: fill "Customer SystemId" for legacy rows from their stored "Customer No.".
    end;

    local procedure NextEntryNo(): Integer
    var
        Bookmark: Record "Customer Bookmark";
    begin
        if Bookmark.FindLast() then
            exit(Bookmark."Entry No." + 1)
        else
            exit(1);
    end;
}
