codeunit 50900 "Path Helper Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FileNameOfReturnsTheLastSegmentOfAForwardSlashPath()
    var
        PathHelper: Codeunit "Path Helper";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FileName: Text;
    begin
        FileName := 'invoice-' + Any.AlphabeticText(8) + '.pdf';

        Assert.AreEqual(FileName, PathHelper.FileNameOf('/exports/2026/' + FileName),
            'Expected FileNameOf to return everything after the last / of the path');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FileNameOfReturnsTheLastSegmentOfABackslashPath()
    var
        PathHelper: Codeunit "Path Helper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('report.xlsx', PathHelper.FileNameOf('C:\Users\Anna\Documents\report.xlsx'),
            'Expected FileNameOf to treat \ as a separator and return everything after the last one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FileNameOfHandlesAPathMixingBothSeparators()
    var
        PathHelper: Codeunit "Path Helper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('summary.csv', PathHelper.FileNameOf('C:\shared/exports\q1/summary.csv'),
            'Expected FileNameOf to split on both / and \ when one path mixes them — the file name starts after whichever separator comes last');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FileNameOfIsEmptyWhenThePathEndsWithAForwardSlash()
    var
        PathHelper: Codeunit "Path Helper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', PathHelper.FileNameOf('/exports/2026/'),
            'Expected an empty file name for a path that ends with / — nothing follows the last separator');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FileNameOfIsEmptyWhenThePathEndsWithABackslash()
    var
        PathHelper: Codeunit "Path Helper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', PathHelper.FileNameOf('C:\Exports\2026\'),
            'Expected an empty file name for a path that ends with \ — nothing follows the last separator');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FileNameOfReturnsABareFileNameUnchanged()
    var
        PathHelper: Codeunit "Path Helper";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        FileName: Text;
    begin
        FileName := Any.AlphabeticText(10) + '.docx';

        Assert.AreEqual(FileName, PathHelper.FileNameOf(FileName),
            'Expected a path without any separator to come back unchanged — it is already a bare file name');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExtensionOfReturnsTheTextAfterTheLastDot()
    var
        PathHelper: Codeunit "Path Helper";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Extension: Text;
    begin
        Extension := Any.AlphabeticText(3);

        Assert.AreEqual(Extension, PathHelper.ExtensionOf('/exports/2026/invoice-1001.' + Extension),
            'Expected ExtensionOf to return the text after the last dot of the file name, without the dot');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExtensionOfUsesOnlyTheLastDotOfTheFileName()
    var
        PathHelper: Codeunit "Path Helper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('gz', PathHelper.ExtensionOf('/backups/backup.2026-03-01.tar.gz'),
            'Expected only the text after the LAST dot — a file name with several dots has exactly one extension');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExtensionOfIsEmptyWhenTheFileNameHasNoDot()
    var
        PathHelper: Codeunit "Path Helper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', PathHelper.ExtensionOf('/exports/README'),
            'Expected an empty extension for a file name without a dot — LastIndexOf returns 0 when there is no dot, and 0 is not a position');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExtensionOfIgnoresADotInAFolderName()
    var
        PathHelper: Codeunit "Path Helper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', PathHelper.ExtensionOf('C:\archive.2025\notes'),
            'Expected an empty extension when the only dot sits in a folder name — the extension belongs to the file name, not to the whole path');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExtensionOfIsEmptyWhenThePathEndsWithASeparator()
    var
        PathHelper: Codeunit "Path Helper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('', PathHelper.ExtensionOf('/exports/2026.q1/'),
            'Expected an empty extension for a path that ends with a separator — there is no file name, so there is nothing to have an extension');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExtensionOfKeepsTheExtensionCaseAsWritten()
    var
        PathHelper: Codeunit "Path Helper";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('JPG', PathHelper.ExtensionOf('Photo.JPG'),
            'Expected the extension exactly as written in the path — uppercase stays uppercase, and a bare file name works like any other path');
    end;
}
