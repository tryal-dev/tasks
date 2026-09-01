// The interface below is the contract the grading tests call through —
// keep its name and procedure signature exactly as declared.
interface "Shipping Fee Calculator"
{
    procedure CalculateFee(ParcelWeightKg: Decimal; OrderAmount: Decimal): Decimal;
}
