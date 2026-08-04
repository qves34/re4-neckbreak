# Prior art

What existing mods actually do, and what that proves about what is possible.

Sorted by relevance to this project.

⚠️ **Access limitation:** Nexus Mods blocks automated requests (HTTP 403).
Everything below about mod *internals* comes from press coverage, patch notes,
and mod descriptions surfaced through search — **not** from inspecting the
mods. Where a claim matters, it is flagged as uninspected. Downloading these
and reading their file lists would settle several open questions cheaply.

---

## Directly relevant

### Classic RE5 Melee for Wesker

[Nexus 1773](https://www.nexusmods.com/residentevil42023/mods/1773)

✅ Makes Wesker **always perform** Cobra Strike, Tiger Uppercut, and Knee
Cannon.

**Why it matters:** precedent for forcing melee selection to a fixed outcome —
the *selection* sub-problem in
[04-neckbreak-decomposition.md](04-neckbreak-decomposition.md).

❓ **Uninspected.** Installs via Fluffy Mod Manager, which suggests asset-level
replacement rather than scripting. If it replaces animation files, it proves
melee appearance can be changed without touching selection logic — cheaper
than anything proposed here, but unable to address the stagger gate.

**Highest-value item to inspect.** Its file list would show whether melee
moves are individually addressable assets.

### RE4R Ultimate Trainer

[Nexus 1479](https://www.nexusmods.com/residentevil42023/mods/1479) ·
[patch notes](https://www.patreon.com/_Raz0r/posts/re4-remake-v1-3-90559183) ·
Raz0r & Dante

A REFramework Lua trainer with a Character Swap feature — the closest published
analogue to the predecessor project's approach.

✅ Described as applying **skins**, not characters.
✅ Documented as needing to be enabled **from the main menu** to avoid crashes.
✅ Documented recovery from a bad state: **enter Mercenaries and return.**

**Why it matters:** independent corroboration that identity is resolved once at
context initialisation. Change it before the player spawns; force a full
re-init to undo a bad state. Exactly what
[01-character-identity.md](01-character-identity.md) concludes from first
principles.

[REFramework issue #1522](https://github.com/praydog/REFramework/issues/1522)
reports its outfit switcher permanently locking a costume — surviving game
restarts and REFramework removal, so written into the save — and its Character
Swap checkbox crashing the game outright.

**Conclusion:** even the most widely used RE4R trainer has not solved runtime
character swapping cleanly. This is not a problem that was solved elsewhere and
merely missed.

❓ **Uninspected.** Ships as Lua, so its swap implementation may be readable.
Not on GitHub; Nexus requires login.

---

## Proves the goal is achievable — by another route

### Playable Ada With Animations

Modder Raq ·
[coverage](https://www.thegamer.com/resident-evil-4-remake-fans-ada-wong-playable-mercenaries-animations-mod/) ·
original deleted · successor:
[Definitive Playable Ada for Main Story](https://www.nexusmods.com/residentevil42023/mods/4902)

✅ Ada playable in the main campaign **with her Mercenaries moveset**.
✅ Method: injecting Mercenaries animations onto another character's skeleton.
✅ Limitation: Leon's voice work had to be removed, leaving her mute apart from
combat grunts.
✅ Limitation: some animations whiff story-mode headshot staggers.

**Why it matters most:** this is the goal of this project, achieved for a
different character — and achieved **without touching `KindID` at all**.

The character is still Leon underneath: same context, same identity, same
player logic, wearing different assets. From the player's side it is "Ada with
her moveset". From the engine's side it is Leon with replaced files.

That distinction is the crux. It means the effect is reachable while the
*mechanism* — HUNK's actual character logic — is not.

### Ultimate Wesker

[coverage](https://wccftech.com/resident-evil-4-remake-new-mod-introduces-fully-playable-wesker/)

✅ Playable in campaign and Mercenaries, with working melee animations and four
costumes.
✅ Campaign behaviour was initially worse than Mercenaries — attacks sometimes
missed. Later versions corrected the hitbox in both modes.
✅ Later versions made him an **additional selectable character in
Mercenaries**, rather than replacing Leon.
⚠️ Taken down by a Capcom DMCA, reportedly ahead of paid Wesker and Ada
content.

**Two things worth extracting:**

The **additional Mercenaries slot** is the more interesting one. Someone found
how to register a new entry in Mercenaries character selection. That is the
"find how Mercenaries performs character selection" avenue, demonstrated to be
reachable. ❓ How, is unknown.

The **campaign hitbox problems** are a warning. Even a well-executed asset-level
port behaves differently between modes. Whatever machinery differs there will
likely also affect a neck break.

**Note on the DMCA:** it targeted Wesker and Ada, who were reportedly destined
for paid content. HUNK is in the base game, so the same commercial motive does
not obviously apply.

---

## Not relevant to this goal

### HUNK cosmetic mods

[HUNK Mod (Nexus 232)](https://www.nexusmods.com/residentevil42023/mods/232)
and similar overhauls.

✅ Replace Leon's model, head, and some audio — grunts, breathing. Dialogue
remains Leon's voice.
❌ Moveset, animations, and abilities are untouched.

These are the "cosmetic reskin" the predecessor project explicitly set out to
improve on. They do not get closer to a neck break.

---

## Summary

| Question | Answer |
|---|---|
| Has anyone done a runtime `KindID` swap? | ✅ No. The most-used trainer applies skins and works around the same constraints. |
| Has anyone mapped RE4R's melee/execution system? | ✅ No. GitHub-wide search returns nothing. |
| Is a real Mercenaries moveset in the campaign achievable? | ✅ Yes — Ada and Wesker prove it, at the asset level. |
| Does that route give HUNK's *character logic*? | ❌ No. It gives his behaviour by replacing Leon's files. |
| Can a single melee move be forced? | 🟡 Apparently — the Wesker melee mod does it. Mechanism uninspected. |
| Can Mercenaries character selection be extended? | 🟡 Apparently — Ultimate Wesker added a slot. Mechanism unknown. |

**The fallback, if Variant B is confirmed:** the asset-level route is proven,
and for this project it would mean porting **one** animation rather than the
dozens the Ada mod required. That is a materially smaller job than the prior
art suggests — the Ada mod's cost was volume, not difficulty per clip.
