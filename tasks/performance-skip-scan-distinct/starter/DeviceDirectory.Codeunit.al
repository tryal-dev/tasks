codeunit 50101 "Device Directory"
{
    procedure GetDeviceCodes(var DeviceCodes: List of [Code[20]])
    var
        SensorReading: Record "Sensor Reading";
    begin
        // TODO: the answer below is right — the cost is not. This scan drags
        // every reading across the wire to collect ~20 distinct codes, and the
        // grading row budget allows 3,000 rows for ~10,000 readings. Sorted by
        // "Device Code", every duplicate sits next to its group — find a way
        // to jump over a whole group instead of reading through it.
        Clear(DeviceCodes);
        SensorReading.SetCurrentKey("Device Code");
        SensorReading.SetFilter("Device Code", '<>%1', '');
        if SensorReading.FindSet() then
            repeat
                if not DeviceCodes.Contains(SensorReading."Device Code") then
                    DeviceCodes.Add(SensorReading."Device Code");
            until SensorReading.Next() = 0;
    end;
}
