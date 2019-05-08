function New-VMvc2 {
    <#
    .SYNOPSIS
    .DESCRIPTION
    .PARAMETER
    .EXAMPLE
    #>    
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$True,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True,
        Position=1)]
    [Alias('CN','MachineName','HostName','Name')]
    [string[]]$NewVmName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('FreeCPU','FreeMemoryGB','FreeSpaceGB')]
    [String]$SelectHostBy = "FreeSpaceGB",

    [Parameter(Mandatory=$True)]
    [string]$Server,

    [Parameter(Mandatory=$false)]
    [ValidateSet('Win2012_x64','Win2016_x64','Win2019_x64')]
    [string]$GuestOS = 'Win2012_x64'
    )

    #Import modules for VMware powercli
    Write-Verbose "Loading VMWare modules."
    Get-Module -ListAvailable *vm* | Import-Module -ErrorAction Stop
    
    #Connect to vCenter server
    Write-Verbose "Connecting to $Server."
    $ViServer_Splat = @{'Server'=$Server
                        'ErrorAction'='Stop'}
    
    Connect-VIServer @ViServer_Splat -Credential (Get-Credential -Message EnterPW -UserName 'username')


    foreach($Name in $NewVmName){
        Write-Verbose "Starting configuration for $Name"
        #Create variable for our site, to define selection of host, datastore, portgroup etc.
        $SiteName = $Name.Substring(0,3)

        #Define our variables that will be used to create the new VM
        [string]$Name = $Name
        [string]$Server = $Server

        #Select host with most CPU or Memory available
        Write-Verbose "Sorting hosts based on $SelectHostBy"
        $ValidHostsChoices = @()
        $ValidHosts = Get-VMHost -Name $SiteName*
        foreach($item in $ValidHosts){
            #Calculate free mem and cpu
            $ConnectionState = $item.ConnectionState
            $FreeCPU = ($item.CpuTotalMhz) - ($item.CpuUsageMhz)
            $FreeMemory = ($item.MemoryTotalGB) - ($item.MemoryUsageGB)
            $FreeStorage = $item | Get-Datastore | Select-Object -ExpandProperty FreeSpaceGB

            #Create an object with cpu and mem values
            $PropertiesHost = @{'Name'=$item.Name
                                'ConnectionState'=$ConnectionState
                                'FreeCPU'=$FreeCPU
                                'FreeMemoryGB'=$FreeMemory
                                'FreeSpaceGB'=$FreeStorage}

            $ValidHostsChoices += New-Object psobject -Property $PropertiesHost

        } #Foreach
        
        Write-Verbose "Sorting through available VM Hosts for site"
        $ValidHostsChoices = $ValidHostsChoices | Where-Object {$_.ConnectionState -eq 'Connected'}

        #Stop if we dont find any available hosts
        if(!$ValidHostsChoices){
            Write-Warning -Message "Can not find any available VM Host for $SiteName"
            Write-Verbose -Message "Aborting $Name, due to no available VM Hosts"
            return
        }
        
        Write-Verbose "Selecting VMHost"
        [string]$VMHost = $ValidHostsChoices | 
            Sort-Object $SelectHostBy -Descending | 
            Select-Object -First 1 -ExpandProperty Name
        
        Write-Verbose "Selecting datastore on $VMHost based on FreeSpaceGB"
        [string]$Datastore = Get-VMHost -Name $VMHost | 
            Get-Datastore | 
            Sort-Object FreeSpaceGB -Descending | 
            Select-Object -First 1

        Write-Verbose "Selecting VirtualPortGroup from $VMHost"
        $Portgroup = Get-VMHost -Name $VMHost | 
            Get-VirtualPortGroup -Name $SiteName* | 
            Select-Object -First 1
        
        Write-Verbose "Selecting default cpu, memory and disks for $Name"
        [string]$Location = 'Discovered virtual machine'
        [string]$GuestId = 'windows8Server64Guest'
        [int]$NumCpu = 4
        [int]$MemoryGB = 4
        [int[]]$DiskGB = 60,8
        [string]$DiskStorageFormat = 'Thick'
        [Boolean]$CD = $true
        [Boolean]$Floppy = $true
        
        <#
        #Stop if we dont have enough space
        $DiskTotalSize = 0
        Foreach($disk in $DiskGB){
            $DiskTotalSize += $disk
        }
        if($Datastore.FreeSpaceGB -lt ($DiskTotalSize+100)){
            Write-Warning -Message "Not enough space on $datastore, less than 100GB after creation of new vm"
            Write-Verbose -Message "Aborting $Name, due to low space on datastore"
            return
        }
        #>

        #Output 
        Write-Output ""
        Write-Output "$Name will be created with the following configuration:"
        Write-Output ""
        Write-Output "Name............... $Name"
        Write-Output "Server............. $Server"
        Write-Output "VMHost............. $VMHost"
        Write-Output "Datastore.......... $Datastore"
        Write-Output "DatastoreFreeSpace. $($Datastore.FreeSpaceGB)"
        Write-Output "Location........... $Location"
        Write-Output "Portgroup.......... $Portgroup"
        Write-Output "GuestId............ $GuestId"
        Write-Output "NumCpu............. $NumCpu"
        Write-Output "MemoryGB........... $MemoryGB"
        Write-Output "DiskGB............. $DiskGB"
        Write-Output "DiskStorageFormat.. $DiskStorageFormat"
        Write-Output ""
        $ProceedOrNo = Read-Host "Do you wish to continue with creation of $Name ? (Y/N)"

        if($ProceedOrNo -eq 'Y' -or $ProceedOrNo -eq 'y'){
            #New-VM parameter splat
            $NewVMConf = @{'Name'=$Name
                            'Server' = $Server
                            'VMHost' = $VMHost
                            'Datastore' = $Datastore
                            'Location' = $Location
                            'Portgroup' = $Portgroup
                            'GuestId' = $GuestId
                            'NumCpu' = $NumCpu
                            'MemoryGB' = $MemoryGB
                            'DiskGB' = $DiskGB
                            'DiskStorageFormat' = $DiskStorageFormat
                            'CD' = $CD
                            'Floppy' = $Floppy}
        

            #Create VM
            Write-Verbose "Creating task to deploy $Name to $VMHost"
            New-Vm @NewVMConf -ErrorAction Stop

            Do{
                $FoundVM = Get-VM -Name $Name -ErrorAction SilentlyContinue
                Write-Verbose "Waiting for creation of VM"
                Start-Sleep -Seconds 2
            } Until ($FoundVM)

            #Change number of cores per socket
            $CoresPerSocket = New-Object -TypeName VMware.Vim.VirtualMachineConfigSpec -Property @{"NumCoresPerSocket" = 2}
            (Get-VM -Name $Name).ExtensionData.ReconfigVM_Task($CoresPerSocket)

            #Change networkadapter type from e1000 to VMXNET3
            Get-VM -Name $Name | Get-NetworkAdapter | Set-NetworkAdapter -Type Vmxnet3 -Confirm:$false
        } #If
        Else{
            $NextOrExit = Read-Host "Do you want to continue with the next object (if 'no' script will exit)? (Y/N)"
            if($NextOrExit -eq 'Y' -or $NextOrExit -eq 'y'){
                Return
            } Else {
                Write-Host "Exiting session"
                Start-Sleep -Seconds 3
                Exit
            }
        }

    } #Foreach
} #Function
