---
name: ai-content-readiness-review

description: >-
  **ANALYSIS SKILL** — Review documents for compliance with AI-optimized content guidelines. Evaluates accuracy, metadata tagging, structure, tone, accessibility, and AI-friendly formatting. WHEN: "review content for AI readiness", "AI content audit", "check document for AI best practices", "content readiness review", "is this document AI-ready", "evaluate content quality for AI". FOR SINGLE OPERATIONS: Read the document and assess each criterion directly.

license: MIT

metadata:
  author: PlagueHO
  version: "1.0"
  reference: https://github.com/PlagueHO/plagueho.os/

compatibility: >-
  GitHub Copilot, VS Code
---

## Overview

Review one or more documents to determine if they adhere to key best practices for AI-ready content. Examine content against six criteria to ensure material is optimized for consumption by AI systems such as generative language models. Highlight issues found and suggest actionable improvements.

## Prerequisites

No special tools or runtimes are required. The skill operates on any text-based document provided in the editor.

## Input and Output

- **Input**: The text of the document(s) to analyze, provided as an open file, text selection, or file path reference. Handles single or multiple documents.
- **Output**: A structured analysis report evaluating the content against each criterion, listing compliance notes and recommendations for improvement.

## Evaluation Criteria

| Criterion | Purpose |
| --- | --- |
| **Accuracy** | Content is factually correct, up-to-date, and free of errors. Builds trust and prevents AI from propagating misinformation. |
| **Metadata Tagging** | Relevant metadata is present (title, authorship, last updated date, audience, content type). Improves discoverability and helps AI interpret context. |
| **Structure & Templates** | Content follows a logical structure with clear sections, headings, and ordering. Makes it easier for AI to parse and locate information. |
| **Conversational Tone** | Writing style is clear, natural, and user-friendly. Helps AI models trained on natural language understand and use the content effectively. |
| **Accessibility** | Images have alt text, videos have captions or transcripts, text is structured for screen readers. Allows AI to access all information inclusively. |
| **AI-Friendly Formatting** | Descriptive headings, short paragraphs, bullet points, and tables are used. Well-formatted content is easier for AI to navigate and extract from. |

## Process

### Step 1 — Examine the Document(s)

Read the provided content thoroughly. If multiple documents are given, handle them individually or compare them if relevant to the request. Identify the document type (how-to guide, FAQ, reference article, blog post) because evaluation context varies by type.

### Step 2 — Evaluate Each Criterion

Assess the document against each criterion below. For every criterion, note whether the document meets the guideline and provide specific recommendations when it does not.

#### Accuracy

Identify statements that might be outdated, incorrect, or unclear. Check for factual correctness and completeness. If the content references data or product information, consider whether it is current and valid. Note issues such as outdated statistics, broken links, or inconsistent facts.

#### Metadata Tagging

Determine if the document includes metadata or front matter such as a title, author, last updated date, intended audience, or relevant tags. If metadata is missing or incomplete, highlight that and suggest appropriate fields to add. Metadata matters because AI systems use it to rank and contextualize content.

#### Structure & Templates

Check the organization of the content. Confirm it follows a sensible flow with clear sections and headings. If the content is expected to follow a specific template (how-to guide, FAQ, reference article), verify those elements are present — an introduction, step-by-step sections, and a conclusion.
Point out structural improvements such as adding a summary, reordering sections for logical flow, or applying a standard template.

#### Conversational Tone

Analyze the tone and clarity of writing. The content should use plain, natural language with active voice and clear phrasing. If the text is too formal, overly technical, or uses unnecessary jargon, suggest ways to make it more conversational and approachable. Note whether the content uses a friendly style or Q&A format where suitable, and recommend simplifying complex sentences.

#### Accessibility

Verify that all non-text elements have text equivalents and that content is perceivable by assistive technologies. Check that images have meaningful alt text, and that multimedia such as videos have captions or transcripts. Confirm the document uses semantic headings and lists properly. Missing accessibility features reduce the amount of information AI can extract.

#### AI-Friendly Formatting

Examine how information is formatted. Look for headings and subheadings to break up topics, bullet or numbered lists for enumerations or steps, and tables for data that would be clearer in rows and columns.
Check that paragraphs are succinct (a few sentences each) and that content is not hidden in overly dense text.
If the document is a wall of text, suggest breaking it into smaller paragraphs, using lists, or converting repetitive text into a table.

### Step 3 — Compile the Results

Summarize findings for the user, organized by criterion using headings or bullet points. Clearly indicate whether the document meets each guideline and provide specific recommendations for any area that needs improvement. Use a professional and constructive tone.

### Step 4 — Handle Multiple Documents

If multiple documents are being analyzed, repeat the evaluation for each and label each analysis separately with a heading or title. This ensures the user can identify which feedback applies to which file.

## Edge Cases

- **No metadata system**: Some document formats do not support front matter (e.g., plain `.txt` files). Note the absence and recommend converting to a format that supports metadata such as Markdown with YAML front matter.
- **Non-text content only**: If the document is primarily images, video, or binary content with minimal text, focus the review on accessibility (alt text, transcripts) and note that the other criteria have limited applicability.
- **Very short documents**: For documents under a few paragraphs, structure and formatting criteria carry less weight. Focus on accuracy, metadata, and tone instead.
- **Multiple languages**: If the document contains content in multiple languages, evaluate each language section independently and note any inconsistencies between them.
- **Domain-specific jargon**: Technical documents aimed at expert audiences may intentionally use specialized terminology. Note the jargon but assess whether it is appropriate for the stated audience rather than always recommending simplification.

## Example

**User Prompt:** "Analyze the draft article below and tell me if it follows AI content best practices."

**Expected Response:**

- **Accuracy**: The article appears accurate and up-to-date; all facts and figures are current with no obvious errors found.
- **Metadata**: No metadata section (title, author, last updated date) is present. Add those details to improve context and traceability.
- **Structure**: The content is divided into clear sections with headings. Add a brief introduction at the top to outline purpose before diving into details.
- **Conversational Tone**: The tone is mostly conversational and easy to follow. One or two complex sentences could be simplified, but overall the language is reader-friendly.
- **Accessibility**: The draft includes images but does not provide alt text. Add descriptive alt text to each image so that screen readers and AI tools can interpret the visual content.
- **Formatting**: Good use of bullet points and numbered lists. Paragraph lengths are reasonable. Consider using a table to summarize comparative data for easier scanning by AI.
