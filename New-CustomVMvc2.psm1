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
New-CustomVMvc2 -VMName SRV1 -ViServer Vcenter.lab.no -NumCpu 4 -CoresPerSocket 2 -MemoryGB 4 -NetAdapterType Vmxnet3 -HostByVMName
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
    [string[]]$VMName,
    
    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [ValidateSet('windows8Server64Guest','Win2012_x64','Win2016_x64','Win2019_x64')]
    [string]$GuestOs = 'windows8Server64Guest',

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [string]$SiteName,

    [Parameter(Mandatory=$True,
        ValueFromPipelineByPropertyName=$True)]
    $ViServer,

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [string]$ServerHost,

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    $Portgroup,

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [ValidateSet('FreeCPU','FreeMemoryGB','FreeSpaceGB')]
    [string]$SelectHostBy = "FreeSpaceGB",

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [string]$Location = 'Discovered virtual machine',

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    $Datastore,

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [ValidateSet('Thick','Example')]
    [string]$DiskStorageFormat = 'Thick',

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [int[]]$DiskGB = 100,

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [ValidateSet('ParaVirtual')]
    [string]$ScsiType = 'ParaVirtual',

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    [int]$NumCpu = 4,

    [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$True)]
    $CoresPerSocket = 2,

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
    $ConfirmConfiguration,

    [Parameter(Mandatory=$false)]
    $LogToFilePath
    )

BEGIN {
    function Timestamp{
        (Get-Date -Format "dd.MM.yyyy hh:mm:ss").ToString()
    }
} #Begin

