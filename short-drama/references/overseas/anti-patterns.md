# Anti-Patterns — Domestic Carryover Failures & Known Bad Patterns

> Read when reviewing outlines or diagnosing quality issues.
> Source: B6 failure cases + v1.11.0 cleanup report + prefix protocol禁词表

---

## Prohibited Terminology (L4 Pollution Defense)

The following terms trigger Hollywood feature film structure priors in LLMs. Their use causes drift away from the 4-Phase 20-beat romance structure. GREP output for these before finalizing any structural document.

### Hard Banned

| Chinese | English |
|---------|---------|
| 三幕 / 三幕剧 | three-act / three act |
| 第一幕 / 第二幕 / 第三幕 | act one / act two / act three / Act I / Act II / Act III |
| 开端-发展-高潮 | setup-confrontation-resolution |
| 铺垫-冲突-结局 | (same structure, Chinese variant) |

### Alert-Level (not banned, but must verify Beat mapping first)

Save the Cat family terms that are Hollywood feature film variants: `catalyst` / `break into 2` / `midpoint` / `all is lost` / `dark night of the soul` / `break into 3` / `finale` / `B story`

**Before using any alert-level term**: Confirm it maps to a specific Gwen Hayes Beat number. If it doesn't map cleanly → treat as banned.

**Correct alternatives**: Always use Phase 1-4 + Beat 1-20 terminology. When referencing a plot point, anchor to "Beat 13 Retreat" not "mid-point crisis" or "second act climax."

---

## 5 C-Drama Red Flags (from B5 §五)

These are plot mechanisms that Chinese screenwriters default to but English mafia romance readers will reject.

### Red Flag 1: Lab-Report Misunderstanding Engine
**Pattern**: Fatal toxin + wrong blood report → drives 10 episodes of misunderstanding
**Why it fails**: English audiences consider lab-report reveals "Grey's Anatomy cheap" since ~2010
**Replacement**: Identity misrecognition beats — she thinks he's the informant because they share a tattoo; he thinks she's undercover because she accessed a specific file

### Red Flag 2: Aphrodisiac / Cold Medicine Mix-Up
**Pattern**: Chemical substance accidentally causes intimacy
**Why it fails**: English dark romance's intimacy is gated by "choice under pressure." Chemical accident = dubcon-without-payoff = Goodreads 1-star
**Replacement**: Delete entirely. Use forced proximity (safe house with one bed / hiding from pursuit / power outage in storm shelter)

### Red Flag 3: 追妻火葬场 Without English Grovel Grammar
**Pattern**: Male public humiliation → female cold indifference → male grovels with flowers/gifts
**Why it fails**: English readers have specific grovel expectations
**Required grammar**: ① He does what she always asked but he refused ② He gives up what he swore never to give up ③ He chooses her over family at literal gunpoint
**Treatment**: Keep the arc, rewrite every beat to English grovel grammar

### Red Flag 4: 下克上 Without English Power Mapping
**Pattern**: Young subordinate overthrows patriarch
**Status**: Clean transfer IF mapped to Tommy Shelby (Peaky Blinders S1-2) "young capo rising" model
**Danger zone**: If the power dynamics rely on audience understanding Chinese hierarchy (入赘/血脉) → fails

### Red Flag 5: Good Girl → Mafia Queen Without Moral Turning Point
**Pattern**: Female lead "becomes powerful" but never makes a morally irreversible choice
**Why it fails**: Without a "moral turning point episode" she's just "a sad girl in a nice dress" — the classic 霸总 failure mode
**Required**: One episode where she orders a hit / approves torture / chooses family over civilian friend. This is the point of no return that makes the transformation real.

---

## Cross-Case Failure Patterns (from B6)

### Pattern 1: Male-frequency content is DOA overseas
2023-2024 data: 赘婿/战神/都市玄幻 genres had **100% failure rate** across DramaBox / ShortMax / FlexTV / GoodShort. Four independent Chinese media outlets confirmed "做一部扑一部" (every single one flopped).

Root cause: Not execution quality — **genre mismatch**. Chinese male-frequency satisfaction arc (humiliation → power reversal) has no cultural equivalent in Western audiences. Meanwhile, female-frequency (霸总/狼人/复仇) ran successfully in the same period.

