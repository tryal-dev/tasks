codeunit 50101 "Inbound Xml Validation"
{
    procedure Validate(XmlPayload: Text; var Diagnostic: Text): Enum "Xml Verdict"
    begin
        // TODO: triage XmlPayload into Valid, NotWellFormed or SchemaInvalid,
        // surface the violation text through Diagnostic for SchemaInvalid only,
        // and never let an error escape this procedure.
    end;

    procedure SchemaText(): Text
    begin
        exit(
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" targetNamespace="urn:tryal:orders" elementFormDefault="qualified">' +
            '<xsd:element name="Order"><xsd:complexType><xsd:sequence>' +
            '<xsd:element name="OrderNo" type="xsd:string"/>' +
            '<xsd:element name="Quantity" type="xsd:int"/>' +
            '</xsd:sequence></xsd:complexType></xsd:element>' +
            '</xsd:schema>');
    end;

    procedure SchemaNamespace(): Text
    begin
        exit('urn:tryal:orders');
    end;
}
