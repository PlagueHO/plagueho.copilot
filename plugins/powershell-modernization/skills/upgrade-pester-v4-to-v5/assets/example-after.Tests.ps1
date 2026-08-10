# Pester v5 — the same test file (AFTER migration)
# Mirrors example-before.Tests.ps1, migrated per the upgrade-pester-v4-to-v5 skill.

#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5.0' }

BeforeAll {
    # v5: import the code under test inside BeforeAll using $PSScriptRoot.
    . $PSScriptRoot/Get-UserInfo.ps1
}

BeforeDiscovery {
    # v5: discovery-time data must live in BeforeDiscovery so -ForEach can see it.
    $knownUsers = @('alice', 'bob')
}

Describe 'Get-UserInfo' {

    Context 'When the user exists' {

        BeforeAll {
            # v5: setup moved out of the Describe body into a block.
            Mock Get-ADUser { @{ Name = 'TestUser'; Enabled = $true } }
        }

        It 'returns the user object' {
            $result = Get-UserInfo -Username 'TestUser'
            $result.Name | Should -Be 'TestUser'
        }

        It 'calls Get-ADUser once' {
            Get-UserInfo -Username 'TestUser'
            Should -Invoke Get-ADUser -Times 1 -Exactly
        }
    }

    Context 'When the user does not exist' {

        BeforeAll {
            Mock Get-ADUser { throw 'User not found' }
        }

        It 'throws a not-found error' {
            # v5: -Throw matches with -like, so wrap the substring in wildcards.
            { Get-UserInfo -Username 'ghost' } | Should -Throw '*not found*'
        }
    }

    # v5: data-driven tests use -ForEach with data from BeforeDiscovery.
    It 'recognizes known user <_>' -ForEach $knownUsers {
        Get-UserInfo -Username $_ | Should -Not -BeNullOrEmpty
    }
}
