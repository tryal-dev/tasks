codeunit 50900 "Address Block Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [FEATURE] [Address Block]

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostCodeCityLayoutFillsEveryLine()
    var
        CountryRegion: Record "Country/Region";
        DocumentAddressBlock: Codeunit "Document Address Block";
        AddressBlock: array[8] of Text[100];
        ExpectedBlock: array[8] of Text[100];
    begin
        // [SCENARIO] A country that prints post code before city, with the contact after the company name, uses all eight lines
        // [GIVEN] a country with Address Format "Post Code+City" and Contact Address Format "After Company Name"
        CreateCountry(CountryRegion, 'TRYALADR1', 'Trailside Republic', "Country/Region Address Format"::"Post Code+City");
        ResetAddressLanguage();

        // [WHEN] building the address block for a fully filled address
        DocumentAddressBlock.BuildAddressBlock(
            AddressBlock, 'Northwind Traders', 'Regional Office', 'Alicia Vega', '12 Harbour Road', 'Building C',
            'Springfield', '12345', 'Blue County', 'TRYALADR1', '');

        // [THEN] every line carries the value the country's format assigns to it
        ExpectedBlock[1] := 'Northwind Traders';
        ExpectedBlock[2] := 'Regional Office';
        ExpectedBlock[3] := 'Alicia Vega';
        ExpectedBlock[4] := '12 Harbour Road';
        ExpectedBlock[5] := 'Building C';
        ExpectedBlock[6] := '12345 Springfield';
        ExpectedBlock[7] := 'Blue County';
        ExpectedBlock[8] := 'Trailside Republic';
        VerifyBlock(ExpectedBlock, AddressBlock, 'Post Code+City / contact after the company name');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MissingNameAndAddressLinesLeaveNoHole()
    var
        CountryRegion: Record "Country/Region";
        DocumentAddressBlock: Codeunit "Document Address Block";
        Any: Codeunit Any;
        AddressBlock: array[8] of Text[100];
        ExpectedBlock: array[8] of Text[100];
        CompanyName: Text[100];
        StreetLine: Text[100];
        CityName: Text[50];
    begin
        // [SCENARIO] An address without Name 2 and Address 2 prints without blank lines in the middle
        // [GIVEN] a country with Address Format "Post Code+City" and an address that leaves Name 2, Address 2 and County empty
        CreateCountry(CountryRegion, 'TRYALADR2', 'Trailside Republic', "Country/Region Address Format"::"Post Code+City");
        ResetAddressLanguage();
        CompanyName := CopyStr('TRYAL ' + Any.AlphabeticText(10), 1, MaxStrLen(CompanyName));
        StreetLine := CopyStr(Any.AlphabeticText(8) + ' Road', 1, MaxStrLen(StreetLine));
        CityName := CopyStr(Any.AlphabeticText(9), 1, MaxStrLen(CityName));

        // [WHEN] building the address block
        DocumentAddressBlock.BuildAddressBlock(
            AddressBlock, CompanyName, '', 'Dana Fisher', StreetLine, '', CityName, '55221', '', 'TRYALADR2', '');

        // [THEN] the used lines are packed to the top and the unused ones are empty
        ExpectedBlock[1] := CompanyName;
        ExpectedBlock[2] := 'Dana Fisher';
        ExpectedBlock[3] := StreetLine;
        ExpectedBlock[4] := CopyStr('55221 ' + CityName, 1, MaxStrLen(ExpectedBlock[4]));
        ExpectedBlock[5] := 'Trailside Republic';
        VerifyBlock(ExpectedBlock, AddressBlock, 'Post Code+City with an empty Name 2 and Address 2');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CityPostCodeLayoutPrintsContactFirst()
    var
        CountryRegion: Record "Country/Region";
        DocumentAddressBlock: Codeunit "Document Address Block";
        AddressBlock: array[8] of Text[100];
        ExpectedBlock: array[8] of Text[100];
    begin
        // [SCENARIO] A country that prints city before post code and puts the contact on the first line
        // [GIVEN] a country with Address Format "City+Post Code" and Contact Address Format "First"
        CreateCountry(CountryRegion, 'TRYALADR3', 'Brentford Isles', "Country/Region Address Format"::"City+Post Code");
        CountryRegion."Contact Address Format" := CountryRegion."Contact Address Format"::First;
        CountryRegion.Modify();
        ResetAddressLanguage();

        // [WHEN] building the address block for a fully filled address
        DocumentAddressBlock.BuildAddressBlock(
            AddressBlock, 'Northwind Traders', 'Regional Office', 'Alicia Vega', '12 Harbour Road', 'Building C',
            'Coventry', 'CV1 2AB', 'Warwickshire', 'TRYALADR3', '');

        // [THEN] the contact opens the block and the city line reads city, post code
        ExpectedBlock[1] := 'Alicia Vega';
        ExpectedBlock[2] := 'Northwind Traders';
        ExpectedBlock[3] := 'Regional Office';
        ExpectedBlock[4] := '12 Harbour Road';
        ExpectedBlock[5] := 'Building C';
        ExpectedBlock[6] := 'Coventry, CV1 2AB';
        ExpectedBlock[7] := 'Warwickshire';
        ExpectedBlock[8] := 'Brentford Isles';
        VerifyBlock(ExpectedBlock, AddressBlock, 'City+Post Code / contact first');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CityCountyPostCodeLayoutFoldsCountyIntoTheCityLine()
    var
        CountryRegion: Record "Country/Region";
        DocumentAddressBlock: Codeunit "Document Address Block";
        AddressBlock: array[8] of Text[100];
        ExpectedBlock: array[8] of Text[100];
    begin
        // [SCENARIO] A country that prints city, county and post code on one line and the contact last
        // [GIVEN] a country with Address Format "City+County+Post Code" and Contact Address Format "Last"
        CreateCountry(CountryRegion, 'TRYALADR4', 'Cascadia Union', "Country/Region Address Format"::"City+County+Post Code");
        CountryRegion."Contact Address Format" := CountryRegion."Contact Address Format"::Last;
        CountryRegion.Modify();
        ResetAddressLanguage();

        // [WHEN] building the address block for a fully filled address
        DocumentAddressBlock.BuildAddressBlock(
            AddressBlock, 'Northwind Traders', 'Regional Office', 'Alicia Vega', '12 Harbour Road', 'Building C',
            'Portland', '97205', 'Multnomah', 'TRYALADR4', '');

        // [THEN] the county shares the city line, the country follows and the contact closes the block
        ExpectedBlock[1] := 'Northwind Traders';
        ExpectedBlock[2] := 'Regional Office';
        ExpectedBlock[3] := '12 Harbour Road';
        ExpectedBlock[4] := 'Building C';
        ExpectedBlock[5] := 'Portland, Multnomah 97205';
        ExpectedBlock[6] := 'Cascadia Union';
        ExpectedBlock[7] := 'Alicia Vega';
        VerifyBlock(ExpectedBlock, AddressBlock, 'City+County+Post Code / contact last');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankLineLayoutKeepsTheBlankLineAboveThePostCode()
    var
        CountryRegion: Record "Country/Region";
        DocumentAddressBlock: Codeunit "Document Address Block";
        AddressBlock: array[8] of Text[100];
        ExpectedBlock: array[8] of Text[100];
    begin
        // [SCENARIO] A country whose format asks for a blank line before the post code keeps that line empty
        // [GIVEN] a country with Address Format "Blank Line+Post Code+City" and an address of name and street only
        CreateCountry(CountryRegion, 'TRYALADR5', 'Dala Kingdom', "Country/Region Address Format"::"Blank Line+Post Code+City");
        ResetAddressLanguage();

        // [WHEN] building the address block
        DocumentAddressBlock.BuildAddressBlock(
            AddressBlock, 'Northwind Traders', '', '', '12 Harbour Road', '', 'Uppsala', '75310', '', 'TRYALADR5', '');

        // [THEN] line 3 stays empty and the post code line follows it
        ExpectedBlock[1] := 'Northwind Traders';
        ExpectedBlock[2] := '12 Harbour Road';
        ExpectedBlock[3] := '';
        ExpectedBlock[4] := '75310 Uppsala';
        ExpectedBlock[5] := 'Dala Kingdom';
        VerifyBlock(ExpectedBlock, AddressBlock, 'Blank Line+Post Code+City');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankLineLayoutPrintsContactAfterTheCountry()
    var
        CountryRegion: Record "Country/Region";
        DocumentAddressBlock: Codeunit "Document Address Block";
        AddressBlock: array[8] of Text[100];
        ExpectedBlock: array[8] of Text[100];
    begin
        // [SCENARIO] The blank-line format combined with a contact printed last
        // [GIVEN] a country with Address Format "Blank Line+Post Code+City" and Contact Address Format "Last"
        CreateCountry(CountryRegion, 'TRYALADR6', 'Dala Kingdom', "Country/Region Address Format"::"Blank Line+Post Code+City");
        CountryRegion."Contact Address Format" := CountryRegion."Contact Address Format"::Last;
        CountryRegion.Modify();
        ResetAddressLanguage();

        // [WHEN] building the address block for an address that carries a contact
        DocumentAddressBlock.BuildAddressBlock(
            AddressBlock, 'Northwind Traders', '', 'Alicia Vega', '12 Harbour Road', '', 'Uppsala', '75310', '', 'TRYALADR6', '');

        // [THEN] the blank line survives and the contact is printed below the country
        ExpectedBlock[1] := 'Northwind Traders';
        ExpectedBlock[2] := '12 Harbour Road';
        ExpectedBlock[3] := '';
        ExpectedBlock[4] := '75310 Uppsala';
        ExpectedBlock[5] := 'Dala Kingdom';
        ExpectedBlock[6] := 'Alicia Vega';
        VerifyBlock(ExpectedBlock, AddressBlock, 'Blank Line+Post Code+City / contact last');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomLayoutFollowsTheCustomAddressFormatLines()
    var
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
        DocumentAddressBlock: Codeunit "Document Address Block";
        AddressBlock: array[8] of Text[100];
        ExpectedBlock: array[8] of Text[100];
        CityPostCodeLineNo: Integer;
    begin
        // [SCENARIO] A country with a custom address layout prints only the fields the layout lists, in its order
        // [GIVEN] a Custom country whose layout is name, contact, address, "city post code", and the country on line 6
        CreateCountry(CountryRegion, 'TRYALADR7', 'Elbonia Federation', "Country/Region Address Format"::Custom);
        CountryRegion.CreateAddressFormat(CountryRegion.Code, 1, CompanyInformation.FieldNo(Name));
        CountryRegion.CreateAddressFormat(CountryRegion.Code, 2, CompanyInformation.FieldNo("Contact Person"));
        CountryRegion.CreateAddressFormat(CountryRegion.Code, 3, CompanyInformation.FieldNo(Address));
        CityPostCodeLineNo := CountryRegion.CreateAddressFormat(CountryRegion.Code, 4, 0);
        CountryRegion.CreateAddressFormatLine(CountryRegion.Code, 1, CompanyInformation.FieldNo(City), CityPostCodeLineNo);
        CountryRegion.CreateAddressFormatLine(CountryRegion.Code, 2, CompanyInformation.FieldNo("Post Code"), CityPostCodeLineNo);
        CountryRegion.CreateAddressFormat(CountryRegion.Code, 6, CompanyInformation.FieldNo("Country/Region Code"));
        ResetAddressLanguage();

        // [WHEN] building the address block for an address that also carries Name 2, Address 2 and a county
        DocumentAddressBlock.BuildAddressBlock(
            AddressBlock, 'Northwind Traders', 'Regional Office', 'Alicia Vega', '12 Harbour Road', 'Building C',
            'Sunnyvale', '94086', 'Santa Clara', 'TRYALADR7', '');

        // [THEN] only the listed fields are printed, and the unused line 5 of the layout leaves no hole
        ExpectedBlock[1] := 'Northwind Traders';
        ExpectedBlock[2] := 'Alicia Vega';
        ExpectedBlock[3] := '12 Harbour Road';
        ExpectedBlock[4] := 'Sunnyvale 94086';
        ExpectedBlock[5] := 'Elbonia Federation';
        VerifyBlock(ExpectedBlock, AddressBlock, 'custom');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountryNameIsPrintedInTheGivenLanguage()
    var
        CountryRegion: Record "Country/Region";
        DocumentAddressBlock: Codeunit "Document Address Block";
        AddressBlock: array[8] of Text[100];
        ExpectedBlock: array[8] of Text[100];
    begin
        // [SCENARIO] The country line is translated when a Country/Region Translation exists for the language
        // [GIVEN] a country named Fjordland with a translation into language TRYALLNG
        CreateCountry(CountryRegion, 'TRYALADR8', 'Fjordland', "Country/Region Address Format"::"Post Code+City");
        CreateCountryTranslation('TRYALADR8', 'TRYALLNG', 'Fjordlandet');
        ResetAddressLanguage();

        // [WHEN] building the address block for language TRYALLNG
        DocumentAddressBlock.BuildAddressBlock(
            AddressBlock, 'Northwind Traders', '', '', '12 Harbour Road', '', 'Bergen', '5003', '', 'TRYALADR8', 'TRYALLNG');

        // [THEN] the country line carries the translated name
        ExpectedBlock[1] := 'Northwind Traders';
        ExpectedBlock[2] := '12 Harbour Road';
        ExpectedBlock[3] := '5003 Bergen';
        ExpectedBlock[4] := 'Fjordlandet';
        VerifyBlock(ExpectedBlock, AddressBlock, 'translated');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountryNameStaysUntranslatedWithoutALanguage()
    var
        CountryRegion: Record "Country/Region";
        DocumentAddressBlock: Codeunit "Document Address Block";
        AddressBlock: array[8] of Text[100];
        ExpectedBlock: array[8] of Text[100];
    begin
        // [SCENARIO] The country line keeps the country's own name when the document has no language code
        // [GIVEN] a country named Fjordland with a translation into TRYALLNG, and an earlier document that left TRYALLNG set on the session
        CreateCountry(CountryRegion, 'TRYALADR9', 'Fjordland', "Country/Region Address Format"::"Post Code+City");
        CreateCountryTranslation('TRYALADR9', 'TRYALLNG', 'Fjordlandet');
        SetSessionAddressLanguage('TRYALLNG');

        // [WHEN] building the address block without a language code
        DocumentAddressBlock.BuildAddressBlock(
            AddressBlock, 'Northwind Traders', '', '', '12 Harbour Road', '', 'Bergen', '5003', '', 'TRYALADR9', '');

        // [THEN] the country line carries the untranslated name
        ExpectedBlock[1] := 'Northwind Traders';
        ExpectedBlock[2] := '12 Harbour Road';
        ExpectedBlock[3] := '5003 Bergen';
        ExpectedBlock[4] := 'Fjordland';
        VerifyBlock(ExpectedBlock, AddressBlock, 'untranslated');
    end;

    local procedure CreateCountry(var CountryRegion: Record "Country/Region"; CountryCode: Code[10]; CountryName: Text[50]; AddressFormat: Enum "Country/Region Address Format")
    var
        CustomAddressFormat: Record "Custom Address Format";
        CountryRegionTranslation: Record "Country/Region Translation";
    begin
        CustomAddressFormat.SetRange("Country/Region Code", CountryCode);
        CustomAddressFormat.DeleteAll(true);
        CountryRegionTranslation.SetRange("Country/Region Code", CountryCode);
        CountryRegionTranslation.DeleteAll();
        if CountryRegion.Get(CountryCode) then
            CountryRegion.Delete();

        CountryRegion.Init();
        CountryRegion.Code := CountryCode;
        CountryRegion.Name := CountryName;
        CountryRegion."Address Format" := AddressFormat;
        CountryRegion.Insert();
    end;

    local procedure CreateCountryTranslation(CountryCode: Code[10]; LanguageCode: Code[10]; TranslatedName: Text[50])
    var
        CountryRegionTranslation: Record "Country/Region Translation";
    begin
        CountryRegionTranslation.Init();
        CountryRegionTranslation."Country/Region Code" := CountryCode;
        CountryRegionTranslation."Language Code" := LanguageCode;
        CountryRegionTranslation.Name := TranslatedName;
        CountryRegionTranslation.Insert();
    end;

    local procedure ResetAddressLanguage()
    begin
        SetSessionAddressLanguage('');
    end;

    local procedure SetSessionAddressLanguage(LanguageCode: Code[10])
    var
        FormatAddress: Codeunit "Format Address";
    begin
        // "Format Address" is SingleInstance and remembers the last language code
        // it was given: this puts the session into a known state before each test,
        // the way a previously printed document would have left it.
        FormatAddress.SetLanguageCode(LanguageCode);
    end;

    local procedure VerifyBlock(ExpectedBlock: array[8] of Text[100]; ActualBlock: array[8] of Text[100]; Layout: Text)
    var
        Assert: Codeunit Assert;
        LineNo: Integer;
    begin
        for LineNo := 1 to ArrayLen(ExpectedBlock) do
            Assert.AreEqual(
                ExpectedBlock[LineNo], ActualBlock[LineNo],
                StrSubstNo('Expected line %1 of the %2 address block', LineNo, Layout));
    end;
}
