# Investigation log

Chronological record. Negative results are recorded in full — they are the
point of keeping a log.

Entries carry the game build where relevant. Enum values and class layouts can
shift between patches; a finding without a build is not reproducible.

---

## Entry 1 — Character swap attempted and abandoned

**Project:** [qves34/re4-hunk-mod](https://github.com/qves34/re4-hunk-mod)
**REFramework:** v1.5.9.1

### Goal

Make the player character HUNK in the main campaign by rewriting identity at
runtime.

### Attempt 1 — write `KindID` directly

```lua
player:call("set_KindID", 200009)
```

**Result:** ❌ Field changed and read back correctly. Nothing else changed —
model, animations, and gameplay all remained Leon.

**Conclusion:** ✅ `KindID` is consumed once at spawn, not observed. Writing it
late has no reactive effect.

### Attempt 2 — force body and head recreation

```lua
local context_id = player:call("get_ID")
player:call("set_KindID", 200009)
cm:call("requestCreateBody", context_id, 200009, 2, nil)
cm:call("requestCreateHead", context_id, 200009, 2)
```

**Log:**

```
[RE4 Trainer] KindID: 100000 -> requested 200009 -> now 200009
[RE4 Trainer] requestCreateBody ok=true result=7
[RE4 Trainer] requestCreateHead ok=true result=8
[RE4 Trainer] requestCreateHead ok=true result=8
```

**Result:** ❌ Both calls returned without throwing. No visible change.
**Regression:** ground item pickup stopped working, recoverable only by
reloading the save.

**Conclusions:**

- 🟡 The returned `int` is a request handle, not a success flag —
  `requestDestroyBody(int requestID)` takes exactly this value
- 🟡 Creation is deferred; the GameObject arrives via the `instantiatedEvent`
  callback, which was `nil`, so nothing wired the new body into the player's
  context
- 🟡 The orphaned body plausibly explains the broken pickup, since ground
  interaction resolves through the body's collider
- ❓ The duplicate handle `8` on two consecutive `requestCreateHead` calls is
  unexplained — deduplication, or a request that never completed

---

## Entry 2 — The `KindID` mapping was wrong

**Trigger:** the log line `KindID: 100000 -> requested 200009` contradicted
the project's own table, which claimed campaign Leon was `200000`.

The discrepancy had been recorded at the time and read as a curiosity rather
than as evidence.

### What was wrong

The mapping had been derived from **circumstantial evidence in class names** in
the `il2cpp` dump, since the dump contains no readable character names.

Cross-checked against three independent tools — see
[08-method-and-tooling.md](08-method-and-tooling.md):

| Claimed | Actual | |
|---|---|---|
| Leon = `ch1_c0z0` = 200000 | **100000** = `ch0_a0z0`; `200000` is Villager | ❌ |
| Ada = `ch1_c8z0` = 200010 | **380000**; `200010` is Brute | ❌ |
| Krauser = `ch1_b7z0` = 200011 | **200011** | ✅ |
| HUNK = `ch1_e0z0` = 200009 | `200009` is **Las Plagas** | ❌ |

**The entire `200000` range is enemies.** Both live attempts in Entry 1
therefore ran against a Las Plagas creature.

### Consequence

✅ The architectural conclusions from Entry 1 stand — they concern the API's
shape, not the character used.

❌ But they are **not** evidence that a correct-ID swap fails. That experiment
has never been run.

### How the evidence was misread

The supporting signals for "`ch1_e0z0` is HUNK" fit the corrected answer
better:

- `SyncInvincible` plus wall-move and wall-climb behavior-tree actions were
  read as HUNK's parkour. They describe a **wall-crawling insect enemy**.
- `chainsaw.Ch1e0z0SpawnParamMercenaries` was read as evidence of a playable
  Mercenaries character. ⚠️ Ordinary enemies have `Mercenaries` spawn-param
  variants too — the suffix means "also spawns in Mercenaries", nothing more.

### Corrected finding

✅ Playable Mercenaries characters occupy their own range, `600000`–`600005`
(`ch6_i0z0`–`ch6_i5z0`). `600000` is confirmed as "Leon (MC)".

🟡 Six slots, six characters in the roster, so **HUNK is one of `600001`–
`600005`**. ❓ Which one is unresolved.

### Lesson

Recorded as the reason for this repository's evidence-labelling convention:
**when observation contradicts a table built from inference, the table is
wrong.** The contradiction was visible in the very first log line.

---

## Entry 3 — Goal narrowed to the neck break

Prompted by the realisation that the objective never required *being* HUNK,
only one of his moves.

**Reframing:** `KindID` is a spawn-time constant, which is why it resisted
runtime modification. An execution is a **runtime decision**, which is a
categorically better hook target. See
[03-execution-system.md](03-execution-system.md).

**Complication raised immediately after:** the neck break must retain its
Mercenaries semantics — usable on a healthy enemy, lethal from full HP. It is
therefore not stagger-gated, which makes it a question of *gating*, not merely
of animation selection.

**Decomposition** into four sub-problems, of which lethality is already
solved: [04-neckbreak-decomposition.md](04-neckbreak-decomposition.md).

**Blocking question** identified — Variant A vs B:
[05-hypotheses-and-discriminator.md](05-hypotheses-and-discriminator.md).

---

## Entry 4 — Survey of prior art

**Finding:** ✅ No public project has mapped RE4R's melee or execution system.
A GitHub-wide code search for candidate class names returns zero results.
Speedrun tools, save editors, randomizers, and content editors have mapped
characters, items, enemies, and inventory — none has touched melee.

**Finding:** ✅ No published mod achieves a runtime character swap. The most
widely used trainer's swap applies **skins**, requires enabling from the main
menu, and documents a Mercenaries round-trip as its recovery procedure.

**Finding:** ✅ Mods that achieved a real moveset in the campaign — playable
Ada, playable Wesker — did so at the **asset level**, replacing Leon's
animations rather than swapping character identity.

**Finding:** ✅ [Classic RE5 Melee for Wesker](https://www.nexusmods.com/residentevil42023/mods/1773)
forces specific melee moves to always play, which is precedent for the
*selection* sub-problem. ❓ Its mechanism is uninspected — Nexus blocks
automated access.

Details in [07-prior-art.md](07-prior-art.md).

---

## Entry 5 — Dump searched; permit hypothesis corrected; real Fatal system found

**Game build:** RE4R `re4.exe` 1.5.9.0. **REFramework:** revision `5bae4701396248a776c1de19f5be9552022295d5`.
**Source:** local `il2cpp_dump.json` (1.03 GB), generated 2026-08-03 20:56 local time.

### Method correction

❌ **`08-method-and-tooling.md`'s claim that the dump contains no runtime
values is too strong for static literal enum fields.** Static `Literal`
fields carry a `"default"` key with the real value inline, e.g.:

```json
"WringNeck": { "default": 4, "flags": "... | Static | Literal", "type": "chainsaw.KidnappedEndAction" }
```

This was used to pull the full `chainsaw.CharacterKindID` table directly from
the static dump, with no game session:

| KindID | Codename | | KindID | Codename |
|---|---|---|---|---|
| `100000` | `ch0_a0z0` (Leon, campaign) | | `600000` | `ch6_i0z0` |
| `380000` | `ch3_a8z0` (Ada) | | `600001` | `ch6_i1z0` |
| `500000` | `ch5_j1z0` | | `600002` | `ch6_i2z0` |
|  |  | | `600003` | `ch6_i3z0` |
|  |  | | `600004` | `ch6_i4z0` |
|  |  | | `600005` | `ch6_i5z0` |

✅ Matches the previously corrected table in
[01-character-identity.md](01-character-identity.md) exactly. `600000`–`600005`
confirmed as the only Mercenaries-playable range.

⚠️ **Still true and load-bearing:** no string tables, no method bodies. Only
`static | Literal` fields carry a value at all — instance fields, non-literal
statics, and every method body remain opaque. Q2 (which of `600001`–`600005`
is HUNK) is *not* solved by this technique, because identity there is by
codename, not by a labelled constant.

### `chainsaw.ExecutionPermitter` is not the stagger gate — corrects Q5

❌ **The `EnemyAttackPermitManager` analogy was wrong.** Full signature read
from the dump:

```csharp
// chainsaw.ExecutionPermitter (AppSingleton)
bool request(chainsaw.ExecutionRequester request)
void addContext(string key, uint capacity, uint interval)
init() / update() / exit()

// chainsaw.ExecutionRequester
string Key
uint   LastFrame
bool   executable()

// chainsaw.ExecutionPermitterBehavior (attached component)
ExecutionPermitterSettings[] SettingList   // { string Key, uint Capacity, uint Interval }
```

✅ **Confirmed role: a rate limiter, not a stagger check.** It takes no
attacker/target pair at all — only a string `Key` and a frame counter. Given
the sibling `ExecutionPermitterBehavior.SettingList` of `{Key, Capacity,
Interval}` triples, this reads as "at most `Capacity` executions tagged `Key`
may start within `Interval`" — almost certainly a crowd-control throttle so
multiple staggered enemies don't all execute in sync. **This closes Q5 with a
negative result:** forcing this predicate open does not touch the stagger
requirement at all. It is the wrong hook target for Q4.

### The real generic execution system: `Fatal`, not `Execution` — resolves Q6

✅ **RE4R's internal name for the campaign's melee finisher system is
`Fatal`.** Found on the base `Player` class (i.e. campaign Leon), not on any
`Ch6i*` class:

```csharp
// chainsaw.PlayerDefine.FatalType  (enum)
None = 0, RoundKick = 1, StraightKick = 2, KnifeFatal = 4

// chainsaw.PlayerCondition_CheckTargetFatal : chainsaw.PlayerConditionBase
bool evaluate(chainsaw.PlayerActionArg arg)

// chainsaw.PlayerCondition_CheckTargetFatalNPC : chainsaw.PlayerConditionBase
bool evaluate(chainsaw.PlayerActionArg arg)

// chainsaw.PlayerBehaviorTreeAction_MFSM_RequestFatal
//   nested enum: RequestType
```

🟡 **`PlayerCondition_CheckTargetFatal.evaluate` is the actual permit
predicate**, not `ExecutionPermitter`. It is an ordinary behavior-tree
`Condition` node (`parent: chainsaw.PlayerConditionBase`), evaluated with a
`PlayerActionArg` — structurally exactly what
[04-neckbreak-decomposition.md](04-neckbreak-decomposition.md)'s step 5 needs:
a boolean gate, hookable, no state mutation. Unverified: what `PlayerActionArg`
carries (presumably includes the target), and whether `...FatalNPC` is a
separate check for non-hostile NPCs or a variant condition for enemy type.

❓ **`FatalType` only has four members and none resembles a neck break.** This
enum is declared on `PlayerDefine` — i.e. it is scoped to campaign Leon's own
three finishers (roundhouse kick, straight kick, knife fatal), **not a
character-agnostic execution registry**. This is new evidence against a clean
Variant A: there is no single shared enum that a HUNK-specific value could
slot into. It does not settle A vs B — Mercenaries characters may carry their
own private `FatalType`-equivalent — but it removes the easy version of A.

### Partial `Ch6i*` identification — updates Q2, does not resolve it

🟡 **Inferred from surviving signature abilities**, cross-checked against two
independent classes each (not yet against a third-party source — treat as
weaker than the ✅ `CharacterKindID` table):

| KindID | Codename | Signal | Read as |
|---|---|---|---|
| `600002` | `ch6_i2z0` | Own `Ch6i2z0Define` with 3 `WeaponID` fields named `BULLETRUSH_L/R/WEAPON_ID`, plus `MFSM_EquipFatalKnife`, `MFSM_EquipHookShotFatalMelee`, own `TargetSelector` | 🟡 Krauser — Bullet Rush is his signature Mercenaries ability |
| `600005` | `ch6_i5z0` | `MFSM_Atemi`, `AtemiSuccess`, `RedEye`, `DisableBulletParry`, `RequestAtemi`, own `TargetSelector`, own `Define` | 🟡 Wesker — bullet-catching parry and glowing red eyes are his signature |
| `600001` | `ch6_i1z0` | Only one unique class: `BehaviorTreeCondition_CheckFatalRandom` | ❓ Unidentified |
| `600003` | `ch6_i3z0` | **No unique `BehaviorTreeAction`/`Condition`/`Define`/`TargetSelector` class found** — only the generic `BodyUpdater`/`HeadUpdater` every character has | ❓ Unidentified |
| `600004` | `ch6_i4z0` | Same as `600003` — no unique class found | ❓ Unidentified |

⚠️ **Do not read the "no unique class" result as absence of a character.**
Roster is six: Leon (`600000`, confirmed), Luis, Krauser, HUNK, Ada, Wesker.
`600002` and `600005` are plausibly Krauser and Wesker, leaving Luis, HUNK,
and Ada across `600001`, `600003`, `600004` in unknown order.

🟡 **Speculative reading, flagged explicitly as weak:** HUNK's Mercenaries kit
has no flashy unique ability the way Krauser (Bullet Rush) and Wesker (Atemi
parry) do — his distinguishing feature *is* the neck break itself, on
otherwise ordinary weapons. A candidate with **no** discoverable
`BehaviorTreeAction`/`Define`/`TargetSelector` class under this search is
therefore not disqualifying for HUNK the way it would be for Krauser or
Wesker. This is a plausibility argument, not evidence — `600003` and `600004`
remain equally unidentified by it.

A `chainsaw.Cp1021CharacterSelectMenuActionType` enum was also found
(`Character01`…`Character06`, with `Character01` and `Character05` alone
carrying a `_01` sub-variant). This is the Mercenaries character-select UI's
own enum and is plausibly display-order-correlated with `KindID`, but the
mapping between `Cp1021CharacterSelectMenuActionType` and `CharacterKindID`
lives in game **userdata/asset resources**, not in the `il2cpp` type
structure, so it is not resolvable from this dump. ❓ Left open — see
[09-open-questions.md](09-open-questions.md) Q2.

### Net effect on the discriminator

Q1 (Variant A/B/C) is **still open**, but the search space has changed:

- The stagger-gate hook target is `PlayerCondition_CheckTargetFatal`, not
  `ExecutionPermitter` — update any future test plan accordingly.
- The generic `Fatal` system is confirmed to exist and is a plausible home
  for Variant A/C, but its known enum (`PlayerDefine.FatalType`) is Leon's
  own three-entry list, not a shared registry — a materially weaker Variant A
  than hoped.
- HUNK's `KindID` is narrowed from five candidates to three (`600001`,
  `600003`, `600004`), with a weak, explicitly-flagged lean toward `600003` or
  `600004` on the "no signature ability" argument.

### Recommended next step

Per [04-neckbreak-decomposition.md](04-neckbreak-decomposition.md)'s test
order, step 5 is now concrete and doable without touching HUNK at all: hook
`chainsaw.PlayerCondition_CheckTargetFatal.evaluate` to force-return `true`
and attempt any of Leon's existing three `FatalType` finishers on a
non-staggered enemy in campaign. This tests the gate/victim sub-problems in
isolation, on a fully generic, already-working system, before spending any
effort narrowing `600001`/`600003`/`600004` further.
