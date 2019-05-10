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
New-CustomVMvc2 -VMName SRV1 -ViServer Vcenter.lab.no -HostName NameOfHost -Portgroup VMNetwork
.EXAMPLE
New-CustomVMvc2 -VMName SRV1 -ViServer Vcenter.lab.no -SelectHostBy FreeSpaceGB -Location 'Discovered virtual machine'
.EXAMPLE
New-CustomVMvc2 -VMName SRV1 -ViServer Vcenter.lab.no -DiskStorageFormat Thick -DiskGB "60","8" -ScsiType ParaVirtual -Floppy -CD
.EXAMPLE
New-CustomVMvc2 -VMName SRV1 -ViServer Vcenter.lab.no -NumCpu 4 -CoresPerSocket 2 -MemoryGB 4 -NetAdapterType Vmxnet3 -CheckHostConnectionState
#>

function FunctionName {
    [CmdletBinding()]
    #^ Optional ..Binding(SupportShouldProcess=$True,ConfirmImpact='Low')
    param (
    [Parameter(Mandatory=$True,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True)]
    [Alias('NewVmName')]
    [string[]]$VMName
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