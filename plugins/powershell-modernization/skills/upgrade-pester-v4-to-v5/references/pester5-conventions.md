# Pester 5 Conventions

Target conventions for migrated tests, based on the
[awesome-copilot Pester 5 instructions](https://github.com/github/awesome-copilot/blob/main/instructions/powershell-pester-5.instructions.md).
Apply these after the structural migration in
[v4-to-v5-mapping.md](v4-to-v5-mapping.md) is complete and the suite is green.

## File naming and structure

- Name test files `*.Tests.ps1`.
- Place them next to the tested code or in a dedicated test directory.
- Import tested code with `BeforeAll { . $PSScriptRoot/FunctionName.ps1 }`.
- Put **all** code inside Pester blocks — never at the top of the file.

## Structure hierarchy

```powershell
BeforeAll {
    . $PSScriptRoot/Get-UserInfo.ps1
}

Describe 'Get-UserInfo' {
    Context 'When the user exists' {
        BeforeAll {
            Mock Get-ADUser { @{ Name = 'TestUser'; Enabled = $true } }
        }

        It 'Returns the user object' {
            $result = Get-UserInfo -Username 'TestUser'
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestUser'
        }

        It 'Calls Get-ADUser once' {
            Get-UserInfo -Username 'TestUser'
            Should -Invoke Get-ADUser -Exactly 1
        }
    }
}
```

## Core keywords

- `Describe` — top-level grouping, usually named after the function under test.
- `Context` — scenario sub-grouping; may be nested.
- `It` — individual test case with a descriptive behavior name.
- `Should` — assertion keyword.
- `BeforeAll`/`AfterAll` — once per containing block.
- `BeforeEach`/`AfterEach` — around every `It` in the block.

## Assertions

- Comparisons: `-Be`, `-BeExactly`, `-Not -Be`.
- Collections: `-Contain`, `-BeIn`, `-HaveCount`.
- Numeric: `-BeGreaterThan`, `-BeLessThan`, `-BeGreaterOrEqual`.
- Strings: `-Match`, `-Like`, `-BeNullOrEmpty`.
- Types/booleans: `-BeOfType`, `-BeTrue`, `-BeFalse`.
- Files: `-Exist`, `-FileContentMatch`.
- Exceptions: `-Throw`, `-Not -Throw`.

## Mocking

- `Mock CommandName { ScriptBlock }` replaces command behavior.
- `-ParameterFilter { ... }` mocks only when parameters match.
- `Should -Invoke CommandName -Exactly N` verifies call count.
- `Should -InvokeVerifiable` verifies all verifiable mocks were called.
- Prefer `Mock -ModuleName` over `InModuleScope` for testing module internals.

## Data-driven tests

```powershell
It 'Returns <Expected> for <Name>' -ForEach @(
    @{ Name = 'test1'; Expected = 'result1' }
    @{ Name = 'test2'; Expected = 'result2' }
) {
    Get-Function $Name | Should -Be $Expected
}
```

- `-ForEach` is available on `Describe`, `Context`, and `It`.
- `-TestCases` is the `It`-level alias retained for compatibility.
- Hashtable items define named variables; array items use `$_`.
- Use `<variablename>` in test names for dynamic expansion.

## Tags and skip

```powershell
Describe 'Function' -Tag 'Unit' {
    It 'Works' -Tag 'Fast' { }
    It 'Is slow' -Tag 'Slow', 'Integration' { }
}

Invoke-Pester -TagFilter 'Unit' -ExcludeTagFilter 'Slow'
```

- `-Skip:$condition` for conditional skips (evaluated during Discovery).
- `Set-ItResult -Skipped` / `-Inconclusive` for runtime skips. These throw
  internally to end the `It`, so code after them is unreachable — do not add a
  trailing `return`.

## Configuration

Define configuration **outside** test files when calling `Invoke-Pester`:

```powershell
$config = New-PesterConfiguration
$config.Run.Path = './Tests'
$config.Output.Verbosity = 'Detailed'
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.Should.ErrorAction = 'Continue'
Invoke-Pester -Configuration $config
```

Key sections: `Run` (Path, Exit), `Filter` (Tag, ExcludeTag), `Output`
(Verbosity), `TestResult` (Enabled, OutputFormat), `CodeCoverage` (Enabled,
Path), `Should` (ErrorAction), `Debug`.

## Best practices

- Descriptive names that explain behavior.
- AAA structure: Arrange, Act, Assert.
- Independent, isolated tests.
- Full cmdlet names, not aliases (`Where-Object`, not `?`).
- Group related tests in `Context` blocks; nest where helpful.
