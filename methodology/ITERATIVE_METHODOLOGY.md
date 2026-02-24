# Iterative Session Methodology

A universal framework for producing high-quality work through structured, self-correcting sessions. Each session follows a fixed phase sequence, accumulates knowledge, and feeds lessons back into the process for the next session.

---

## Origin and Findings

This methodology was extracted from an 11-session UI/UX design series that designed operator interface profiles for a commercial ham radio application. The results:

| Metric | Session 1 | Sessions 2-11 |
|--------|-----------|---------------|
| Iterations to approval | 4 | 1 (every session) |
| Stakeholder corrections | 5 | 0-1 average (one outlier at 3) |
| Defects found in existing work | 0 | 2 → 15 (monotonically increasing) |
| Research depth | Partial, prompted | Comprehensive, proactive |

**What changed between session 1 and session 2 was not skill — it was methodology.** The same person, using the same tools, on the same type of problem, achieved radically different outcomes by changing HOW they worked. Specifically:

1. **Completing all research before any creative work** (eliminated interleaving-caused rework)
2. **Reading implementations, not just descriptions** (eliminated assumption-based errors)
3. **Presenting designs for approval before implementing** (eliminated wasted implementation)
4. **Converting every failure into a numbered anti-pattern** (eliminated repeated mistakes)
5. **Tracking performance quantitatively across sessions** (eliminated self-congratulatory narratives)

These five changes account for the entire improvement. They are domain-independent. This document codifies them into a reusable framework.

---

## When to Use This Methodology

Use this methodology when:

- **You are doing the same TYPE of work repeatedly** — designing APIs, building features, fixing bugs in a subsystem, writing design documents, conducting audits
- **Quality matters more than speed** — the cost of rework exceeds the cost of upfront research
- **Knowledge compounds** — what you learn in session N makes session N+1 better
- **The work has a stakeholder** — someone who approves or rejects the output

Do NOT use this methodology for:

- One-off tasks with no repetition (the self-improvement loop has nothing to feed into)
- Trivial tasks where the overhead exceeds the work itself
- Exploratory research with no defined deliverable

---

## The 7 Universal Principles

These are the load-bearing ideas. Everything else in this document is an implementation of one or more of these principles.

### 1. Complete-Then-Create

Finish ALL research before ANY creative work. No interleaving. The temptation to start creating after partial research is always present and always produces worse results.

**Evidence:** Session 1 interleaved research with design and took 4 iterations. Session 2 completed all research first and achieved first-pass approval. Every subsequent session followed this discipline and maintained single-iteration approval.

### 2. Self-Correcting Loop

Every failure becomes a numbered anti-pattern. Every success becomes a named pattern. The methodology prompt itself evolves after each session. Knowledge compounds; mistakes do not repeat.

**Mechanism:** What Went Wrong → Anti-Pattern #N → Added to prompt → Next session checks for it.

### 3. Hard Phase Gates

You cannot enter the next phase until the previous one is complete. The gates are not suggestions — they are structural controls. The most valuable gate is between Present and Implement: no implementation begins without stakeholder approval.

**Evidence:** Session 7 designed an entire view around the wrong tool. The Present gate caught this before any implementation was wasted. Without the gate, the implementation would have been built, tested, and THEN discovered to be wrong.

### 4. Knowledge Compounding

Reference tables, pattern libraries, anti-pattern lists, and cross-session citations. Later sessions build on earlier sessions by citation, not by re-derivation. Prediction chains form: "Session 4 predicted X would apply to satellite; Session 10 confirmed it."

**Mechanism:** Each session reads ALL previous session outputs before starting. The cost is fixed (one research pass); the value grows with each session.

### 5. Honest Accounting

What Went Right AND What Went Wrong, tracked quantitatively across all sessions. Performance comparison tables with trajectory narratives. No escape from the numbers.

**Mechanism:** A performance comparison table spans all sessions with consistent metrics. Trajectory narratives interpret the numbers honestly: "Session 7 was the worst since Session 1" is stated plainly, not hidden.

### 6. Scope Validation Before Execution

"Am I solving the right problem?" before "Am I solving the problem right?" A well-executed solution to the wrong problem is worse than a rough solution to the right problem, because it looks correct and resists correction.

**Mechanism:** The Splitting Test, Domain-Ecosystem Validation, and Role Classification — all applied before any design work begins.

### 7. Ascending Verification

