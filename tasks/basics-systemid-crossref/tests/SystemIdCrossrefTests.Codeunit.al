codeunit 50900 "SystemId Crossref Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddBookmarkStoresTheCustomerSystemIdAndNo()
    var
        Customer: Record Customer;
        Bookmark: Record "Customer Bookmark";
        Bookmarks: Codeunit "Customer Bookmarks";
        EntryNo: Integer;
    begin
        // [SCENARIO] AddBookmark snapshots both the durable id and the display number
        // [GIVEN] a customer
        LibrarySales.CreateCustomer(Customer);
        // [WHEN] adding a bookmark for it
        EntryNo := Bookmarks.AddBookmark(Customer."No.");
        // [THEN] the bookmark row stores the customer's SystemId and No.
        Bookmark.Get(EntryNo);
        Assert.AreEqual(Format(Customer.SystemId), Format(StoredCustomerSystemId(Bookmark)),
            'Expected AddBookmark to store the customer''s SystemId in "Customer SystemId"');
        Assert.AreEqual(Customer."No.", Bookmark."Customer No.",
            'Expected AddBookmark to store the customer''s number in "Customer No."');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResolveReturnsTheBookmarkedCustomer()
    var
        Customer: Record Customer;
        FoundCustomer: Record Customer;
        Bookmarks: Codeunit "Customer Bookmarks";
        EntryNo: Integer;
    begin
        // [SCENARIO] a bookmark resolves back to the customer it was created for
        // [GIVEN] a bookmarked customer
        LibrarySales.CreateCustomer(Customer);
        EntryNo := Bookmarks.AddBookmark(Customer."No.");
        // [WHEN] resolving the bookmark
        // [THEN] the customer is found and is the bookmarked one
        Assert.IsTrue(Bookmarks.ResolveCustomer(EntryNo, FoundCustomer),
            'Expected ResolveCustomer to find the customer the bookmark was created for');
        Assert.AreEqual(Customer."No.", FoundCustomer."No.",
            'Expected ResolveCustomer to return the bookmarked customer');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResolveStillFindsTheCustomerAfterRename()
    var
        Customer: Record Customer;
        FoundCustomer: Record Customer;
        Bookmarks: Codeunit "Customer Bookmarks";
        EntryNo: Integer;
        NewNo: Code[20];
    begin
        // [SCENARIO] renaming the customer must not break the bookmark
        // [GIVEN] a bookmarked customer
        LibrarySales.CreateCustomer(Customer);
        EntryNo := Bookmarks.AddBookmark(Customer."No.");
        // [WHEN] the customer is renamed to a new number
        NewNo := LibraryUtility.GenerateGUID();
        Customer.Rename(NewNo);
        // [THEN] the bookmark still resolves, to the customer's new number
        Assert.IsTrue(Bookmarks.ResolveCustomer(EntryNo, FoundCustomer),
            StrSubstNo('Expected the bookmark to still resolve after the customer was renamed to %1 — resolution must go through the SystemId, not the stored number', NewNo));
        Assert.AreEqual(NewNo, FoundCustomer."No.",
            'Expected the resolved customer to carry the new number after the rename');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StoredCustomerNoGoesStaleAfterRename()
    var
        Customer: Record Customer;
        Bookmark: Record "Customer Bookmark";
        Bookmarks: Codeunit "Customer Bookmarks";
        EntryNo: Integer;
        OldNo: Code[20];
    begin
        // [SCENARIO] the stored number is a plain snapshot that a rename leaves behind
        // [GIVEN] a bookmarked customer
        LibrarySales.CreateCustomer(Customer);
        OldNo := Customer."No.";
        EntryNo := Bookmarks.AddBookmark(OldNo);
        // [WHEN] the customer is renamed
        Customer.Rename(LibraryUtility.GenerateGUID());
        // [THEN] the bookmark's "Customer No." still shows the old number
        Bookmark.Get(EntryNo);
        Assert.AreEqual(OldNo, Bookmark."Customer No.",
            'Expected "Customer No." to keep the old number after a rename — it must stay a plain snapshot with no table relation');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResolveReturnsFalseWhenTheCustomerWasDeleted()
    var
        Customer: Record Customer;
        FoundCustomer: Record Customer;
        Bookmarks: Codeunit "Customer Bookmarks";
        EntryNo: Integer;
    begin
        // [SCENARIO] a bookmark whose customer is gone resolves to false, not an error
        // [GIVEN] a bookmarked customer that is then deleted
        LibrarySales.CreateCustomer(Customer);
        EntryNo := Bookmarks.AddBookmark(Customer."No.");
        Customer.Delete();
        // [WHEN] resolving the bookmark
        // [THEN] ResolveCustomer returns false
        Assert.IsFalse(Bookmarks.ResolveCustomer(EntryNo, FoundCustomer),
            'Expected ResolveCustomer to return false when the bookmarked customer no longer exists');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResolveReturnsFalseForAnUnknownEntryNo()
    var
        FoundCustomer: Record Customer;
        Bookmarks: Codeunit "Customer Bookmarks";
    begin
        // [SCENARIO] resolving an entry number that has no bookmark
        // [WHEN] resolving an entry number no bookmark uses
        // [THEN] ResolveCustomer returns false instead of erroring
        Assert.IsFalse(Bookmarks.ResolveCustomer(987654321, FoundCustomer),
            'Expected ResolveCustomer to return false for an entry number that has no bookmark');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ImportBookmarkKeepsTheSuppliedId()
    var
        Customer: Record Customer;
        Bookmark: Record "Customer Bookmark";
        Bookmarks: Codeunit "Customer Bookmarks";
        BookmarkId: Guid;
        EntryNo: Integer;
    begin
        // [SCENARIO] an imported bookmark carries the caller-supplied SystemId
        // [GIVEN] a customer and a GUID chosen by the caller
        LibrarySales.CreateCustomer(Customer);
        BookmarkId := CreateGuid();
        // [WHEN] importing a bookmark with that GUID
        EntryNo := Bookmarks.ImportBookmark(BookmarkId, Customer."No.");
        // [THEN] the row is retrievable by the supplied id and references the customer
        Assert.IsTrue(Bookmark.GetBySystemId(BookmarkId),
            'Expected the imported bookmark row''s own SystemId to be the caller-supplied GUID, not a platform-generated one');
        Assert.AreEqual(EntryNo, Bookmark."Entry No.",
            'Expected ImportBookmark to return the entry number of the row that carries the supplied id');
        Assert.AreEqual(Format(Customer.SystemId), Format(StoredCustomerSystemId(Bookmark)),
            'Expected the imported bookmark to store the customer''s SystemId, like AddBookmark does');
        Assert.AreEqual(Customer."No.", Bookmark."Customer No.",
            'Expected the imported bookmark to store the customer''s number, like AddBookmark does');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ImportingTheSameBookmarkIdTwiceFails()
    var
        Customer: Record Customer;
        Bookmarks: Codeunit "Customer Bookmarks";
        BookmarkId: Guid;
    begin
        // [SCENARIO] a SystemId is unique — a second import with the same id must fail
        // [GIVEN] a bookmark imported with a caller-supplied GUID
        LibrarySales.CreateCustomer(Customer);
        BookmarkId := CreateGuid();
        Bookmarks.ImportBookmark(BookmarkId, Customer."No.");
        // [WHEN] importing again with the same GUID
        asserterror ImportBookmarkAndReadItBack(Bookmarks, BookmarkId, Customer."No.");
        // [THEN] the duplicate-id insert fails with the platform's unique-index error on SystemId
        Assert.ExpectedError('There is already a record in table');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MigrationFillsTheSystemIdFromTheStoredNo()
    var
        Customer: Record Customer;
        Bookmark: Record "Customer Bookmark";
        Bookmarks: Codeunit "Customer Bookmarks";
        MigratedCount: Integer;
    begin
        // [SCENARIO] a legacy row is upgraded to carry the customer's SystemId
        // [GIVEN] a legacy bookmark row holding only the customer's number
        LibrarySales.CreateCustomer(Customer);
        InsertLegacyBookmark(Bookmark, 773301, Customer."No.");
        // [WHEN] running the migration
        MigratedCount := Bookmarks.MigrateLegacyBookmarks();
        // [THEN] one row is reported migrated and it now carries the customer's SystemId
        Assert.AreEqual(1, MigratedCount,
            'Expected MigrateLegacyBookmarks to report exactly one migrated row');
        Bookmark.Get(773301);
        Assert.AreEqual(Format(Customer.SystemId), Format(StoredCustomerSystemId(Bookmark)),
            'Expected migration to fill "Customer SystemId" with the SystemId of the customer the stored number points at');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MigrationSkipsRowsWhoseCustomerIsGone()
    var
        Customer: Record Customer;
        Bookmark: Record "Customer Bookmark";
        Bookmarks: Codeunit "Customer Bookmarks";
        GoneNo: Code[20];
        MigratedCount: Integer;
    begin
        // [SCENARIO] a legacy row pointing at a vanished customer stays untouched
        // [GIVEN] a legacy row whose stored number matches no customer
        LibrarySales.CreateCustomer(Customer);
        GoneNo := Customer."No.";
        Customer.Delete();
        InsertLegacyBookmark(Bookmark, 773311, GoneNo);
        // [WHEN] running the migration
        MigratedCount := Bookmarks.MigrateLegacyBookmarks();
        // [THEN] nothing is counted and the row keeps its empty id
        Assert.AreEqual(0, MigratedCount,
            'Expected MigrateLegacyBookmarks to count no rows when the stored number matches no customer');
        Bookmark.Get(773311);
        Assert.IsTrue(IsNullGuid(StoredCustomerSystemId(Bookmark)),
            StrSubstNo('Expected the unresolvable legacy row to keep an empty "Customer SystemId", got %1', StoredCustomerSystemId(Bookmark)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MigrationNeverRepointsRowsThatAlreadyCarryAnId()
    var
        Customer: Record Customer;
        Impostor: Record Customer;
        Bookmark: Record "Customer Bookmark";
        Bookmarks: Codeunit "Customer Bookmarks";
        EntryNo: Integer;
        OldNo: Code[20];
        MigratedCount: Integer;
    begin
        // [SCENARIO] migration must not touch rows that already have an id, even when their stored number now belongs to someone else
        // [GIVEN] a bookmarked customer renamed away from its old number, and a different customer taking that number over
        LibrarySales.CreateCustomer(Customer);
        OldNo := Customer."No.";
        EntryNo := Bookmarks.AddBookmark(OldNo);
        Customer.Rename(LibraryUtility.GenerateGUID());
        Impostor.Init();
        Impostor."No." := OldNo;
        Impostor.Insert();
        // [WHEN] running the migration
        MigratedCount := Bookmarks.MigrateLegacyBookmarks();
        // [THEN] nothing is counted and the bookmark still points at the renamed customer
        Assert.AreEqual(0, MigratedCount,
            'Expected MigrateLegacyBookmarks to skip rows that already carry a "Customer SystemId"');
        Bookmark.Get(EntryNo);
        Assert.AreEqual(Format(Customer.SystemId), Format(StoredCustomerSystemId(Bookmark)),
            'Expected the bookmark to keep pointing at the renamed customer — migration must never repoint a row that already has an id');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MigratedBookmarkSurvivesARename()
    var
        Customer: Record Customer;
        FoundCustomer: Record Customer;
        Bookmark: Record "Customer Bookmark";
        Bookmarks: Codeunit "Customer Bookmarks";
        NewNo: Code[20];
    begin
        // [SCENARIO] the payoff: a migrated legacy bookmark survives the rename that would have broken it
        // [GIVEN] a legacy row migrated onto the SystemId
        LibrarySales.CreateCustomer(Customer);
        InsertLegacyBookmark(Bookmark, 773321, Customer."No.");
        Bookmarks.MigrateLegacyBookmarks();
        // [WHEN] the customer is renamed
        NewNo := LibraryUtility.GenerateGUID();
        Customer.Rename(NewNo);
        // [THEN] the migrated bookmark resolves to the customer's new number
        Assert.IsTrue(Bookmarks.ResolveCustomer(773321, FoundCustomer),
            'Expected a migrated legacy bookmark to resolve even after the customer was renamed');
        Assert.AreEqual(NewNo, FoundCustomer."No.",
            'Expected the migrated bookmark to resolve to the customer''s new number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MigrationHandlesAMixOfRowsInOneRun()
    var
        FirstCustomer: Record Customer;
        SecondCustomer: Record Customer;
        GoneCustomer: Record Customer;
        AlreadyMigratedCustomer: Record Customer;
        Bookmark: Record "Customer Bookmark";
        Bookmarks: Codeunit "Customer Bookmarks";
        GoneNo: Code[20];
        AlreadyMigratedEntryNo: Integer;
        MigratedCount: Integer;
    begin
        // [SCENARIO] one migration run over a mix of rows counts exactly the resolvable legacy ones
        // [GIVEN] two resolvable legacy rows, one legacy row for a vanished customer, and one already-migrated row
        LibrarySales.CreateCustomer(FirstCustomer);
        LibrarySales.CreateCustomer(SecondCustomer);
        LibrarySales.CreateCustomer(GoneCustomer);
        GoneNo := GoneCustomer."No.";
        GoneCustomer.Delete();
        LibrarySales.CreateCustomer(AlreadyMigratedCustomer);
        AlreadyMigratedEntryNo := Bookmarks.AddBookmark(AlreadyMigratedCustomer."No.");
        InsertLegacyBookmark(Bookmark, 773331, FirstCustomer."No.");
        InsertLegacyBookmark(Bookmark, 773332, SecondCustomer."No.");
        InsertLegacyBookmark(Bookmark, 773333, GoneNo);
        // [WHEN] running the migration once
        MigratedCount := Bookmarks.MigrateLegacyBookmarks();
        // [THEN] exactly the two resolvable legacy rows are counted
        Assert.AreEqual(2, MigratedCount,
            'Expected MigrateLegacyBookmarks to count exactly the two resolvable legacy rows in a single run — every legacy row must be examined, not just the first');
        // [THEN] each resolvable legacy row carries its own customer's SystemId
        Bookmark.Get(773331);
        Assert.AreEqual(Format(FirstCustomer.SystemId), Format(StoredCustomerSystemId(Bookmark)),
            'Expected the first legacy row to be filled with its own customer''s SystemId');
        Bookmark.Get(773332);
        Assert.AreEqual(Format(SecondCustomer.SystemId), Format(StoredCustomerSystemId(Bookmark)),
            'Expected the second legacy row to be filled with its own customer''s SystemId');
        // [THEN] the vanished-customer row keeps its empty id and the already-migrated row keeps its id
        Bookmark.Get(773333);
        Assert.IsTrue(IsNullGuid(StoredCustomerSystemId(Bookmark)),
            StrSubstNo('Expected the legacy row for the vanished customer to keep an empty "Customer SystemId", got %1', StoredCustomerSystemId(Bookmark)));
        Bookmark.Get(AlreadyMigratedEntryNo);
        Assert.AreEqual(Format(AlreadyMigratedCustomer.SystemId), Format(StoredCustomerSystemId(Bookmark)),
            'Expected the already-migrated row to keep its "Customer SystemId" untouched');
    end;

    local procedure InsertLegacyBookmark(var Bookmark: Record "Customer Bookmark"; EntryNo: Integer; CustomerNo: Code[20])
    begin
        Bookmark.Init();
        Bookmark."Entry No." := EntryNo;
        Bookmark."Customer No." := CustomerNo;
        Bookmark.Insert();
    end;

    local procedure ImportBookmarkAndReadItBack(var Bookmarks: Codeunit "Customer Bookmarks"; BookmarkId: Guid; CustomerNo: Code[20])
    var
        Bookmark: Record "Customer Bookmark";
    begin
        Bookmarks.ImportBookmark(BookmarkId, CustomerNo);
        // Inserts are buffered and only reach SQL Server on the next read of the table, so a
        // duplicate SystemId is refused here — inside the asserterror — rather than at the end of the test.
        Bookmark.GetBySystemId(BookmarkId);
    end;

    local procedure StoredCustomerSystemId(Bookmark: Record "Customer Bookmark"): Guid
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        CustomerSystemId: Guid;
        i: Integer;
    begin
        // Looked up by name at run time so the tests also compile against a starter
        // that does not declare the field yet.
        RecRef.GetTable(Bookmark);
        for i := 1 to RecRef.FieldCount() do begin
            FieldRef := RecRef.FieldIndex(i);
            if FieldRef.Name = 'Customer SystemId' then begin
                CustomerSystemId := FieldRef.Value();
                exit(CustomerSystemId);
            end;
        end;
        Error('Expected the "Customer Bookmark" table to have a field named "Customer SystemId" of type Guid — add it, it is the reference that survives a rename');
    end;
}
