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

### `chainsaw.ExecutionPermitter`

✅ **Confirmed to exist.** Listed among the game's singletons in
[str0mback/RE4_Overlay](https://github.com/str0mback/RE4_Overlay)'s header
notes.

🟡 **Inferred role:** the gate deciding whether an execution is permitted
right now. The name is unusually direct — a class whose only job is permitting
executions is exactly the component a non-stagger-gated move must bypass.

🟡 **Inferred shape.** The same source documents a sibling manager:

```csharp
chainsaw.EnemyAttackPermitManager.AttackPermitResult
    checkAttackPermit(chainsaw.CharacterContext attacker,
                      chainsaw.CharacterContext target)
```

A `check…Permit(attacker, target) → Result` predicate. Codebases are
internally consistent, so `ExecutionPermitter` plausibly exposes something
similar. If it does, it is close to an ideal hook target: a predicate,
receiving both parties, whose return value can be overridden in a pre-hook
without touching any object state.

❓ **Unverified:** every word of the two paragraphs above beyond the class
existing. No method names, no signature, no confirmation it is even involved
in player executions rather than enemy ones.

---

## What has not been located

❓ None of the following has a confirmed name:

| Missing piece | Why it is needed |
|---|---|
| Execution **ID enum** | To know what to force |
| Execution **selector** method | To force it |
| Permit **predicate** | To bypass the stagger requirement |
| **Victim-side** transition | To pull a healthy enemy into the animation |
| Animation **residency** rules | To know whether HUNK's clip exists in campaign memory |

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
