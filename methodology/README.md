# Iterative Session Methodology

A universal framework for producing high-quality work through structured, self-correcting sessions. Built for any repeated process — design, architecture, development, audits — where quality compounds across iterations.

---

## Origin

Extracted from an 11-session UI/UX design series that took a process from **4 iterations and 5 stakeholder corrections** (Session 1) to **consistent single-iteration approval with 0 corrections** (Sessions 9-11). The improvement came entirely from methodology, not skill — the same person, same tools, same problem type, radically different outcomes.

The seven principles that drove that improvement are domain-independent. This framework codifies them for reuse across any workstream.

---

## What's Here

```
docs/methodology/
│
├── README.md                          ← You are here
├── ITERATIVE_METHODOLOGY.md           ← The master framework (start here)
├── HOW_TO_USE.md                      ← Practical guide with 3 examples
│
├── workstreams/                       ← Domain-specific adaptations
│   ├── DESIGN_WORKSTREAM.md           UI/UX design, visual design, layout
│   ├── ARCHITECTURE_WORKSTREAM.md     System architecture, API design, data modeling
│   ├── DEVELOPMENT_WORKSTREAM.md      Feature implementation, bug fix campaigns
│   ├── AUDIT_WORKSTREAM.md            Code audits, security reviews, quality gates
│   └── TEMPLATE_WORKSTREAM.md         Blank template — create your own workstream
│
└── sessions/                          ← Where session output documents go
```

---

## Quick Start

### 1. Read the master framework

[`ITERATIVE_METHODOLOGY.md`](ITERATIVE_METHODOLOGY.md) defines the 6 phases, 7 quality gates, and the self-improvement loop that makes each session better than the last. This is the foundation — everything else builds on it.

### 2. Pick a workstream

Choose the template that matches your work:

| Workstream | Use When |
|-----------|----------|
| [Design](workstreams/DESIGN_WORKSTREAM.md) | Designing UI layouts, component arrangements, visual hierarchy |
| [Architecture](workstreams/ARCHITECTURE_WORKSTREAM.md) | Designing systems, APIs, data models, integration patterns |
| [Development](workstreams/DEVELOPMENT_WORKSTREAM.md) | Implementing features, running bug fix campaigns |
| [Audit](workstreams/AUDIT_WORKSTREAM.md) | Reviewing code for security, performance, correctness, style |
| [Template](workstreams/TEMPLATE_WORKSTREAM.md) | None of the above — create your own |

### 3. Run a session

Every session follows the same loop:

```
Pre-Flight → Research → Create → Present → Implement → Verify & Close
```

### 4. Read the how-to

[`HOW_TO_USE.md`](HOW_TO_USE.md) walks through three complete examples:

| Example | Lifecycle Phase | Workstream | Sessions |
|---------|----------------|------------|----------|
| REST API design | Greenfield | Architecture → Development | 6 |
| Accessibility bug campaign | Maintenance | Development | 3 |
| Monolith handler extraction | Refactoring | Development | 6 |

It also covers lifecycle guidance (greenfield → growth → maintenance → refactoring), AI agent usage, team scaling, and troubleshooting.

---

## The 7 Principles

These are the load-bearing ideas. Everything else implements them.

| # | Principle | One-Line Summary |
|---|-----------|-----------------|
| 1 | **Complete-Then-Create** | Finish ALL research before ANY creative work. No interleaving. |
| 2 | **Self-Correcting Loop** | Every failure → numbered anti-pattern. Every success → named pattern. The prompt evolves. |
| 3 | **Hard Phase Gates** | You cannot enter the next phase until the current one is done. No skipping. |
| 4 | **Knowledge Compounding** | Later sessions build on earlier sessions by citation, not re-derivation. |
| 5 | **Honest Accounting** | What Went Right AND What Went Wrong, tracked quantitatively. No hiding from the numbers. |
| 6 | **Scope Validation** | "Am I solving the right problem?" before "Am I solving the problem right?" |
| 7 | **Ascending Verification** | Move from cheap-but-unreliable (assumptions) to expensive-but-reliable (mechanical checks). |

---

## The 6 Phases

