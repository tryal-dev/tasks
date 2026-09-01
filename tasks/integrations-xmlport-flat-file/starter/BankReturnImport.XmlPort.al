xmlport 50111 "Bank Return Import"
{
    Caption = 'Bank Return Import';

    schema
    {
        textelement(ReturnFile)
        {
            // TODO: read the semicolon-separated return file and insert one
            // "Bank Return Line" record per line of it.
        }
    }
}
