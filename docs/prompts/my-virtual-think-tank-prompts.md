# Virtual Think Tank Prompts (Generic Set)

These prompts are designed to help you use an LLM as a **virtual think tank**: a structured discussion that explores **trade-offs** from multiple perspectives, and then forces you (the human) to make an explicit decision.

## How to use this set

- **Start a fresh chat** for each new think tank topic.
- Work through the prompts **in order** (A → H). Skip only if you already have that output.
- Keep the LLM honest:
  - Ask for **assumptions**, **unknowns**, and **what would change the conclusion**.
  - When it names real people, ask it to **state uncertainty** and to provide **verification steps** (do not rely on names blindly).
- The think tank is here to **surface options and trade-offs**, not to "decide for you".

---

## Placeholders

Replace placeholders in `{braces}` before running a prompt.

- `{decision_subject}`: what the decision is about (a system, product, programme, policy, process, contract, organisational change, etc.)
- `{current_state}`: what exists today (facts, behaviours, constraints, ways of working, or baseline performance)
- `{required_state}`: what you need next (target outcomes, desired behaviours, or future state)
- `{problem_statement}`: the core question you need to decide
- `{constraints}`: budgets, people, timelines, policies, platforms, organisational boundaries, risk appetite, etc.
- `{non_goals}`: what is explicitly out of scope
- `{decision_horizon}`: how long this decision should last before review (e.g. 3 months)

---

## A) Session setup and problem shaping 🧭

Use this first. It primes the model and reduces "garbage in, garbage out".

```text
You are my virtual think tank facilitator.

Your job is to help me make a high-quality engineering/architecture/business decision by exploring trade-offs from multiple perspectives.
Do not decide for me. You must force me to decide explicitly at the end.

Rules:
- If anything is unclear, ask questions before giving options.
- Be explicit about assumptions, uncertainties, and what evidence is missing.
- Prefer simple language and high signal.
- Do not invent facts. If you are unsure, say so.

Context:
Decision subject: {decision_subject}
Current state: {current_state}
Required state: {required_state}
Problem statement: {problem_statement}
Constraints: {constraints}
Non-goals: {non_goals}
Decision horizon: {decision_horizon}

Step 1 - Validate the problem:
1) Tell me whether {problem_statement} is the real decision or a symptom of something else.
2) Ask me at least 2 questions about each: decision subject, current state, required state, problem statement, constraints, non-goals.
3) Reword the problem statement into a single crisp decision question.
4) List the decision's success criteria (how we will know it worked) and failure modes (how it could go wrong).
Output format:
- Clarifying questions
- Reworded decision question
- Proposed success criteria
- Top risks / failure modes
```

---

## B) Baseline explanation (neutral, "textbook" view) 📚

This gives you the "standard answer" before you introduce opinions.

```text
Explain the key concepts involved in this decision in a neutral way.
- Define the key terms in plain language.
- List typical benefits, typical costs, and common failure modes.
- Include a short "when it is a bad idea" section.
Keep it concise and avoid salesmanship.

Decision question: {reworded_decision_question}
Output format:
- Definitions
- Benefits
- Costs / risks
- When it is a bad idea
- Open questions
```

---

## C) Persona discovery (find advocates, sceptics, and a middle view) 🧑‍🏫🧑‍🔧🧑‍⚖️

Pick voices that genuinely disagree.

```text
I want to set up a virtual think tank with distinct, conflicting viewpoints.

For the decision question below, suggest:
1) A strong advocate of approach A
2) A strong advocate of approach B
3) A pragmatic "middle ground" voice
4) A neutral moderator (well-informed, not known for strong opinions)

Decision question: {reworded_decision_question}

For each suggested person/voice:
- Why they fit this role
- What their typical argument would be (2–4 bullets)
- What they would be biased towards (1–2 bullets)
- A quick "verification plan" to confirm they are real and relevant (what to search for, what to read)

If you are not confident a person is real or relevant, say so and propose an alternative.

Output format (JSON):
{
  "moderator": {"name": "...", "stance": "neutral", "why": "...", "biases": ["..."], "verification_plan": ["..."]},
  "advocate_A": {"name": "...", "stance": "A", "why": "...", "biases": ["..."], "verification_plan": ["..."]},
  "advocate_B": {"name": "...", "stance": "B", "why": "...", "biases": ["..."], "verification_plan": ["..."]},
  "middle": {"name": "...", "stance": "middle", "why": "...", "biases": ["..."], "verification_plan": ["..."]}
}
```

---

## D) Add "outside wisdom" (transferable perspective) 🧠✨

Add a voice that is not "in the trench" but can challenge assumptions.

