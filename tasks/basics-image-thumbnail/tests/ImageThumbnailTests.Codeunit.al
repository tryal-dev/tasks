codeunit 50900 "Image Thumbnail Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        // Solid-color PNG fixtures, named after their pixel size.
        Png100x40Tok: Label 'iVBORw0KGgoAAAANSUhEUgAAAGQAAAAoCAYAAAAIeF9DAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAB6SURBVGhD7dEhAQAgAMAw4hCRiLQCTwEuJmZuP+bah47xBv4yJMaQGENiDIkxJMaQGENiDIkxJMaQGENiDIkxJMaQGENiDIkxJMaQGENiDIkxJMaQGENiDIkxJMaQGENiDIkxJMaQGENiDIkxJMaQGENiDIkxJMaQmAu8FouM9SpK/QAAAABJRU5ErkJggg==', Locked = true;
        Png40x100Tok: Label 'iVBORw0KGgoAAAANSUhEUgAAACgAAABkCAYAAAD0ZHJ6AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAACASURBVGhD7c4hAQAgAMAw4hCRiLQCj71BTMxcfcy1z8/GG35jsDJYGawMVgYrg5XBymBlsDJYGawMVgYrg5XBymBlsDJYGawMVgYrg5XBymBlsDJYGawMVgYrg5XBymBlsDJYGawMVgYrg5XBymBlsDJYGawMVgYrg5XBymBlsLoXm4uMuCo2agAAAABJRU5ErkJggg==', Locked = true;
        Png80x80Tok: Label 'iVBORw0KGgoAAAANSUhEUgAAAFAAAABQCAYAAACOEfKtAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAADBSURBVHhe7dChAcAgAMAwzuHEnchX4OegNiKmsmN+a/Nu/AN3DIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDIwMjAyMDt7DEoVokXyzAAAAAElFTkSuQmCC', Locked = true;
        Png20x10Tok: Label 'iVBORw0KGgoAAAANSUhEUgAAABQAAAAKCAYAAAC0VX7mAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAcSURBVDhPY9CoOPGfmpgBXYBSPGog5XjUQMoxADJH4IiS0r9aAAAAAElFTkSuQmCC', Locked = true;
        Png100x2Tok: Label 'iVBORw0KGgoAAAANSUhEUgAAAGQAAAACCAYAAACuT3kTAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAYSURBVDhPY9CoOPF/FA8ezIAuMIoHFgMAr+fgiNqsL9MAAAAASUVORK5CYII=', Locked = true;
        ProseTok: Label 'This is plain prose, not an image at all.', Locked = true;
        Base64ProseTok: Label 'VGhpcyBpcyBqdXN0IHBsYWluIHRleHQsIG5vdCBhIHBpY3R1cmUu', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetDimensionsReadsALandscapePng()
    begin
        // [SCENARIO] GetDimensions reports width and height, not swapped
        // [WHEN] reading the landscape fixture
        // [THEN] it reports 100 wide and 40 high
        VerifyDimensions(Png100x40Tok, 100, 40, 'the 100x40 landscape PNG');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetDimensionsReadsAPortraitPng()
    begin
        // [SCENARIO] GetDimensions reports width and height, not swapped
        // [WHEN] reading the portrait fixture
        // [THEN] it reports 40 wide and 100 high
        VerifyDimensions(Png40x100Tok, 40, 100, 'the 40x100 portrait PNG');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetDimensionsFailsOnTextThatIsNotBase64()
    var
        Generator: Codeunit "Thumbnail Generator";
        Width: Integer;
        Height: Integer;
    begin
        // [SCENARIO] GetDimensions rejects text that is not even Base64
        // [WHEN/THEN] reading plain prose must raise an error (any error text is fine)
        asserterror Generator.GetDimensions(ProseTok, Width, Height);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GetDimensionsFailsOnBase64ThatIsNotAPicture()
    var
        Generator: Codeunit "Thumbnail Generator";
        Width: Integer;
        Height: Integer;
    begin
        // [SCENARIO] GetDimensions rejects valid Base64 whose bytes are not an image
        // [WHEN/THEN] reading Base64-encoded prose must raise an error (any error text is fine)
        asserterror Generator.GetDimensions(Base64ProseTok, Width, Height);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShrinksALandscapePngToTheMaxDimension()
    begin
        // [SCENARIO] the longer side becomes the limit, the shorter side scales along
        // [WHEN] shrinking a 100x40 PNG to a max dimension of 50
        // [THEN] the thumbnail is 50x20
        VerifyThumbnail(Png100x40Tok, '100x40', 50, 50, 20);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShrinksAPortraitPngToTheMaxDimension()
    begin
        // [SCENARIO] for a portrait picture the height is the longer side
        // [WHEN] shrinking a 40x100 PNG to a max dimension of 50
        // [THEN] the thumbnail is 20x50
        VerifyThumbnail(Png40x100Tok, '40x100', 50, 20, 50);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShrinksASquarePngOnBothSides()
    begin
        // [SCENARIO] a square picture larger than the limit lands exactly on it
        // [WHEN] shrinking an 80x80 PNG to a max dimension of 32
        // [THEN] the thumbnail is 32x32
        VerifyThumbnail(Png80x80Tok, '80x80', 32, 32, 32);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoundsTheScaledSideToTheNearestPixel()
    begin
        // [SCENARIO] a fractional scaled side rounds to the nearest whole pixel
        // [WHEN] shrinking a 100x40 PNG to a max dimension of 64 (40 * 0.64 = 25.6)
        // [THEN] the thumbnail is 64x26
        VerifyThumbnail(Png100x40Tok, '100x40', 64, 64, 26);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoundsAnExactHalfPixelUp()
    begin
        // [SCENARIO] an exact half rounds up, not down
        // [WHEN] shrinking a 20x10 PNG to a max dimension of 15 (10 * 0.75 = 7.5)
        // [THEN] the thumbnail is 15x8
        VerifyThumbnail(Png20x10Tok, '20x10', 15, 15, 8);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoundsAFractionBelowHalfDown()
    begin
        // [SCENARIO] a fraction below one half rounds down — always rounding up is wrong
        // [WHEN] shrinking a 100x40 PNG to a max dimension of 41 (40 * 0.41 = 16.4)
        // [THEN] the thumbnail is 41x16, not 41x17
        VerifyThumbnail(Png100x40Tok, '100x40', 41, 41, 16);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ScalesProportionallyToAGeneratedLimit()
    var
        Any: Codeunit Any;
        MaxDimension: Integer;
        ExpectedHeight: Integer;
    begin
        // [SCENARIO] the proportional rule holds for a limit the test picks at random
        // [GIVEN] a random max dimension between 41 and 99 for the 100x40 fixture
        MaxDimension := Any.IntegerInRange(41, 99);
        ExpectedHeight := Round(40 * MaxDimension / 100, 1);
        // [WHEN] shrinking the 100x40 PNG to that limit
        // [THEN] the width is the limit and the height follows the formula from the statement
        VerifyThumbnail(Png100x40Tok, '100x40', MaxDimension, MaxDimension, ExpectedHeight);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsAPngAlreadyWithinTheLimitUnchanged()
    begin
        // [SCENARIO] a picture already inside the limit is never scaled up
        // [WHEN] thumbnailing a 20x10 PNG with a max dimension of 64
        // [THEN] the thumbnail stays 20x10
        VerifyThumbnail(Png20x10Tok, '20x10', 64, 20, 10);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure KeepsAPngExactlyAtTheLimitUnchanged()
    begin
        // [SCENARIO] the boundary case: the longer side equals the limit exactly
        // [WHEN] thumbnailing a 20x10 PNG with a max dimension of exactly 20
        // [THEN] the thumbnail stays 20x10
        VerifyThumbnail(Png20x10Tok, '20x10', 20, 20, 10);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NeverShrinksASideBelowOnePixel()
    begin
        // [SCENARIO] a side that would round to 0 is clamped to 1
        // [WHEN] shrinking a 100x2 PNG to a max dimension of 10 (2 * 0.1 = 0.2)
        // [THEN] the thumbnail is 10x1 — not an error and not 10x0
        VerifyThumbnail(Png100x2Tok, '100x2', 10, 10, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TheThumbnailIsStillAPng()
    var
        Generator: Codeunit "Thumbnail Generator";
        Result: Codeunit Image;
        ImageFormat: Enum "Image Format";
        Assert: Codeunit Assert;
    begin
        // [SCENARIO] shrinking must not change the image format
        // [WHEN] shrinking a 100x40 PNG to a max dimension of 50
        Result.FromBase64(Generator.CreateThumbnail(Png100x40Tok, 50));
        // [THEN] the returned Base64 decodes to a PNG
        Assert.IsTrue(Result.GetFormat() = ImageFormat::Png,
            StrSubstNo('Expected the thumbnail to still be a PNG, got %1', Result.GetFormatAsText()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreateThumbnailFailsOnTextThatIsNotBase64()
    var
        Generator: Codeunit "Thumbnail Generator";
    begin
        // [SCENARIO] CreateThumbnail rejects text that is not even Base64
        // [WHEN/THEN] thumbnailing plain prose must raise an error (any error text is fine)
        asserterror Generator.CreateThumbnail(ProseTok, 100);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreateThumbnailFailsOnBase64ThatIsNotAPicture()
    var
        Generator: Codeunit "Thumbnail Generator";
    begin
        // [SCENARIO] CreateThumbnail rejects valid Base64 whose bytes are not an image
        // [WHEN/THEN] thumbnailing Base64-encoded prose must raise an error (any error text is fine)
        asserterror Generator.CreateThumbnail(Base64ProseTok, 100);
    end;

    local procedure VerifyDimensions(SourceBase64: Text; ExpectedWidth: Integer; ExpectedHeight: Integer; SourceDescription: Text)
    var
        Generator: Codeunit "Thumbnail Generator";
        Assert: Codeunit Assert;
        Width: Integer;
        Height: Integer;
    begin
        Generator.GetDimensions(SourceBase64, Width, Height);
        Assert.AreEqual(ExpectedWidth, Width,
            StrSubstNo('Expected GetDimensions to return the pixel width of %1', SourceDescription));
        Assert.AreEqual(ExpectedHeight, Height,
            StrSubstNo('Expected GetDimensions to return the pixel height of %1', SourceDescription));
    end;

    local procedure VerifyThumbnail(SourceBase64: Text; SourceDescription: Text; MaxDimension: Integer; ExpectedWidth: Integer; ExpectedHeight: Integer)
    var
        Generator: Codeunit "Thumbnail Generator";
        Result: Codeunit Image;
        ImageFormat: Enum "Image Format";
        Assert: Codeunit Assert;
    begin
        Result.FromBase64(Generator.CreateThumbnail(SourceBase64, MaxDimension));
        Assert.AreEqual(ExpectedWidth, Result.GetWidth(),
            StrSubstNo('Expected the thumbnail width of a %1 PNG with a max dimension of %2', SourceDescription, MaxDimension));
        Assert.AreEqual(ExpectedHeight, Result.GetHeight(),
            StrSubstNo('Expected the thumbnail height of a %1 PNG with a max dimension of %2', SourceDescription, MaxDimension));
        Assert.IsTrue(Result.GetFormat() = ImageFormat::Png,
            StrSubstNo('Expected the thumbnail to still be a PNG, got %1', Result.GetFormatAsText()));
    end;
}
