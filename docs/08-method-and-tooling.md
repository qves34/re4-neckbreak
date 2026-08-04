# Method and tooling

How findings here are produced, and how to verify them.

---

## Setup

- [REFramework](https://github.com/praydog/REFramework) for RE4 Remake —
  `dinput8.dll` plus a `reframework/` folder beside `re4.exe`
- Lua scripts go in `reframework/autorun/` and load at game start
- **Insert** opens the overlay; scripts appear under **Script Generated UI**
- Predecessor project tested against REFramework **v1.5.9.1**

---

## The il2cpp dump

Insert → Developer Tools → **Generate SDK**. Produces JSON listing every
class, field, and method the managed runtime exposes.

### What it contains

✅ Class names, field names and types, method names and signatures, enum member
names, inheritance.

### What it does not contain

❌ **Runtime values** — including enum member values
❌ **String tables** — no readable character or move names
❌ **Method bodies** — no logic, no control flow

**This limitation caused the project's one significant error.** Character
identity is expressed entirely as codenames like `ch0_a0z0`; no literal
`"HUNK"` string exists anywhere. The predecessor project therefore inferred a
character-to-ID mapping from surrounding class names, and got it wrong. See
[06-investigation-log.md](06-investigation-log.md), Entry 2.

**Rule:** the dump tells you what *exists*. It does not tell you what things
*are*, and it never tells you what values they hold.

---

## Reading enum values from the running game

The correct source for any enum value. Members are static fields on the type,
readable from the live type database:

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

`scripts/dump_enums.lua` packages this for arbitrary enum types and writes
results to the REFramework log. **Run it before trusting any table in this
repository**, including the verified ones — values can shift between patches.

---

## Searching the dump

The dump is large. Suggested approach:

1. **Search broadly first.** The internal vocabulary is unknown; do not assume
   a move is named anything like its English name.
2. **Enumerate by prefix when direct search fails.** Every class belonging to a
   character shares its codename prefix. Listing all
   `Ch6i3z0*` classes and reading them is more reliable than guessing at
   move names.
3. **Note both the name and its neighbours.** Sibling classes carry most of the
   signal — `Ch1b7z0HeadUpdater` containing `KrauserDamage01Hash` is how
   Krauser was confirmed.
4. **Record the game build** with any finding.

### Current search targets

```
ExecutionPermitter          Execution
Neck                        Break
Melee
BehaviorTreeAction
Ch6i0z0  Ch6i1z0  Ch6i2z0  Ch6i3z0  Ch6i4z0  Ch6i5z0
```

Purpose and interpretation:
[05-hypotheses-and-discriminator.md](05-hypotheses-and-discriminator.md).

---

## Live inspection

**ObjectExplorer** (Insert menu) browses live managed objects. Useful for
confirming that a field found in the dump exists on a running object and holds
what you expect — the step that would have caught the `KindID` error
immediately.

For the player specifically:

```
chainsaw.CharacterManager → PlayerContextList → item 0
```

---

## Cross-checking sources

Public projects that dump or map RE4R data. Used to verify the corrected
`CharacterKindID` table in
[01-character-identity.md](01-character-identity.md), and useful for future
cross-checks.

| Project | What it provides |
|---|---|
| [SpeedrunTooling/SRTPluginProviderRE4R](https://github.com/SpeedrunTooling/SRTPluginProviderRE4R) | `Structs/Enums.cs` — `CharacterKindID` with named characters, plus `ItemID` |
| [hntd187/re-speedrun-overlay](https://github.com/hntd187/re-speedrun-overlay) | `src/enums.h` — ID-to-codename map, independent of the above |
| [Synthlight/RE-Editor](https://github.com/Synthlight/RE-Editor) | Codename-to-display-name mapping; the source for `ch6_i0z0` = "Leon (MC)" |
| [kagenocookie/REE-Content-Editor](https://github.com/kagenocookie/REE-Content-Editor) | `RE4CharacterSpawnParam.cs` — broad `Ch*SpawnParam` inventory |
| [str0mback/RE4_Overlay](https://github.com/str0mback/RE4_Overlay) | Working REFramework Lua; singleton list, `GetEnumMap` technique |
| [biorand/re4r](https://github.com/biorand/re4r) | Randomizer; enemy and item data handling |
| [alphazolam/EMV-Engine](https://github.com/alphazolam/EMV-Engine) | General RE Engine Lua tooling and console |

⚠️ **None of these maps the melee or execution system.** A GitHub-wide code
search for candidate class names returns zero results. For this project's core
question, the dump is the only source.

**Cross-check anything important against at least two.** The corrected
`CharacterKindID` table agrees across three, which is why it is marked ✅.

---

## Conventions for recording findings

1. Label evidence ✅ / 🟡 / ❓ per [00-glossary.md](00-glossary.md)
2. Cite the source: repository path, log line, or live test
3. Record the game build and REFramework version
4. Record negative results — a documented failure is worth more than an
   untested idea
5. When observation contradicts a table, the table is wrong