```
┌─────────────┐     ┌──────────┐     ┌────────┐     ┌─────────┐     ┌───────────┐     ┌────────────────┐
│  Pre-Flight  │────▶│ Research │────▶│ Create │────▶│ Present │────▶│ Implement │────▶│ Verify & Close │
│             │     │          │     │        │     │         │     │           │     │                │
│ Clean state │     │ Complete │     │ Design │     │  STOP   │     │ Mechanical│     │ Adjacent check │
│ Prior work  │     │ before   │     │ on     │     │  Wait   │     │ execution │     │ Honest acctg.  │
│ Adjacent    │     │ creating │     │ paper  │     │  for    │     │ of the    │     │ Pattern/anti-  │
│ check       │     │          │     │        │     │ approval│     │ approved  │     │ pattern update │
└─────────────┘     └──────────┘     └────────┘     └─────────┘     │ design    │     │ Recommendations│
                         ▲                               │          └───────────┘     └────────────────┘
                         │                               │                                    │
                         │            Revisions requested │                                    │
                         └───────────────────────────────┘                                    │
                                                                                              │
                    ┌─────────────────────────────────────────────────────────────────────────┘
                    │
                    ▼
            ┌──────────────────┐
            │ Next Session     │
            │ reads this       │
            │ session's output │
            │ (the loop)       │
            └──────────────────┘
```

---

## The Self-Improvement Loop

This is what makes the methodology work across sessions:

```
Session 1                    Session 2                    Session 3
┌──────────────┐            ┌──────────────┐            ┌──────────────┐
│ Do the work  │            │ Read S1 docs │            │ Read S1+S2   │
│              │            │ Apply S1     │            │ Apply all    │
│ Write:       │───────────▶│ patterns     │───────────▶│ patterns     │
│ • Patterns   │  feeds     │ Avoid S1     │  feeds     │ Avoid all    │
│ • Anti-pats  │  into      │ anti-pats    │  into      │ anti-pats    │
│ • Metrics    │            │              │            │              │
│ • Recs       │            │ Write new    │            │ Validate old │
└──────────────┘            │ learnings    │            │ patterns     │
                            └──────────────┘            └──────────────┘

 Roughest session            Better — applies             Best yet — full
 (methodology being          Session 1 lessons            pattern library
 invented)                                                and anti-pattern
                                                          coverage
```

**Evidence from the original series:**

| Metric | Session 1 | Session 5 | Session 10 |
|--------|-----------|-----------|------------|
| Iterations to approval | 4 | 1 | 1 |
| Stakeholder corrections | 5 | 1 | 0 |
| Defects found in existing work | 0 | 11 | 15 |
| Patterns in library | 5 | 23 | 40+ |
| Anti-patterns in list | 0 | 27 | 31 |

---

## When to Use / When Not to Use

**Use when:**
- You do the same TYPE of work repeatedly (APIs, UI layouts, audits, bug fixes)
- Quality matters more than speed on any individual session
- You want each session to be better than the last

**Don't use when:**
- The task is a one-off with no repetition (the loop has nothing to feed into)
- The task is trivial enough that the overhead exceeds the work
- You're exploring with no defined deliverable

---

## Lifecycle Coverage

The methodology adapts to every project phase. See [`HOW_TO_USE.md`](HOW_TO_USE.md) for detailed guidance.

| Phase | Primary Workstream | Key Emphasis |
|-------|--------------------|-------------|
| **Greenfield** | Architecture → Design → Development | Research and Create phases are heaviest |
| **Growth** | Development, occasional Architecture | Research focuses on existing code integration |
| **Maintenance** | Development or Audit | Root cause analysis; regression prevention |
| **Refactoring** | Development (Architecture session first) | Safety commits; pure extraction before improvement; rollback rules |

---

## Creating a Custom Workstream

1. Copy [`TEMPLATE_WORKSTREAM.md`](workstreams/TEMPLATE_WORKSTREAM.md)
2. Fill in the domain-specific sections (research steps, deliverable format, verification checklist, common anti-patterns)
3. Run 2-3 sessions — update the template with lessons learned after each
4. By Session 3, the template is tailored to your domain

---

## File Sizes

| File | Lines | Purpose |
|------|-------|---------|
| `ITERATIVE_METHODOLOGY.md` | 586 | Master framework — phases, gates, loop, templates |
| `HOW_TO_USE.md` | 789 | Practical guide — 3 examples, lifecycle, troubleshooting |
| `DESIGN_WORKSTREAM.md` | 199 | UI/UX design adaptation |
| `ARCHITECTURE_WORKSTREAM.md` | 231 | System architecture adaptation |
| `DEVELOPMENT_WORKSTREAM.md` | 223 | Feature/bug development adaptation |
| `AUDIT_WORKSTREAM.md` | 226 | Code audit adaptation |
| `TEMPLATE_WORKSTREAM.md` | 117 | Blank template for new workstreams |
| **Total** | **2,371** | |
