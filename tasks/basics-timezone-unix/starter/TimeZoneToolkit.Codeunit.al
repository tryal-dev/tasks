codeunit 50100 "Time Zone Toolkit"
{
    procedure GetOffsetText(AtDateTime: DateTime; TimeZoneId: Text): Text
    begin
        // TODO: return the zone's UTC offset at that instant as '+HH:MM' / '-HH:MM' text.
    end;

    procedure IsDaylightSaving(AtDateTime: DateTime; TimeZoneId: Text): Boolean
    begin
        // TODO: return whether the instant falls in the zone's daylight saving period.
    end;

    procedure ToLocalTime(UtcDateTime: DateTime; TimeZoneId: Text): DateTime
    begin
        // TODO: return the wall-clock datetime of the UTC instant in the target zone.
    end;

    procedure ToUnixSeconds(FromDateTime: DateTime): BigInteger
    begin
        // TODO: return the Unix timestamp of the datetime in whole seconds.
    end;

    procedure FromUnixSeconds(UnixSeconds: BigInteger): DateTime
    begin
        // TODO: return the UTC datetime for the Unix seconds value.
    end;
}
