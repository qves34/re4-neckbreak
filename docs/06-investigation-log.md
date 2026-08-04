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

## Next entry

The next entry should record the Variant A / B / C determination. Until then,
this project has no findings of its own — only inherited ones.
