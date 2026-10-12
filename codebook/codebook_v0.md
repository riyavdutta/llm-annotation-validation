# Trust-Cue Codebook — v0 (draft)

**Status:** Draft. To be reviewed by the author and frozen as v1 before the
full Part B run. Changes after freezing must be logged as a new version.

**Provenance:** Definitions drafted by an AI assistant (Claude) at the author's
request on 2026-10-12, based on the sources cited below; the three marked
decisions were set to the AI's suggested defaults on 2026-10-13. See
`AI_USE_LOG.md`, sessions 3 and 6. All examples are invented, not taken from
the dataset.

---

## General rules

| Rule | Definition |
|------|------------|
| Unit | The whole review: title and text together. |
| Values | `1` = cue present, `0` = absent. One clear instance is enough for `1`. |
| Independence | Each cue is coded separately. One phrase may count for more than one cue. |
| Doubt | Code `1` only when the wording clearly fits the definition; otherwise `0`. |

---

## 1. `expertise_claim`

*Concept:* the expertise dimension of source credibility
(Hovland, Janis & Kelley, 1953; Ohanian, 1990).

**Code `1`** when the reviewer claims knowledge, skill or experience that gives
their judgement more authority than an ordinary buyer's:

- occupation or training: "as a seamstress", "I worked in retail for years", "I'm a stylist"
- extensive experience with the brand or category: "I've bought this brand for 10 years", "I own about 20 of their dresses"
- specialist knowledge used as a reason: "as someone who sews, I can tell the seams are poorly finished"

**Code `0`** for:

- body measurements, usual size or fit information ("I'm 5'4 and 130 lbs, the small fits")
- having bought the item or one similar item
- unsupported opinions ("great quality!")

> **Decision D1:** body measurements and fit information are **excluded**.
> They are self-disclosure, not a claim of authority.

---

## 2. `hedging`

*Concept:* hedges as markers of tentativeness or reduced commitment to a claim
(Lakoff, 1972; Hyland, 1998).

**Code `1`** when the reviewer softens their certainty about a claim:

- epistemic markers: *I think, maybe, perhaps, might, probably, seems, I guess, not sure*
- tentative predictions: "it might work better for taller women"

**Code `0`** for:

- degree words describing the item: "a bit long", "slightly sheer" (how much, not how sure)
- confidently stated mixed or negative opinions (pros and cons alone are not hedging)
- questions; strong confident language ("absolutely", "perfect")

> **Decision D2:** personal scope limiters ("for me", "on my body") are
> **excluded** unless they clearly soften a claim, because they occur in most
> clothing reviews.

---

## 3. `social_proof`

*Concept:* other people's behaviour or approval used as evidence about a
product (Cialdini, *Influence*).

**Code `1`** when the review cites other people's reactions to, or behaviour
around, the product:

- others' approval: "I get compliments every time", "my husband loved it"
- others buying or owning it: "my sister bought one too", "it sold out in my size"
- other reviewers: "like other reviewers said, it runs large"
- recommendations from others: "the store associate recommended it"

**Code `0`** for:

- the reviewer's own repeat purchases ("I bought it in 3 colours")
- advice to the reader ("you'll love it!", "size down")

> **Decision D3:** compliments from people the reviewer knows are **included**.

---

## References

- Cialdini, R. B. *Influence: The Psychology of Persuasion.*
- Hovland, C. I., Janis, I. L., & Kelley, H. H. (1953). *Communication and Persuasion.* Yale University Press.
- Hyland, K. (1998). *Hedging in Scientific Research Articles.* John Benjamins.
- Lakoff, G. (1972). Hedges: A study in meaning criteria and the logic of fuzzy concepts. *Papers from the Eighth Regional Meeting of the Chicago Linguistic Society.*
- Ohanian, R. (1990). Construction and validation of a scale to measure celebrity endorsers' perceived expertise, trustworthiness, and attractiveness. *Journal of Advertising, 19*(3), 39–52.
