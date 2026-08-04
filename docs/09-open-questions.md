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

🟡 Narrowed further to `600001`, `600003`, or `600004`. `600002` and `600005`
are now plausibly identified as Krauser and Wesker respectively (Bullet Rush
weapon IDs / Atemi+RedEye+bullet-parry classes — see
[06-investigation-log.md](06-investigation-log.md) Entry 5), leaving Luis,
HUNK, and Ada across the remaining three in unknown order. `600003` and
`600004` have **no** discoverable unique `BehaviorTreeAction`/`Define`/
`TargetSelector` class at all under direct codename-prefix search — 🟡
speculatively consistent with HUNK, whose Mercenaries kit has no flashy
signature ability the way Krauser/Wesker do, but not evidence on its own.

**Resolves by:** `scripts/dump_enums.lua` for direct in-game confirmation, or
correlating `chainsaw.Cp1021CharacterSelectMenuActionType`
(`Character01`–`Character06`) against `CharacterKindID` — that mapping lives
in game userdata/assets, not the `il2cpp` structure dump, so it needs either a
live session or an asset-level tool.
**Cost:** minutes for the enum dump; asset correlation is unscoped.

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

**Resolves by:** hooking `chainsaw.PlayerCondition_CheckTargetFatal.evaluate`
(found in Entry 5, replacing the earlier `ExecutionPermitter` guess — see
Resolved below) to force-return `true`, then attempting any campaign
`FatalType` finisher on a healthy enemy. Isolates the gate and victim problems
from selection. **This is now the concrete recommended next action** — see
[06-investigation-log.md](06-investigation-log.md) Entry 5.
**Details:** [04-neckbreak-decomposition.md](04-neckbreak-decomposition.md)

---

## 🟡 Medium

### Q6b — Is there a Mercenaries-character-specific `Fatal`-equivalent?

`chainsaw.PlayerDefine.FatalType` (`None`, `RoundKick`, `StraightKick`,
`KnifeFatal`) is scoped to the base `Player` class, i.e. campaign Leon — it is
not obviously a shared registry other characters plug into. Whether
`600001`–`600005` each carry their own private fatal-type enum, or share this
one via inheritance, is unknown and matters for Variant A's feasibility.

**Resolves by:** once Q2 pins HUNK's codename, search for a
`Ch6i<N>z0`-scoped fatal/finisher enum analogous to `PlayerDefine.FatalType`.

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

### ~~What is `chainsaw.ExecutionPermitter`'s interface, and is it the stagger gate?~~

❌ **No, it is not the gate.** Full signature read from the dump:
`request(ExecutionRequester) → bool`, where `ExecutionRequester` carries only
a string `Key` and a frame counter — no attacker/target. Combined with
`ExecutionPermitterBehavior.SettingList`'s `{Key, Capacity, Interval}`
triples, this is a **rate limiter** (how many executions of a kind may run
concurrently), not a per-target eligibility check.

✅ **The real permit predicate is `chainsaw.PlayerCondition_CheckTargetFatal
.evaluate(PlayerActionArg) → bool`** (plus a sibling `...FatalNPC` variant) —
an ordinary behavior-tree condition node on the base `Player` class.
→ [06-investigation-log.md](06-investigation-log.md), Entry 5;
[03-execution-system.md](03-execution-system.md)

### ~~Is there an execution ID enum, and what is in it?~~

🟡 **Partially.** `chainsaw.PlayerDefine.FatalType` = `None`, `RoundKick`,
`StraightKick`, `KnifeFatal` — but it is scoped to campaign Leon's own three
finishers, not a shared cross-character registry. No neck-break-like entry
exists in it. Whether Mercenaries characters have their own equivalent is
open — see Q6b above.
→ [06-investigation-log.md](06-investigation-log.md), Entry 5
