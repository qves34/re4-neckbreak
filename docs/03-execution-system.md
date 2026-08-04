# The execution system

What is known about RE4R's melee finishers, and — mostly — what isn't.

---

## Observable behaviour

From playing the game, not from code. ✅ Reliable as description, but it says
nothing about implementation.

**Campaign melee is stagger-gated.** The sequence is:

1. Player damages an enemy in a specific way — headshot, leg shot, certain
   knife hits
2. Enemy enters a **stagger** state
3. A contextual prompt appears
4. Player presses it, and an execution plays — roundhouse kick, suplex, knife
   finisher, and so on

Which execution plays is not chosen by the player. It is selected from
context: which character, which enemy type, what staggered them, relative
position and orientation, possibly enemy remaining health.

**That selection is a runtime decision**, and that is the single most
encouraging fact available. A decision made every time an execution triggers
is a hookable point, structurally unlike `KindID`, which is a constant read
once at spawn. The character-swap approach failed because it tried to change a
constant; this approach targets a decision.

**Mercenaries neck break is not stagger-gated.** HUNK can perform it on an
undamaged enemy, and it kills from full HP. Everything hard about this project
follows from that one difference.

---

## What has been located

### `chainsaw.ExecutionPermitter` — ❌ not the stagger gate

✅ **Confirmed to exist, full signature now read from the dump** (local
`il2cpp_dump.json`, RE4R 1.5.9.0, see
[06-investigation-log.md](06-investigation-log.md) Entry 5):

```csharp
// AppSingleton<ExecutionPermitter>
bool request(chainsaw.ExecutionRequester request)
void addContext(string key, uint capacity, uint interval)

// chainsaw.ExecutionRequester
string Key
uint   LastFrame
bool   executable()

// chainsaw.ExecutionPermitterBehavior — attached component
ExecutionPermitterSettings[] SettingList   // { string Key, uint Capacity, uint Interval }
```

❌ **The `EnemyAttackPermitManager` analogy from the earlier draft of this
document was wrong.** `request()` takes no attacker/target pair — only a
string `Key` and a frame counter. Paired with `SettingList`'s `{Key, Capacity,
Interval}` triples, this is a **rate limiter**: at most `Capacity` executions
tagged `Key` may start within `Interval`, plausibly to stop a crowd of
staggered enemies all executing in sync. It says nothing about whether *this*
target is eligible for *an* execution — only how many of a given kind may run
concurrently.

**Do not use this as the gate hook.** See below for the real one.

### `chainsaw.PlayerCondition_CheckTargetFatal` — the actual permit predicate

✅ **Confirmed signature**, found under `chainsaw.Player*` rather than a
manager singleton:

```csharp
// chainsaw.PlayerCondition_CheckTargetFatal : chainsaw.PlayerConditionBase
bool evaluate(chainsaw.PlayerActionArg arg)

// chainsaw.PlayerCondition_CheckTargetFatalNPC : chainsaw.PlayerConditionBase
bool evaluate(chainsaw.PlayerActionArg arg)
```

🟡 **Inferred role:** an ordinary behavior-tree `Condition` node — the kind
evaluated every tick as part of the tree that decides whether the "fatal"
(RE4R's internal name for execution — see below) branch is reachable. This
matches the shape [04-neckbreak-decomposition.md](04-neckbreak-decomposition.md)
asked for: a boolean predicate, hookable in isolation, no state mutation.

❓ **Unverified:** the contents of `PlayerActionArg` (presumably carries the
target), and whether `...FatalNPC` is a distinct check for non-hostile NPCs or
an alternate condition for a different enemy category.

### The generic system is called `Fatal`, not `Execution`

✅ Found on the base `Player` class (i.e. campaign Leon):

```csharp
// chainsaw.PlayerDefine.FatalType (enum)
None = 0, RoundKick = 1, StraightKick = 2, KnifeFatal = 4

// chainsaw.PlayerBehaviorTreeAction_MFSM_RequestFatal
//   nested enum: RequestType
```

❓ **This is Leon's own three-entry list, not a shared registry.** `FatalType`
is declared on `PlayerDefine`, scoped to the base player character. There is
no evidence (yet) of a single character-agnostic execution ID enum that a
HUNK-specific value could be added to — this weakens the easy version of
Variant A. Mercenaries characters may carry their own private
`FatalType`-equivalent instead of sharing this one; unconfirmed.

---

## What has not been located

❓ None of the following has a confirmed name:

| Missing piece | Why it is needed |
|---|---|
| Execution **selector** method | To force the neck break specifically |
| **Victim-side** transition | To pull a healthy enemy into the animation |
| Animation **residency** rules | To know whether HUNK's clip exists in campaign memory |
| Mercenaries-character-specific `Fatal`-equivalent | To know if `600001`/`600003`/`600004` share `PlayerDefine.FatalType` or have their own |

A GitHub-wide code search across every public repository for RE4R melee and
execution class names returns **zero results**. Speedrun tools, save editors,
randomizers, and content editors have all mapped characters, items, enemies,
and inventory — none has touched the melee system.

This means no shortcuts, and it also means the dump is the only source.

---

## Why executions might be reachable when identity is not

Worth stating plainly, because it is the premise of the whole project.

| | `KindID` swap | Execution override |
|---|---|---|
| What it targets | A constant, read once at spawn | A decision, made per event |
| Timing | Must happen before context init | Any time the event fires |
| Requires object surgery | Yes — body/head recreation, context rewiring | No |
| Failure mode | Orphaned GameObjects, broken interactions, save reload | The hook returns a value the game ignores |
| Recoverable | Only by reloading a save | Toggle the hook off |

The second column is a fundamentally safer experiment. Failed attempts should
not corrupt the running session, which makes iteration cheap — the exact
opposite of the character-swap work, where each attempt cost a save reload and
discouraged experimentation.

🟡 This is a prediction, not a measurement. It assumes the execution system
does not itself perform object surgery. If forcing an unpermitted execution
puts an enemy into an invalid state, iteration may be no cheaper. Test with
this in mind.

---

## Prior art on forcing a specific melee

[Classic RE5 Melee for Wesker](https://www.nexusmods.com/residentevil42023/mods/1773)
makes Wesker **always perform** Cobra Strike, Tiger Uppercut, and Knee Cannon.

✅ Confirmed the mod exists and is described that way. "Always perform"
implies the selection can be forced to a fixed outcome — precisely the
capability this project needs for the *selection* sub-problem.

❓ **Unverified:** whether it overrides selection logic or simply replaces the
animation files. It installs through Fluffy Mod Manager, which suggests
asset-level replacement rather than scripting. Nexus blocks automated access,
so the archive contents have not been inspected.

**Worth doing:** download it and look at the file list. If it is asset
replacement, it tells us animation swapping alone can change which move
appears — a cheaper mechanism than anything discussed here, though one that
cannot address the stagger gate. See
[07-prior-art.md](07-prior-art.md).
