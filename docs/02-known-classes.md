# Known classes and signatures

Every `chainsaw.*` type collected so far, with provenance. This is the working
reference — extend it as the dump is searched.

Existence of a class name is ✅ confirmed. Its **purpose** is 🟡 inferred from
naming unless a live test is cited.

---

## Confirmed signatures

These have full signatures, either from an `il2cpp` dump or from another
project's working code.

### `chainsaw.CharacterManager` (singleton)

```csharp
List<chainsaw.CharacterContext> get_PlayerContextList()

int  requestCreateBody(chainsaw.ContextID contextID,
                       chainsaw.CharacterKindID characterKindID,
                       chainsaw.CharacterUsePurposeFlag usePurpose,
                       System.Action<(int, via.GameObject)> instantiatedEvent = null)

int  requestCreateHead(chainsaw.ContextID contextID,
                       chainsaw.CharacterKindID characterKindID,
                       chainsaw.CharacterUsePurposeFlag usePurpose)

void requestDestroyBody(int requestID)
```

Source: predecessor project's `il2cpp` dump. Behaviour notes in
[01-character-identity.md](01-character-identity.md).

### `chainsaw.EnemyAttackPermitManager` (singleton)

```csharp
chainsaw.EnemyAttackPermitManager.AttackPermitResult
    checkAttackPermit(chainsaw.CharacterContext attacker,
                      chainsaw.CharacterContext target)
```

Source: [str0mback/RE4_Overlay](https://github.com/str0mback/RE4_Overlay)
header notes.

🟡 **Why this matters here:** this is a *permit manager* with a
`check…Permit(attacker, target) → Result` shape. If `chainsaw.ExecutionPermitter`
follows the same convention — and manager classes in one codebase usually do —
then the execution gate is a hookable predicate taking both parties, which is
exactly the shape needed to force an execution on a non-staggered enemy. See
[03-execution-system.md](03-execution-system.md).

### `chainsaw.CharacterUsePurposeFlag` (enum)

```
None = 0, Spawner = 1, Dynamic = 2
```

### `chainsaw.Item`

```csharp
void reduceCount(...)
```

✅ Confirmed working hook target. All ammunition, thrown weapons, and knife
durability route through it — skipping the original call yields infinite ammo
and durability.

### `chainsaw.HitController`

```csharp
callbackCalculateDamageByAttacker(...)
```

✅ Confirmed working hook target. The damage object is argument 3; its
`<Damage>k__BackingField` can be read and rewritten in a pre-hook.

**Directly relevant to this project** — this is a solved instant-kill
primitive. See [04-neckbreak-decomposition.md](04-neckbreak-decomposition.md).

### `chainsaw.CharacterContext`

```csharp
chainsaw.CharacterKindID get_KindID() / set_KindID(v)
chainsaw.ContextID       get_ID()          // inherited from chainsaw.Context
```

Also carries `<HitPoint>k__BackingField`, whose object exposes
`get_DefaultHitPoint`, `set_CurrentHitPoint`, `set_NoDeath`.

---

## Confirmed to exist, purpose unverified

Singletons enumerated in
[str0mback/RE4_Overlay](https://github.com/str0mback/RE4_Overlay)'s header
notes. Names only — no signatures yet.

| Class | 🟡 Presumed role | Priority |
|---|---|---|
| **`chainsaw.ExecutionPermitter`** | **Gates whether a melee execution is allowed** | 🔴 **Highest — the central unknown** |
| `chainsaw.EnemyManager` | Enemy registry | Medium — needed for target state |
| `chainsaw.PlayerManager` | Player registry | Medium |
| `chainsaw.GameSituationManager` | Global situation/mode state | Medium — may distinguish campaign from Mercenaries |
| `chainsaw.CharacterBackup` | Save/restore of character state | Low |
| `chainsaw.EnemyDropPartsManager` | Dismemberment | Low |
| `chainsaw.DynamicsSystem` | Physics | Low |
| `chainsaw.DropItemManager` | Item drops | Low |
| `chainsaw.GameRankSystem` | Adaptive difficulty | Low |
| `chainsaw.GameStatsManager` | Statistics | Low |
| `chainsaw.MaterialGroupManager` | Surface materials | Low |
| `chainsaw.MaterialZoneManager` | Surface material zones | Low |
| `chainsaw.MovieManager` | Cutscene playback | Low |
| `chainsaw.SoundDetectionManager` | Enemy hearing | Low |
| `chainsaw.HitPoint` | Health object | Already used |

## Character classes

Pattern-level observations, ✅ confirmed to exist:

| Pattern | Example | Note |
|---|---|---|
| `Ch<code>Context` | `Ch1e0z0Context` | Per-character context subclass |
| `Ch<code>SpawnParam` | `Ch1e0z0SpawnParam` | Level-placement parameters |
| `Ch<code>SpawnParamMercenaries` | `Ch1e0z0SpawnParamMercenaries` | ⚠️ Means "also spawns in Mercenaries", **not** "playable" |
| `Ch<code>HeadUpdater` | `Ch1b7z0HeadUpdater` | Contains e.g. `KrauserDamage01Hash` — how Krauser was confirmed |
| `Ch<code>BehaviorTreeAction_<Name>` | `Ch1c8z0BehaviorTreeAction_ShootCrossBowBolt` | **Signature abilities appear to live here** |

The last row is the basis of Variant B in
[05-hypotheses-and-discriminator.md](05-hypotheses-and-discriminator.md).
Ada's crossbow — her defining weapon — is a behavior-tree action rather than a
generic weapon entry. If Capcom structures signature abilities that way
consistently, HUNK's neck break is likely one too.

A larger `Ch*SpawnParam` inventory is visible in
[kagenocookie/REE-Content-Editor](https://github.com/kagenocookie/REE-Content-Editor),
`ContentEditor.App/EngineObjects/GameSpecific/RE4/RE4CharacterSpawnParam.cs`.

---

## Not yet located

❓ Everything below is needed and has **no confirmed class name**:

- An execution/melee **ID enum**
- The method that **selects** which execution plays
- The **permit predicate** inside `ExecutionPermitter`
- The **victim-side** transition that pulls an enemy into a synchronised
  execution animation
- Any HUNK-specific action classes (blocked on resolving his codename — see
  [09-open-questions.md](09-open-questions.md))

Searching for these is the immediate next task. Suggested search terms are in
[08-method-and-tooling.md](08-method-and-tooling.md).

⚠️ Note that a GitHub-wide code search for RE4R melee and execution class
names returns **nothing**. No public project appears to have mapped this
system. Expect to be first, and expect no shortcuts.
