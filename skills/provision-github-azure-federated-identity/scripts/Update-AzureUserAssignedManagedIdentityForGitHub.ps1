#Requires -Modules @{ ModuleName="Az.Accounts"; ModuleVersion="5.3.2" }
#Requires -Modules @{ ModuleName="Az.Resources"; ModuleVersion="9.0.0" }
#Requires -Modules @{ ModuleName="Az.ManagedServiceIdentity"; ModuleVersion="2.0.0" }

<#
.SYNOPSIS
    Creates or updates a single Azure User Assigned Managed Identity for GitHub OIDC authentication.

.DESCRIPTION
    Provisions one User Assigned Managed Identity (UAMI) with a Federated Identity Credential
    and RBAC role assignments for passwordless GitHub authentication via OIDC. Run once per
    identity needed (once per GitHub Actions environment, or once for the Copilot coding agent).

    Each invocation creates or verifies:
    - A resource group named rg-github-<RepositoryName>-mi (or a custom name)
    - One User Assigned Managed Identity (name derived from Type/Environment, or custom)
    - A Federated Identity Credential binding the identity to the GitHub context
    - RBAC role assignments at subscription scope (Contributor + User Access Administrator
      with conditions, or a custom list)

    The script is idempotent — existing resources are left unchanged and their details output.

.PARAMETER RepositoryName
    The GitHub repository name. Used to derive resource group and identity names, and to
    construct OIDC federated credential subjects.

.PARAMETER Type
    The identity type to provision. Accepted values:
    - 'actions'     : For a GitHub Actions deployment environment (requires -Environment).
    - 'codingAgent' : For the GitHub Copilot coding agent.
    Defaults to 'actions'.

.PARAMETER Environment
    The GitHub environment name (e.g. 'test', 'staging', 'prod'). Only used when
    -Type is 'actions'. Defaults to 'test'.

.PARAMETER GitHubOrganization
    The GitHub organization or user account that owns the repository. Defaults to 'PlagueHO'.

.PARAMETER SubscriptionId
    The Azure subscription ID to deploy resources into. Defaults to the current context.

.PARAMETER Location
    The Azure region for the resource group and identity. Defaults to 'New Zealand North'.

.PARAMETER ResourceGroupName
    Overrides the default resource group name ('rg-github-<RepositoryName>-mi').

.PARAMETER IdentityName
    Overrides the computed UAMI name.
    Defaults:
    - actions type     : 'mi-actions-<RepositoryName>-<Environment>-env'
    - codingAgent type : 'mi-coding-agent-<RepositoryName>'

.PARAMETER RbacRoles
    Array of RBAC role names to assign to the identity at subscription scope.
    Defaults to @('Contributor', 'User Access Administrator').
    When 'User Access Administrator' is included it is always assigned with a condition
    that prevents granting Owner, User Access Administrator, or Role Based Access Control
    Administrator to any principal.

.PARAMETER RemoveUnlistedRoles
    When specified, removes any subscription-scope role assignments for this identity
    that are not present in -RbacRoles. By default, unlisted roles are left intact.

.PARAMETER Force
    Skips interactive confirmation prompts.

.EXAMPLE
    .\Update-AzureUserAssignedManagedIdentityForGitHub.ps1 -RepositoryName 'my-repo' -Type 'actions' -Environment 'test'

    Creates a GitHub Actions identity for the 'test' environment.

.EXAMPLE
    .\Update-AzureUserAssignedManagedIdentityForGitHub.ps1 -RepositoryName 'my-repo' -Type 'codingAgent'

    Creates a Copilot coding agent identity.

.EXAMPLE
    foreach ($env in @('test', 'staging', 'prod')) {
        .\Update-AzureUserAssignedManagedIdentityForGitHub.ps1 -RepositoryName 'my-repo' -Type 'actions' -Environment $env -Force
    }

    Creates identities for three GitHub Actions environments.

