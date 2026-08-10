# AI Readability Best Practices

Best practices for writing prompt, skill, and agent definitions optimized for
AI consumption. Sourced from OpenAI and Anthropic guidance.

## Core Principles

1. **Be clear and direct.** State exactly what output is expected. Avoid vague
   or implicit instructions — if the desired behavior requires "above and
   beyond" effort, request it explicitly.
2. **Be specific about constraints.** Define output format, length limits,
   allowed values, and edge-case handling explicitly.
3. **Use imperative mood.** "Read the file" not "You should read the file" or
   "The file should be read."
4. **One idea per sentence.** Break compound sentences into separate statements.
5. **Tell what to do, not what not to do.** Instead of "Do not use markdown",
   try "Write in flowing prose paragraphs." Reserve "do not" for critical
   guardrails.
6. **Add context for why.** Explaining motivation behind an instruction helps
   the model generalize correctly. Brief rationale improves compliance.

## Structure and Formatting

### Use Markdown and XML for Logical Boundaries

- Use Markdown headers (`#`, `##`, `###`) to mark distinct sections and convey
  hierarchy.
- Use XML tags to delineate content types: `<instructions>`, `<context>`,
  `<examples>`, `<input>`. This reduces misinterpretation in mixed-content
  prompts.
- Use consistent, descriptive tag names across prompts.
- Nest tags when content has a natural hierarchy.

### Recommended Section Order

Structure definitions in this order (matches model processing expectations):

1. **Identity** — Purpose, communication style, high-level goals.
2. **Instructions** — Rules, constraints, behavioral directives.
3. **Examples** — Input/output pairs demonstrating desired behavior.
4. **Context** — Supporting data, reference material (best near the end).

### Progressive Disclosure

Design for efficient token use across loading levels:

1. **Metadata** (~100 tokens): `name` + `description` — always loaded.
2. **Body** (< 5000 tokens recommended): Full instructions — loaded on
   activation.
3. **Bundled resources** (as needed): `scripts/`, `references/`, `assets/` —
   loaded on demand via explicit instructions.

Move detailed reference material (lookup tables, extended examples, schemas)
to `references/` files. Keep the main body focused on workflow steps and
constraints.

## Clarity Patterns

### Sequential Steps

- Use numbered lists when order matters.
- Use bullet points for unordered requirements.
- Each step should be a single, actionable instruction.

### Decision Points

- Make branching conditions explicit: "If X, do Y. Otherwise, do Z."
- Avoid ambiguous conditionals — specify both branches.

### Precision over Brevity

- Replace vague quantifiers ("some", "various", "several") with specific
  values or remove them.
- Replace "etc." with the actual items or remove the list.
- Convert conditional instructions to imperative where the condition is
  always true.

### Active Voice

- "Read the file" not "The file should be read."
- "Extract the pattern" not "The pattern should be extracted."

## Conciseness Patterns

### Remove Without Losing Meaning

- Filler adverbs: "simply", "just", "basically", "actually", "really"
- Hedging: "it is important to note that" → state the fact directly
- Redundant preambles: "In order to" → "To"
- Polite padding: "please", "kindly" (AI does not need politeness)
- Tautologies: "each and every" → "every"

### Shorten Without Changing Meaning

- "in order to" → "to"
- "due to the fact that" → "because"
- "has the ability to" / "is able to" → "can"
- "make sure that" → "ensure"
- "it is necessary to" → "must"
- "whether or not" → "whether"
- "for the purpose of" → "to" / "for"

See `optimization-patterns.md` for the complete catalog.

### Eliminate Structural Redundancy

- Remove descriptions that restate the heading.
- Remove section introductions that repeat the title.
- Consolidate duplicate constraints — keep the most specific version.
- Remove meta-commentary: "This section explains how to..." → remove.

## Examples Best Practices

- Include 3–5 diverse examples for best results.
- Wrap examples in `<example>` tags to distinguish from instructions.
- Cover edge cases with varied examples.
- Each example should demonstrate a different aspect of the desired behavior.

## Formatting for AI Parsing

### Do

- Use consistent heading levels to convey hierarchy.
- Use tables for structured data (mappings, comparisons, checklists).
- Use fenced code blocks for code, commands, and templates.
- Keep lines under 120 characters for readability.

### Avoid

- Excessive blank lines (more than one consecutive).
- Decorative horizontal rules with no structural purpose.
- Over-use of bold/italic where structure already conveys importance.
- Inconsistent formatting patterns within the same document.

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Vague instructions | Model guesses intent | Be specific and explicit |
| Passive voice | Ambiguous actor | Use imperative mood |
| Nested conditionals | Hard to parse | Flatten or use decision tables |
| Duplicate rules | Conflicting interpretations | Consolidate to one location |
| Polite hedging | Wastes tokens, no benefit | Direct commands |
| Wall of text | Model loses important details | Use headers, lists, structure |
| Over-prompting with emphasis | Causes overtriggering in newer models | Use normal language |
