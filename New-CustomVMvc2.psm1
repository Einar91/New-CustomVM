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
New-CustomVMvc2 -VMName SRV1 -ViServer Vcenter.lab.no -Datastore 'EinarStorage' -DiskStorageFormat Thick -DiskGB "60","8" -ScsiType ParaVirtual -Floppy -CD
.EXAMPLE
New-CustomVMvc2 -VMName SRV1 -ViServer Vcenter.lab.no -NumCpu 4 -CoresPerSocket 2 -MemoryGB 4 -NetAdapterType Vmxnet3 -CheckHostConnectionState -HostByVMName
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
    [string]$Datastore,

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
    $HostByVMName,

    [Parameter(Mandatory=$false)]
    [Switch]
    $CheckHostConnactionState,

    [Parameter(Mandatory=$false)]
    [Switch]
    $ConfirmConfiguration
    )

BEGIN {
    # Intentionaly left empty.
    # Provides optional one-time pre-processing for the function.
    # Setup tasks such as opening database connections, setting up log files, or initializing arrays.
} #Begin

PROCESS {
    foreach($NewVM in $VMName){
        Try{
            #Check if we want to define host for VM by name
            if($PSBoundParameters.ContainsKey('HostByVMName')){
                Write-Verbose -Message 'Setting sitename by vm name.'
                $SiteName = ($NewVM.Substring(0,3)).ToUpper()
            
                Write-Verbose -Message "Searching avilable host for $SiteName"
                $ValidHosts = Get-VMHost -Name $SiteName*

                #If no valid hosts, write warning and abort.
                if(!$ValidHosts){
                    Write-Warning -Message "Can not automatically find any available VM Hosts for $SiteName"
                    Write-Error -Message "No VM Host for $SiteName found" -ErrorAction Stop
                }

                if(($ValidHosts.count) -eq 1){
                    $ServerHost = $ValidHosts
                } #If
                
                if(($ValidHosts.count) -gt 1 ){
                    Write-Verbose -Message "Selecting host by $SelectHostBy"
                    $ValidHostsChoices = @()
                    foreach($VMHost in $ValidHosts){
                        #Calculate free mem, cpu and storage
                        $FreeCPU = ($VMHost.CpuTotalMhz) - ($VMHost.CpuUsageMhz)
                        $FreeMemory = ($VMHost.MemoryTotalGB) - ($VMHost.MemoryUsageGB)
                        $FreeStorage = $VMHost | Get-Datastore | Select-Object -ExpandProperty FreeSpaceGB

                        #Create a new object with our properties
                        $ValidHostsProperties = @{'Name'=$VMHost.Name
                                                'FreeCPU'=$FreeCPU
                                                'FreeMemoryGB'=$FreeMemory
                                                'FreeSpaceGB'=$FreeStorage}
                        $ValidHostsChoices += New-Object psobject -Property $ValidHostsProperties    
                    } #Foreach VMHost
                
                    #Select VM based on parameter $SelectByHost
                    $ServerHost = $ValidHostsChoices |
                        Sort-Object $SelectHostBy -Descending |
                        Select-Object -First 1 -ExpandProperty Name

                    #Get full host object
                    $ServerHost = Get-VMHost -Name $ServerHost
                } #If ($ValidHosts.count) -gt 1
            } #If $PSBoundParameters.ContainsKey('HostByVMName')

            #Select portgroup if not defined by parameter
            If($PSBoundParameters.ContainsKey('Portgroup') -eq $false){
                Write-Verbose -Message "Selecting VirtualPortGroup from $($ServerHost.Name)"
                $Portgroup = $ServerHost |
                    Get-VirtualPortGroup -Name $SiteName* |
                    Select-Object -First 1
                
                if(!$Portgroup){
                    Write-Warning -Message "No SiteName portgroup found for $SiteName"
                    Write-Verbose -Message "Searching for alternative portgroup on $($ServerHost.Name)"
                    $Portgroup = $ServerHost |
                        Get-VirtualPortGroup |
                        Sort-Object VLandId -Descending |
                        Select-Object -First 1
                } #If
            } #If $PSBoundParameters.ContainsKey('Portgroup')
            
                
            }

        } #Try
        Catch{

        } #Catch
    } #Foreach $vmname
} #Process


END {
    # Intentionaly left empty.
    # This block is used to provide one-time post-processing for the function.
} #End

} #Function