```text
Suggest 1–3 outside thinkers (real or fictional) who are not direct experts in this topic, but could add valuable transferable perspective.

For each:
- What transferable lens they bring (e.g. incentives, organisational design, ethics, systems thinking)
- The kind of question they would ask that others might miss
- Any risk of distortion (e.g. too abstract, overly ideological)

Decision question: {reworded_decision_question}

Output format:
- Candidate list (3 max)
- For each: lens, likely questions, risks
- Your recommended pick (1) and why
```

---

## E) Think tank debate (the core) 🗣️

This is the heart of the method. It should **debate trade-offs**, not just list pros/cons.

```text
Set up and run a virtual think tank debate.

Participants:
- Moderator: {moderator_name}
- Advocate A: {advocate_A_name}
- Advocate B: {advocate_B_name}
- Middle: {middle_name}
- Outside thinker: {outside_thinker_name}

Decision question: {reworded_decision_question}
Context: {decision_subject} / {current_state} / {required_state}
Constraints: {constraints}
Non-goals: {non_goals}

Debate rules:
- Each participant speaks in a distinct voice and argues their position.
- They must challenge each other (politely but directly).
- They must call out assumptions, unknowns, and hidden costs.
- They must propose at least one compromise / third option (if any).
- If something essential is missing, the moderator must ask me a question.
- Avoid vague platitudes. Use concrete examples and failure scenarios.

Output structure:
1) Opening statements (short)
2) Cross-examination: each participant challenges one other participant (1 round each)
3) Moderator summary: key trade-offs, points of agreement, points of disagreement
4) Options on the table:
   - Option A
   - Option B
   - Option C (if any)
   For each: benefits, costs, risks, prerequisites, "what must be true"
5) 5–10 "decisive questions" I must answer to choose well
```

---

## F) Radical option round (break conventional thinking) ⚡️

Use this when you feel stuck or the debate converges too quickly.

```text
Radical option round.

For the same participants, have each propose one radical approach that breaks normal conventions.
Rules:
- It may be risky or unpopular.
- It must include why it could work *in this context* and what safety rails would be needed.
- It must include the likely failure mode (how it would go wrong).

Decision question: {reworded_decision_question}
Output format:
- One radical option per participant
- For each: why it might work, safety rails, failure mode
- Moderator: which radical idea is worth a small experiment, and why
```

---

## G) Produce a think tank report (not a decision) 🧾

This creates the "white paper" style output.

```text
Write a think tank report for the decision below.

Decision question: {reworded_decision_question}
Participants: {moderator_name}, {advocate_A_name}, {advocate_B_name}, {middle_name}, {outside_thinker_name}

Report rules:
- Do not choose the final decision for me.
- Present trade-offs clearly.
- Be explicit about assumptions and uncertainties.
- Include follow-up research and experiments.

Output structure:
1) Executive summary (5–10 bullets)
2) Context and constraints
3) Options compared (table)
   Columns: option, key idea, benefits, costs, risks, prerequisites, reversibility, time-to-value
4) What we agree on / what we disagree on
5) Recommended experiments (small, time-boxed)
6) What evidence would change our recommendation
7) Open questions to answer next
```

---

## H) Force a human decision (accountability step) ✅

This is where the think tank becomes useful: it makes you commit.

```text
Now force me to make a decision.

Using the report so far:
- Summarise the options in 3–5 bullets each (no new content).
- Ask me to choose: A, B, or C (or "defer" with a time-box).
- Ask me to state:
  1) Why I chose it
  2) What I am giving up
  3) What would make me reverse this decision
  4) The review date (within {decision_horizon})

Then draft a short decision record (ADR-style) for my approval, with:
- Context
- Decision
- Drivers
- Options considered
- Outcome
- Consequences
- Compliance / how we will measure success
Keep it short and ready to paste.
```

---

## Optional "quality control" prompts

### Q1) Bias and weak-argument detector 🔍

```text
Review the think tank outputs and identify:
- Where arguments were weak, vague, or rhetorical
- Where claims were made without support
- Where participants talked past each other
- The top 5 assumptions that need validation

Then propose 3 concrete ways to validate the assumptions (readings, measurements, experiments).
Keep it blunt and specific.
```

### Q2) "Stakeholder meeting" version (organisational trade-offs) 🧑‍🤝‍🧑

Use this when the decision is as much about people/process as it is about technology.

```text
Run the same debate, but as a stakeholder meeting with organisational roles, not famous people.

Include:
- Product owner
- Engineering lead
- Platform/operations
- Security/privacy
- Data/analytics
- Finance/commercial
- Support/live operations
- Moderator (neutral)

For each stakeholder:
- State their top concerns and non-negotiables
- Challenge trade-offs explicitly
- Identify risks and mitigations
Output the same "options on the table" summary and decisive questions.
```