PROCESS {
    foreach($NewVM in $VMName){
        Try{
            #Check if we want to define host for VM by name
            if($PSBoundParameters.ContainsKey('HostByVMName')){
                Write-Verbose -Message "$(TimeStamp) Setting SiteName by VMName."
                $SiteName = ($NewVM.Substring(0,3)).ToUpper()
            
                Write-Verbose -Message "Searching avilable host for $SiteName"
                $ValidHosts = Get-VMHost -Name $SiteName*

                #If no valid hosts, write warning and abort.
                if(!$ValidHosts){
                    Write-Warning -Message "Can not automatically find any available VM Hosts for $SiteName"
                    Write-Error -Message "$NewVM not created, due to no VMHost found for $SiteName." -ErrorAction Stop -ErrorVariable ErrNoHost
                }

                if(($ValidHosts.count) -eq 1){
                    $ServerHost = $ValidHosts | Select-Object -ExpandProperty Name
                } #If
                
                if(($ValidHosts.count) -gt 1 ){
                    Write-Verbose -Message "Selecting host by $SelectHostBy"
                    $ValidHostsChoices = @()
                    foreach($VMHost in $ValidHosts){
                        #Calculate free mem, cpu and storage
                        $ConnectionState = $VMHost.ConnectionState
                        $FreeCPU = ($VMHost.CpuTotalMhz) - ($VMHost.CpuUsageMhz)
                        $FreeMemory = ($VMHost.MemoryTotalGB) - ($VMHost.MemoryUsageGB)
                        $FreeStorage = $VMHost | Get-Datastore | Select-Object -ExpandProperty FreeSpaceGB

                        #Create a new object with our properties
                        $ValidHostsProperties = @{'Name'=$VMHost.Name
                                                'ConnectionState'=$ConnectionState
                                                'FreeCPU'=$FreeCPU
                                                'FreeMemoryGB'=$FreeMemory
                                                'FreeSpaceGB'=$FreeStorage}
                        $ValidHostsChoices += New-Object psobject -Property $ValidHostsProperties    
                    } #Foreach VMHost
                
                    #Select VM based on parameter $SelectByHost
                    $ServerHost = $ValidHostsChoices |
                        Sort-Object ConnectionState,$SelectHostBy -Descending |
                        Select-Object -First 1 -ExpandProperty Name
                } #If ($ValidHosts.count) -gt 1
            } #If $PSBoundParameters.ContainsKey('HostByVMName')

            #Get our host object to work with
            $VMWareHost = Get-VMHost -Name $ServerHost

            #Make sure our selected host is online, if not abort
            If($VMWareHost.ConnectionState -notmatch 'Connected'){
                Write-Error -Message "$NewVM not created, the VMHost $($VMWareHost.name) ConnectionState is not equal Connected." -ErrorAction Stop -ErrorVariable ErrHostConnection
            }

            #Select portgroup if not defined by parameter
            If($PSBoundParameters.ContainsKey('Portgroup') -eq $false){
                Write-Verbose -Message "Selecting VirtualPortGroup from $($VMWareHost.name)"
                $Portgroup = $VMWareHost |
                    Get-VirtualPortGroup -Name $SiteName* |
                    Select-Object -First 1
                
                if(!$Portgroup){
                    Write-Warning -Message "No SiteName portgroup found for $SiteName"
                    Write-Verbose -Message "Searching for alternative portgroup on $($VMWareHost.name)"
                    $Portgroup = $VMWareHost |
                        Get-VirtualPortGroup |
                        Sort-Object VLanId -Descending |
                        Select-Object -First 1
                } #If
            } #If $PSBoundParameters.ContainsKey('Portgroup')

            #Select datastore if not defined by parameter
            If($PSBoundParameters.ContainsKey('Datastore') -eq $false){
                Write-Verbose "Selecting datastore on $($VMWareHost.name) based on FreeSpace"
                $Datastore = $VMWareHost |
                    Get-Datastore |
                    Sort-Object FreeSpaceGB -Descending |
                    Select-Object -First 1
            } #If $PSBoundParameters.ContainsKey('Datastore')

            #Check that we have enough storage space for the VM on datastore
            $DiskTotalUse = 0
            Foreach($Disk in $DiskGB){
                $DiskTotalUse = $DiskTotalUse + $Disk
            } #Foreach
            
            if(($Datastore.FreeSpaceGB) -lt ($DiskTotaluse+100)){
                Write-Error -Message "$NewVM not created, the total disks specified is $DiskTotalUse GB and the free space on datastore`
                 $($Datastore.Name) is $($Datastore.FreeSpaceGB)" -ErrorAction Stop -ErrorVariable ErrStorageSpace
            }

            #Output our configuration for new vm
            Write-Verbose "$NewVM will be created with the following configuration:"
            Write-Verbose "Name....................$NewVM"
            Write-Verbose "Server..................$VIServer"
            Write-Verbose "Site....................$SiteName"
            Write-Verbose "VMHost..................$($VMWareHost.Name)"
            Write-Verbose "Location................$Location"
            Write-Verbose "GuestId.................$GuestOs"
            Write-Verbose "NumCpu..................$NumCpu"
            Write-Verbose "CoresPerSocket..........$CoresPerSocket"
            Write-Verbose "MemoryGB................$MemoryGB"
            Write-Verbose "Datastore...............$Datastore"
            Write-Verbose "DatastoreFreeSpaceGB....$($Datastore.FreeSpaceGB)"
            Write-Verbose "DiskGB..................$DiskGB"
            Write-Verbose "StorageFormat...........$DiskStorageFormat"
            Write-Verbose "ScsiType................$ScsiType"
            Write-Verbose "Portgroup...............$Portgroup"
            Write-Verbose "NetAdapterType..........$NetAdapterType"
            Write-Verbose "Floppy..................$CD"
            Write-Verbose "CD......................$Floppy"

            #For testing purposes, confirm creation
            $ProceedOrNo = Read-Host "Do you wish to continue with creation of $NewVM ? (Y/N)"

            if($ProceedOrNo -ne 'Y' -or $ProceedOrNo -ne 'y'){
                Write-Warning -Message "$NewVM not created."
                Write-Error "$NewVM not created, due to user answere to proceed or not with creation of VM." -ErrorAction Stop -ErrorVariable ErrUserAbort
            }

            #Define our New-VM parameters
            $NewVM_Param = @{'Name'=$NewVM
                                    'Server'=$ViServer
                                    'VMHost'=$VMWareHost
                                    'Location'=$Location
                                    'GuestId'=$GuestOs
                                    'NumCpu'=$NumCpu
                                    'MemoryGB'=$MemoryGB
                                    'Datastore'=$Datastore
                                    'DiskGB'=$DiskGB
                                    'DiskStorageFormat'=$DiskStorageFormat
                                    'Portgroup'=$Portgroup
                                    'CD'=$CD
                                    'Floppy'=$Floppy}
            
            #Create VM and configure post creation tasks
            Write-Verbose -Message "Creating task to deploy $NewVM to $ServerHost"
            New-Vm @NewVM_Param -whatif -ErrorAction Stop -ErrorVariable ErrNewVM

            #Make sure VM is available before reconfigurations
            Do{
                $FoundVM = Get-VM -Name $NewVM -ErrorAction SilentlyContinue
                Write-Verbose "Waiting for creation of VM"
                Start-Sleep -Seconds 5
            } Until ($FoundVM)

            #Change number of cores per socket
            $ConfigCoresPerSocket = New-Object -TypeName VMware.Vim.VirtualMachineConfigSpec -Property @{"NumCoresPerSocket" = $CoresPerSocket}
            (Get-VM -Name $NewVM).ExtensionData.ReconfigVM_Task($ConfigCoresPerSocket)

            #Change networkadapter type from e1000 to VMXNET3
            Get-VM -Name $NewVM | Get-NetworkAdapter | Set-NetworkAdapter -Type Vmxnet3 -Confirm:$false

            #Change SCSI controller type
            Get-VM -Name $NewVM | Get-ScsiController | Set-ScsiController -Type ParaVirtual
        } #Try
        Catch{
            #Log errors to filepath if parameter is specified
            if($PSBoundParameters.ContainsKey('LogToFilePath')){
                #Error handling for no vmhost found
                if($ErrNoHost){
                    $ErrNoHost.ErrorRecord.Exception | Out-File -FilePath $LogToFilePath -Append
                } #If ErrNoHost

                #Error handling for vmhost connection state not connected
                if($ErrHostConnection){
                    $ErrHostConnection.ErrorRecord.Exception | Out-File -FilePath $LogToFilePath -Append
                } #If ErrHostConnection

                #Error handling for not enough storage capacity
                if($ErrStorageSpace){
                    $ErrStorageSpace.ErrorRecord.Exception | Out-File -FilePath $LogToFilePath -Append
                } #If ErrStorageSpace

                #Error handling for user abortion to proceede or not ErrUserAbort
                if($ErrUserAbort){
                    $ErrUserAbort.ErrorRecord.Exception | Out-File -FilePath $LogToFilePath -Append
                } #If ErrHostConnection

                #Error handling for error creating VM
                if($ErrNewVM){
                    Write-Warning -Message "$NewVM not created, see log."
                    "$NewVM not created, due to $($ErrNewVM.ErrorRecord.Exception)" | Out-File -FilePath $LogToFilePath -Append
                }
            } #If log to filepath
        } #Catch
    } #Foreach $vmname
} #Process


END {
    # Intentionaly left empty.
    # This block is used to provide one-time post-processing for the function.
} #End

} #Function