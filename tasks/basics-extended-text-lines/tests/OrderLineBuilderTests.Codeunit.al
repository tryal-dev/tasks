codeunit 50900 "Order Line Builder Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Sales] [Extended Text]

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddItemLineStoresAnItemLineAndReturnsItsLineNo()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderLineBuilder: Codeunit "Order Line Builder";
        Quantity: Decimal;
    begin
        // [SCENARIO] AddItemLineWithText stores an item line on the order and returns its Line No.
        // [GIVEN] an order and an item
        CreateOrder(SalesHeader);
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandIntInRange(2, 9);

        // [WHEN] adding a line for that item
        GetLine(SalesLine, SalesHeader, OrderLineBuilder.AddItemLineWithText(SalesHeader, Item."No.", Quantity));

        // [THEN] the stored line is an Item line for that item and quantity
        Assert.IsTrue(SalesLine.Type = SalesLine.Type::Item,
            StrSubstNo('Expected the stored line to be of type Item, got %1', SalesLine.Type));
        Assert.AreEqual(Item."No.", SalesLine."No.", 'Expected the stored line to carry the item passed to AddItemLineWithText');
        Assert.AreEqual(Quantity, SalesLine.Quantity, 'Expected the stored line to carry the quantity passed to AddItemLineWithText');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ItemWithoutExtendedTextGetsABareLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderLineBuilder: Codeunit "Order Line Builder";
    begin
        // [SCENARIO] An item without extended text gets its item line and nothing else
        // [GIVEN] an order and an item that has no extended text
        CreateOrder(SalesHeader);
        LibraryInventory.CreateItem(Item);

        // [WHEN] adding a line for that item
        GetLine(SalesLine, SalesHeader, OrderLineBuilder.AddItemLineWithText(SalesHeader, Item."No.", LibraryRandom.RandIntInRange(2, 9)));

        // [THEN] the order holds exactly that one line
        Assert.AreEqual(1, OrderLineCount(SalesHeader),
            'Expected the order to hold only the item line when the item has no extended text — no blank lines under it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TextLinesFollowTheItemLineInOrder()
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        SalesHeader: Record "Sales Header";
        OrderLineBuilder: Codeunit "Order Line Builder";
        Texts: List of [Text];
        LineNo: Integer;
    begin
        // [SCENARIO] Every line of the item's extended text becomes a sales line behind the item line, in order
        // [GIVEN] an item whose extended text has three lines, and an order
        CreateItemWithText(Item, ExtendedTextHeader, '');
        AddTextLines(ExtendedTextHeader, 3, Texts);
        CreateOrder(SalesHeader);

        // [WHEN] adding a line for that item
        LineNo := OrderLineBuilder.AddItemLineWithText(SalesHeader, Item."No.", LibraryRandom.RandIntInRange(2, 9));

        // [THEN] three lines attached to the item line follow it, carrying the three texts in order
        VerifyAttachedTexts(SalesHeader, LineNo, Texts, 'every line of the item''s extended text follows the item line');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TextLinesAreBlankLinesWithoutQuantity()
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderLineBuilder: Codeunit "Order Line Builder";
        Texts: List of [Text];
        LineNo: Integer;
    begin
        // [SCENARIO] A text line is a line of blank type, without a No. and without a quantity
        // [GIVEN] an item whose extended text has two lines, and an order
        CreateItemWithText(Item, ExtendedTextHeader, '');
        AddTextLines(ExtendedTextHeader, 2, Texts);
        CreateOrder(SalesHeader);

        // [WHEN] adding a line for that item
        LineNo := OrderLineBuilder.AddItemLineWithText(SalesHeader, Item."No.", LibraryRandom.RandIntInRange(2, 9));

        // [THEN] each attached line has a blank type, no No. and a zero quantity
        FilterAttachedLines(SalesLine, SalesHeader, LineNo);
        Assert.AreEqual(2, SalesLine.Count(),
            StrSubstNo('Expected 2 text lines attached to item line %1 through "Attached to Line No."', LineNo));
        SalesLine.FindSet();
        repeat
            Assert.IsTrue(SalesLine.Type = SalesLine.Type::" ",
                StrSubstNo('Expected text line %1 under item line %2 to be of blank type, got %3', SalesLine."Line No.", LineNo, SalesLine.Type));
            Assert.AreEqual('', SalesLine."No.",
                StrSubstNo('Expected text line %1 under item line %2 to carry no "No." — the text is in Description, not on an item', SalesLine."Line No.", LineNo));
            Assert.AreEqual(0, SalesLine.Quantity,
                StrSubstNo('Expected text line %1 under item line %2 to have zero quantity', SalesLine."Line No.", LineNo));
        until SalesLine.Next() = 0;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TextFollowsEvenWhenTheItemCardDoesNotAskForItAutomatically()
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        SalesHeader: Record "Sales Header";
        OrderLineBuilder: Codeunit "Order Line Builder";
        Texts: List of [Text];
        LineNo: Integer;
    begin
        // [SCENARIO] The integration inserts the text whatever the item card's Automatic Ext. Texts toggle says
        // [GIVEN] an item with extended text whose "Automatic Ext. Texts" is off, and an order
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", false);
        Item.Modify(true);
        CreateTextHeader(ExtendedTextHeader, Item."No.", '');
        AddTextLines(ExtendedTextHeader, 1, Texts);
        CreateOrder(SalesHeader);

        // [WHEN] adding a line for that item
        LineNo := OrderLineBuilder.AddItemLineWithText(SalesHeader, Item."No.", LibraryRandom.RandIntInRange(2, 9));

        // [THEN] the text follows the line all the same
        VerifyAttachedTexts(SalesHeader, LineNo, Texts,
            'the text must follow the line although the item''s "Automatic Ext. Texts" is off — the second parameter of SalesCheckIfAnyExtText decides whether the item card is consulted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TextNotMeantForSalesOrdersIsSkipped()
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        SalesHeader: Record "Sales Header";
        OrderLineBuilder: Codeunit "Order Line Builder";
        Texts: List of [Text];
        LineNo: Integer;
    begin
        // [SCENARIO] A text whose Sales Order toggle is off is not inserted on an order
        // [GIVEN] an item whose extended text is not meant for sales orders, and an order
        CreateItemWithText(Item, ExtendedTextHeader, '');
        ExtendedTextHeader.Validate("Sales Order", false);
        ExtendedTextHeader.Modify(true);
        AddTextLines(ExtendedTextHeader, 1, Texts);
        CreateOrder(SalesHeader);

        // [WHEN] adding a line for that item
        LineNo := OrderLineBuilder.AddItemLineWithText(SalesHeader, Item."No.", LibraryRandom.RandIntInRange(2, 9));

        // [THEN] no text line follows the item line
        Assert.AreEqual(0, AttachedLineCount(SalesHeader, LineNo),
            'Expected no text lines from a text whose "Sales Order" toggle is off — that text is meant for other document types');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExpiredTextIsSkipped()
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        SalesHeader: Record "Sales Header";
        OrderLineBuilder: Codeunit "Order Line Builder";
        Texts: List of [Text];
        LineNo: Integer;
    begin
        // [SCENARIO] A text whose validity ended before the order's document date is not inserted
        // [GIVEN] an order, and an item whose extended text ended the day before the order's document date
        CreateOrder(SalesHeader);
        CreateItemWithText(Item, ExtendedTextHeader, '');
        ExtendedTextHeader.Validate("Ending Date", SalesHeader."Document Date" - 1);
        ExtendedTextHeader.Modify(true);
        AddTextLines(ExtendedTextHeader, 1, Texts);

        // [WHEN] adding a line for that item
        LineNo := OrderLineBuilder.AddItemLineWithText(SalesHeader, Item."No.", LibraryRandom.RandIntInRange(2, 9));

        // [THEN] no text line follows the item line
        Assert.AreEqual(0, AttachedLineCount(SalesHeader, LineNo),
            StrSubstNo('Expected no text lines from a text whose "Ending Date" (%1) lies before the order''s "Document Date" (%2) — expired text is not inserted',
                ExtendedTextHeader."Ending Date", SalesHeader."Document Date"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TextEndingOnTheDocumentDateStillApplies()
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        SalesHeader: Record "Sales Header";
        OrderLineBuilder: Codeunit "Order Line Builder";
        Texts: List of [Text];
        LineNo: Integer;
    begin
        // [SCENARIO] The ending date itself is still inside the validity window
        // [GIVEN] an order, and an item whose extended text ends exactly on the order's document date
        CreateOrder(SalesHeader);
        CreateItemWithText(Item, ExtendedTextHeader, '');
        ExtendedTextHeader.Validate("Ending Date", SalesHeader."Document Date");
        ExtendedTextHeader.Modify(true);
        AddTextLines(ExtendedTextHeader, 1, Texts);

        // [WHEN] adding a line for that item
        LineNo := OrderLineBuilder.AddItemLineWithText(SalesHeader, Item."No.", LibraryRandom.RandIntInRange(2, 9));

        // [THEN] the text follows the line
        VerifyAttachedTexts(SalesHeader, LineNo, Texts,
            StrSubstNo('a text whose "Ending Date" equals the order''s "Document Date" (%1) still applies — the boundary day counts', SalesHeader."Document Date"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TextStartingAfterTheDocumentDateIsSkipped()
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        SalesHeader: Record "Sales Header";
        OrderLineBuilder: Codeunit "Order Line Builder";
        Texts: List of [Text];
        LineNo: Integer;
    begin
        // [SCENARIO] A text whose validity starts after the order's document date is not inserted
        // [GIVEN] an order, and an item whose extended text starts the day after the order's document date
        CreateOrder(SalesHeader);
        CreateItemWithText(Item, ExtendedTextHeader, '');
        ExtendedTextHeader.Validate("Starting Date", SalesHeader."Document Date" + 1);
        ExtendedTextHeader.Modify(true);
        AddTextLines(ExtendedTextHeader, 1, Texts);

        // [WHEN] adding a line for that item
        LineNo := OrderLineBuilder.AddItemLineWithText(SalesHeader, Item."No.", LibraryRandom.RandIntInRange(2, 9));

        // [THEN] no text line follows the item line
        Assert.AreEqual(0, AttachedLineCount(SalesHeader, LineNo),
            StrSubstNo('Expected no text lines from a text whose "Starting Date" (%1) lies after the order''s "Document Date" (%2) — text that is not valid yet is not inserted',
                ExtendedTextHeader."Starting Date", SalesHeader."Document Date"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TextStartingOnTheDocumentDateStillApplies()
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        SalesHeader: Record "Sales Header";
        OrderLineBuilder: Codeunit "Order Line Builder";
        Texts: List of [Text];
        LineNo: Integer;
    begin
        // [SCENARIO] The starting date itself is already inside the validity window
        // [GIVEN] an order, and an item whose extended text starts exactly on the order's document date
        CreateOrder(SalesHeader);
        CreateItemWithText(Item, ExtendedTextHeader, '');
        ExtendedTextHeader.Validate("Starting Date", SalesHeader."Document Date");
        ExtendedTextHeader.Modify(true);
        AddTextLines(ExtendedTextHeader, 1, Texts);

        // [WHEN] adding a line for that item
        LineNo := OrderLineBuilder.AddItemLineWithText(SalesHeader, Item."No.", LibraryRandom.RandIntInRange(2, 9));

        // [THEN] the text follows the line
        VerifyAttachedTexts(SalesHeader, LineNo, Texts,
            StrSubstNo('a text whose "Starting Date" equals the order''s "Document Date" (%1) already applies — the boundary day counts', SalesHeader."Document Date"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerLanguagePicksTheTextInThatLanguage()
    var
        Item: Record Item;
        NeutralTextHeader: Record "Extended Text Header";
        LanguageTextHeader: Record "Extended Text Header";
        SalesHeader: Record "Sales Header";
        OrderLineBuilder: Codeunit "Order Line Builder";
        NeutralTexts: List of [Text];
        LanguageTexts: List of [Text];
        LanguageCode: Code[10];
        LineNo: Integer;
    begin
        // [SCENARIO] A customer with a language gets the text written in that language, not the language-neutral one
        // [GIVEN] an item with a language-neutral text and a text in language L, and an order for a customer whose language is L
        LanguageCode := CreateLanguage();
        CreateItemWithText(Item, NeutralTextHeader, '');
        AddTextLines(NeutralTextHeader, 1, NeutralTexts);
        CreateTextHeader(LanguageTextHeader, Item."No.", LanguageCode);
        AddTextLines(LanguageTextHeader, 1, LanguageTexts);
        CreateOrderForCustomerWithLanguage(SalesHeader, LanguageCode);

        // [WHEN] adding a line for that item
        LineNo := OrderLineBuilder.AddItemLineWithText(SalesHeader, Item."No.", LibraryRandom.RandIntInRange(2, 9));

        // [THEN] only the text in the customer's language follows the line
        VerifyAttachedTexts(SalesHeader, LineNo, LanguageTexts,
            StrSubstNo('only the text in the customer''s language %1 applies — the language-neutral text is not inserted next to it', LanguageCode));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomerWithoutLanguageGetsTheLanguageNeutralText()
    var
        Item: Record Item;
        NeutralTextHeader: Record "Extended Text Header";
        LanguageTextHeader: Record "Extended Text Header";
        SalesHeader: Record "Sales Header";
        OrderLineBuilder: Codeunit "Order Line Builder";
        NeutralTexts: List of [Text];
        LanguageTexts: List of [Text];
        LanguageCode: Code[10];
        LineNo: Integer;
    begin
        // [SCENARIO] A customer without a language gets the language-neutral text only
        // [GIVEN] an item with a language-neutral text and a text in language L, and an order for a customer without a language
        LanguageCode := CreateLanguage();
        CreateItemWithText(Item, NeutralTextHeader, '');
        AddTextLines(NeutralTextHeader, 1, NeutralTexts);
        CreateTextHeader(LanguageTextHeader, Item."No.", LanguageCode);
        AddTextLines(LanguageTextHeader, 1, LanguageTexts);
        CreateOrder(SalesHeader);

        // [WHEN] adding a line for that item
        LineNo := OrderLineBuilder.AddItemLineWithText(SalesHeader, Item."No.", LibraryRandom.RandIntInRange(2, 9));

        // [THEN] only the language-neutral text follows the line
        VerifyAttachedTexts(SalesHeader, LineNo, NeutralTexts,
            StrSubstNo('a customer without a language code gets the language-neutral text only — the text in language %1 is not for them', LanguageCode));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AllLanguagesTextServesACustomerWhoseLanguageHasNoTextOfItsOwn()
    var
        Item: Record Item;
        NeutralTextHeader: Record "Extended Text Header";
        LanguageTextHeader: Record "Extended Text Header";
        SalesHeader: Record "Sales Header";
        OrderLineBuilder: Codeunit "Order Line Builder";
        NeutralTexts: List of [Text];
        LanguageTexts: List of [Text];
        LineNo: Integer;
    begin
        // [SCENARIO] A language-neutral text marked for all languages serves a customer whose language has no text
        // [GIVEN] an item with a language-neutral text (All Language Codes on) and a text in language L, and an order for a customer whose language is M
        CreateItemWithText(Item, NeutralTextHeader, '');
        AddTextLines(NeutralTextHeader, 1, NeutralTexts);
        CreateTextHeader(LanguageTextHeader, Item."No.", CreateLanguage());
        AddTextLines(LanguageTextHeader, 1, LanguageTexts);
        CreateOrderForCustomerWithLanguage(SalesHeader, CreateLanguage());

        // [WHEN] adding a line for that item
        LineNo := OrderLineBuilder.AddItemLineWithText(SalesHeader, Item."No.", LibraryRandom.RandIntInRange(2, 9));

        // [THEN] the language-neutral text follows the line
        VerifyAttachedTexts(SalesHeader, LineNo, NeutralTexts,
            'a customer whose language has no text of its own gets the language-neutral text marked "All Language Codes" — and not the text of another language');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LanguageNeutralTextNotMarkedForAllLanguagesIsSkippedForALanguageCustomer()
    var
        Item: Record Item;
        NeutralTextHeader: Record "Extended Text Header";
        SalesHeader: Record "Sales Header";
        OrderLineBuilder: Codeunit "Order Line Builder";
        NeutralTexts: List of [Text];
        LineNo: Integer;
    begin
        // [SCENARIO] A language-neutral text with All Language Codes off is only for customers without a language
        // [GIVEN] an item whose only text has no language and "All Language Codes" off, and an order for a customer with a language
        CreateItemWithText(Item, NeutralTextHeader, '');
        NeutralTextHeader.Validate("All Language Codes", false);
        NeutralTextHeader.Modify(true);
        AddTextLines(NeutralTextHeader, 1, NeutralTexts);
        CreateOrderForCustomerWithLanguage(SalesHeader, CreateLanguage());

        // [WHEN] adding a line for that item
        LineNo := OrderLineBuilder.AddItemLineWithText(SalesHeader, Item."No.", LibraryRandom.RandIntInRange(2, 9));

        // [THEN] no text line follows the item line
        Assert.AreEqual(0, AttachedLineCount(SalesHeader, LineNo),
            'Expected no text lines for a customer with a language when the item''s only text has no language and "All Language Codes" is off');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NextItemLineIsNumberedAfterThePreviousLinesText()
    var
        FirstItem: Record Item;
        SecondItem: Record Item;
        FirstTextHeader: Record "Extended Text Header";
        SecondTextHeader: Record "Extended Text Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderLineBuilder: Codeunit "Order Line Builder";
        FirstTexts: List of [Text];
        SecondTexts: List of [Text];
        FirstLineNo: Integer;
        SecondLineNo: Integer;
    begin
        // [SCENARIO] A second item line lands after the first line's text, and its own text lands after it
        // [GIVEN] two items with two text lines each, and an order that already holds a line for the first item
        CreateItemWithText(FirstItem, FirstTextHeader, '');
        AddTextLines(FirstTextHeader, 2, FirstTexts);
        CreateItemWithText(SecondItem, SecondTextHeader, '');
        AddTextLines(SecondTextHeader, 2, SecondTexts);
        CreateOrder(SalesHeader);
        FirstLineNo := OrderLineBuilder.AddItemLineWithText(SalesHeader, FirstItem."No.", LibraryRandom.RandIntInRange(2, 9));
        GetLine(SalesLine, SalesHeader, FirstLineNo);

        // [WHEN] adding a line for the second item
        SecondLineNo := OrderLineBuilder.AddItemLineWithText(SalesHeader, SecondItem."No.", LibraryRandom.RandIntInRange(2, 9));

        // [THEN] every line attached to the first item line comes before the second item line, whose own text follows it
        GetLine(SalesLine, SalesHeader, SecondLineNo);
        FilterAttachedLines(SalesLine, SalesHeader, FirstLineNo);
        SalesLine.SetFilter("Line No.", '>=%1', SecondLineNo);
        Assert.IsTrue(SalesLine.IsEmpty(),
            StrSubstNo('Expected the text of item line %1 to be numbered before the next item line %2 — the item line must be numbered above every line already in the order', FirstLineNo, SecondLineNo));
        VerifyAttachedTexts(SalesHeader, SecondLineNo, SecondTexts, 'the second item line gets its own text right behind it');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemovingTheItemLineTakesItsTextLinesWithIt()
    var
        FirstItem: Record Item;
        SecondItem: Record Item;
        FirstTextHeader: Record "Extended Text Header";
        SecondTextHeader: Record "Extended Text Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderLineBuilder: Codeunit "Order Line Builder";
        FirstTexts: List of [Text];
        SecondTexts: List of [Text];
        FirstLineNo: Integer;
        SecondLineNo: Integer;
    begin
        // [SCENARIO] Removing an item line removes the text lines attached to it and nothing else
        // [GIVEN] an order with two item lines, each followed by its text
        CreateItemWithText(FirstItem, FirstTextHeader, '');
        AddTextLines(FirstTextHeader, 2, FirstTexts);
        CreateItemWithText(SecondItem, SecondTextHeader, '');
        AddTextLines(SecondTextHeader, 1, SecondTexts);
        CreateOrder(SalesHeader);
        FirstLineNo := OrderLineBuilder.AddItemLineWithText(SalesHeader, FirstItem."No.", LibraryRandom.RandIntInRange(2, 9));
        SecondLineNo := OrderLineBuilder.AddItemLineWithText(SalesHeader, SecondItem."No.", LibraryRandom.RandIntInRange(2, 9));
        GetLine(SalesLine, SalesHeader, FirstLineNo);
        VerifyAttachedTexts(SalesHeader, FirstLineNo, FirstTexts, 'the first item line has its text before anything is removed');

        // [WHEN] removing the first item line
        OrderLineBuilder.RemoveItemLine(SalesHeader, FirstLineNo);

        // [THEN] the first item line and its text lines are gone, the second item line and its text remain
        Assert.IsFalse(SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", FirstLineNo),
            StrSubstNo('Expected RemoveItemLine to delete item line %1', FirstLineNo));
        Assert.AreEqual(0, AttachedLineCount(SalesHeader, FirstLineNo),
            StrSubstNo('Expected the text lines attached to item line %1 to be deleted along with it — a delete that skips the line''s OnDelete trigger leaves them orphaned', FirstLineNo));
        Assert.IsTrue(SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SecondLineNo),
            StrSubstNo('Expected item line %1 to survive the removal of item line %2', SecondLineNo, FirstLineNo));
        VerifyAttachedTexts(SalesHeader, SecondLineNo, SecondTexts, 'the other item line keeps its own text');
        Assert.AreEqual(1 + SecondTexts.Count(), OrderLineCount(SalesHeader),
            'Expected the order to hold exactly the second item line and its text after the removal');
    end;

    local procedure CreateOrder(var SalesHeader: Record "Sales Header")
    begin
        CreateOrderForCustomerWithLanguage(SalesHeader, '');
    end;

    // The order header takes its language from the customer, which is where the
    // extended-text lookup reads it.
    local procedure CreateOrderForCustomerWithLanguage(var SalesHeader: Record "Sales Header"; LanguageCode: Code[10])
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Language Code", LanguageCode);
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
    end;

    local procedure CreateLanguage(): Code[10]
    var
        Language: Record Language;
    begin
        Language.Init();
        Language.Code := LibraryUtility.GenerateGUID();
        Language.Name := Language.Code;
        Language."Windows Language ID" := 1033;
        Language.Insert();
        exit(Language.Code);
    end;

    // The item asks for its text itself, so a solution that consults the item card
    // instead of inserting unconditionally fails only the test that switches the toggle off.
    local procedure CreateItemWithText(var Item: Record Item; var ExtendedTextHeader: Record "Extended Text Header"; LanguageCode: Code[10])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);
        CreateTextHeader(ExtendedTextHeader, Item."No.", LanguageCode);
    end;

    // Seeded by hand: the header's language, dates and document toggles are what the
    // tests vary, and inserting it with its trigger numbers "Text No." the standard way.
    local procedure CreateTextHeader(var ExtendedTextHeader: Record "Extended Text Header"; ItemNo: Code[20]; LanguageCode: Code[10])
    begin
        ExtendedTextHeader.Init();
        ExtendedTextHeader.Validate("Table Name", ExtendedTextHeader."Table Name"::Item);
        ExtendedTextHeader.Validate("No.", ItemNo);
        ExtendedTextHeader.Validate("Language Code", LanguageCode);
        ExtendedTextHeader.Insert(true);
    end;

    local procedure AddTextLines(ExtendedTextHeader: Record "Extended Text Header"; NumberOfLines: Integer; var Texts: List of [Text])
    var
        i: Integer;
    begin
        for i := 1 to NumberOfLines do
            Texts.Add(AddTextLine(ExtendedTextHeader));
    end;

    local procedure AddTextLine(ExtendedTextHeader: Record "Extended Text Header"): Text
    var
        ExtendedTextLine: Record "Extended Text Line";
    begin
        ExtendedTextLine.Init();
        ExtendedTextLine."Table Name" := ExtendedTextHeader."Table Name";
        ExtendedTextLine."No." := ExtendedTextHeader."No.";
        ExtendedTextLine."Language Code" := ExtendedTextHeader."Language Code";
        ExtendedTextLine."Text No." := ExtendedTextHeader."Text No.";
        ExtendedTextLine."Line No." := NextTextLineNo(ExtendedTextHeader);
        ExtendedTextLine.Text := CopyStr(LibraryRandom.RandText(30), 1, MaxStrLen(ExtendedTextLine.Text));
        ExtendedTextLine.Insert(true);
        exit(ExtendedTextLine.Text);
    end;

    local procedure NextTextLineNo(ExtendedTextHeader: Record "Extended Text Header"): Integer
    var
        ExtendedTextLine: Record "Extended Text Line";
    begin
        ExtendedTextLine.SetRange("Table Name", ExtendedTextHeader."Table Name");
        ExtendedTextLine.SetRange("No.", ExtendedTextHeader."No.");
        ExtendedTextLine.SetRange("Language Code", ExtendedTextHeader."Language Code");
        ExtendedTextLine.SetRange("Text No.", ExtendedTextHeader."Text No.");
        if ExtendedTextLine.FindLast() then
            exit(ExtendedTextLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure GetLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineNo: Integer)
    begin
        Assert.IsTrue(SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", LineNo),
            StrSubstNo('Expected AddItemLineWithText to return the Line No. of a stored sales line, but order %1 has no line no. %2', SalesHeader."No.", LineNo));
    end;

    local procedure FilterAttachedLines(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemLineNo: Integer)
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Attached to Line No.", ItemLineNo);
    end;

    local procedure AttachedLineCount(SalesHeader: Record "Sales Header"; ItemLineNo: Integer): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        FilterAttachedLines(SalesLine, SalesHeader, ItemLineNo);
        exit(SalesLine.Count());
    end;

    local procedure OrderLineCount(SalesHeader: Record "Sales Header"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        exit(SalesLine.Count());
    end;

    local procedure VerifyAttachedTexts(SalesHeader: Record "Sales Header"; ItemLineNo: Integer; ExpectedTexts: List of [Text]; Because: Text)
    var
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        FilterAttachedLines(SalesLine, SalesHeader, ItemLineNo);
        Assert.AreEqual(ExpectedTexts.Count(), SalesLine.Count(),
            StrSubstNo('Expected %1 text line(s) attached to item line %2 through "Attached to Line No.": %3', ExpectedTexts.Count(), ItemLineNo, Because));
        if SalesLine.FindSet() then
            repeat
                i += 1;
                Assert.IsTrue(SalesLine."Line No." > ItemLineNo,
                    StrSubstNo('Expected text line %1 under item line %2 to be numbered after it, got line no. %3', i, ItemLineNo, SalesLine."Line No."));
                Assert.AreEqual(ExpectedTexts.Get(i), SalesLine.Description,
                    StrSubstNo('Expected text line %1 under item line %2 to carry line %1 of the extended text in Description: %3', i, ItemLineNo, Because));
            until SalesLine.Next() = 0;
    end;
}
