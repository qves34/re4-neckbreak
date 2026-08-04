# Character identity: `CharacterKindID`

Why the character-swap approach fails, and the corrected value table.

This document is inherited from the predecessor project
[qves34/re4-hunk-mod](https://github.com/qves34/re4-hunk-mod). It is kept here
because the identity model is still the foundation for locating HUNK's assets
and behaviour classes — even though swapping identity is no longer the goal.

---

## The model

✅ **Confirmed.** The player's identity is reached as:

```
chainsaw.CharacterManager           (managed singleton)
  └─ get_PlayerContextList()        List<chainsaw.CharacterContext>
      └─ get_Item(0)                the local player
          └─ <KindID>k__BackingField    type chainsaw.CharacterKindID
             get_KindID() / set_KindID()
```

Both a getter and a setter exist and both work — the setter accepts a write
and the getter reads the new value back.

## Why writing it does nothing

✅ **Confirmed by live test.** Setting `KindID` on a running player changes the
field and nothing else. Model, animations, and gameplay are unaffected.

🟡 **Inferred mechanism.** `KindID` is an *input* consumed once during context
initialisation, not observed state. The body and head GameObjects, motion
banks, behavior tree, colliders, and attach nodes are all resolved from it at
spawn time. Nothing watches the field afterwards, so there is no reactive path
from a late write to a model reload.

Corroborating evidence from prior art: the most widely used RE4R trainer
requires its character swap to be enabled **from the main menu**, and its
documented recovery from a bad state is to **enter Mercenaries and return** —
i.e. force a full context re-initialisation. Both behaviours are what you
would expect if identity is resolved once at spawn. See
[07-prior-art.md](07-prior-art.md).

## Why forcing body recreation also fails

`chainsaw.CharacterManager` exposes what look like purpose-built methods:

```csharp
int  requestCreateBody(chainsaw.ContextID contextID,
                       chainsaw.CharacterKindID characterKindID,
                       chainsaw.CharacterUsePurposeFlag usePurpose,
                       System.Action<(int, via.GameObject)> instantiatedEvent = null)

int  requestCreateHead(chainsaw.ContextID contextID,
                       chainsaw.CharacterKindID characterKindID,
                       chainsaw.CharacterUsePurposeFlag usePurpose)

void requestDestroyBody(int requestID)
```

✅ **Confirmed:** `chainsaw.CharacterUsePurposeFlag` has exactly three values —
`None = 0`, `Spawner = 1`, `Dynamic = 2`.

✅ **Confirmed by live test:** both calls return without throwing, and both
produce no visible change. The attempt also broke ground item pickup until the
save was reloaded.

🟡 **Inferred:** the returned `int` is a **request handle, not a success
flag** — `requestDestroyBody(int requestID)` takes exactly this value. The
incrementing handles (7, 8) plus the `instantiatedEvent` callback parameter
together indicate a **deferred instantiate**: the GameObject is created later
and delivered through that callback, which was passed as `nil`. Nothing then
wires the new body into the player's context, leaving an orphan. An orphaned
body plausibly also explains the broken pickup, since ground interaction
resolves through the body's collider.

A further oddity: a second `requestCreateHead` returned the *same* handle as
the first, suggesting either per-context deduplication or a request that never
completed. ❓ Unresolved.

## The corrected value table

The predecessor project derived its mapping from **circumstantial evidence in
class names**, because the dump contains no readable character names. That
mapping was wrong.

✅ **Confirmed** against three independent public tools that dump the enum
properly — see [08-method-and-tooling.md](08-method-and-tooling.md) for the
sources.

### Campaign and enemies

| KindID | Identity |
|---|---|
| `100000` | `ch0_a0z0` — **Leon, main campaign** |
| `110000` | Ashley |
| `200000` | Villager |
| `200001` | Zealot |
| `200002` | Island Ganado |
| `200003` | Salvador |
| `200004` | Colmillos |
| `200005` | Novistador |
| `200006` | El Gigante |
| `200007` | Del Lago |
| `200008` | Garrador |
| `200009` | **Las Plagas** ("Plagas Insect") |
| `200010` | Brute |
| `200011` | Krauser |
| `200012` | Regenerador |
| `380000` | Ada |

**The entire `200000` range is enemies.** The predecessor project sent
`200009` believing it was HUNK; it is a Las Plagas creature.

### Mercenaries playable characters

| KindID | Codename |
|---|---|
| `600000` | `ch6_i0z0` — ✅ labelled **"Leon (MC)"** by RE-Editor's name table |
| `600001` | `ch6_i1z0` |
| `600002` | `ch6_i2z0` |
| `600003` | `ch6_i3z0` |
| `600004` | `ch6_i4z0` |
| `600005` | `ch6_i5z0` |

🟡 **Inferred:** six slots, and the RE4R Mercenaries roster is exactly six
characters — Leon, Luis, Krauser, HUNK, plus Ada and Wesker from the Separate
Ways update. With `600000` confirmed as Leon, **HUNK is one of `600001`–
`600005`**.

❓ **Unknown:** which one. This must be resolved before any search for HUNK's
behaviour classes, because those classes are named after his codename.

## The tell that was missed

The predecessor project's own log said:

```
[RE4 Trainer] KindID: 100000 -> requested 200009 -> now 200009
```

`100000` is correct campaign Leon. The project's table claimed Leon was
`200000`. The discrepancy was recorded and read as a curiosity rather than as
evidence the table was wrong.

**Lesson, and the reason for this repository's evidence-labelling
convention:** when observation contradicts a table built from inference,
the table is what is wrong.

## Reading the enum properly

Do not hardcode any of the above. `chainsaw.CharacterKindID` is a managed
enum; its members are static fields readable from the live type database:

```lua
local function GetEnumMap(enumTypeName)
    local t = sdk.find_type_definition(enumTypeName)
    if not t then return {} end

    local enum = {}
    for i, field in ipairs(t:get_fields()) do
        if field:is_static() then
            enum[field:get_data(nil)] = field:get_name()
        end
    end
    return enum
end
```

Technique from [str0mback/RE4_Overlay](https://github.com/str0mback/RE4_Overlay).
`scripts/dump_enums.lua` in this repository packages it for any enum type.

Values may shift between game patches, and the tables above come from
third-party tools tracking their own builds. **Verify on your build first.**