**Implication**: Mafia romance is FEMALE-FREQUENCY content (female POV watching dangerous male lead). It's a tailwind genre, not headwind. This genre direction is fundamentally correct for English-language vertical drama.

### Pattern 2: Legal/IP exposure is the #1 killer
ReelShort plagiarism scandal (2025-07): scene-for-scene copies of Chinese originals flagged by DramaBox parent company + two more studios. 8 titles flagged, only 3 removed, legal unresolved.

**Implication**: The habit of "take a Chinese hit and translate it" is a legal time bomb in Western jurisdictions. This skill must generate **original content** — not adaptations of Chinese IPs, not echoes of English IPs.

### Pattern 3: AI-generated drama quality collapse
127,800 AI short dramas → 0.117% broke 100M views (vs ~2-3% for human-produced). "Traffic arbitrage, not storytelling." 670 pulled for unauthorized likenesses.

**Implication**: The market top (DramaBox/ReelShort) explicitly positions "human-written" as a selling point. AI-written scripts must be **indistinguishable from human** — which means passing craft rubric (beat density, emotional curve, dialogue rhythm, motivation coherence), not just being grammatically correct.

---

## Domestic Skill Carryover Failures (from v1.11.0 cleanup)

The following elements from the domestic short-drama skill are ANTI-PATTERNS for overseas use. They must not leak into this skill:

1. **红果 160+ self-check rubric** — built for Chinese domestic platform, actively harmful for English audiences
2. **爽点 density scoring** — replaced by romance beat emotional threshold
3. **打脸/装X/反转 as KPIs** — English audiences read these as petty/juvenile
4. **国内 4-stage wave pattern** — replaced by Gwen Hayes 4-Phase 20-beat
5. **"Physical conflict can only appear once" rule** — REVERSED for mafia romance (male lead's violence toward threats to female lead is a recurring, expected beat)
6. **Single female POV assumption** — overseas dark romance defaults to dual POV

---

## Vertical Craft Anti-Patterns (9:16)

> These are vertical-specific writing mistakes. 9:16 physics + hook-window rationale in `references/platform-knowledge.md`.
> For domestic content anti-patterns, see sections above.

### AP-V2: Wide Establishing Shots

**Pattern**: Opening with a landscape, building exterior, or skyline to "set the scene."

```
❌ WRONG:
FADE IN:
EXT. BLACKWELL UNIVERSITY - DAWN
Gothic spires rise above morning mist. Students cross the quad in twos and threes.
The bell tower strikes seven. Autumn leaves scatter across cobblestone paths.

✅ RIGHT:
FADE IN:
INSERT - GARGOYLE: stone teeth bared, morning frost on its lip. Below it, a hand pushes open an iron gate.

(SFX: gate hinge — a slow, reluctant groan)

Elara's breath fogs in the cold. She doesn't look up at the gargoyle. It looks down at her.
```

**Why it fails**: Wide shots are unreadable at 9:16 resolution on a phone screen. The first 3 seconds must be a visual anchor (see `platform-knowledge.md` §2 — 50-60% of viewer dropoff happens by 3s) — a specific, concrete image, not a panorama. Establishing mood through environment description wastes the hook window.

**Rule**: Replace every wide establishing shot with one INSERT detail that implies the whole environment. A gargoyle implies Gothic campus. A signet ring implies mafia dynasty. A cracked mirror implies decay.

### AP-V3: Unfilmable Choreography

**Pattern**: Writing action sequences that require multiple simultaneous actors, complex blocking, or physical stunts.

```
❌ WRONG:
Julian kicks the table into Marco's legs while spinning to grab the gun
from the third man's holster. Elara ducks behind the bar as bullets shatter
the mirror. Julian fires twice — one man drops, the other crashes through
the window. Glass everywhere.

✅ RIGHT:
Julian's hand closes around the gun on the table. One motion.

(SFX: a single gunshot — then ringing silence)

INSERT - SHATTERED GLASS: a whiskey tumbler, not a window. The crack runs through Julian's reflection.

Marco stares. Doesn't move. The third man is already gone — running footsteps fade down the corridor.

Elara watches from behind the bar. Julian's hand is steady. His eyes are not.
```

**Why it fails**: 9:16 vertical video uses single-subject framing. The camera follows one person at a time. Simultaneous multi-character blocking is unfilmable in vertical. Complex fight choreography requires wide shots and careful spatial blocking — both impossible at 9:16.

**Rule**: Violence is shown through **consequence and reaction**, not choreography. One decisive action + one reaction shot + one INSERT of aftermath.

### AP-V4: Interior Monologue as Scene Driver

**Pattern**: Extended internal monologue (via VO) drives the scene instead of visible action.

```
❌ WRONG:
ELARA (V.O.)
I knew I should leave. Every instinct screamed to run. But something
about the way he looked at me — not with hunger, not with anger, but
with recognition, like he'd been waiting for me to walk through that
door — made my feet root to the floor. I'd been invisible my whole
life. And now someone was finally seeing me. The worst possible someone.

✅ RIGHT:
Elara's hand is on the door handle. She pulls it down.

Stops.

Julian hasn't moved. Hasn't spoken. He's watching her the way a man watches
something he's already decided to keep.

Her hand releases the door handle.

ELARA
(to herself, barely audible)
Don't.

She sits back down.
```

**Why it fails**: Interior monologue is the novel's tool, not the screenplay's. In vertical video, the audience watches faces and actions — they don't read minds. Extended VO monologue turns visual media into an audiobook with pictures. Note: VO itself is platform-standard (see `platform-knowledge.md` §5), but its function is brief self-introduction or emotional tag, not narrative exposition.

### AP-V5: Dialogue-Free Establishing Sequences (>30s)

**Pattern**: Extended wordless sequences meant to "build atmosphere" before any character interaction.

**Why it fails**: Vertical drama audiences decide to stay or leave within 3-15 seconds. A 30+ second wordless atmospheric sequence is a feature film luxury. In ~90-second episodes (see `platform-knowledge.md` §1), 30s wordless = 33% of runtime — indefensible.

**Rule**: Maximum wordless/dialogue-free stretch = 15s (one Hook or Establish sub-segment). After 15s, either dialogue, VO (legal function only), or a new character must enter the frame.

### AP-V6: "Talking Heads" — Dialogue Without Physical Action

**Pattern**: Two characters talking with no physical action, prop interaction, or spatial movement.

```
❌ WRONG:
JULIAN
I need the research files.

ELARA
They're not ready.

JULIAN
When will they be ready?

ELARA
When I say they are.

JULIAN
That's not how this works.

ELARA
Then change how it works.

✅ RIGHT:
Julian picks up the specimen jar from Elara's desk. Holds it to the light.

JULIAN
I need the research files.

ELARA
They're not ready.

She takes the jar from his hand. Places it back. Exactly where it was. To the millimeter.

JULIAN
When will they be ready?

ELARA
(adjusting the jar's label to face him)
When I say they are.

Julian's fingers tap the desk. Once. Twice. He stops.

JULIAN
That's not how this works.

ELARA
(doesn't look up)
Then change how it works.
```

**Why it fails**: 9:16 video without physical action is radio with a static image. Every dialogue exchange must be accompanied by **hands doing something, objects being manipulated, or spatial relationships shifting**. The physical action carries subtext that dialogue alone cannot — her precise jar placement communicates territorial control more than her words do.

---

## 6 Failure Modes from 2026-04-11 (Agent Error Carryover)

These are real errors that occurred during this project's research phase. They will recur unless explicitly guarded against:

1. **Treating own inferences as external evidence** — quoting your own structural analysis as if a source page explicitly stated it
2. **Single-lens verification** — checking only structure compliance OR audience fit, not both
3. **Dead links as evidence** — dailymotion/youtube/fandom clips for vertical drama are frequently DMCA'd
4. **Local grep ≠ global truth** — checking one installation path doesn't mean all copies are consistent
5. **Commit messages as ground truth** — commit messages can be aspirational; only `git show --stat` shows actual changes
6. **Starting work before reading ground truth** — the root cause of all 6 errors above
