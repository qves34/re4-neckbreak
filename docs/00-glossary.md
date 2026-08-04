# Glossary and conventions

## Evidence labelling

Every factual claim in this repository carries one of three labels. This is
not decoration — the predecessor project failed because an inference was
recorded as a fact and then trusted.

| Label | Meaning | Requirement |
|---|---|---|
| ✅ **Confirmed** | Verified against a named, checkable source | Must cite the source: a tool, a repository path, a log line, or a live test |
| 🟡 **Inferred** | Reasoning from naming, structure, or analogy | Must state what the reasoning is, so it can be attacked |
| ❓ **Unknown** | Open question | Should state what evidence would resolve it |

A class name appearing in an `il2cpp` dump is ✅ confirmed to *exist*. What it
*does* is 🟡 inferred until observed at runtime. These are different claims
and must not be collapsed.

## Terms

**REFramework** — praydog's mod loader and Lua scripting platform for RE
Engine games. Provides access to the managed type system: hooking methods,
traversing objects, reading and writing fields, calling engine functions.

**il2cpp dump / SDK dump** — JSON produced by REFramework (Insert → Developer
Tools → Generate SDK) listing every class, field, and method the managed
runtime exposes. **Structural metadata only.** No runtime values, no string
tables, no method bodies.

**Managed object** — an object in the game's .NET-style runtime, reachable
from Lua through REFramework's bindings.

**Singleton** — a manager object retrieved with
`sdk.get_managed_singleton("chainsaw.Foo")`. Most game systems are exposed
this way.

**Context** — the game's per-entity state object. `chainsaw.CharacterContext`
holds a character's identity, health, and references to its body and head.
The player is `CharacterManager → PlayerContextList[0]`.

**ContextID** — an entity handle, obtained via the base `chainsaw.Context`
method `get_ID()`.

**KindID** — a character's identity, typed `chainsaw.CharacterKindID`. An
enum whose members are internal codenames. See
[01-character-identity.md](01-character-identity.md).

**Execution** — RE4R's prompted melee finisher (the contextual kick, suplex,
knife finisher). Normally gated on the target being staggered.

**Stagger** — the enemy state entered after a head or leg hit, during which
an execution prompt appears. Also a state-machine state, not merely a visual
effect — this matters, see
[04-neckbreak-decomposition.md](04-neckbreak-decomposition.md).

**Neck break** — HUNK's signature melee in Mercenaries. Kills instantly and,
critically, **does not require the target to be staggered**.

**Behavior tree** — the engine's per-character AI/action structure. Classes
follow the pattern `Ch<codename>BehaviorTreeAction_<Name>`. Signature
character abilities appear to be implemented here, which is the basis of
Variant B in [05-hypotheses-and-discriminator.md](05-hypotheses-and-discriminator.md).

## Codename scheme

Characters are identified internally by codenames, never by readable names —
no literal `"HUNK"` string exists anywhere in the dump.

The format is `ch<N>_<letter><digit>z<digit>`, e.g. `ch0_a0z0`, `ch6_i3z0`.
In class names the underscore is dropped and the parts are capitalised:
`ch1_e0z0` becomes `Ch1e0z0Context`, `Ch1e0z0SpawnParam`.

The leading group appears to partition the roster:

| Prefix | Contents | Evidence |
|---|---|---|
| `ch0_` | Campaign player characters | ✅ `ch0_a0z0` = campaign Leon |
| `ch1_` | Enemies | ✅ Values map into the 200000 range, which is enemies |
| `ch2_`, `ch4_` | Further enemies and bosses | ✅ Present in verified value tables |
| `ch6_` | **Mercenaries playable characters** | ✅ `ch6_i0z0` labelled "Leon (MC)" |
| `ch8_` | Animals and props | ✅ Pig, Cow, Dog, Black Bass |

⚠️ A `Mercenaries` suffix on a class (`Ch1e0z0SpawnParamMercenaries`) means
"this entity also spawns in Mercenaries mode". It does **not** mean the entity
is a playable Mercenaries character. Ordinary enemies have these too. This
was a false signal that misled the predecessor project.

## Notation

- `chainsaw.Foo` — a managed type
- `Foo:call("bar")` — REFramework Lua method invocation
- `<Foo>k__BackingField` — compiler-generated backing field for a property
  `Foo`, readable with `get_field` when no getter is convenient
