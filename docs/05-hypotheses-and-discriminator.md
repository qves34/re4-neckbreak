# Hypotheses and the discriminator

One question determines whether this project is feasible. This document states
it precisely and describes the test.

---

## The fork

### Variant A — generic execution

The neck break is an ordinary entry in RE4R's execution system. It has an ID
in an execution enum, an animation, and a permit condition that happens to be
laxer than other executions' — no stagger required.

**If A holds**, the project is tractable:

- Hook the permit predicate to bypass the stagger gate
- Hook the selector to force the neck break's ID
- Reuse the existing damage hook for lethality
- Remaining risk is animation residency and the victim-side transition

**Consequences of A being true:** HUNK's uniqueness is *data* — a permissive
permit condition attached to one execution — rather than *code*. Which would
mean nothing about the move is intrinsically tied to being HUNK, and a Leon
who is permitted to use it would behave identically.

### Variant B — HUNK-only behavior-tree action

The neck break is implemented as an action on HUNK's behavior tree, something
like `Ch6i<N>z0BehaviorTreeAction_NeckBreak`, bound to his player controller
and reachable only through it.

**If B holds**, the runtime approach is dead. There is no generic execution to
select and no permit predicate to relax, because the move is not part of that
system at all. Getting it would require HUNK's character logic — the exact
problem the predecessor project failed to solve, and which
[01-character-identity.md](01-character-identity.md) argues is not solvable by
runtime identity rewriting.

The remaining route under B is **asset-level replacement of Leon**: the
technique used by the playable Ada and Wesker mods. See
[07-prior-art.md](07-prior-art.md).

---

## Which is more likely

🟡 **Variant B**, on current evidence — though the evidence is weak and
entirely circumstantial.

The argument: Capcom appears to implement signature abilities as behavior-tree
actions rather than as data entries in generic systems. The clearest example
is Ada's crossbow, which exists as
`Ch1c8z0BehaviorTreeAction_ShootCrossBowBolt` and a matching
`ShootCrossbowBoltTrack` — a defining weapon expressed as a per-character
action class, not as an entry in a weapon table.

Wall-move and wall-climb behaviours are likewise expressed as behavior-tree
actions on the characters that have them.

If that pattern is consistent, a signature melee is more likely to follow it
than to be a generic execution.

**Counter-argument, and it is not weak:** the neck break *is* a melee finisher
in form — a synchronised two-actor animation ending in a kill, structurally
identical to the campaign's suplex and kick executions. Building it twice, once
as an execution and once as a behavior-tree action, would be wasteful. The
victim-side machinery in particular is expensive and already exists. A designer
wanting a non-stagger-gated finisher would more plausibly reuse the execution
system with a different permit condition than reimplement it.

There is also a middle possibility worth naming:

### Variant C — hybrid

The **trigger** is a HUNK-only behavior-tree action, but it invokes the
**generic execution machinery** to actually run the move. The action decides
*when*; the execution system handles *what* and the victim-side transition.

Under C, the execution ID and victim machinery are reachable, but the trigger
is not — so a Leon could be made to perform the move by driving the execution
system directly, bypassing the behavior-tree action entirely. This would be
the best realistic outcome: the hard part (victim transition) is generic, and
only the trigger needs reimplementing.

🟡 C is speculation with no supporting evidence beyond plausibility.

---

## The discriminator

The `il2cpp` dump answers this without a game session.

**Test:** search the dump for the neck break. Then ask *where it lives*.

| Finding | Verdict |
|---|---|
| An execution ID enum containing a neck-break-like entry, and no HUNK-specific class for it | **A** |
| A `Ch6i<N>z0BehaviorTreeAction_*` class for it, and no generic execution entry | **B** |
| Both — a HUNK action class *and* a generic execution entry | **C** |
| Neither, after a thorough search | ❓ Search was wrong; see below |

### Prerequisite

The search depends on knowing HUNK's codename, since his classes are named
after it. Resolve his `KindID` first — `600001`–`600005`, see
[01-character-identity.md](01-character-identity.md) — then search for
`Ch6i<N>z0*`.

Until that is pinned, search all five prefixes. Five is a small number.

### Search terms

Start broad, because the internal vocabulary is unknown:

```
ExecutionPermitter          Execution
Neck                        Break
Ch6i0z0  Ch6i1z0  Ch6i2z0  Ch6i3z0  Ch6i4z0  Ch6i5z0
BehaviorTreeAction
Melee
```

⚠️ Do not assume the internal name resembles "neck break". Capcom's naming
runs to codenames and abbreviations, and no literal `"HUNK"` string exists in
the dump at all. If direct terms fail, enumerate every
`Ch6i<N>z0BehaviorTreeAction_*` class and read the list — the move will be
identifiable by elimination against his other abilities.

### If the search finds nothing

❓ A null result does not settle the question. It more likely means the search
vocabulary was wrong. Fall back to enumerating **all** classes matching HUNK's
codename prefix and reading them, rather than concluding the move is absent.

---

## Recording the answer

Whichever variant is confirmed, record it in
[06-investigation-log.md](06-investigation-log.md) with the exact class names
found and the dump's game build. A confirmed **B** is a valuable negative
result: it closes the runtime approach definitively and redirects effort to
the asset-level route, which is known to work.