.EXAMPLE
    .\Update-AzureUserAssignedManagedIdentityForGitHub.ps1 -RepositoryName 'my-repo' -Type 'actions' -Environment 'prod' `
        -RbacRoles @('Contributor') -RemoveUnlistedRoles

    Ensures only the Contributor role is assigned, removing any others.

.OUTPUTS
    PSCustomObject with properties: ResourceGroupName, Location, IdentityName, ClientId,
    PrincipalId, FederatedCredentialName, Subject, RbacRoles, TenantId, SubscriptionId.

.NOTES
    Requires: Az.Accounts, Az.Resources, Az.ManagedServiceIdentity PowerShell modules.
    Requires: Authenticated Azure session (Connect-AzAccount).
    Requires: Permission to create resource groups, managed identities, and assign RBAC roles.

.LINK
    https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$RepositoryName,

    [Parameter()]
    [ValidateSet('actions', 'codingAgent')]
    [string]$Type = 'actions',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Environment = 'test',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$GitHubOrganization = 'PlagueHO',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location = 'New Zealand North',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$IdentityName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string[]]$RbacRoles = @('Contributor', 'User Access Administrator'),

    [Parameter()]
    [switch]$RemoveUnlistedRoles,

    [Parameter()]
    [switch]$Force
)

#region Main Script

begin {
    Write-Verbose "Starting Azure User Assigned Managed Identity setup process"
    $ErrorActionPreference = 'Stop'

    #region Helper Functions

    function Initialize-AzureEnvironment {
        <#
        .SYNOPSIS
            Verifies Azure modules and authentication.

        .DESCRIPTION
            Checks that required Azure PowerShell modules are installed and loaded,
            then verifies Azure authentication and sets the subscription context.

        .PARAMETER SubscriptionId
            Optional subscription ID to set as the active context.

        .OUTPUTS
            Hashtable containing context information (Subscription, Tenant)
        #>
        [CmdletBinding()]
        param(
            [Parameter()]
            [string]$SubscriptionId
        )

        Write-Verbose "Checking for required Azure PowerShell modules"
        $requiredModules = @('Az.Accounts', 'Az.Resources', 'Az.ManagedServiceIdentity')

        foreach ($moduleName in $requiredModules) {
            if (-not (Get-Module -ListAvailable -Name $moduleName)) {
                throw "Required module '$moduleName' is not installed. Please install it using: Install-Module -Name $moduleName -Scope CurrentUser"
            }
            Import-Module -Name $moduleName -ErrorAction Stop
            Write-Verbose "Module '$moduleName' loaded successfully"
        }

        Write-Verbose "Verifying Azure authentication"
        $context = Get-AzContext
        if (-not $context) {
            throw "Not authenticated to Azure. Please run Connect-AzAccount first."
        }
        Write-Verbose "Authenticated as: $($context.Account.Id)"

        if ($SubscriptionId) {
            Write-Verbose "Setting subscription context to: $SubscriptionId"
            Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        }

        $currentSubscription = (Get-AzContext).Subscription
        Write-Verbose "Using subscription: $($currentSubscription.Name) ($($currentSubscription.Id))"

        return @{
            Subscription = $currentSubscription
            Tenant       = $context.Tenant
        }
    }

    function New-GitHubResourceGroup {
        <#
        .SYNOPSIS
            Creates a resource group for GitHub integration resources.

        .DESCRIPTION
            Creates or verifies existence of an Azure Resource Group with appropriate tags
            for GitHub repository integration.

        .PARAMETER ResourceGroupName
            The name of the resource group to create.

        .PARAMETER Location
            The Azure location for the resource group.

        .PARAMETER RepositoryName
            The GitHub repository name for tagging.

        .PARAMETER Force
            Skip confirmation prompts.
        #>
        [CmdletBinding(SupportsShouldProcess = $true)]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ResourceGroupName,

            [Parameter(Mandatory = $true)]
            [string]$Location,

            [Parameter(Mandatory = $true)]
            [string]$RepositoryName,

            [Parameter()]
            [switch]$Force
        )

        Write-Verbose "Checking for resource group: $ResourceGroupName"
        $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue

        if (-not $resourceGroup) {
            if ($Force -or $PSCmdlet.ShouldProcess($ResourceGroupName, "Create Resource Group in $Location")) {
                Write-Verbose "Creating resource group: $ResourceGroupName in $Location"
                $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag @{
                    Purpose   = 'GitHub Integration'
                    ManagedBy = 'PowerShell Script'
                    Repository = $RepositoryName
                }
                Write-Warning "Resource group '$ResourceGroupName' created in $Location"
            }
            else {
                throw "Resource group creation cancelled by user"
            }
        }
        else {
            Write-Verbose "Resource group '$ResourceGroupName' already exists"
        }

        return $resourceGroup
    }

    function New-GitHubManagedIdentity {
        <#
        .SYNOPSIS
            Creates a User Assigned Managed Identity.

        .DESCRIPTION
            Creates or verifies existence of an Azure User Assigned Managed Identity
            in the specified resource group.

        .PARAMETER ResourceGroupName
            The name of the resource group.

        .PARAMETER IdentityName
            The name of the managed identity to create.

        .PARAMETER Location
            The Azure location for the identity.

        .PARAMETER Force
            Skip confirmation prompts.

        .OUTPUTS
            Microsoft.Azure.Commands.ManagedServiceIdentity.Models.PsManagedIdentity
        #>
        [CmdletBinding(SupportsShouldProcess = $true)]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ResourceGroupName,

            [Parameter(Mandatory = $true)]
            [string]$IdentityName,

            [Parameter(Mandatory = $true)]
            [string]$Location,

            [Parameter()]
            [switch]$Force
        )

        Write-Verbose "Processing managed identity: $IdentityName"
        $identity = Get-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName -Name $IdentityName -ErrorAction SilentlyContinue

        if (-not $identity) {
            if ($Force -or $PSCmdlet.ShouldProcess($IdentityName, "Create User Assigned Managed Identity")) {
                Write-Verbose "Creating managed identity: $IdentityName"
                $identity = New-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName -Name $IdentityName -Location $Location
                Write-Warning "Managed identity '$IdentityName' created"

                # Wait for the identity's service principal to propagate in Azure AD.
                # Replication can take 15-30+ seconds; insufficient delay causes RBAC
                # assignment to fail with PrincipalNotFound even with retries.
                Write-Verbose "Waiting 30 seconds for identity to propagate in Azure AD..."
                Start-Sleep -Seconds 30
            }
            else {
                throw "Managed identity creation cancelled by user"
            }
        }
        else {
            Write-Verbose "Managed identity '$IdentityName' already exists"
        }

        return $identity
    }

    function New-GitHubFederatedCredential {
        <#
        .SYNOPSIS
            Creates a Federated Identity Credential for GitHub OIDC.

        .DESCRIPTION
            Creates or verifies existence of a Federated Identity Credential that allows
            GitHub Actions or Copilot to authenticate using OIDC.

        .PARAMETER ResourceGroupName
            The name of the resource group.

        .PARAMETER IdentityName
            The name of the managed identity.

        .PARAMETER CredentialName
            The name of the federated credential.

        .PARAMETER Subject
            The GitHub OIDC subject identifier.

        .PARAMETER Force
            Skip confirmation prompts.
        #>
        [CmdletBinding(SupportsShouldProcess = $true)]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ResourceGroupName,

            [Parameter(Mandatory = $true)]
            [string]$IdentityName,

            [Parameter(Mandatory = $true)]
            [string]$CredentialName,

            [Parameter(Mandatory = $true)]
            [string]$Subject,

            [Parameter()]
            [switch]$Force
        )

        Write-Verbose "Processing federated credential: $CredentialName"
        $existingCredential = Get-AzFederatedIdentityCredential `
            -ResourceGroupName $ResourceGroupName `
            -IdentityName $IdentityName `
            -Name $CredentialName `
            -ErrorAction SilentlyContinue

        if (-not $existingCredential) {
            if ($Force -or $PSCmdlet.ShouldProcess($CredentialName, "Create Federated Credential")) {
                Write-Verbose "Creating federated credential: $CredentialName"
                Write-Verbose "Subject: $Subject"

                New-AzFederatedIdentityCredential `
                    -ResourceGroupName $ResourceGroupName `
                    -IdentityName $IdentityName `
                    -Name $CredentialName `
                    -Issuer 'https://token.actions.githubusercontent.com' `
                    -Subject $Subject `
                    -Audience @('api://AzureADTokenExchange') | Out-Null

                Write-Warning "Federated credential '$CredentialName' created"
            }
        }
        else {
            Write-Verbose "Federated credential '$CredentialName' already exists"
        }
    }

    function Set-ManagedIdentityRbacRoles {
        <#
        .SYNOPSIS
            Assigns RBAC roles to a managed identity at subscription scope.

        .DESCRIPTION
            Assigns the specified RBAC roles to a managed identity. When 'User Access
            Administrator' is included, it is always assigned with a condition that prevents
            the identity from granting Owner, User Access Administrator, or Role Based Access
            Control Administrator to any principal.

            Existing assignments not in the provided list are left unchanged unless
            -RemoveUnlistedRoles is specified.

        .PARAMETER PrincipalId
            The principal ID of the managed identity.

        .PARAMETER IdentityName
            The name of the identity (used in log messages).

        .PARAMETER SubscriptionId
            The subscription ID used to build the role assignment scope.

        .PARAMETER RbacRoles
            Array of RBAC role names to assign. Defaults to Contributor and User Access
            Administrator when called from the main script.

        .PARAMETER RemoveUnlistedRoles
            When set, removes any subscription-scope role assignments for this identity
            that are not present in -RbacRoles.

        .PARAMETER Force
            Skip confirmation prompts.
        #>
        [CmdletBinding(SupportsShouldProcess = $true)]
        param(
            [Parameter(Mandatory = $true)]
            [string]$PrincipalId,

            [Parameter(Mandatory = $true)]
            [string]$IdentityName,

            [Parameter(Mandatory = $true)]
            [string]$SubscriptionId,

            [Parameter(Mandatory = $true)]
            [string[]]$RbacRoles,

            [Parameter()]
            [switch]$RemoveUnlistedRoles,

            [Parameter()]
            [switch]$Force
        )

        Write-Verbose "Configuring RBAC roles for '$IdentityName'"
        $subscriptionScope = "/subscriptions/$SubscriptionId"
        $maxRetries = 5
        $retryDelaySecs = 15

        # Pre-fetch prohibited role IDs needed for the UAA condition
        $ownerRoleId       = (Get-AzRoleDefinition -Name 'Owner').Id
        $uaaRoleId         = (Get-AzRoleDefinition -Name 'User Access Administrator').Id
        $rbacAdminRoleId   = (Get-AzRoleDefinition -Name 'Role Based Access Control Administrator').Id
        $uaaCondition      = "((!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidNotEquals {$ownerRoleId, $uaaRoleId, $rbacAdminRoleId}))"
        $uaaConditionVersion = '2.0'

        # Assign each requested role
        foreach ($roleName in $RbacRoles) {
            $roleDefinition = Get-AzRoleDefinition -Name $roleName -ErrorAction SilentlyContinue
            if (-not $roleDefinition) {
                Write-Warning "Role '$roleName' not found in Azure — skipping."
                continue
            }

            $existingAssignment = Get-AzRoleAssignment `
                -ObjectId $PrincipalId `
                -RoleDefinitionId $roleDefinition.Id `
                -Scope $subscriptionScope `
                -ErrorAction SilentlyContinue

            if (-not $existingAssignment) {
                $actionDescription = if ($roleName -eq 'User Access Administrator') {
                    "Assign '$roleName' (with least-privilege condition) to '$IdentityName'"
                } else {
                    "Assign '$roleName' to '$IdentityName'"
                }

                if ($Force -or $PSCmdlet.ShouldProcess($subscriptionScope, $actionDescription)) {
                    Write-Verbose $actionDescription

                    $retryCount = 0
                    $assigned   = $false
                    while (-not $assigned -and $retryCount -lt $maxRetries) {
                        try {
                            $assignParams = @{
                                ObjectId           = $PrincipalId
                                RoleDefinitionName = $roleName
                                Scope              = $subscriptionScope
                                ErrorAction        = 'Stop'
                            }
                            if ($roleName -eq 'User Access Administrator') {
                                $assignParams['Condition']        = $uaaCondition
                                $assignParams['ConditionVersion'] = $uaaConditionVersion
                            }
                            New-AzRoleAssignment @assignParams | Out-Null
                            $assigned = $true
                            Write-Warning "'$roleName' assigned to '$IdentityName'"
                        }
                        catch {
                            $retryCount++
                            if ($retryCount -lt $maxRetries) {
                                # Exponential backoff: 15s, 30s, 60s, 120s
                                $delay = $retryDelaySecs * [math]::Pow(2, $retryCount - 1)
                                Write-Verbose "Assignment failed (attempt $retryCount/$maxRetries). Retrying in $delay seconds..."
                                Start-Sleep -Seconds $delay
                            }
                            else {
                                Write-Warning "Failed to assign '$roleName' after $maxRetries attempts: $_"
                                throw
                            }
                        }
                    }
                }
            }
            else {
                Write-Verbose "'$roleName' already assigned to '$IdentityName'"
            }
        }

        # Optionally remove roles that are not in the requested list
        if ($RemoveUnlistedRoles) {
            $currentAssignments = Get-AzRoleAssignment `
                -ObjectId $PrincipalId `
                -Scope $subscriptionScope `
                -ErrorAction SilentlyContinue

            foreach ($assignment in $currentAssignments) {
                if ($assignment.RoleDefinitionName -notin $RbacRoles) {
                    if ($Force -or $PSCmdlet.ShouldProcess($assignment.RoleDefinitionName, "Remove unlisted role from '$IdentityName'")) {
                        Write-Verbose "Removing unlisted role '$($assignment.RoleDefinitionName)' from '$IdentityName'"
                        Remove-AzRoleAssignment -InputObject $assignment -ErrorAction Stop | Out-Null
                        Write-Warning "Removed role '$($assignment.RoleDefinitionName)' from '$IdentityName'"
                    }
                }
            }
        }
    }

    function Show-SetupSummary {
        <#
        .SYNOPSIS
            Displays the setup summary and next steps.

        .DESCRIPTION
            Prints the output values needed to configure GitHub repository secrets,
            along with a guide for referencing the identity in GitHub Actions workflows.

        .PARAMETER AzureContext
            Hashtable containing Subscription and Tenant information.

        .PARAMETER IdentityResult
            PSCustomObject with the identity details output by the process block.
        #>
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [hashtable]$AzureContext,

            [Parameter(Mandatory = $true)]
            [PSCustomObject]$IdentityResult
        )

        Write-Verbose "Displaying setup summary"
        Write-Host "`nNext Steps:" -ForegroundColor Cyan
        Write-Host "1. Set the following repository-level secrets in GitHub:" -ForegroundColor Yellow
        Write-Host "   AZURE_TENANT_ID       : $($AzureContext.Tenant.Id)" -ForegroundColor White
        Write-Host "   AZURE_SUBSCRIPTION_ID : $($AzureContext.Subscription.Id)" -ForegroundColor White

        Write-Host "`n2. Set the following secret under GitHub environment '$($IdentityResult.Environment)':" -ForegroundColor Yellow
        Write-Host "   AZURE_CLIENT_ID : $($IdentityResult.ClientId)" -ForegroundColor White

        Write-Host "`n3. Reference the identity in your workflow:" -ForegroundColor Yellow
        Write-Host "   permissions:" -ForegroundColor White
        Write-Host "     id-token: write" -ForegroundColor White
        Write-Host "   environment: $($IdentityResult.Environment)" -ForegroundColor White
        Write-Host "   # azure/login@v2 with client-id, tenant-id, subscription-id secrets" -ForegroundColor White
    }

    #endregion

    # Initialize Azure environment
    try {
        $azureContext = Initialize-AzureEnvironment -SubscriptionId $SubscriptionId
    }
    catch {
        throw "Azure environment initialization failed: $_"
    }
}

