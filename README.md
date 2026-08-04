# RE4R Neck Break Research

Reverse-engineering notes on porting **HUNK's neck break** from Mercenaries
mode into the main campaign of *Resident Evil 4 (2023)*, using
[REFramework](https://github.com/praydog/REFramework).

Fan-made educational modding research. Not affiliated with or endorsed by
Capcom. Single-player, offline use only.

---

## The goal

HUNK's neck break, working in the main campaign, **with its Mercenaries
semantics** — meaning it is *not* a stagger-gated finisher. In Mercenaries it
can be performed on a healthy enemy and kills instantly from full HP.

That last part is the whole difficulty. RE4R's normal melee finishers require
the enemy to already be staggered. A move that bypasses that requirement is
not just a different animation — it is a different **gating condition**, and
possibly a different system entirely.

### Explicit non-goals

- A cosmetic HUNK reskin. Several already exist on Nexus Mods; they swap
  Leon's model and audio and leave his moveset untouched.
- A full character swap. That was attempted in a
  [predecessor project](#relationship-to-re4-hunk-mod) and is documented here
  as a dead end, with the reasons.
- Anything touching online play, leaderboards, or anti-cheat.

---

## Current state

Nothing works yet. This repository is **documentation and hypotheses**, not a
working mod. What exists is a body of verified facts, a decomposition of the
problem, and a single question whose answer determines whether the project is
feasible at all.

| Piece | State |
|---|---|
| Character identity model (`KindID`) | ✅ Understood, and understood to be a dead end for this goal |
| Corrected `CharacterKindID` value table | ✅ Verified against three independent tools |
| Which `KindID` is HUNK | 🟡 Narrowed to `600001`–`600005`, not yet pinned |
| Execution/melee system | ❓ Barely mapped. One confirmed class name. |
| Neck break implementation | ❓ **Unknown — this is the blocking question** |
| Instant-kill damage | ✅ Solved (working hook exists in the predecessor project) |

---

## The blocking question

Everything hinges on one fork:

**Variant A — the neck break is a generic execution.**
It has an ID in an execution enum and a permit condition somewhere in
`chainsaw.ExecutionPermitter`. If so, it is reachable by hooking the permit
check and the execution selector. Difficult but tractable.

**Variant B — the neck break is a HUNK-only behavior-tree action.**
Something like `Ch6i*BehaviorTreeAction_NeckBreak`, bound to his player
controller. If so, it does not exist in the generic execution system at all,
and the runtime approach is dead — the only remaining route is asset-level
replacement of Leon.

Current expectation is **B**, based on how Capcom appears to structure
signature abilities elsewhere in this game. But this is an inference from
naming conventions, not evidence. See
[docs/05-hypotheses-and-discriminator.md](docs/05-hypotheses-and-discriminator.md)
for how to tell the two apart from an `il2cpp` dump.

---

## Documentation

| Document | Contents |
|---|---|
| [00-glossary.md](docs/00-glossary.md) | Terms, codename scheme, evidence-labelling convention |
| [01-character-identity.md](docs/01-character-identity.md) | `CharacterKindID`, the corrected value table, why runtime swap fails |
| [02-known-classes.md](docs/02-known-classes.md) | Every confirmed `chainsaw.*` class and signature collected so far |
| [03-execution-system.md](docs/03-execution-system.md) | What is known about melee/executions, and what isn't |
| [04-neckbreak-decomposition.md](docs/04-neckbreak-decomposition.md) | The four independent sub-problems, and which are already solved |
| [05-hypotheses-and-discriminator.md](docs/05-hypotheses-and-discriminator.md) | Variant A vs B, and the exact test that distinguishes them |
| [06-investigation-log.md](docs/06-investigation-log.md) | Chronological record of attempts, results, and corrections |
| [07-prior-art.md](docs/07-prior-art.md) | Existing mods, what they actually do, what that proves |
| [08-method-and-tooling.md](docs/08-method-and-tooling.md) | Dumping enums, searching the type dump, sources cross-checked |
| [09-open-questions.md](docs/09-open-questions.md) | Everything unresolved, prioritised |

`scripts/dump_enums.lua` is a standalone REFramework script that writes any
managed enum to the log. Start there — it is the cheapest way to replace
guesses with facts.

---

## Method in one paragraph

Generate an `il2cpp` type dump via REFramework (Insert → Developer Tools →
Generate SDK). That yields structural metadata only: class, field, and method
names and types. It does **not** contain runtime values, string tables, or
method bodies. Anything about *behaviour* is therefore inference until tested
live, and anything about *enum values* must be read from the running game
rather than guessed from class names. This distinction is not academic — the
predecessor project drew a character mapping from class names, got it wrong,
and spent its live testing on the wrong character. See
[docs/08-method-and-tooling.md](docs/08-method-and-tooling.md).

---

## Relationship to `re4-hunk-mod`

This project supersedes the character-swap investigation in
[qves34/re4-hunk-mod](https://github.com/qves34/re4-hunk-mod). That project
attempted to make the player *be* HUNK by rewriting `KindID` at runtime. It
does not work, and [01-character-identity.md](docs/01-character-identity.md)
explains why in detail.

The insight that produced this repository: **the goal never required being
HUNK.** It required one of his moves. Those are different problems with
different difficulty, and the second one may have a runtime answer.

---

## Contributing

Findings are welcome, including negative ones — a documented failure is worth
more here than an untested idea. Two rules:

1. **Label your evidence.** Use the ✅ / 🟡 / ❓ convention from
   [00-glossary.md](docs/00-glossary.md). Never present an inference from a
   class name as a fact. This project exists partly because that mistake was
   made once already.
2. **Record the game build.** Enum values and class layouts can shift between
   patches. A finding without a version is not reproducible.

---

## Disclaimer

For personal modding and educational reverse-engineering. Single-player,
offline. No online or leaderboard integrity claims are made or intended.
Nothing here circumvents copy protection or redistributes game assets.
