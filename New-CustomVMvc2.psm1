<#
.SYNOPSIS
The template gives a good starting point for creating powershell functions and tools.
Start your design with writing out the examples as a functional spesification.
.DESCRIPTION
.PARAMETER
.EXAMPLE
New-CustomVMvc2 -VMName SRV1 -Verbose -GuestOs Win2012R2
.EXAMPLE
New-CustomVMvc2 -VMName SRV1 -Verbose -GuestOs Win2012R2 -SiteName EinarLab
.EXAMPLE
New-CustomVMvc2 -VMName SRV1 -ViServer Vcenter.lab.no -SelectHostBy FreeSpaceGB/FreeCPU/FreeMemory
.EXAMPLE
New-CustomVMvc2 -VMName SRV1 -ViServer Vcenter.lab.no -ServerHost NameOfHost -Portgroup VMNetwork
.EXAMPLE
New-CustomVMvc2 -VMName SRV1 -ViServer Vcenter.lab.no -SelectHostBy FreeSpaceGB -Location 'Discovered virtual machine'
.EXAMPLE
New-CustomVMvc2 -VMName SRV1 -ViServer Vcenter.lab.no -DiskStorageFormat Thick -DiskGB "60","8" -ScsiType ParaVirtual -Floppy -CD
.EXAMPLE
New-CustomVMvc2 -VMName SRV1 -ViServer Vcenter.lab.no -NumCpu 4 -CoresPerSocket 2 -MemoryGB 4 -NetAdapterType Vmxnet3 -CheckHostConnectionState -LocationByVMName
#>

function New-CustomVMvc2 {
    [CmdletBinding()]
    #^ Optional ..Binding(SupportShouldProcess=$True,ConfirmImpact='Low')
    param (
    [Parameter(Mandatory=$True,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True,
        Position=1)]
    [Alias('NewVmName')]
    [string]$VMName,
    
    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [ValidateSet('Win2012_x64','Win2016_x64','Win2019_x64')]
    [string]$GuestOs = 'Win2012_x64',

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [string]$SiteName,

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [string]$ViServer,

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [string]$ServerHost,

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [string]$Portgroup,

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [ValidateSet('FreeCPU','FreeMemoryGB','FreeSpaceGB')]
    [string]$SelectHostBy = "FreeSpaceGB",

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [string]$Location,

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [ValidateSet('Thick','Example')]
    [string]$DiskStorageFormat = 'Thick',

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [int[]]$DiskGB,

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [ValidateSet('ParaVirtual')]
    [string]$ScsiType = 'ParaVirtual',

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [int]$NumCpu = 4,

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [string]$CoresPerSocket,

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [int]$MemoryGB = 4,

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [ValidateSet('Vmxnet3')]
    [string]$NetAdapterType = 'Vmxnet3',

    [Parameter(Mandatory=$false)]
    [Switch]
    $Floppy,

    [Parameter(Mandatory=$false)]
    [Switch]
    $CD,

    [Parameter(Mandatory=$false)]
    [Switch]
    $LocationByVMName,

    [Parameter(Mandatory=$false)]
    [Switch]
    $CheckHostConnactionState
    )

BEGIN {
    # Intentionaly left empty.
    # Provides optional one-time pre-processing for the function.
    # Setup tasks such as opening database connections, setting up log files, or initializing arrays.
} #Begin

PROCESS {
    foreach($NewVM in $VMName){

    } #Foreach $vmname
} #Process


END {
    # Intentionaly left empty.
    # This block is used to provide one-time post-processing for the function.
} #End

} #Function