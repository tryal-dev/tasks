codeunit 50900 "Endpoint Url Builder Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SearchUrlComposesPathParametersAndFlag()
    var
        Impl: Codeunit "Endpoint Url Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A plain two-word search term is composed into path, encoded parameters and the trailing flag
        Assert.AreEqual(
            'https://api.nordwind.example/v1/items?search=desk%20lamp&pageSize=25&includeArchived',
            Impl.ItemSearchUrl('desk lamp', 25),
            'Expected the search URL with the space encoded as %20, pageSize as plain digits, and includeArchived last as a flag without =');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SearchUrlEncodesAmpersandAndEquals()
    var
        Impl: Codeunit "Endpoint Url Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] & and = inside the search term travel as data (%26 and %3D), not as query syntax
        Assert.AreEqual(
            'https://api.nordwind.example/v1/items?search=salt%20%26%20pepper%20set%3Ddeluxe&pageSize=50&includeArchived',
            Impl.ItemSearchUrl('salt & pepper set=deluxe', 50),
            'Expected & to be encoded as %26 and = as %3D inside the search value — unencoded they would be read as query syntax');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SearchUrlEncodesNonAsciiAsUtf8()
    var
        Impl: Codeunit "Endpoint Url Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Non-ASCII letters are percent-encoded from their UTF-8 bytes with uppercase hex
        Assert.AreEqual(
            'https://api.nordwind.example/v1/items?search=cr%C3%A8me%20br%C3%BBl%C3%A9e&pageSize=10&includeArchived',
            Impl.ItemSearchUrl('crème brûlée', 10),
            'Expected each non-ASCII letter to be encoded from its UTF-8 bytes (è = %C3%A8, û = %C3%BB, é = %C3%A9)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SearchUrlHandlesGeneratedTermAndPageSize()
    var
        Impl: Codeunit "Endpoint Url Builder";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FirstWord: Text;
        SecondWord: Text;
        PageSize: Integer;
    begin
        // [SCENARIO] A generated two-word term and page size are reproduced exactly, so hardcoded example URLs fail
        FirstWord := Any.AlphabeticText(8);
        SecondWord := Any.AlphabeticText(8);
        PageSize := Any.IntegerInRange(1, 500);

        Assert.AreEqual(
            'https://api.nordwind.example/v1/items?search=' + FirstWord + '%20' + SecondWord + '&pageSize=' + Format(PageSize) + '&includeArchived',
            Impl.ItemSearchUrl(FirstWord + ' ' + SecondWord, PageSize),
            'Expected the generated search term and page size to appear in the URL exactly as passed in');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CardUrlEncodesSpaceInItemNo()
    var
        Impl: Codeunit "Endpoint Url Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A space inside the item number becomes %20 in the path segment
        Assert.AreEqual(
            'https://api.nordwind.example/v1/items/CHAIR%20100',
            Impl.ItemCardUrl('CHAIR 100'),
            'Expected the space in the item number to be encoded as %20 in the path segment');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CardUrlEncodesReservedCharactersInItemNo()
    var
        Impl: Codeunit "Endpoint Url Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] & = + in the item number are percent-encoded — a raw path splice leaves them unencoded
        Assert.AreEqual(
            'https://api.nordwind.example/v1/items/A%26B%3D100%2B',
            Impl.ItemCardUrl('A&B=100+'),
            'Expected & = + in the item number to be encoded as %26 %3D %2B — the path segment must be escaped as data');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CardUrlEncodesNonAsciiItemNo()
    var
        Impl: Codeunit "Endpoint Url Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A non-ASCII letter in the item number is UTF-8 percent-encoded in the path segment
        Assert.AreEqual(
            'https://api.nordwind.example/v1/items/S%C3%98LVSTOL-9',
            Impl.ItemCardUrl('SØLVSTOL-9'),
            'Expected Ø to be encoded as %C3%98 while - and digits stay as they are');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExportUrlAppendsFormatWhenMissing()
    var
        Impl: Codeunit "Endpoint Url Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] A base URL without a query gets format appended as its only parameter
        Assert.AreEqual(
            'https://api.nordwind.example/v1/items/export?format=csv',
            Impl.ExportUrl('https://api.nordwind.example/v1/items/export', 'csv'),
            'Expected format=csv to be appended to a base URL that has no query string yet');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExportUrlAppendsFormatAfterExistingParameters()
    var
        Impl: Codeunit "Endpoint Url Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] When format is missing it is appended at the end, after the parameters the base URL already has
        Assert.AreEqual(
            'https://api.nordwind.example/v1/items/export?compress=true&format=csv',
            Impl.ExportUrl('https://api.nordwind.example/v1/items/export?compress=true', 'csv'),
            'Expected format=csv to be appended at the end of the query, after the existing compress=true parameter');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExportUrlOverwritesExistingFormatInPlace()
    var
        Impl: Codeunit "Endpoint Url Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] An existing format value is replaced in place while the neighbor parameter survives untouched
        Assert.AreEqual(
            'https://api.nordwind.example/v1/items/export?compress=true&format=xlsx',
            Impl.ExportUrl('https://api.nordwind.example/v1/items/export?compress=true&format=pdf', 'xlsx'),
            'Expected the existing format=pdf to be replaced by format=xlsx in its original position, keeping compress=true untouched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExportUrlCollapsesDuplicateFormatParameters()
    var
        Impl: Codeunit "Endpoint Url Builder";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] Two pre-existing format parameters collapse into a single replaced one at the first position
        Assert.AreEqual(
            'https://api.nordwind.example/v1/items/export?format=csv&delimiter=semicolon',
            Impl.ExportUrl('https://api.nordwind.example/v1/items/export?format=pdf&format=xml&delimiter=semicolon', 'csv'),
            'Expected both existing format parameters to collapse into a single format=csv where format first appeared');
    end;
}
