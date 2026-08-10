# Token Optimization Patterns

Reference tables for identifying and replacing token-waste patterns in prompt,
skill, and agent definition files.

## Redundant and Filler Language

Flag and remove these patterns — they add no precision:

### Filler Adverbs

"simply", "just", "basically", "actually", "really", "very", "extremely",
"quite", "fairly", "rather", "somewhat"

### Hedging Phrases

- "it is important to note that"
- "please make sure to"
- "you should consider"
- "it is worth mentioning"
- "keep in mind that"
- "note that you should"

### Redundant Preambles

- "In order to"
- "The purpose of this is to"
- "What this does is"
- "This section describes how to"

### Filler Transitions

- "Next, we will"
- "Now let's"
- "Moving on to"
- "As mentioned above"
- "As previously stated"

### Polite Padding

"please", "kindly", "if you don't mind"

### Tautologies

- "each and every"
- "first and foremost"
- "any and all"
- "completely and totally"

## Verbose-to-Concise Replacements

| Verbose | Concise |
|---------|---------|
| "in order to" | "to" |
| "due to the fact that" | "because" |
| "at this point in time" | "now" |
| "in the event that" | "if" |
| "with the exception of" | "except" |
| "on a regular basis" | "regularly" |
| "a large number of" | "many" |
| "has the ability to" | "can" |
| "is able to" | "can" |
| "make sure that" | "ensure" |
| "whether or not" | "whether" |
| "it is necessary to" | "must" |
| "for the purpose of" | "to" / "for" |
| "in the case of" | "for" / "when" |
| "the fact that" | remove or rephrase |
| "there is/are ... that" | rephrase directly |

## Structural Redundancy Patterns

- Repeated instructions already covered by frontmatter or parent context.
- Descriptions that restate the heading in prose form.
- Section introductions that repeat the section title as a sentence.
- Duplicate constraints stated in multiple places — consolidate to one
  location, keeping the most specific version.
- Examples that illustrate the same pattern more than once — keep the most
  illustrative example.

**Caution**: If a statement appears duplicated but serves a different purpose
in each location (e.g., a constraint repeated as a validation check), keep
both.

## Unnecessary Formatting Patterns

- Excessive blank lines (more than one consecutive).
- Decorative separators or horizontal rules with no structural purpose.
- Over-use of bold/italic where structure already conveys importance.
- Long table header labels that can be shortened.

## Instruction Precision Patterns

- Passive voice → active voice ("The file should be read" → "Read the file").
- Conditional → imperative where the condition is always true.
- Vague quantifiers ("some", "various", "several") → specific values or
  remove.
- Meta-commentary about the instructions ("This section explains how to...")
  → remove.
