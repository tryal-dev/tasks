xmlport 50110 "Payment Batch Export"
{
    Caption = 'Payment Batch Export';

    schema
    {
        textelement(PaymentFile)
        {
            // TODO: write one 63-character PMT line per "Payment Batch Line"
            // record, in ascending "Line No." order, followed by exactly one
            // 21-character TRL trailer line.
        }
    }
}
