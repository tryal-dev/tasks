codeunit 50100 "Category Breadcrumb"
{
    procedure CategoryPath(ItemNo: Code[20]): Text
    begin
        // TODO: walk from the item's category up through "Parent Category" and join the codes root-first with ' > '.
    end;

    procedure CategoryDepth(ItemNo: Code[20]): Integer
    begin
        // TODO: how many categories are on that path.
    end;

    procedure RootCategory(ItemNo: Code[20]): Code[20]
    begin
        // TODO: the first code of that path.
    end;
}
