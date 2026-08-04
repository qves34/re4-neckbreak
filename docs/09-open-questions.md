# Open questions

Everything unresolved, ordered by how much it blocks. Resolve top-down —
several lower items only matter if the ones above them go a particular way.

---

## 🔴 Blocking

### Q1 — Is the neck break a generic execution or a HUNK-only action?

The project's feasibility rests on this. Variant A is tractable; Variant B
kills the runtime approach.

**Resolves by:** searching the `il2cpp` dump. No game session needed.
**Details:** [05-hypotheses-and-discriminator.md](05-hypotheses-and-discriminator.md)
**Blocked on:** Q2.

### Q2 — Which `KindID` is HUNK?

Narrowed to `600001`–`600005`. His classes are named after his codename, so
nothing can be searched for until this is pinned.

**Resolves by:** `scripts/dump_enums.lua`, then matching codenames against the
Mercenaries roster. Possibly by setting each ID and observing which the game
accepts.
**Cost:** minutes. **Do this first.**

---

## 🟠 High

### Q3 — Are Mercenaries animations resident in campaign memory?

If HUNK's clip is not loaded during campaign play, forcing its ID yields a
T-pose or nothing, regardless of how correct the rest is.

**Resolves by:** forcing a *known campaign* execution out of its normal
context. If a familiar clip cannot be forced, a Mercenaries-only clip
certainly cannot.
**Note:** the Ada mod solved this by importing animations into the campaign
character's bank — evidence that they are *not* freely available, though that
mod may simply not have tried.

### Q4 — Can a non-staggered enemy be pulled into an execution?

The likely blocker. A neck break is a synchronised two-actor animation, and
the transition into "grabbed" may only be legal from the stagger state.

**Resolves by:** hooking the permit predicate and attempting any campaign
execution on a healthy enemy. Isolates the gate and victim problems from
selection.
**Details:** [04-neckbreak-decomposition.md](04-neckbreak-decomposition.md)

### Q5 — What is `chainsaw.ExecutionPermitter`'s interface?

Confirmed to exist; nothing else is known. If it mirrors
`EnemyAttackPermitManager.checkAttackPermit(attacker, target) → Result`, it is
close to an ideal hook target.

**Resolves by:** reading its methods in the dump. Trivial once the dump is
searched.

---

## 🟡 Medium

### Q6 — Is there an execution ID enum, and what is in it?

Needed for the selection sub-problem. Also feeds Q1 — if such an enum exists
and contains a neck-break-like entry, that alone argues for Variant A.

### Q7 — How does the Wesker melee mod force specific moves?

[Classic RE5 Melee for Wesker](https://www.nexusmods.com/residentevil42023/mods/1773)
makes Wesker always perform particular moves. If it replaces animation files
rather than overriding selection, that is a cheaper mechanism than anything
proposed here — though it cannot address the stagger gate.

**Resolves by:** downloading it and reading the file list. Nexus blocks
automated access, so this needs a human.

### Q8 — How does Ultimate Wesker add a Mercenaries character slot?

Someone registered a new entry in Mercenaries character selection. That is the
"find how Mercenaries performs character selection" avenue, demonstrated
reachable.

**Caveat:** the mod was DMCA'd, so it may be hard to obtain.

### Q9 — Is execution lethality damage, or an instant-death flag?

Affects whether the existing `callbackCalculateDamageByAttacker` hook is the
right lever for the lethality sub-problem. Low urgency — that sub-problem is
already solved by other means.

---

## 🟢 Low

### Q10 — Why did two `requestCreateHead` calls return the same handle?

Inherited from the predecessor project. Deduplication, or a request that never
completed. Only matters if body recreation is revisited, which it currently
is not.

### Q11 — Does `chainsaw.GameSituationManager` distinguish campaign from Mercenaries?

If some behaviour is mode-gated, this may be where. Speculative.

### Q12 — Does the neck break work on all enemy types?

In Mercenaries it presumably does not apply to bosses or armoured enemies.
Whatever restricts it may be a further permit condition. Only relevant once
something works.

---

## Resolved

Moved here with the answer and its source, so the reasoning stays visible.

### ~~Which `KindID` is HUNK — is it `200009`?~~

❌ **No.** `200009` is a Las Plagas creature; the whole `200000` range is
enemies. Verified against three independent tools.
→ [06-investigation-log.md](06-investigation-log.md), Entry 2

### ~~Can the player's character be swapped by writing `KindID` at runtime?~~

❌ **No.** It is consumed once at spawn. Forcing body/head recreation produces
orphaned GameObjects and breaks interactions.
→ [01-character-identity.md](01-character-identity.md)

⚠️ Note the scope: this is confirmed for the *approach*, and the test that ran
used a wrong ID. The architectural reasoning is independent of which ID was
used, but a correct-ID swap has never actually been attempted.

### ~~Has anyone already solved this?~~

❌ **No.** No public project maps RE4R's melee or execution system; a
GitHub-wide search returns nothing. No published mod achieves a runtime
character swap.
→ [07-prior-art.md](07-prior-art.md)

### ~~Is a Mercenaries moveset in the campaign possible at all?~~

✅ **Yes**, at the asset level — playable Ada and Wesker both demonstrate it.
Not via character identity, and the result is Leon wearing replaced files.
→ [07-prior-art.md](07-prior-art.md)
