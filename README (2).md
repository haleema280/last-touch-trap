# The Last-Touch Trap — Paid Social Attribution Review

## The question

Meridian's dashboard runs on last-touch attribution. Under that model, Paid Social gets credit for under 3% of Q2 paid signups, while Brand Search and Retargeting take most of the credit. The proposal on the table is to cut Paid Social's budget by 60% and move the money to the "converting" channels.

Before signing off on that, this analysis checks whether last-touch attribution is telling the whole story — or just crediting whichever channel happens to close the deal last.

## Method

- Source data: `touches.csv` (89,102 rows) and `conversions.csv` (6,422 rows), covering Q2 2026 (Apr 1 – Jun 30).
- **Deduped conversions**: each customer counted once, under their earliest `converted_at`, to remove resubscribe duplicates → **5,939 unique converting customers**.
- **30-day attribution window**: a touch only qualifies if it falls within 30 days before the conversion, and no later than the conversion timestamp itself.
- **Last-touch**: for each customer, the *latest* qualifying touch gets 100% credit.
- **First-touch**: for each customer, the *earliest* qualifying touch gets 100% credit.
- Both attribution models were computed from the same 20,533 qualifying (customer, touch) pairs, so the comparison is apples-to-apples.

Full query logic is in [`analysis.sql`](./analysis.sql).

## Findings

| Metric | Paid Social |
|---|---|
| Last-touch share of conversions | **2.9%** |
| First-touch share of conversions | **27.3%** |

That's roughly a **9x gap** between the two models. Under last-touch, Paid Social barely registers — it looks like dead weight. Under first-touch, it's the *most common originating channel* of all converting customer journeys (ahead of Brand Search's last-touch-driven ranking).

This isn't noise. It's consistent with a channel that plays a **top-of-funnel discovery role**: it's usually the first thing a future customer sees, but the sale itself gets closed later — often by Brand Search or Retargeting, which show up disproportionately as the *last* touch because they're catching people who were already warmed up.

Last-touch attribution structurally can't see this. It only ever credits the channel that happened to be present at the finish line, regardless of who did the work to get the customer there.

## Recommendation

**Do not cut the Paid Social budget.** The last-touch dashboard is measuring who closes, not who originates — and by that measure it's systematically undercrediting the channel doing roughly a quarter of the discovery work. A 60% cut would shrink the top of the funnel that Brand Search and Retargeting currently depend on to have anyone to close.

Going forward, Meridian shouldn't evaluate discovery-stage channels (Paid Social, Display, YouTube) on last-touch alone. Two concrete changes:

1. **Add first-touch (or a multi-touch model — linear or position-based) to the dashboard** alongside last-touch, so discovery channels are judged on the stage of the funnel they actually operate in.
2. **Track assisted conversions** — conversions where a channel appeared anywhere in the qualifying path but didn't get last-touch credit — as a standing metric for channels like Paid Social.

Cutting budget based on a single attribution model risks optimizing the business into a funnel with no top.
