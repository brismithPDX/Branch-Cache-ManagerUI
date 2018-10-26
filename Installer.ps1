param(
    $VerbosePreference = "SilentlyContinue"
)
# Branch Cache Confgiuration Application Envrioment Installer

# Script References & Configuration Variables
$InstallDirectory = "C:\Program Files\BranchCache_Management_GUI"

function Repair-Install{
    # Check for the application componenets and registered tasks, remove them if needed.
    try{
        Write-Verbose "INFO: Repair installation has Started"
        Write-Verbose "INFO: Repair installation : Looking for Old Install Files"

        if(Test-Path $InstallDirectory){
            Write-Verbose "INFO: Repair installation : Removing Old Install Files"
            if(10 -eq $(Get-WindowsVersion)){
                Remove-Item $InstallDirectory -Recurse -Force 
            }
            else{
                Remove-Item $InstallDirectory -Recurse -Force
            }
            

            Write-Verbose "INFO: Repair installation : Removing Old Install Files Compleated"
        }
        Write-Verbose "INFO: Repair installation : Looking for old Scheduled Tasks"
        if(Query-ScheduledTasks){
            Write-Verbose "INFO: Repair installation : Removing Old Scheduled Tasks"

            Remove-ScheduledTasks

            Write-Verbose "INFO: Repair installation : Removing Old Scheduled Tasks Compleated"
        }

        Remove-StartMenuIcons
    
    }
    catch{
        Write-Verbose "ERROR: Unable To Repair the installation"
        throw "ERROR: Unable To Repair the installation"
    }
    # Kick off the re-installation if the above is successful
    Install-Files
}
function Query-ScheduledTasks {
    Write-Verbose "INFO: Query Scheduled Tasks has Started"
    Write-Verbose "INFO: Query Scheduled Tasks : Determining Windows Version"
    if(10 -eq $(Get-WindowsVersion)){
        Write-Verbose "INFO: Query Scheduled Tasks : Windows 10 Detected, Evaluating Scheduled Task"
        $result = Get-ScheduledTask -TaskName "Launch_BranchCacheManager" -ErrorAction SilentlyContinue
        
        if($result){
            Write-Verbose "INFO: Query Scheduled Tasks : Windows 10 Detected, Scheduled Task Found"
            return $true
        }
        else{
            Write-Verbose "INFO: Query Scheduled Tasks : Windows 10 Detected, Scheduled Task Missing"
            return $false
        }
    }
    else{
        Write-Verbose "INFO: Query Scheduled Tasks : Windows 7 Detected, Evaluating Scheduled Task"
        $result = & $ENV:WinDir\System32\schtasks.exe /query /TN "Launch_BranchCacheManager"
        if($result){
            Write-Verbose "INFO: Query Scheduled Tasks : Windows 7 Detected, Scheduled Task Found"
            return $true
        }
        else{
            Write-Verbose "INFO: Query Scheduled Tasks : Windows 7 Detected, Scheduled Task Missing"
            return $false
        }

    }
}
function Install-Files {
    try{
        Write-Verbose "INFO: Install-Files has Started"
        # Quick for prior installation
        if (Test-Path $InstallDirectory){
            Write-Verbose "INFO: Instal-Files : Previous Install Detected Starting Repair-Installation"
            Repair-Install
        }
        # Install application components
        else{
            Write-Verbose "INFO: Install-Files : Copying files to installation directory"
            New-Item -ItemType "Directory" -Path $InstallDirectory
    
            robocopy . $InstallDirectory /xf *.xml Installer.ps1    # Use robocopy because Move-Item & Copy-Item suck
        }
    }
    catch{
        Write-Verbose "ERROR: Unable to Install Files"
        throw "ERROR: Unable to Install Files"
    }
}
function Install-ScheduledTasks{
    try{
        Write-Verbose "INFO: Install-ScheduledTasks has Started"
        # Install the logon scheduled task for launching the UI application with user logons
        Write-Verbose "INFO: Install-ScheduledTasks : Detecting Windows Version"
        if(10 -eq $(Get-WindowsVersion)){
            Write-Verbose "INFO: Install-ScheduledTasks : Windows 10 Detected, Adding Scheduled Task"
            Register-ScheduledTask -Xml (get-content Launch_BranchCacheManager-Interactive.xml | out-string) -TaskName "Launch_BranchCacheManager"
        }
        else{
            Write-Verbose "INFO: Install-ScheduledTasks : Windows 7 Detected, Adding Scheduled Task"
            schtasks.exe /Create /XML Launch_BranchCacheManager-Interactive.xml /tn "Launch_BranchCacheManager"
        }
        Write-Verbose "INFO: Install-ScheduledTasks has compleated"
    }
    catch{
        Write-Verbose "ERROR: Unable to Install Scheduled Tasks"
        throw "ERROR: Unable to Install Scheduled Tasks"
    }
}
function Remove-ScheduledTasks {
    try{
        Write-Verbose "INFO: Remove-ScheduledTasks has Started"
        Write-Verbose "INFO: Remove-ScheduledTasks : Detecting Windows Version"
        if(10 -eq $(Get-WindowsVersion)){
            Write-Verbose "INFO: Remove-ScheduledTasks : Windows 10 Detected, Removing Scheduled Task"
            Unregister-ScheduledTask -TaskName "Launch_BranchCacheManager" -Confirm:$false
        }
        else{
            Write-Verbose "INFO: Remove-ScheduledTasks : Windows 7 Detected, Removing Scheduled Task"
            schtasks.exe /Delete /tn "Launch_BranchCacheManager" /f
        }
    }
    catch{
        Write-Verbose "ERROR: Unable to Remove Scheduled Tasks"
        throw "ERROR: Unable to Remove Scheduled Task"
    }
}
function Get-WindowsVersion {
    Write-Verbose "INFO: Get-WindowsVersion Started"
    try{
        Write-Verbose "INFO: Get-WindowsVersion : Determining Windows Version"
        $version = Get-WmiObject Win32_OperatingSystem | Select-Object -Property Version
        $version = $version.version.split("{.}")[0]

        if(6 -eq $version){
            Write-Verbose "INFO: Get-WindowsVersion : Windows 7 Detected"
            return 7
        }
        else{
            Write-Verbose "INFO: Get-WindowsVersion : Windows 10 Detected"
            return 10
        }
    }
    catch{
        Write-Verbose "INFO: Get-WindowsVersion : Unable to Determine Windows Version, falling back to legacy windows 7 methods"
        # if determining version fails default to the legacy windows 7 methods.
        return 7
    }
}
function Remove-StartMenuIcons{
    Write-Verbose "INFO: Remove-StartMenuIcons has Started"
    Write-Verbose "INFO: Remove-StartMenuIcons : Detecting Windows Version"
    try{
        if(10 -eq $(Get-WindowsVersion)){
            Write-Verbose "INFO: Remove-StartMenuIcons : Windows 10 Detected, Removing Start Menu Icons"
            
            $List = Get-ChildItem C:\Users | where-object {$_.psiscontainer -eq "True"} | Select-Object name
            
            Foreach ($User in $List){
                #fix this so that it will overwrite if needed or create a removeal version for the reapir function

                $UserName = $User.name

                $Path = "C:\Users\$UserName\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
                
                $test = test-path -Path "$Path\Check Scanner Mode Utility.lnk"
                
                if($test){
                    Remove-Item -Path "$Path\Check Scanner Mode Utility.lnk" -Force
                }
            }
        }
        else{

            Write-Verbose "INFO: Remove-StartMenuIcons : Windows 7 Detected, Removing Start Menu Icons"
            #code to install start menu icon on windows 7
            $Path = "C:\ProgramData\Microsoft\Windows\Start Menu"

            $test = test-path -Path "$Path\Check Scanner Mode Utility.lnk"
                
            if($test){
                Remove-Item -Path "$Path\Check Scanner Mode Utility.lnk" -Force
            }
            
        }
        
        Write-Verbose "INFO: Remove-StartMenuIcons has Compleated"
    }
    catch{
        Write-Verbose "ERROR: Unable to Remove-StartMenuIcons"
        throw "ERROR: Unable to Remove-StartMenuIcons - $PSItem"
    }
}
# We dont use the install Start Menu icons because it does not load the system try icon as expected.
#   This issue does no occour when launched via shceduled task durring logon though.
function Install-StartMenuIcons{
    Write-Verbose "INFO: Install-StartMenuIcons has Started"
    Write-Verbose "INFO: Install-StartMenuIcons : Detecting Windows Version"
    try{
        if(10 -eq $(Get-WindowsVersion)){
            Write-Verbose "INFO: Install-StartMenuIcons : Windows 10 Detected, Installing Start Menu Icons"
            
            $List = Get-ChildItem C:\Users | where-object {$_.psiscontainer -eq "True"} | Select-Object name
            
            Foreach ($User in $List){
                
                $UserName = $User.name

                $Path = "C:\Users\$UserName\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
                
                robocopy . $Path 'Check Scanner Mode Utility.lnk'
            }
        }
        else{

            Write-Verbose "INFO: Install-StartMenuIcons : Windows 7 Detected, Installing Start Menu Icons"
            #code to install start menu icon on windows 7
            $Path = "C:\ProgramData\Microsoft\Windows\Start Menu"

            robocopy . $Path 'Check Scanner Mode Utility.lnk'
            
        }
        Write-Verbose "INFO: Install-StartMenuIcons has Compleated"
    }
    catch{
        Write-Verbose "ERROR: Unable to Install-StartMenuIcons"
        throw "ERROR: Unable to Install-StartMenuIcons"
    }
}


Write-Verbose "INFO: Starting Installation"

try{
    Install-Files
    Install-ScheduledTasks
}
catch{
    if($VerbosePreference -eq "SilentlyContinue"){
        [System.Environment]::Exit(2600)
    }
    else{
        Write-Error $PSItem
        return
    }
    
}

Write-Verbose "INFO: Installation Compleated"

