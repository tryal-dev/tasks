// The two interfaces are the contract the grading tests bind to —
// keep their names and procedure signatures exactly as declared.
interface "IShipping Carrier"
{
    procedure Quote(Weight: Decimal): Decimal;
}
