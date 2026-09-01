codeunit 50900 "Duplicate Customer Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalizeUppercasesAndStripsSpacesAndPunctuation()
    var
        DuplicateCustomerFinder: Codeunit "Duplicate Customer Finder";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('CONTOSOLTD', DuplicateCustomerFinder.Normalize('Contoso, Ltd.'),
            'Expected Normalize to uppercase the letters and drop spaces and punctuation');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalizeKeepsDigitsAndDropsSeparators()
    var
        DuplicateCustomerFinder: Codeunit "Duplicate Customer Finder";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('GB123456789', DuplicateCustomerFinder.Normalize('gb 123-456 78.9'),
            'Expected Normalize to keep digits, uppercase the letters, and drop spaces, dashes and dots');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalizeRemovesTabsAndSymbols()
    var
        DuplicateCustomerFinder: Codeunit "Duplicate Customer Finder";
        Assert: Codeunit Assert;
        TabChar: Char;
        TabText: Text;
    begin
        TabChar := 9;
        TabText := TabChar;
        Assert.AreEqual('ACMECO', DuplicateCustomerFinder.Normalize('Acme' + TabText + '&Co'),
            'Expected Normalize to remove a tab character and the & symbol, keeping only letters and digits');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalizePunctuationOnlyGivesEmptyText()
    var
        DuplicateCustomerFinder: Codeunit "Duplicate Customer Finder";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', DuplicateCustomerFinder.Normalize(' .,-/&() '),
            'Expected a value with no letters or digits to normalize to an empty text');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NormalizeRandomizedLettersSurviveUppercased()
    var
        DuplicateCustomerFinder: Codeunit "Duplicate Customer Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Letters: Text;
        Mangled: Text;
    begin
        // [SCENARIO] random letters split by randomized non-alphanumeric separators — deleting a hardcoded list of characters instead of keeping letters and digits fails here
        Letters := Any.AlphabeticText(8);
        Mangled := RandomSeparator(Any) + CopyStr(Letters, 1, 3) + RandomSeparator(Any) +
            CopyStr(Letters, 4, 3) + RandomSeparator(Any) + CopyStr(Letters, 7) + RandomSeparator(Any);
        Assert.AreEqual(Letters.ToUpper(), DuplicateCustomerFinder.Normalize(Mangled),
            'Expected the randomized letters to survive normalization uppercased, with every non-letter, non-digit character removed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FindsNameDuplicateAcrossCaseSpacingAndPunctuation()
    var
        DuplicateCustomerFinder: Codeunit "Duplicate Customer Finder";
        Assert: Codeunit Assert;
        Duplicates: List of [Code[20]];
    begin
        // [SCENARIO] same company entered twice with different casing, spacing and punctuation; a third customer is unrelated
        CreateCustomer('TRYAL-N1A', 'Tryal Widget Works, Inc.', '');
        CreateCustomer('TRYAL-N1B', 'TRYAL WIDGETWORKS INC', '');
        CreateCustomer('TRYAL-N1C', 'Tryal Unrelated N1', '');

        Duplicates := DuplicateCustomerFinder.FindDuplicatesOf('TRYAL-N1A');

        Assert.AreEqual('TRYAL-N1B', JoinList(Duplicates),
            'Expected exactly the customer whose normalized name matches — blank VAT numbers must not match each other, and the customer you asked about must not be in the list');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FindsVatDuplicateWhenNamesDiffer()
    var
        DuplicateCustomerFinder: Codeunit "Duplicate Customer Finder";
        Assert: Codeunit Assert;
        Duplicates: List of [Code[20]];
    begin
        CreateCustomer('TRYAL-V1A', 'Tryal Vat Alpha', 'GB 777 8888 99');
        CreateCustomer('TRYAL-V1B', 'Tryal Vat Beta', 'gb-7778 88899');

        Duplicates := DuplicateCustomerFinder.FindDuplicatesOf('TRYAL-V1A');

        Assert.AreEqual('TRYAL-V1B', JoinList(Duplicates),
            'Expected the customer whose normalized VAT registration number matches, even though the names differ');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankAndPunctuationOnlyValuesNeverMatch()
    var
        DuplicateCustomerFinder: Codeunit "Duplicate Customer Finder";
        Assert: Codeunit Assert;
        Duplicates: List of [Code[20]];
    begin
        // [SCENARIO] both customers' names and VAT numbers normalize to '' — empty keys must never produce a match
        CreateCustomer('TRYAL-B1A', '- - -', '. .');
        CreateCustomer('TRYAL-B1B', '***', '--');

        Duplicates := DuplicateCustomerFinder.FindDuplicatesOf('TRYAL-B1A');

        Assert.AreEqual('', JoinList(Duplicates),
            'Expected no duplicates: values that normalize to an empty text must never make a match, on either field');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EachDuplicateListedOnceSortedAscendingByNo()
    var
        DuplicateCustomerFinder: Codeunit "Duplicate Customer Finder";
        Assert: Codeunit Assert;
        Duplicates: List of [Code[20]];
    begin
        // [SCENARIO] lowest No. matches by VAT only, middle by name only, highest on both fields — collecting all name matches before VAT matches (or the reverse) yields the wrong order; customers are inserted out of key order
        CreateCustomer('TRYAL-M1C', 'tryal mega corp m1!', 'GB M1 777');
        CreateCustomer('TRYAL-M1E', 'Tryal Unrelated M1E', 'GB M1 999');
        CreateCustomer('TRYAL-M1B', 'Tryal Mega Corp M1', 'GB M1 555');
        CreateCustomer('TRYAL-M1D', 'TRYAL MEGA-CORP M1', 'g.b.m.1.5.5.5');
        CreateCustomer('TRYAL-M1A', 'Tryal Vat Twin M1A', 'gbm1555');

        Duplicates := DuplicateCustomerFinder.FindDuplicatesOf('TRYAL-M1B');

        Assert.AreEqual('TRYAL-M1A, TRYAL-M1C, TRYAL-M1D', JoinList(Duplicates),
            'Expected every duplicate exactly once — including the one matching on both name and VAT — sorted ascending by No.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoDuplicatesReturnsEmptyList()
    var
        DuplicateCustomerFinder: Codeunit "Duplicate Customer Finder";
        Assert: Codeunit Assert;
        Duplicates: List of [Code[20]];
    begin
        CreateCustomer('TRYAL-U1A', 'Tryal Solo Unique U1', 'GB U1 42');

        Duplicates := DuplicateCustomerFinder.FindDuplicatesOf('TRYAL-U1A');

        Assert.AreEqual('', JoinList(Duplicates),
            'Expected an empty list for a customer with no duplicate name and no duplicate VAT registration number');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RandomizedNameDuplicateIsFound()
    var
        DuplicateCustomerFinder: Codeunit "Duplicate Customer Finder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Duplicates: List of [Code[20]];
        Base: Text;
    begin
        // [SCENARIO] a randomized company name reappears uppercased with different, randomized separators — hardcoding the fixed examples fails here
        Base := Any.AlphabeticText(10);
        CreateCustomer('TRYAL-R1A', 'Tryal ' + Base + ' Ltd', '');
        CreateCustomer('TRYAL-R1B', RandomSeparator(Any) + 'TRYAL' + RandomSeparator(Any) + Base.ToUpper() + RandomSeparator(Any) + 'LTD', '');

        Duplicates := DuplicateCustomerFinder.FindDuplicatesOf('TRYAL-R1A');

        Assert.AreEqual('TRYAL-R1B', JoinList(Duplicates),
            'Expected the randomized name duplicate to be found across casing, spacing and punctuation differences');
    end;

    local procedure RandomSeparator(Any: Codeunit Any): Text
    var
        SeparatorChar: Char;
        CharText: Text;
        Separator: Text;
        CharIndex: Integer;
        i: Integer;
    begin
        // Three characters drawn from ASCII '!'..'/' (33..47) and ':'..'@' (58..64) —
        // all non-alphanumeric, so only an implementation that KEEPS letters and digits
        // (rather than deleting a fixed list of separators) survives every draw.
        for i := 1 to 3 do begin
            CharIndex := Any.IntegerInRange(1, 22);
            if CharIndex <= 15 then
                SeparatorChar := 32 + CharIndex
            else
                SeparatorChar := 42 + CharIndex;
            CharText := SeparatorChar;
            Separator += CharText;
        end;
        exit(Separator);
    end;

    local procedure CreateCustomer(No: Code[20]; Name: Text; VatRegNo: Text[20])
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer."No." := No;
        Customer.Name := CopyStr(Name, 1, MaxStrLen(Customer.Name));
        Customer."VAT Registration No." := VatRegNo;
        Customer.Insert();
    end;

    local procedure JoinList(Values: List of [Code[20]]): Text
    var
        Value: Code[20];
        Result: Text;
    begin
        foreach Value in Values do begin
            if Result <> '' then
                Result += ', ';
            Result += Value;
        end;
        exit(Result);
    end;
}
