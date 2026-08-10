---
name: upgrade-pester-v4-to-v5
description: >-
  **WORKFLOW SKILL** — Migrate PowerShell Pester v4 tests to Pester v5, covering
  structural, assertion, and mock changes. WHEN: "upgrade Pester to v5", "migrate
  Pester v4 to v5", "convert Pester tests to Pester 5", "modernize Pester tests",
  "Assert-MockCalled to Should -Invoke". INVOKES: run_in_terminal for detection
  scripts and Invoke-Pester. FOR SINGLE OPERATIONS: edit one assertion or
  Invoke-Pester call directly.
metadata:
  author: Daniel Scott-Raynsford
  version: "1.0"
  reference: https://pester.dev/docs/migrations/v4-to-v5
---

# Upgrade Pester v4 to v5

Migrate PowerShell test suites from Pester v4 to Pester v5 so they pass under the
v5 two-phase (Discovery + Run) engine and conform to current conventions.

**Required references** — consult before and during migration:

- [Migrating from Pester v4 to v5](https://pester.dev/docs/migrations/v4-to-v5)
- [Breaking changes in v5](https://pester.dev/docs/migrations/breaking-changes-in-v5)
- [awesome-copilot Pester 5 instructions](https://github.com/github/awesome-copilot/blob/main/instructions/powershell-pester-5.instructions.md)

The full breaking-change mapping lives in
[references/v4-to-v5-mapping.md](references/v4-to-v5-mapping.md). The target style
rules live in [references/pester5-conventions.md](references/pester5-conventions.md).
Before/after examples are in [assets/](assets/).

## Why reliability matters here

A Pester v4→v5 migration silently changes behavior if done carelessly: code that
used to run inside `Describe`/`Context` now runs during **Discovery**, mocks are
scoped by **placement** rather than the whole block, and `Should -Throw` matches
with `-like` instead of `.Contains`. A test that still *passes* may no longer
test what it claims. Therefore this workflow is **evidence-driven**: establish a
green baseline first, migrate in small reviewable units, and re-run the suite
after every file. Never declare success without a passing `Invoke-Pester` run.

## Prerequisites

- **PowerShell 5.1+ or PowerShell 7+** (`pwsh` recommended).
- **Pester 5.x** installed: `Install-Module Pester -MinimumVersion 5.5.0 -Force -SkipPublisherCheck`.
- A **clean source-control state** so every change is reviewable and reversible.
- The **module or scripts under test** must be importable from the test files.

## Process

### Step 1 — Establish a baseline

Capture the current state so regressions are detectable:

1. Confirm the working tree is committed (or stash unrelated changes).
2. Record the installed Pester version: `Get-Module Pester -ListAvailable | Select-Object Version`.
3. If Pester 4 is still available, run the suite once and save the result count.
   This is the behavior you must preserve. If only Pester 5 is installed, capture
   the current (likely failing) `Invoke-Pester` output instead — it becomes the
   error list to drive the migration.

> Do not change test *intent* during migration. The goal is identical coverage
> under the new engine, not new or "improved" tests.

### Step 2 — Detect v4 patterns

Run the detection script to inventory every file and the v4 constructs it
contains. This produces the worklist; do not migrate blind.

**PowerShell:**

```powershell
& "<skill-path>/scripts/Find-PesterV4Pattern.ps1" -Path . -OutputFormat Table
```

**Shell:**

```bash
"<skill-path>/scripts/find-pester-v4-pattern.sh" --path .
```

The script flags: legacy `Should` (no dash), `Assert-MockCalled`,
`Assert-VerifiableMock(s)`, `InModuleScope` wrappers, `$MyInvocation.MyCommand.Path`,
top-level/`Describe`-body code, and deprecated `Invoke-Pester` parameters
(`-Script`, `-TestName`, `-Show`, `-PesterOption`, `-Strict`). Treat its output as
the checklist for Steps 3–5.

### Step 3 — Migrate test-file structure (the high-risk change)

For **each** `*.Tests.ps1` file, apply these structural rules. They address the
two-phase engine and are the most common cause of silent breakage:

1. **Move all executable code into Pester blocks.** No code may sit at the top of
   the file or directly inside a `Describe`/`Context` body. Wrap shared setup in
   `BeforeAll` (runs once per block during Run), per-test setup in `BeforeEach`,
   and teardown in `AfterAll`/`AfterEach`. Teardown runs inside a `finally`, so it
   executes even when a test or its setup fails. Variables from `BeforeAll` are
   visible to child blocks but read-only there (tests stay isolated); `BeforeEach`,
   `It`, and `AfterEach` share one scope, so `AfterEach` can see variables an `It`
   created.
2. **Import the code under test inside `BeforeAll`** using `$PSScriptRoot`:

   ```powershell
   BeforeAll {
       . $PSScriptRoot/Get-Thing.ps1
       # or dot-source the sibling script: . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
       # or import a module: Import-Module $PSScriptRoot/MyModule.psd1 -Force
   }
   ```

   Replace any `$MyInvocation.MyCommand.Path` path discovery with `$PSScriptRoot`
   or `$PSCommandPath`; the former does not work in v5 `BeforeAll`.
3. **Move discovery-time code into `BeforeDiscovery`.** Code that builds
   `-ForEach`/`-TestCases` data, or computes `-Skip` conditions, runs during
   Discovery. Put it in `BeforeDiscovery`, not `BeforeAll` (which runs later).
4. **Pass data into tests explicitly.** Variables created in Discovery are **not**
   visible in `It`/`BeforeAll`. Supply them via `-ForEach`/`-TestCases` so each
   test receives its own data.
5. **Do not wrap `Describe`/`It` in `InModuleScope`.** To intercept a module's
   internal calls, prefer `Mock -ModuleName MyModule` (see Step 4). Reserve
   `InModuleScope` for reaching *non-exported* functions, and place it **inside** an
   `It`, never around `Describe`/`Context`/`It`; wrapping blocks prevents testing
   exported functions, skips export validation, and slows Discovery by loading the
   module. Variables or functions created inside `InModuleScope` do not persist by
   default; use the `script:` scope modifier when they must outlive the scriptblock.

See [references/v4-to-v5-mapping.md](references/v4-to-v5-mapping.md) for the
exhaustive rule table and [assets/example-before.Tests.ps1](assets/example-before.Tests.ps1)
versus [assets/example-after.Tests.ps1](assets/example-after.Tests.ps1).

### Step 4 — Migrate assertions and mocks

Apply these token-level replacements (full list in the mapping reference):

| v4 construct | v5 replacement |
|--------------|----------------|
| `Should Be x` (no dash) | `Should -Be x` |
| `Should Throw 'msg'` | `Should -Throw '*msg*'` (matches with `-like`) |
| `Assert-MockCalled Foo -Times 1` | `Should -Invoke Foo -Times 1` |
| `Assert-VerifiableMock(s)` | `Should -InvokeVerifiable` |

Critical mock behavior changes:

- **Mocks are scoped by placement, not the whole `Describe`/`Context`.** A mock in
  `BeforeAll` covers the block and its children; a mock inside an `It` covers only
  that `It`. Move mocks deliberately and re-check every `-Times`/`-Exactly` after
  re-scoping.
- **Mock counting also depends on placement.** `Should -Invoke` defaults to `It`
  scope when called from `It`, `BeforeEach`, or `AfterEach`, and to the containing
  `Describe`/`Context` scope when called from `BeforeAll`/`AfterAll`. Override with
  `-Scope It`/`-Scope Context`/`-Scope Describe` when the assertion sits in a
  different block than the calls it counts.
- **Mock commands called *inside* a module with `-ModuleName`.** A plain `Mock`
  only intercepts calls made from the test script. To mock a command invoked by the
  module under test, use `Mock -ModuleName MyModule CommandName { ... }` and verify
  with `Should -Invoke CommandName -ModuleName MyModule`. Inside an
  `InModuleScope MyModule { ... }` block the `-ModuleName` is implicit and omitted.
- **`-ParameterFilter` no longer needs a `param()` block**; reference the mocked
  command's parameters (for example `$Path`) directly.
- **Read bound parameters with `$PesterBoundParameters`** (Pester 5.2+) inside a
  mock body; the mock hook overwrites `$PSBoundParameters`.
- **`Should -Throw` matches with `-like`.** Wrap expected substrings in `*`
  wildcards, or the assertion requires an exact message match and fails.

### Step 5 — Migrate `Invoke-Pester` calls and configuration

Update runners, CI scripts, and build tasks:

- `-Script` → `-Path` (paths only — hashtables are not accepted).
- `-TestName` → `-FullNameFilter`.
- `-Show` → `-Output` with one of `None`, `Normal`, `Detailed`, `Diagnostic`.
- Remove `-PesterOption` and `-Strict` (unsupported).
- Prefer the advanced interface for anything non-trivial:

  ```powershell
  $config = New-PesterConfiguration
  $config.Run.Path = './tests'
  $config.Output.Verbosity = 'Detailed'
  $config.TestResult.Enabled = $true
  $config.TestResult.OutputFormat = 'NUnitXml'
  Invoke-Pester -Configuration $config
  ```

For CI that still consumes the v4 result shape, convert with
`ConvertTo-Pester4Result`, or emit NUnit output via `-CI` / `ConvertTo-NUnitReport`.
The legacy-parameter mapping (`EnableExit`, `CodeCoverage`, `OutputFile`, …) is in
the mapping reference.

### Step 6 — Validate after every file

Reliability gate: run the suite and require a green (or baseline-equivalent)
result before moving on.

**PowerShell:**

```powershell
& "<skill-path>/scripts/Invoke-PesterValidation.ps1" -Path . -Verbosity Detailed
```

**Shell:**

```bash
"<skill-path>/scripts/invoke-pester-validation.sh" --path .
```

The script runs `Invoke-Pester` with the advanced configuration, fails on any
errored/failed test, and surfaces Discovery errors (the signal that structural
migration in Step 3 is incomplete). If counts dropped versus the Step 1 baseline,
a test was silently skipped — investigate before continuing.

### Step 7 — Apply conventions and finalize

Once green, align with [references/pester5-conventions.md](references/pester5-conventions.md):

- `*.Tests.ps1` naming; tests next to code or in a dedicated test directory.
- Descriptive `Describe`/`Context`/`It` names; AAA structure; isolated tests.
- Full cmdlet names (no aliases); tags for filtering; `Set-ItResult` for runtime skips.
- Add a `#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5.0' }`
  guard (or update an existing v4 requirement) where appropriate.

Then run the full suite one final time and summarize: files changed, constructs
replaced, and the before/after test counts.

## Reliability checklist

Verify all of the following before declaring the migration complete:

- [ ] Baseline test count captured before any change (Step 1)
- [ ] Detection script run; every flagged construct addressed (Step 2)
- [ ] No executable code at file top level or directly in `Describe`/`Context`
- [ ] Code under test imported in `BeforeAll` via `$PSScriptRoot`
- [ ] Discovery-time code moved to `BeforeDiscovery`; data passed via `-ForEach`
- [ ] All `Should` assertions use the dashed form; `Should -Throw` uses `*` wildcards
- [ ] `Assert-MockCalled` → `Should -Invoke`; `Assert-VerifiableMock(s)` → `Should -InvokeVerifiable`
- [ ] Mock placement and `-Times`/`-Exactly` counts re-checked after re-scoping
- [ ] Commands called inside a module mocked with `-ModuleName`; `Should -Invoke` scope verified
- [ ] `InModuleScope` (if used) kept inside `It`; no `Describe`/`Context`/`It` wrapped in it
- [ ] `Invoke-Pester` parameters and CI scripts migrated to v5 / configuration object
- [ ] `Invoke-Pester` passes with **no Discovery errors**; counts match the baseline
- [ ] Conventions applied; `#Requires` Pester version updated to 5.x

## Bundled assets

| Path | Purpose |
|------|---------|
| [scripts/Find-PesterV4Pattern.ps1](scripts/Find-PesterV4Pattern.ps1) / [.sh](scripts/find-pester-v4-pattern.sh) | Scan `*.Tests.ps1` for v4 constructs and report line numbers |
| [scripts/Invoke-PesterValidation.ps1](scripts/Invoke-PesterValidation.ps1) / [.sh](scripts/invoke-pester-validation.sh) | Run Pester 5 and fail on failures or Discovery errors |
| [references/v4-to-v5-mapping.md](references/v4-to-v5-mapping.md) | Exhaustive v4→v5 breaking-change mapping |
| [references/pester5-conventions.md](references/pester5-conventions.md) | Target Pester 5 conventions and structure |
| [assets/example-before.Tests.ps1](assets/example-before.Tests.ps1) | Representative v4 test file |
| [assets/example-after.Tests.ps1](assets/example-after.Tests.ps1) | The same file migrated to v5 |
