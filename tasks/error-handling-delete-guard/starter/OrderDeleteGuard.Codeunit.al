codeunit 50100 "Order Delete Guard"
{
    // TODO: Make deleting a released sales order fail with an error that contains
    // "is released and cannot be deleted" and the order's "No.", without modifying
    // any base application object. Open orders, reopened orders, and other sales
    // document types must keep deleting normally.
}
