# Decomposing the neck break

The move splits into four independent sub-problems. One is already solved, one
is probably tractable, one is unknown, and one is the likely killer.

Treating them separately matters: they fail independently, and testing them in
the right order avoids wasting effort on pieces that only matter if an earlier
piece works.

---

## The four pieces

| # | Piece | Question | Status |
|---|---|---|---|
| 1 | **Lethality** | Kill from full HP | ✅ **Solved** |
| 2 | **Gate** | Allow an execution with no stagger | 🟡 Plausible target identified |
| 3 | **Selection** | Play the neck break specifically | ❓ Unknown |
| 4 | **Victim** | Pull a healthy enemy into the animation | 🔴 **Likely the hard blocker** |

---

## 1. Lethality — solved

✅ **Confirmed working.** The predecessor project's One Hit Kill hooks
`chainsaw.HitController:callbackCalculateDamageByAttacker`, reads the damage
object from argument 3, and multiplies `<Damage>k__BackingField` by 500.

That is already an instant kill. For this project it needs narrowing —
conditional on the attack being the neck break rather than global — but the
primitive works and needs no research.

Worth stating explicitly because the "kills from full HP" requirement sounds
like it makes the project harder. It doesn't. That part was finished before
the project started.

❓ Minor open question: whether an execution's lethality is expressed as
damage at all, or as an instant-death flag on the execution definition. If the
latter, this hook is the wrong lever — but a working alternative already
exists either way.

---

## 2. Gate — plausible target identified

The stagger requirement has to be bypassed.

🟡 `chainsaw.ExecutionPermitter` is the obvious candidate, by name and by
analogy with `EnemyAttackPermitManager.checkAttackPermit(attacker, target)`.
If it exposes a similar predicate, a pre-hook forcing "permitted" is
straightforward — no state mutation, trivially reversible, safe to iterate on.

❓ Unverified: method names, signature, and whether it governs player
executions at all.

⚠️ Do not assume forcing the predicate is sufficient. A permit check is
usually one of several conditions; distance, orientation, enemy type, and
enemy state may be tested elsewhere. Forcing one gate open does not open the
others.

---

## 3. Selection — unknown

Even with the gate open, the game must be made to play *this* execution.

❓ No execution ID enum and no selector method have been located. See
[02-known-classes.md](02-known-classes.md).

Two failure modes worth anticipating:

**The ID exists but the animation isn't loaded.** Forcing an execution whose
clip is not resident in campaign memory yields a T-pose or nothing at all.
This is the wall the Ada mod hit and solved by *importing* Mercenaries
animations into the campaign character's bank. ❓ Whether Mercenaries clips are
resident during campaign play is unknown and should be tested early — it is
cheap to test and expensive to discover late.

**The neck break has no generic ID at all.** If it is a behavior-tree action
rather than an execution, there is nothing to select. This is Variant B in
[05-hypotheses-and-discriminator.md](05-hypotheses-and-discriminator.md).

---

## 4. Victim — the likely blocker

This is the piece most likely to end the project, and it deserves more
attention than the others.

A neck break is a **synchronised two-actor animation**. The attacker and the
target play matched clips, locked in position. The target is not merely
receiving damage; it is being driven.

In the normal case, the game pulls a **staggered** enemy into that role. But
stagger is a state in the enemy's state machine, not just a visual condition —
and the transition into "grabbed" is presumably only legal from certain
states.

**Attacking from full HP means requesting that transition from a neutral
state, which may simply not be a legal edge.**

Failure modes, in increasing order of badness:

| Outcome | Meaning |
|---|---|
| Enemy ignores the request | Player animation plays into empty air; enemy walks on |
| Enemy enters the state and desyncs | Visual mismatch, enemy in the wrong place |
| Enemy enters an invalid state | Broken AI, possibly session-corrupting |

🟡 **Inferred, not measured.** It is entirely possible the engine allows the
transition from any state and the concern is unfounded — Mercenaries HUNK does
exactly this, after all, so *some* path exists. The real question is whether
that path is generic or specific to him.

That question is the same fork as everything else. See
[05-hypotheses-and-discriminator.md](05-hypotheses-and-discriminator.md).

---

## Recommended test order

Ordered so that the cheapest disqualifying answer comes first.

1. **Resolve HUNK's `KindID`** (`600001`–`600005`). Cheap, and everything
   downstream needs his codename to search for his classes.
   → `scripts/dump_enums.lua`
2. **Search the dump for the execution system.** Decides Variant A vs B.
   No game time required.
3. **If Variant B — stop and reconsider.** The runtime approach is dead;
   see [07-prior-art.md](07-prior-art.md) for the asset-level route.
4. **Test animation residency.** Force any *known campaign* execution
   out of context. If forcing a familiar one already fails, forcing a
   Mercenaries-only clip certainly will.
5. **Hook the permit predicate.** Try to trigger any execution on a
   non-staggered enemy — start with a campaign execution, not the neck break.
   This isolates the gate and victim problems from the selection problem.
6. **Only then** attempt the neck break itself.

Steps 1–3 need no game session at all. Do them first.
