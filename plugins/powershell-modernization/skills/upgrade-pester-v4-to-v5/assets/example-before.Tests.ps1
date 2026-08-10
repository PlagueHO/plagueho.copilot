# Pester v4 — representative test file (BEFORE migration)
# This file demonstrates the common v4 constructs that the
# upgrade-pester-v4-to-v5 skill replaces. See example-after.Tests.ps1.

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here/Get-UserInfo.ps1"

$global:knownUsers = @('alice', 'bob')

Describe 'Get-UserInfo' {

    # v4: setup placed directly in the Describe body
    Mock Get-ADUser { @{ Name = 'TestUser'; Enabled = $true } }

    Context 'When the user exists' {

        It 'returns the user object' {
            $result = Get-UserInfo -Username 'TestUser'
            $result.Name | Should Be 'TestUser'
        }

        It 'calls Get-ADUser once' {
            Get-UserInfo -Username 'TestUser'
            Assert-MockCalled Get-ADUser -Times 1 -Exactly
        }
    }

    Context 'When the user does not exist' {

        It 'throws a not-found error' {
            Mock Get-ADUser { throw 'User not found' }
            { Get-UserInfo -Username 'ghost' } | Should Throw 'not found'
        }
    }

    # v4: data-driven loop built in the Describe body
    foreach ($user in $global:knownUsers) {
        It "recognizes known user $user" {
            Get-UserInfo -Username $user | Should Not BeNullOrEmpty
        }
    }
}
