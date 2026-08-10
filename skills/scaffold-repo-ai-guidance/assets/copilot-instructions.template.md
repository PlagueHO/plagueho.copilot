# [Repository Name] — Copilot Instructions

<!-- .github/copilot-instructions.md — Project-specific conventions for
     GitHub Copilot chat and code review. Loaded automatically for all
     requests in this repo's context. Keep under 150 lines.
     See AGENTS.md for layout, commands, and CI pipeline. -->

## Purpose

<!-- 2–3 sentences: what the repo does, primary language/framework, target
     environment. This helps Copilot scope its suggestions correctly. -->

[Repository description. E.g., "A TypeScript REST API built with Express,
deployed to Azure App Service. Serves the public product catalog and
order-management endpoints."]

## Code Style

<!-- Only document non-obvious or non-default rules. If a formatter/linter
     enforces it, a one-line mention is sufficient. -->

- [Indentation rule, e.g., "2 spaces for TypeScript; 4 spaces for Python"]
- [Quote style, e.g., "Single quotes for strings; backticks for interpolation"]
- [Import order, e.g., "stdlib → third-party → local, separated by blank lines"]
- [Line length, e.g., "120 characters max; exceptions for URLs and tables"]

## Naming Conventions

<!-- Include brief examples for non-obvious rules. -->

| Element | Convention | Example |
|---------|-----------|---------|
| Files | [e.g., kebab-case] | `user-service.ts` |
| Classes | [e.g., PascalCase] | `UserService` |
| Functions | [e.g., camelCase] | `getUserById()` |
| Constants | [e.g., UPPER_SNAKE] | `MAX_RETRY_COUNT` |
| Database tables | [e.g., snake_case] | `user_sessions` |

## [Primary Framework] Patterns

<!-- Replace heading with the framework name, e.g., "Express Patterns",
     "React Patterns", "ASP.NET Core Patterns".
     Document 3–5 key conventions. Use do/don't examples for the most
     important or surprising rules. -->

- [Pattern 1, e.g., "Use controller classes for route handlers, not inline functions"]
- [Pattern 2, e.g., "Return Result<T> from service methods; never throw for expected errors"]
- [Pattern 3, e.g., "Inject dependencies via constructor; do not use service locator"]

<!-- Example of a non-obvious do/don't:

**Do:**
```typescript
export class UserController {
  constructor(private readonly userService: UserService) {}
}
```

**Don't:**
```typescript
import { userService } from '../services';
export function getUser(req, res) { ... }
```
-->

## Testing

<!-- Patterns specific to how this repo writes tests. -->

- [Test framework, e.g., "Use Jest with TypeScript; co-locate test files as `*.test.ts`"]
- [Naming, e.g., "Test names follow: `should <expected behavior> when <condition>`"]
- [Mocking, e.g., "Use dependency injection over module mocking"]

## Security

<!-- Only rules applicable to this codebase.
     Omit generic OWASP advice unless the repo has specific enforcement. -->

- [e.g., "Never log request bodies — they may contain PII"]
- [e.g., "All SQL queries use parameterized statements; no string concatenation"]
- [e.g., "Validate all external input at the API boundary with Zod schemas"]
- [e.g., "Never commit secrets; use environment variables via `.env.local`"]
