# Get the path the script is executing from
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# If the module is already in memory, remove it
Get-Module New-CustomVM | Remove-Module -Force

# Import the module from the local path, not from the users Documents folder
Import-Module $here\New-CustomVM.psm1 -Force

# Pester
Describe "New-CustomVM" {
    It "does something useful" {
        $true | Should Be $false
    }
}