<#
.SYNOPSIS
The template gives a good starting point for creating powershell functions and tools.
Start your design with writing out the examples as a functional spesification.
.DESCRIPTION
.PARAMETER
.EXAMPLE
New-CustomVMvc2 -VMName SRV1 -Verbose
.EXAMPLE
New-CustomVMvc2 -VMName SRV1 -ViServer Vcenter.lab.no -SelectHostBy FreeSpaceGB
.EXAMPLE
New-CustomVMvc2 -VMName SRV1 -ViServer Vcenter.lab.no -portgroup VMNetwork -ScsiType ParaVirtual -SelectHostBy FreeSpaceGB -CoresPerSocket 2
.EXAMPLE
New-CustomVMvc2 -VMName SRV1 -ViServer Vcenter.lab.no -portgroup VMNetwork -ScsiType ParaVirtual -Host NameOfHost -NumCpu 4 -MemoryGB 4 -DiskGB "60","8","20"
.EXAMPLE
New-CustomVMvc2 -VMName SRV1 -ViServer Vcenter.lab.no -portgroup VMNetwork -ScsiType ParaVirtual -DiskStorageFormat Thick -CD -Floppy -GuestOs Win2012R2 
#>

function FunctionName {
    [CmdletBinding()]
    #^ Optional ..Binding(SupportShouldProcess=$True,ConfirmImpact='Low')
    param (
    <# EXAMPLE PARAMETER
    [Parameter(Mandatory=$True,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True)]
    [Alias('CN','MachineName','HostName','Name')]
    [string[]]$ComputerName,

    [ValidateSet('WSMan','Dcom')]
    [string]$Protocol = "Wsman",

    [switch]$ProtocolFallback
    #>
    )

BEGIN {
    # Intentionaly left empty.
    # Provides optional one-time pre-processing for the function.
    # Setup tasks such as opening database connections, setting up log files, or initializing arrays.
}

PROCESS {
    # Provides record-by-record processing for the function.
}


END {
    # Intentionaly left empty.
    # This block is used to provide one-time post-processing for the function.
}

} #Function