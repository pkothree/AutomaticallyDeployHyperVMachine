# Check PowerShell Version
$PSVersionTable.PSVersion

# Update Windows with PowerShell
# If Version greater than 5, you can install the Module
Install-Module PSWindowsUpdate

# Load module
Set-ExecutionPolicy RemoteSigned
Import-Module PSWindowsUpdate

# If you want to use "Microsoft Update" instead of "Windows Update" only
Add-WUServiceManager-ServiceID 7971f918-a847-4430-9279-4a52d1efe18d

# Install Updates
Get-WUInstall -WindowsUpdate -AcceptAll
# Install Updates (Incl. Microsoft Updates)
Get-WUInstall -WindowsUpdate -MicrosoftUpdate -AcceptAll

# SysPrep to make disk image "usable"
Start-Process -FilePath C:\Windows\System32\Sysprep\Sysprep.exe -ArgumentList '/generalize /oobe /shutdown /quiet'

# Hyper-V
# Install only the PowerShell module
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell