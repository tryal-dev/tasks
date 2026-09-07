codeunit 50900 "Category Breadcrumb Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PathListsTheCategoriesFromTheRootDownToTheItemsCategory()
    var
        CategoryBreadcrumb: Codeunit "Category Breadcrumb";
        RootCode: Code[20];
        MidCode: Code[20];
        LeafCode: Code[20];
    begin
        RootCode := CreateCategory('');
        MidCode := CreateCategory(RootCode);
        LeafCode := CreateCategory(MidCode);

        Assert.AreEqual(RootCode + ' > ' + MidCode + ' > ' + LeafCode, CategoryBreadcrumb.CategoryPath(CreateItemInCategory(LeafCode)),
            'Expected the path to start at the root and end at the item''s own category, with " > " (space, greater-than, space) between the codes');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PathOfAnItemInARootCategoryIsJustThatCode()
    var
        CategoryBreadcrumb: Codeunit "Category Breadcrumb";
        RootCode: Code[20];
    begin
        RootCode := CreateCategory('');

        Assert.AreEqual(RootCode, CategoryBreadcrumb.CategoryPath(CreateItemInCategory(RootCode)),
            'Expected a category without a parent to give a path of just its own code, with no separator');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PathIsEmptyForAnItemWithoutACategory()
    var
        CategoryBreadcrumb: Codeunit "Category Breadcrumb";
    begin
        Assert.AreEqual('', CategoryBreadcrumb.CategoryPath(CreateItemInCategory('')),
            'Expected an empty path for an item that has no Item Category Code, without any error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DepthCountsEveryCategoryOnThePath()
    var
        CategoryBreadcrumb: Codeunit "Category Breadcrumb";
        Level1Code: Code[20];
        Level2Code: Code[20];
        Level3Code: Code[20];
        Level4Code: Code[20];
    begin
        Level1Code := CreateCategory('');
        Level2Code := CreateCategory(Level1Code);
        Level3Code := CreateCategory(Level2Code);
        Level4Code := CreateCategory(Level3Code);

        Assert.AreEqual(4, CategoryBreadcrumb.CategoryDepth(CreateItemInCategory(Level4Code)),
            'Expected the depth of an item four levels below the root to be 4 (the root counts as level 1)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DepthIsOneForAnItemInARootCategory()
    var
        CategoryBreadcrumb: Codeunit "Category Breadcrumb";
        RootCode: Code[20];
    begin
        RootCode := CreateCategory('');

        Assert.AreEqual(1, CategoryBreadcrumb.CategoryDepth(CreateItemInCategory(RootCode)),
            'Expected a depth of 1 for an item whose category has no parent');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DepthIsZeroForAnItemWithoutACategory()
    var
        CategoryBreadcrumb: Codeunit "Category Breadcrumb";
    begin
        Assert.AreEqual(0, CategoryBreadcrumb.CategoryDepth(CreateItemInCategory('')),
            'Expected a depth of 0 for an item that has no Item Category Code, without any error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RootCategoryReturnsTheTopOfTheTree()
    var
        CategoryBreadcrumb: Codeunit "Category Breadcrumb";
        RootCode: Code[20];
        MidCode: Code[20];
        LeafCode: Code[20];
    begin
        RootCode := CreateCategory('');
        MidCode := CreateCategory(RootCode);
        LeafCode := CreateCategory(MidCode);

        Assert.AreEqual(RootCode, CategoryBreadcrumb.RootCategory(CreateItemInCategory(LeafCode)),
            'Expected RootCategory to return the code of the topmost category of the item''s tree, not the item''s own category');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RootCategoryOfAnItemInARootCategoryIsThatCategory()
    var
        CategoryBreadcrumb: Codeunit "Category Breadcrumb";
        RootCode: Code[20];
    begin
        RootCode := CreateCategory('');

        Assert.AreEqual(RootCode, CategoryBreadcrumb.RootCategory(CreateItemInCategory(RootCode)),
            'Expected a category without a parent to be its own root');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RootCategoryIsEmptyForAnItemWithoutACategory()
    var
        CategoryBreadcrumb: Codeunit "Category Breadcrumb";
    begin
        Assert.AreEqual('', CategoryBreadcrumb.RootCategory(CreateItemInCategory('')),
            'Expected an empty root for an item that has no Item Category Code, without any error');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PathFailsWhenTheItemsCategoryPointsAtADeletedParent()
    var
        RootCode: Code[20];
        MidCode: Code[20];
        LeafCode: Code[20];
        ItemNo: Code[20];
    begin
        RootCode := CreateCategory('');
        MidCode := CreateCategory(RootCode);
        LeafCode := CreateCategory(MidCode);
        ItemNo := CreateItemInCategory(LeafCode);
        DeleteCategoryDirectly(MidCode);

        if TryCategoryPath(ItemNo) then
            Assert.Fail(StrSubstNo('Expected CategoryPath to raise an error because the parent %1 of category %2 no longer exists, but it returned a value', MidCode, LeafCode));

        Assert.ExpectedError(StrSubstNo('Item category %1 refers to parent category %2, which does not exist.', LeafCode, MidCode));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DepthFailsWhenTheRootOfTheTreeWasDeleted()
    var
        RootCode: Code[20];
        MidCode: Code[20];
        LeafCode: Code[20];
        ItemNo: Code[20];
    begin
        RootCode := CreateCategory('');
        MidCode := CreateCategory(RootCode);
        LeafCode := CreateCategory(MidCode);
        ItemNo := CreateItemInCategory(LeafCode);
        DeleteCategoryDirectly(RootCode);

        if TryCategoryDepth(ItemNo) then
            Assert.Fail(StrSubstNo('Expected CategoryDepth to raise an error because the root %1 above category %2 no longer exists, but it returned a value', RootCode, MidCode));

        Assert.ExpectedError(StrSubstNo('Item category %1 refers to parent category %2, which does not exist.', MidCode, RootCode));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RootCategoryFailsWhenTheParentCodeNamesNoCategory()
    var
        CategoryCode: Code[20];
        ItemNo: Code[20];
    begin
        CategoryCode := CreateCategory('');
        ItemNo := CreateItemInCategory(CategoryCode);
        SetParentDirectly(CategoryCode, 'TRYAL-NOWHERE');

        if TryRootCategory(ItemNo) then
            Assert.Fail(StrSubstNo('Expected RootCategory to raise an error because category %1 names a parent TRYAL-NOWHERE that does not exist, but it returned a value', CategoryCode));

        Assert.ExpectedError(StrSubstNo('Item category %1 refers to parent category TRYAL-NOWHERE, which does not exist.', CategoryCode));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PathFailsOnATwoCategoryCycle()
    var
        CodeA: Code[20];
        CodeB: Code[20];
        ItemNo: Code[20];
    begin
        CodeA := CreateCategory('');
        CodeB := CreateCategory(CodeA);
        ItemNo := CreateItemInCategory(CodeA);
        SetParentDirectly(CodeA, CodeB);

        if TryCategoryPath(ItemNo) then
            Assert.Fail(StrSubstNo('Expected CategoryPath to raise an error because categories %1 and %2 are each other''s parent, but it returned a value', CodeA, CodeB));

        Assert.ExpectedError(StrSubstNo('Item category %1 is its own ancestor.', CodeA));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DepthFailsOnACycleAboveTheItemsCategory()
    var
        CodeA: Code[20];
        CodeB: Code[20];
        CodeD: Code[20];
        ItemNo: Code[20];
    begin
        CodeA := CreateCategory('');
        CodeB := CreateCategory(CodeA);
        CodeD := CreateCategory(CodeB);
        ItemNo := CreateItemInCategory(CodeD);
        SetParentDirectly(CodeA, CodeB);

        if TryCategoryDepth(ItemNo) then
            Assert.Fail(StrSubstNo('Expected CategoryDepth to raise an error because the walk from %1 runs into the cycle %2 <-> %3, but it returned a value', CodeD, CodeB, CodeA));

        Assert.ExpectedError(StrSubstNo('Item category %1 is its own ancestor.', CodeB));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RootCategoryFailsWhenACategoryIsItsOwnParent()
    var
        CategoryCode: Code[20];
        ItemNo: Code[20];
    begin
        CategoryCode := CreateCategory('');
        ItemNo := CreateItemInCategory(CategoryCode);
        SetParentDirectly(CategoryCode, CategoryCode);

        if TryRootCategory(ItemNo) then
            Assert.Fail(StrSubstNo('Expected RootCategory to raise an error because category %1 is its own parent, but it returned a value', CategoryCode));

        Assert.ExpectedError(StrSubstNo('Item category %1 is its own ancestor.', CategoryCode));
    end;

    local procedure CreateCategory(ParentCode: Code[20]): Code[20]
    var
        ItemCategory: Record "Item Category";
    begin
        LibraryInventory.CreateItemCategory(ItemCategory);
        if ParentCode <> '' then begin
            ItemCategory.Validate("Parent Category", ParentCode);
            ItemCategory.Modify(true);
        end;
        exit(ItemCategory.Code);
    end;

    local procedure CreateItemInCategory(CategoryCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Category Code", CategoryCode);
        Item.Modify(true);
        exit(Item."No.");
    end;

    // Skips the field's OnValidate on purpose: it refuses cycles, and the task is about
    // surviving data that got past it (imports, configuration packages, direct writes).
    local procedure SetParentDirectly(CategoryCode: Code[20]; ParentCode: Code[20])
    var
        ItemCategory: Record "Item Category";
    begin
        ItemCategory.Get(CategoryCode);
        ItemCategory."Parent Category" := ParentCode;
        ItemCategory.Modify();
    end;

    // Delete() without triggers: OnDelete refuses a category that still has children,
    // which is exactly the dangling-parent state these tests need.
    local procedure DeleteCategoryDirectly(CategoryCode: Code[20])
    var
        ItemCategory: Record "Item Category";
    begin
        ItemCategory.Get(CategoryCode);
        ItemCategory.Delete();
    end;

    [TryFunction]
    local procedure TryCategoryPath(ItemNo: Code[20])
    var
        CategoryBreadcrumb: Codeunit "Category Breadcrumb";
    begin
        CategoryBreadcrumb.CategoryPath(ItemNo);
    end;

    [TryFunction]
    local procedure TryCategoryDepth(ItemNo: Code[20])
    var
        CategoryBreadcrumb: Codeunit "Category Breadcrumb";
    begin
        CategoryBreadcrumb.CategoryDepth(ItemNo);
    end;

    [TryFunction]
    local procedure TryRootCategory(ItemNo: Code[20])
    var
        CategoryBreadcrumb: Codeunit "Category Breadcrumb";
    begin
        CategoryBreadcrumb.RootCategory(ItemNo);
    end;
}