Move from cheap-but-unreliable verification (assumptions, names, descriptions) to expensive-but-reliable verification (implementation reading, domain validation, mechanical code-level checks). Each level was added to the methodology after the previous level's failure mode was exposed in a real session.

**Evidence:** Assumption-based verification failed in session 1 (waterfall name). Description-based failed in session 5 (WSPR scope). Implementation reading failed in session 7 (domain mismatch). Agent claims failed in session 9 (false variant support). Each failure added a verification level.

---

## The 6 Phases

Every session follows these phases in order. Phases are sequential and gated — you cannot skip a phase or enter the next one early.

### Phase 1: Pre-Flight

**Purpose:** Verify the workspace is clean, the prior state is understood, and nothing is broken before you touch anything.

**Steps:**
1. Read all governing documents (safety rules, process docs, style guides)
2. Read prior session notes (what was the last session doing? what's in progress?)
3. Check the current state of the workspace (version control status, recent changes)
4. Verify the artifact you will modify exists and is in a known-good state
5. Spot-check 2-3 ADJACENT artifacts to confirm they are also healthy
6. **Report findings to the stakeholder before proceeding**

**Gate:** Pre-Flight Pass — workspace is clean, prior work is understood, no broken artifacts. If any artifact is broken, report it and get direction before continuing.

**Anti-patterns to avoid:**
- Starting work without reading prior session notes
- Assuming the workspace is clean because it was clean last time
- Skipping the adjacent artifact check (this is how cross-session damage goes undetected)

### Phase 2: Research

**Purpose:** Build a complete understanding of the problem space, available tools, prior art, and constraints BEFORE any creative work.

**This is the most critical phase.** The quality of research directly determines the quality of the output. Incomplete research produces rework; complete research produces first-pass approval.

**Steps:**
1. **Study the domain.** Read requirements, use case documents, specifications. Extract: who is the user? What is their workflow? What do they need most? What do they NOT need?
2. **Inventory available tools/components.** Build a reference table of everything you could use. Include capabilities, constraints, sizes, dependencies.
3. **Read implementations, not just descriptions.** A component's name or description tells you what it IS. Its implementation tells you how it BEHAVES. Read the actual code/config/spec for every component you might use.
4. **Review ALL prior work in this series.** Read every previous session's output. Extract reusable patterns and avoidable mistakes. Note which patterns apply to your current work and which don't.
5. **Challenge the scope.** (See Scope Validation section.) Is this the right problem to solve? Does this work item encompass things that should be separate?
6. **Validate domain fit.** (See Domain-Ecosystem Validation section.) Are you using the right tools for this domain, or substituting generic equivalents for domain-specific tools?
7. **Verify capability claims.** For any critical capability ("this component supports X"), verify by reading the implementation. Do not trust names, descriptions, or third-party summaries.

**Gate:** Research Complete — all components inventoried AND their implementations read, all prior work reviewed, scope validated, domain fit confirmed.

**The Complete-Then-Create Rule:** Do NOT begin Phase 3 until all 7 steps are done. The temptation to start creating after steps 1-3 is strong. Resist it. Steps 4-7 routinely surface insights that change the entire approach.

### Phase 3: Create

**Purpose:** Design the solution in a document — NOT in implementation artifacts. The design IS the deliverable of this phase. Implementation is mechanical work in Phase 5.

**Steps:**
1. Define the solution approach, referencing patterns from prior sessions where applicable
2. For each component/tool included, document WHY it was included (what user need it serves)
3. For each component/tool EXCLUDED, document WHY it was excluded (what made it unnecessary or wrong)
4. Calculate or estimate quantitative measures (balance, sizing, performance, etc.)
5. Identify gaps — things the solution needs that don't exist yet
6. Write the solution as a complete document that could be handed to someone else for implementation

**Gate:** Design document is complete and internally consistent. All inclusions and exclusions are justified. Quantitative measures are calculated, not estimated.

**Anti-patterns to avoid:**
- Rubber-stamping the existing state (rearranging what's already there instead of designing from first principles)
- Including components because they're available, not because the user needs them ("filler")
- Designing from component names instead of component implementations
- Forcing proven patterns from prior sessions when they don't fit the current problem

### Phase 4: Present

**Purpose:** Show the complete design to the stakeholder and STOP. Get explicit approval before any implementation.

**Steps:**
1. Present the design document to the stakeholder
2. Highlight key decisions and their rationale
3. Explicitly identify areas of uncertainty or domain knowledge gaps
4. Ask for feedback — "What did I get wrong? What am I missing?"
5. **STOP. Do not proceed to implementation until explicit approval.**

**Gate:** Stakeholder Approval — explicit go-ahead to implement. If the stakeholder requests changes, return to Phase 3, revise the design, and present again.

**Why this gate exists:** Implementation is expensive. A flawed design caught at the Present gate costs zero implementation effort. A flawed design caught after implementation costs all the implementation effort plus the rework effort. This gate has the highest ROI of any step in the methodology.

**Anti-patterns to avoid:**
- Presenting and immediately starting implementation ("I'll just get started while they review")
- Treating silence as approval
- Presenting a summary instead of the full design (the stakeholder needs to see the details to catch domain-specific errors)

### Phase 5: Implement

**Purpose:** Execute the approved design mechanically. This phase is bounded and predictable because the creative work was done in Phase 3.

**Steps:**
1. **Safety commit.** Before modifying any files, create a commit/snapshot of the current state. This is your rollback point. Non-negotiable.
2. **Enumerate the change set.** List every file you will modify and every file you will NOT modify. The NOT list is as important as the WILL list — it prevents scope creep during implementation.
3. **Implement the approved design.** Follow the design document. Do not redesign during implementation. If you discover something that requires a design change, STOP implementing and return to Phase 3.
4. **Build and verify.** After implementation, verify the artifact works as designed.

**Gate:** Implementation matches the approved design. Build succeeds. The artifact functions correctly.

**Anti-patterns to avoid:**
- Skipping the safety commit ("it's a small change")
- Redesigning during implementation (this is the most common source of compounding errors)
- Implementing beyond the approved design ("while I'm here, I'll also fix...")
- Not enumerating the change set (leads to accidental modification of unrelated files)

### Phase 6: Verify and Close

**Purpose:** Confirm the work is correct, nothing else broke, and all knowledge is captured for the next session.

**Steps:**
1. **Verify the artifact.** Does it match the design? Does it build? Does it function?
2. **Verify adjacent artifacts.** Check 2-3 artifacts that were NOT modified. Are they still healthy? Cross-artifact regression is the most insidious failure mode because nobody is looking for it.
3. **Commit the work.** Structured commit message referencing the session.
4. **Write What Went Right / What Went Wrong.** (See Honest Accounting section.) Be specific and honest.
5. **Update the performance comparison table.** Add this session's metrics.
6. **Write recommendations for the next session.** What should the next person do better?
7. **Update the pattern library and anti-pattern list.** If you discovered a new pattern or made a new mistake, name it and add it.
8. **Update session continuity notes.** What should the next session know before starting?

**Gate:** All verification passes. Session document is complete with honest accounting. Continuity notes are written.

---

## Quality Gates (Summary)

| # | Gate | Between | Question It Answers |
|---|------|---------|---------------------|
| 1 | Pre-Flight Pass | Start → Research | Is the workspace clean and prior work understood? |
| 2 | Research Complete | Research → Create | Have I read everything I need to make good decisions? |
| 3 | Scope Validated | Within Research | Am I solving the right problem? |
| 4 | Stakeholder Approval | Present → Implement | Does the stakeholder agree this is the right solution? |
| 5 | Safety Commit | Before Implementation | Can I roll back if something goes wrong? |
| 6 | Cross-Artifact Verification | After Implementation | Did I break anything I wasn't working on? |
| 7 | Session Learnings Documented | Before Close | Will the next session benefit from what I learned? |

---

## The Self-Improvement Loop

This is the mechanism that makes the methodology get better over time. It operates at three timescales.

### Within a Session

**What Went Right / What Went Wrong** sections are written at the end of every session. These are not perfunctory — they require root cause analysis.

Bad: "The design needed revisions."
Good: "The designer included dxCluster based on a syllogism: 'hunting requires spots → dxCluster shows spots → dxCluster serves hunting.' The middle term was wrong — this domain uses a different spot ecosystem. Root cause: no step existed for domain-ecosystem validation."

### Between Sessions (Prompt Evolution)

Failures become **numbered anti-patterns** added to the methodology prompt:
```
Anti-pattern #29: Domain-tool mismatch — a panel can be functionally correct
for a general task but wrong for a domain's specific ecosystem. Reading code
tells you what a tool DOES; domain knowledge tells you if it's the RIGHT tool.
```

Successes become **named patterns** with usage guidance:
```
Pattern: "Star panel CENTER" — Each profile has ONE defining panel that
belongs in CENTER of Operate. It differentiates this profile from all others.
When to Use: Every profile — identify the star early. It's the single
most important design decision.
```

### Across the Full Series (Performance Tracking)

A **performance comparison table** spans all sessions with consistent metrics. The trajectory narrative interprets the data honestly:

```
Session 7 was the worst since Session 1 on user corrections (3 vs the 0
standard). The defining failure — treating dxCluster as a POTA hunting
tool — revealed a blind spot in the methodology.
```

**Recommendations tracking** creates accountability:

| # | Recommendation (from Session N) | Status in Session N+1 | How Addressed |
|---|--------------------------------|----------------------|---------------|
| 1 | Add domain-ecosystem validation | Done | Explicit section in design doc |
| 2 | Write user testing questions | Not done | Regression — see What Went Wrong |

---

## Knowledge Accumulation System

Knowledge compounds across sessions through four mechanisms. All four are required — they serve different purposes.

### 1. Reference Tables

Structured tables recording factual findings about components, tools, or materials. Each session adds rows; no session removes them (unless correcting an error).

**Format:**
| Item | Key Finding | Constraints | Verified? |
|------|-------------|-------------|-----------|

**Purpose:** Eliminates re-derivation. When a future session needs to know a component's behavior, the reference table provides the answer without re-reading the implementation.

**Rule:** Reference tables record FACTS (measured heights, observed behaviors, code-confirmed capabilities), not opinions. If a finding is uncertain, mark it explicitly.

### 2. Pattern Library

Named patterns with "Description" and "When to Use" columns. Each pattern is attributed to the session that discovered it.

**Format:**
| Pattern Name | Description | When to Use | Discovered |
|-------------|-------------|-------------|------------|

**Purpose:** Makes successful solutions reusable. A future session can apply "RX/TX thematic split" by name rather than re-inventing it.

**Rule:** Patterns are TOOLS, not mandates. A pattern that works for 8 of 10 sessions may fail for the other 2. Each session must evaluate whether a pattern applies to its specific context. Anti-pattern: "Force-fitting a proven pattern because it worked before."

### 3. Anti-Pattern List

Numbered list of mistakes with descriptions of what went wrong and why.

**Format:**
```
Anti-pattern #N: [Name] — [Description of the mistake, what caused it,
and what would have prevented it]. Discovered: Session X.
```

**Purpose:** Makes failures non-repeatable. A numbered anti-pattern is citable — "check for anti-pattern #29" is specific and actionable.

**Rule:** Every entry in the anti-pattern list exists because a real session made that exact mistake. Do not add hypothetical anti-patterns. Only actual failures earn a number.

### 4. Cross-Session Citations

Design documents explicitly reference previous sessions when reusing patterns or avoiding anti-patterns.

**Examples:**
- "Applying the RX/TX thematic split from Session 1..."
- "Session 4 predicted ritXit would apply to satellite; this session confirms it."
- "Unlike Session 7's dxCluster error, this domain's ecosystem IS the DX cluster network."

**Purpose:** Creates institutional memory. A citation trail lets anyone trace WHY a decision was made, all the way back to the session that established the precedent.

---

## Honest Accounting Framework

Honest accounting is the integrity mechanism of the methodology. It prevents the common failure mode of "everything went well" narratives that hide real problems.

### What Went Right (Per Session)

List 3-6 things that worked well, with EVIDENCE:
- What specifically happened?
- Why did it work?
- Is it a reusable pattern? If so, name it and add it to the pattern library.
- What would have happened without this?

### What Went Wrong (Per Session)

List 1-4 things that went wrong, with ROOT CAUSE ANALYSIS:
- What specifically happened?
- Why did it happen? (Not "I made a mistake" — what structural gap allowed the mistake?)
- What would have prevented it?
- Is it a new anti-pattern? If so, number it and add it to the anti-pattern list.
- What should the next session do differently?

**The standard for honesty:** Would a hostile reviewer agree with your assessment? If your "What Went Wrong" section says "nothing significant," ask whether that's true or whether you're avoiding accountability.

### Performance Comparison Table

Maintained across all sessions. Columns should include:

| Metric | Description |
|--------|-------------|
| Iterations to approval | How many times was the design revised before approval? Target: 1. |
| Stakeholder corrections | How many factual errors did the stakeholder catch? Target: 0. |
| Defects found in existing work | How many problems were found in the artifact's prior state? Higher is better (means more thorough audit). |
| Research depth | What was examined before creating? Quantify (e.g., "all 22 plugin directories"). |
| New patterns discovered | Named patterns added to the library this session. |
| Gaps identified | Deficiencies found that can't be fixed this session. |
| Prior recommendations applied | X of Y recommendations from the previous session. Target: Y of Y. |

### Trajectory Narrative

After updating the performance table, write a paragraph interpreting the trend:
- Is quality improving, stable, or regressing?
- What explains the trend?
- Are there leading indicators of future problems?
- What is the current quality standard? (e.g., "first-pass approval, 0 corrections, 12+ defects found")

---

## Scope Validation System

Scope validation asks "Am I solving the right problem?" before "Am I solving the problem right?" Three tools:

### The Splitting Test

When a work item encompasses multiple sub-items, evaluate each pair:

1. Does sub-item A have a **different primary tool/component** than sub-item B?
2. Does sub-item A have a **different tempo/pace** than sub-item B?
3. Does sub-item A have a **different user posture** than sub-item B?

If all three are true, the sub-items belong in separate scopes. If they share a primary tool, keep them together and handle differences through views/configurations.

**Signal phrases that indicate a split is needed:** "fundamentally different," "passive vs active," "different tempo," "set-and-forget vs interactive." If you write these phrases about sub-items within a single scope, stop and evaluate.

### Domain-Ecosystem Validation

Before including a tool or component, ask:

1. Does this domain have its own specialized tool ecosystem?
2. Does my tool set include a tool FROM that ecosystem?
3. Or am I substituting a generic equivalent?

**Four possible outcomes:**
| Outcome | Meaning | Action |
|---------|---------|--------|
| **Rejection** | Generic tool is domain-inappropriate | Exclude; document the gap |
| **Confirmation** | My tool IS the domain's native tool | Include with confidence |
| **Identity** | My tool set IS the ecosystem | Include; no external tools needed |
| **Complementary** | My tool partially covers the domain; integration exists for the full tool | Include honestly; document limitations |

### Role/Mode Classification

Before designing, classify the work item:

- **Personal operation:** The user manages their own work
- **Group management:** The user manages others' work

This classification changes which components are "star" components and how the interface is organized. A personal-operation design centers on the user's own actions; a group-management design centers on a roster/queue of others' items.

---

## Verification Hierarchy

Seven levels, from least reliable to most reliable. Use the highest level that's practical for each claim.

| Level | Method | Cost | What It Catches | What It Misses |
|-------|--------|------|-----------------|----------------|
| 1 | **Assumption** | Free | Nothing | Everything |
| 2 | **Name/Label** | Free | Gross miscategorization | Subtle mismatches |
| 3 | **Description/Manifest** | Low | Capability gaps | Behavioral constraints |
| 4 | **Implementation Reading** | Medium | Width constraints, actual sizes, variant behavior | Domain-inappropriate usage |
| 5 | **Comprehensive Reading** | Medium | Unexpected components, hidden capabilities | Domain knowledge gaps |
| 6 | **Domain Validation** | High | Wrong tool for the community | Implementation bugs |
| 7 | **Mechanical Verification** | Medium | False capability claims | Semantic errors |

**Rule:** Each level was added because a real session trusted a lower level and got burned. Level 4 was added after session 1 trusted names (level 2) and proposed the wrong component. Level 6 was added after session 7 trusted implementation reading (level 4) and proposed a domain-inappropriate tool. Level 7 was added after session 9 trusted an agent's summary and discovered 5 false capability claims.

**Mechanical verification example (Level 7):**
```
Step 1: grep for capability declaration (does it claim to support X?)
Step 2: grep for capability usage (does it actually implement X?)
Zero matches on Step 2 = zero support. No interpretation needed.
```

---

## Session Document Template

Every session produces a document following this structure. Copy this template and fill it in.

```markdown
# Session [N]: [Work Item Name]

## Pre-Flight Assessment
- Workspace state: [clean/dirty — if dirty, what and why]
- Prior session notes: [summary of what the last session did]
- Artifact current state: [builds? passes? known issues?]
- Adjacent artifact check: [which ones checked, their status]

## Research Summary

### Domain/Requirements
- [Who is the user? What do they need? What's their workflow?]

### Component Inventory
| Component | Key Finding | Constraints | Verified? |
|-----------|-------------|-------------|-----------|

### Prior Work Review
- [Which previous sessions were read]
- [Patterns being reused from prior sessions]
- [Anti-patterns being watched for]

### Scope Validation
- [Splitting test results]
- [Domain-ecosystem validation results]
- [Role/mode classification]

## Design

### Approach
- [Overall solution description]
- [Key decisions and their rationale]

### Component Selection
| Component | Included/Excluded | Rationale |
|-----------|-------------------|-----------|

### Quantitative Analysis
- [Balance calculations, sizing estimates, performance projections — whatever is measurable]

### Gap Analysis
| Gap | Severity | Workaround | Future Fix |
|-----|----------|------------|------------|

## Implementation

### Change Set
| File | Action | Notes |
|------|--------|-------|
| (file) | Modify/Create/Delete | (what changes) |

### Files NOT Modified (Scope Boundary)
- [Explicit list of files that are adjacent but out of scope]

## Verification
- Artifact verification: [pass/fail, details]
- Adjacent artifact check: [which ones, status]

## Session Learnings

### What Went Right
1. [Specific success with evidence]
2. [Reusable pattern, if discovered]

### What Went Wrong
1. [Specific failure with root cause analysis]
2. [New anti-pattern, if discovered]

### Performance Metrics
| Metric | This Session | Trend |
|--------|-------------|-------|
| Iterations to approval | | |
| Stakeholder corrections | | |
| Defects found | | |
| Research depth | | |
| New patterns | | |
| Prior recommendations applied | X of Y | |

### Recommendations for Next Session
1. [Specific, actionable improvement]
2. [...]

### Patterns Added to Library
| Pattern | Description | When to Use |

### Anti-Patterns Added
| # | Name | Description |
```

---

## Performance Tracking

Maintain a performance comparison table across ALL sessions in the methodology prompt or a dedicated tracking file.

**Required columns:**

| Column | What It Measures | Target |
|--------|-----------------|--------|
| Session | Identifier | — |
| Iterations to approval | Creative rework cycles | 1 |
| Stakeholder corrections | Domain errors caught by stakeholder | 0 |
| Defects in existing work | Thoroughness of pre-work audit | Increasing trend |
| Research depth | Components/files examined | "All" (comprehensive) |
| New patterns discovered | Methodology growth | 2+ (early), 0+ (mature) |
| Prior recommendations applied | Accountability | 100% |

**Interpreting the table:**
- **Iterations > 1:** Research was incomplete. Tighten Phase 2.
- **Corrections > 0:** Domain knowledge gap. Add domain validation steps.
- **Defects decreasing:** Audit is getting lazy. Check audit methodology.
- **Recommendations < 100%:** Either the recommendations were impractical or the session skipped them. Investigate which.

**Maturity indicators:**
- Sessions 1-3: Foundation — expect methodology changes, pattern discovery, some corrections
- Sessions 4-7: Expansion — patterns stabilize, new anti-patterns emerge from edge cases
- Sessions 8+: Maturity — validations exceed discoveries, corrections near zero, methodology changes are rare

---

## Adapting to Your Domain

This methodology is domain-independent. The phases, gates, and self-improvement loop work for any repeated process. What changes per domain is:

1. **What you research in Phase 2** (components for UI, APIs for backend, schemas for data, etc.)
2. **What you create in Phase 3** (layout for UI, architecture doc for systems, implementation plan for features)
3. **What scope validation looks like** (mode-splitting for UI, bounded context analysis for architecture, etc.)
4. **What verification looks like** (visual inspection for UI, contract testing for APIs, load testing for performance)
5. **What the reference tables contain** (panel sizes for UI, endpoint contracts for APIs, table schemas for data)

See the `workstreams/` directory for domain-specific adaptations:
- `DESIGN_WORKSTREAM.md` — UI/UX design, visual design, layout work
- `ARCHITECTURE_WORKSTREAM.md` — System architecture, API design, data modeling
- `DEVELOPMENT_WORKSTREAM.md` — Feature implementation, bug fix campaigns
- `AUDIT_WORKSTREAM.md` — Code audits, system reviews, security assessments
- `TEMPLATE_WORKSTREAM.md` — Blank template for creating new workstreams

See `HOW_TO_USE.md` for practical examples and lifecycle guidance.