process {
    try {
        # Resolve resource group name
        $resolvedResourceGroupName = if ($ResourceGroupName) {
            $ResourceGroupName
        } else {
            "rg-github-$RepositoryName-mi"
        }

        # Resolve identity name and GitHub environment label based on Type
        if ($Type -eq 'codingAgent') {
            $resolvedIdentityName  = if ($IdentityName) { $IdentityName } else { "mi-coding-agent-$RepositoryName" }
            $githubEnvironment     = 'copilot'
            $federatedCredName     = "$GitHubOrganization-$RepositoryName-copilot"
            $federatedSubject      = "repo:$GitHubOrganization/$($RepositoryName):environment:copilot"
        } else {
            # Type -eq 'actions'
            $resolvedIdentityName  = if ($IdentityName) { $IdentityName } else { "mi-actions-$RepositoryName-$Environment-env" }
            $githubEnvironment     = $Environment
            $federatedCredName     = "$GitHubOrganization-$RepositoryName-$Environment"
            $federatedSubject      = "repo:$GitHubOrganization/$($RepositoryName):environment:$Environment"
        }

        Write-Verbose "Resource group : $resolvedResourceGroupName"
        Write-Verbose "Identity name  : $resolvedIdentityName"
        Write-Verbose "GitHub env     : $githubEnvironment"
        Write-Verbose "OIDC subject   : $federatedSubject"

        # Ensure resource group exists
        New-GitHubResourceGroup `
            -ResourceGroupName $resolvedResourceGroupName `
            -Location $Location `
            -RepositoryName $RepositoryName `
            -Force:$Force | Out-Null

        # Ensure managed identity exists
        $identity = New-GitHubManagedIdentity `
            -ResourceGroupName $resolvedResourceGroupName `
            -IdentityName $resolvedIdentityName `
            -Location $Location `
            -Force:$Force

        # Ensure federated credential exists
        New-GitHubFederatedCredential `
            -ResourceGroupName $resolvedResourceGroupName `
            -IdentityName $resolvedIdentityName `
            -CredentialName $federatedCredName `
            -Subject $federatedSubject `
            -Force:$Force

        # Assign RBAC roles
        Set-ManagedIdentityRbacRoles `
            -PrincipalId $identity.PrincipalId `
            -IdentityName $resolvedIdentityName `
            -SubscriptionId $azureContext.Subscription.Id `
            -RbacRoles $RbacRoles `
            -RemoveUnlistedRoles:$RemoveUnlistedRoles `
            -Force:$Force

        # Build and emit result object
        $result = [PSCustomObject]@{
            ResourceGroupName       = $resolvedResourceGroupName
            Location                = $Location
            IdentityName            = $resolvedIdentityName
            Environment             = $githubEnvironment
            ClientId                = $identity.ClientId
            PrincipalId             = $identity.PrincipalId
            FederatedCredentialName = $federatedCredName
            Subject                 = $federatedSubject
            RbacRoles               = $RbacRoles
            TenantId                = $azureContext.Tenant.Id
            SubscriptionId          = $azureContext.Subscription.Id
        }

        Write-Output $result
    }
    catch {
        Write-Error "Failed to create or configure managed identity: $_"
        throw
    }
}

end {
    Write-Verbose "Azure User Assigned Managed Identity setup completed"

    if ($result) {
        Show-SetupSummary `
            -AzureContext $azureContext `
            -IdentityResult $result
    }
}

#endregion
