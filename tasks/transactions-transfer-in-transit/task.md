# Ship Now, Receive Later

When goods move between two warehouses they spend days on a truck — no longer at the source, not yet at the destination. Business Central models that limbo honestly: at shipment the quantity is posted out of the from-location and into a dedicated in-transit location, and at receipt out of in-transit and into the destination. Your job is to drive that lifecycle from code and to answer, at any moment in between, "what is where?" — straight from the item ledger.

## Requirements

Create a **codeunit** named `"Transfer Flow"` with five public procedures:

```al
procedure CreateOrder(ItemNo: Code[20]; FromLocation: Code[10]; InTransitLocation: Code[10]; ToLocation: Code[10]; Quantity: Decimal): Code[20]
procedure Ship(OrderNo: Code[20]; QtyToShip: Decimal)
procedure Receive(OrderNo: Code[20]; QtyToReceive: Decimal)
procedure DirectTransfer(ItemNo: Code[20]; FromLocation: Code[10]; ToLocation: Code[10]; Quantity: Decimal)
procedure OnHand(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
```

Rules:

1. `CreateOrder` creates a genuine, **unposted** transfer order — a `Transfer Header` carrying the three location codes plus exactly one `Transfer Line` for the item and quantity — and returns the order's number. Creating an order writes **no** item ledger entries.
2. `Ship` posts a transfer shipment of exactly `QtyToShip`, which may be less than the ordered quantity. Shipping a quantity `q` writes exactly **two** item ledger entries, both with `Entry Type` = `Transfer`: `-q` at `FromLocation` and `+q` at `InTransitLocation` — while underway the goods are at neither real warehouse.
3. After a partial shipment the order's own line — the one with `"Derived From Line No." = 0`; posting may add derived bookkeeping lines, which the tests ignore — must read: `Quantity` = the ordered quantity, `"Quantity Shipped"` = what has been shipped so far, `"Outstanding Quantity"` = the rest, `"Qty. in Transit"` = shipped but not yet received.
4. `Receive` posts a transfer receipt of exactly `QtyToReceive` and writes the mirroring **two** entries: `-q` at `InTransitLocation` and `+q` at `ToLocation`. A full ship-then-receive of quantity `q` therefore leaves exactly **four** `Transfer` entries on the item.
5. Asking `Receive` for more than is currently in transit must raise an error with a message that contains `You cannot receive more than`, and must not post anything.
6. `DirectTransfer` moves the quantity between two real locations in a single step and leaves exactly **two** `Transfer` entries: `-q` at `FromLocation` and `+q` at `ToLocation` — no in-transit stop, no other entries.
7. `OnHand` returns the net sum of the item's item ledger `Quantity` at the given location, and `0` for a location the item has never touched.
8. Entry types are part of the contract: a pair of item-journal **adjustments** produces the right on-hand totals with the wrong history. The tests count the item's `Transfer` entries and its total entries, so impersonating a transfer with `Positive Adjmt.`/`Negative Adjmt.` postings fails.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

## What the tests check

The tests create fresh items and locations (two real ones plus an in-transit one), seed stock with their own journal postings, and drive your codeunit through the lifecycle with quantities generated at run time: that `CreateOrder` returns a real, unposted order; the exact two-entry and four-entry `Transfer` footprints with the exact signed quantity at each location; the order line's split fields after a partial `Ship`; that a partial `Receive` posts exactly the received quantity, leaves the remainder at the in-transit location and updates the line's `"Qty. in Transit"`; on-hand at all three locations after shipping and again after receiving; the `You cannot receive more than` error — and that the failed receipt posted nothing; the two-entry direct transfer; and `OnHand` against ledger entries the tests posted themselves.

## Learn More

- [Transfer inventory between locations](https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-transfer-between-locations) — the business process you are automating, including exactly which item ledger entries each transfer flavor produces.
- [Design details: Inventory posting](https://learn.microsoft.com/en-us/dynamics365/business-central/design-details-inventory-posting) — what posting writes to the item ledger and why the ledger is the source of truth for "what is where".
- [Set up locations](https://learn.microsoft.com/en-us/dynamics365/business-central/inventory-how-setup-locations) — locations, in-transit locations, and transfer routes.
