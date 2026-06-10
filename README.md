# The Block: Buyer App

An iOS app for the buyer side of a vehicle auction. Browse the inventory, open a
vehicle to see its details and condition, and place bids.

Built with SwiftUI.

## How to Run

1. Open `OpenlaneInterview/OpenlaneInterview.xcodeproj` in Xcode 16 (iOS 17+).
2. Pick an iPhone simulator.
3. Press Run (⌘R).

The 200-vehicle dataset ships with the app (`Resources/vehicles.json`), so there's
nothing to set up and no network needed for the data. Vehicle photos are placeholder
images that load over the network.

To run the tests: ⌘U.

## Stack

- **Frontend:** SwiftUI (iOS 17+)
- **Backend:** none (a mock API client reads the bundled JSON)
- **Database:** none

## What I Built

Two screens:

- **Inventory:** a searchable, sortable list of every vehicle. Search covers make,
  model, trim, dealer, city and lot. A filter sheet narrows by make and body style, and
  you can sort by auction timing, year, or current bid. Each row shows a photo, the key
  facts, the current bid, and a live/upcoming/ended badge.
- **Vehicle detail:** photos, auction status, specs, condition report and damage
  notes, whether the reserve has been met, and the selling dealer. While an auction is
  live, a footer lets you bid. The default button bumps the bid by $50, or you can type
  a custom amount.

Bids update immediately on screen and are written back through the mock client, so the
new amount and bid count stick if you leave and come back.

## Notable Decisions

- **MVVM with a repository.** Views are thin, view models hold the logic, and a
  repository sits behind a protocol with a mock API client underneath. Swapping in a
  real network layer later means writing one new client, and nothing else changes. The
  protocols also make the view models easy to test with fakes.

- **Auction status is driven by the date, not by bids.** The dataset's `auction_start`
  values are synthetic and all in the past, so on their own every lot would read as
  "ended." I take the dataset's busiest day and map it onto today, keeping each
  auction's original day offset and time of day. Status then comes purely from that
  shifted time: an auction in the future is Upcoming, one that opened within the last
  two hours is Live, and anything older is Ended. 

  The `current_bid` and `bid_count` fields are price and history only; 
  they don't decide whether an auction is open, so a lot is never shown as Live 
  just because the data carries a bid. Ignoring these and relying strictly on
  the date allowed us to simplify things and make logic make sense. 

  Anchoring to the busiest day keeps the most auctions  opening and closing 
  as the day goes on. It re-spreads fresh each day and is deterministic 
  for a given moment, and ended auctions sort to the bottom so the list leads with 
  what a buyer can act on. The challenge mentions normalizing the timestamps, 
  so this was an intended approach rather than a workaround.

- **Optimistic bidding.** A bid updates the UI right away instead of waiting on the
  client, which is how a real auction needs to feel. The mock client persists it so the
  change survives navigation. Against a real backend I'd architect this differently. The
  server owns the authoritative bid, and the client would reconcile (and likely
  subscribe to live updates) rather than mutate its own copy. The repository protocol is
  the seam where that swap happens.

- **A collapsible photo header on the detail screen.** It starts large and collapses to
  a compact bar with a tap on the chevron, keeping the title and current bid visible
  while you read the specs. This was the one place I spent extra time on polish.

## Assumptions and Scope

- Native iOS only. Swift and SwiftUI
- No auth, accounts, checkout, or seller tooling, since the brief says these aren't needed.
- A buy-now action is surfaced in the data (the price shows on the detail screen) but I
  didn't wire up a separate purchase flow, since bidding is the core of the brief.
- Auctions are normalized by date. Certain architectural decisions were made keeping in mind
  time constraints and the scope of the assessment. If this was a production app, 
  we would further make use of DI and Mock Services for testing purposes instead of using flags.  

## Testing

- Unit tests (Swift Testing) cover the data loading and caching, search + filter +
  sort, auction-status normalization, and the bidding view model (default and custom
  increments, input sanitizing).
- A few UI tests cover loading the inventory, opening a vehicle, and placing a bid.
- The UI tests pass a `-uitesting` launch argument that stubs image loading and freezes
  the auto-updating time views, so the tests stay fast and don't depend on the network.
  For a prototype the flag is a smaller, lower-risk seam; in production I'd
  promote it to environment-injected dependencies, which would also make the image view's
  loading states unit-testable.

## What I'd Do With More Time

- A bid confirmation step and clearer feedback when a bid is below the current price.
- Pull-to-refresh and a real network client behind the existing repository protocol.
- An iPad layout that uses the extra width (e.g. a list/detail split).
- Further improve certain logic and increased separation of view/viewmodel. 
- Further polish the sort page and general polish for the app such as adding an icon and
  proper Home Screen etc.
- Refactor certain components to fit best practices.
- Add further testing. 
