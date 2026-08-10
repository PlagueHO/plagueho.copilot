# Pester v4 → v5 Breaking-Change Mapping

Authoritative mapping used by the `upgrade-pester-v4-to-v5` skill. Sources:
[v4→v5 migration guide](https://pester.dev/docs/migrations/v4-to-v5) and
[breaking changes in v5](https://pester.dev/docs/migrations/breaking-changes-in-v5).

## Contents

- [The two-phase engine (Discovery + Run)](#the-two-phase-engine-discovery--run)
- [Structure and setup](#structure-and-setup)
- [Assertions](#assertions)
- [Mocking](#mocking)
- [Invoke-Pester parameters](#invoke-pester-parameters)
- [Data-driven tests, Skip, and TestDrive](#data-driven-tests-skip-and-testdrive)
- [Removed and deprecated features](#removed-and-deprecated-features)

## The two-phase engine (Discovery + Run)

Pester v5 runs in two phases. **Discovery** scans every file and evaluates all
code that is *not* inside `It`, `BeforeAll`, `BeforeEach`, `AfterAll`, or
`AfterEach`. **Run** then executes the discovered blocks.

Consequences:

- Code at the top of a file or directly inside `Describe`/`Context` runs during
  Discovery, and its state may not survive into Run.
- Variables defined in Discovery are **not** available in `BeforeAll`/`BeforeEach`/
  `It`/`AfterAll`/`AfterEach`.
- Discovery should be fast; avoid expensive work there.

| v4 habit | v5 requirement |
|----------|----------------|
| Setup code in `Describe` body | Move to `BeforeAll`/`BeforeEach` |
| Loop building tests in `Describe` body | Wrap loop data in `BeforeDiscovery`; feed tests via `-ForEach` |
| Relying on a `Describe`-scope variable inside `It` | Pass it through `-ForEach`/`-TestCases` |

## Structure and setup

| v4 | v5 |
|----|----|
| `. $MyInvocation.MyCommand.Path.Replace('.Tests.ps1','.ps1')` | `BeforeAll { . $PSScriptRoot/Name.ps1 }` |
| Dot-source at top of file | Dot-source inside `BeforeAll` |
| `$MyInvocation.MyCommand.Path` for location | `$PSScriptRoot` or `$PSCommandPath` |
| `InModuleScope { Describe ... }` | Prefer `Mock -ModuleName`; if needed, `InModuleScope` inside `It` |

## Assertions

| v4 | v5 |
|----|----|
| `Should Be 1` (legacy, no dash) | `Should -Be 1` |
| `Should Not Be 1` | `Should -Not -Be 1` |
| `Should Throw 'not found'` | `Should -Throw '*not found*'` |
| `{ ... } \| Should Throw` | `{ ... } \| Should -Throw` |

`Should -Throw` matches the exception message with `-like`, not `.Contains`. Wrap
expected substrings in `*` wildcards or the match requires the full message.

## Mocking

| v4 | v5 |
|----|----|
| `Assert-MockCalled Foo -Times 1 -Exactly` | `Should -Invoke Foo -Times 1 -Exactly` |
| `Assert-MockCalled Foo -ParameterFilter {...}` | `Should -Invoke Foo -ParameterFilter {...}` |
| `Assert-VerifiableMock` / `Assert-VerifiableMocks` | `Should -InvokeVerifiable` |

**Mock scoping changed.** In v4, mocks effectively applied to the whole
`Describe`/`Context`. In v5, a mock applies from its **placement** onward within
its block and that block's children. A mock in `BeforeAll` covers the block; a
mock inside an `It` covers only that `It`. After moving mocks during migration,
re-check every `-Times`/`-Exactly` assertion.

**Counting scope depends on placement.** `Should -Invoke` defaults to `It` scope
when called from `It`, `BeforeEach`, or `AfterEach`, and to the containing
`Describe`/`Context` scope when called from `BeforeAll`/`AfterAll`. Override the
default with `-Scope It`/`-Scope Context`/`-Scope Describe`.

**Mocking commands called inside a module.** A plain `Mock` only intercepts calls
made from the test script. To mock a command called by the module under test, add
`-ModuleName MyModule` to both `Mock` and `Should -Invoke`. Inside an
`InModuleScope MyModule { ... }` block, `-ModuleName` is implicit and omitted.
Prefer `Mock -ModuleName` over `InModuleScope`; when `InModuleScope` is required,
keep it inside an `It`, and use the `script:` modifier for variables that must
persist beyond the scriptblock. Manifest modules fully support `Mock -ModuleName`
and `InModuleScope` in Pester 5.4+. Binary modules can have their exported commands
mocked, but `-ModuleName` injection and `InModuleScope` are not possible.

**Other mock changes.** `-ParameterFilter` no longer requires a `param()` block;
reference the command's parameters directly. Inside a mock body use
`$PesterBoundParameters` (Pester 5.2+) instead of `$PSBoundParameters`, which the
mock hook overwrites. Mocks are no longer rewritten, so you can set breakpoints
inside mock bodies and `-ParameterFilter` blocks.

## Invoke-Pester parameters

Simple interface: `-Path`, `-ExcludePath`, `-Tag`, `-ExcludeTag`,
`-FullNameFilter`, `-Output`, `-CI`, `-PassThru`.

| v4 parameter | v5 |
|--------------|----|
| `-Script <path or hashtable>` | `-Path <path[]>` (paths only — no hashtables) |
| `-TestName` | `-FullNameFilter` |
| `-Show <value>` | `-Output` (`None`, `Normal`, `Detailed`, `Diagnostic`) |
| `-PesterOption` | removed |
| `-Strict` | removed |
| `-EnableExit` | `Run.Exit` (configuration) |
| `-CodeCoverage` | `CodeCoverage.Path` |
| `-CodeCoverageOutputFile` | `CodeCoverage.OutputPath` |
| `-OutputFile` | `TestResult.OutputPath` |
| `-OutputFormat` | `TestResult.OutputFormat` |

`-Show` value mapping to `Output.Verbosity`: `All`/`Default`/`Detailed` →
`Detailed`; `Fails`/`Normal` → `Normal`; `Diagnostic` → `Diagnostic`;
`Minimal` → `Minimal`; `None` → `None`.

Advanced interface (preferred):

```powershell
$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.Run.Exit = $true
$config.Filter.Tag = 'Unit'
$config.Output.Verbosity = 'Detailed'
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.CodeCoverage.Enabled = $true
Invoke-Pester -Configuration $config
```

For CI consuming the v4 result shape, use `ConvertTo-Pester4Result`. For NUnit
output, use `-CI` or `ConvertTo-NUnitReport`.

## Data-driven tests, Skip, and TestDrive

- `-TestCases` and `-ForEach` are evaluated during **Discovery**; expensive setup
  there runs on every discovery. Each case's data is available on the result's
  `Data` property.
- `It` still splats hashtable case data into named variables — no `param` block
  needed. Templated names use `<name>` placeholders.
- `-Skip:$condition` is evaluated during Discovery. Keep skip conditions cheap or
  static (e.g. `$IsWindows`); for runtime skips use `Set-ItResult -Skipped`.
- `TestDrive` exists only during **Run** — it cannot be used in `-ForEach`.

## Removed and deprecated features

- Legacy `Should Be` (no dash) is removed.
- `Assert-VerifiableMocks` removed; `Assert-MockCalled` and `Assert-VerifiableMock`
  deprecated.
- `Set-ItResult -Pending` deprecated.
- `-Strict` and `-PesterOption` removed; `-Show` alias removed.
- Gherkin support removed (stay on Pester 4 for Gherkin).
- PowerShell 2 is no longer supported.
