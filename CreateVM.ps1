###
# Danny Davis
# Create VM in Hyper-V
# Created: 04/23/19
# Modified: 06/12/19
###

$environmentName = "Example" # CustomerName
$type = "S" # Client (C) or Server (S)
$OS = "16" # Windows Server 16 (16), Win Server 19 (19), Win10 (10)
$IP = "192.168.0.15" # provide the IP Address

$ipString = $IP.split(".")
$ipString = $ipString[7] # last three digits of the IP

$VMName = $environmentName + $type + $OS + $ipString # generate name
$VMSize = "S1" # S1, M1, L1, XXL1
$Path = "C:\Hyper-V\"+$VMName #Path to store VMs and stuff
$ParentVHDOS = "C:\Hyper-V\ParentOS\ParentOS\Virtual Hard Disks\ParentOS.vhdx" #Define parent vhd path to create new disks from
$VHDPathOS = $Path+"\ParentOS.vhdx"
$VHDPath = $Path+"\ddrive.vhdx"

$VMHost = "DESKTOP-0JB2P4J" #Change to correct Hyper-V VM Host

# Build VM Credentials
$username = ""
$pw = ""
$secpassword = ConvertTo-SecureString $pw -AsPlainText -Force
$VMCredentials= New-Object System.Management.Automation.PSCredential ($username, $secpassword)

switch($VMSize) 
{
    "S1" 
    {
        $MemoryStartupBytes = 1GB
        $VHDSize = 10GB
        $ProcCount = 1
        $MemoryMinimumBytes = 512MB
        $MemoryMaximumBytes = 1GB
        $Generation = "2"
    }
    "M1"
    {
        $MemoryStartupBytes = 1GB
        $VHDSize = 50GB
        $ProcCount = 1
        $MemoryMinimumBytes = 1GB
        $MemoryMaximumBytes = 1GB
        $Generation = 2
    }
    "L1"
    {
        $MemoryStartupBytes = 4GB
        $VHDSize = 120GB
        $ProcCount = 2
        $MemoryMinimumBytes = 4GB
        $MemoryMaximumBytes = 4GB
        $Generation = 2
    }
    "XXL1"
    {
        $MemoryStartupBytes = 8GB
        $VHDSize = 160GB
        $ProcCount = 4
        $MemoryMinimumBytes = 8GB
        $MemoryMaximumBytes = 8GB
        $Generation = 2
    }
}

# Create new VM and basic VHD
try
{
    # "Copy" HDD of the Parent OS
    New-VHD -Path $VHDPathOS -ParentPath $ParentVHDOS #-Differencing 
}
catch{ "An error occured during the creation of of VHD OS in Path "+$VHDPathOS }

try
{
    # Create VM according to the VM sizes chosen above
    New-VM -Name $VMName -MemoryStartupBytes $MemoryStartupBytes -VHDPath $VHDPathOS -Generation $Generation -ComputerName $VMHost -Path $Path
}
catch { "An error occured during the creation of the VM "+$VMName}

try
{
    # Change some settings according to the chosen VM size
    Set-VM -Name $VMName -ProcessorCount $ProcCount -MemoryMinimumBytes $MemoryMinimumBytes -MemoryMaximumBytes $MemoryMaximumBytes
}
catch{ "An error occured during the definition of the VM "+$VMName}

# Add second VHD
try
{
    New-VHD -Path $VHDPath -SizeBytes $VHDSize
}
catch{ "An error occured during the creation of the second VHD in Path "+$VHDPath}

try
{
    Add-VMHardDiskDrive -VMName $VMName -ControllerType SCSI -Path $VHDPath
}
catch{ "An error occured druing the attach-process of the second VHD to VM "+$VMName}

# Start Hyper-V VM
Start-VM –ComputerName $VMHost –Name $VMName

# Waits till VM is running
do{
    $RunningVM = Get-VM -ComputerName $VMHost -Name $VMName
    $state = $RunningVM.State
}while($state -ne "Running")

# Break to get OS Version to ensure that Windows is up
# Maybe have to use the old computer name and not the newly created $VMName
do{
    try{
        Get-WMIObject -Class Win32_OperatingSystem -ComputerName $VMName -Credential $VMCredentials | Select-Object *Version -ExpandProperty Version*
        $OSRunning = $true
    }
    catch{$OSRunning = $false}
}while($OSRunning -ne $true)
Write-Host "System is available."

# Set IP Address
do{
    try
    {
        Invoke-Command -VMName $VMName -ScriptBlock { Set-NetIPAddress -InterfaceIndex 12 -IPAddress $IP }
        $IPSet = $true
    }
    catch{ "An error occured during the process of setting an IP address in VM "+$VMName}
}while($IPSet -ne $true)
Write-Host "IP is set and will be restarted."

Restart-VM -Name $VMName -ComputerName $VMHost

# Set computer name?