# BranchCache Configurator

# Script References & Configuration Variables
$IconOKLocation = "C:\Program Files\BranchCache_Management_GUI\icon-ok.ico"
$IconNotOKLocation = "C:\Program Files\BranchCache_Management_GUI\icon.ico"
$LogFileDirectory = "C:\BranchCacheManagerLogs"
$LogFilePath = "C:\BranchCacheManagerLogs\UtilityActivationLog.log"

# Generate Form
[void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")
$Form = New-Object System.Windows.Forms.form
$NotifyIcon= New-Object System.Windows.Forms.NotifyIcon
$ContextMenu = New-Object System.Windows.Forms.ContextMenu

$Button_StopBrancheCache = New-Object System.Windows.Forms.MenuItem
$Button_EnableBranchCache = New-Object System.Windows.Forms.MenuItem
$Button_CloseApplication = New-Object System.Windows.Forms.MenuItem

$WaitTimer = New-Object System.Windows.Forms.Timer
$iconOK = New-Object System.Drawing.Icon($IconOKLocation)
$Icon = New-Object System.Drawing.Icon($IconNotOKLocation)

# Configure Form Display
$Form.ShowInTaskbar = $false
$Form.WindowState = "minimized"

# Configure Taskbar Items
$NotifyIcon.Icon =  $icon
$NotifyIcon.ContextMenu = $ContextMenu

$NotifyIcon.contextMenu.MenuItems.AddRange($Button_StopBrancheCache)
$NotifyIcon.ContextMenu.MenuItems.AddRange($Button_EnableBranchCache)
$NotifyIcon.ContextMenu.MenuItems.AddRange($Button_CloseApplication)

$NotifyIcon.Visible = $True

#Configure Wait Timer
$WaitTimer.Interval =  300000  # (5 min)
$WaitTimer.add_Tick({ProgramCheck})

# Configure Right-Click Menu Items
$Button_StopBrancheCache.Text = "Enable Check Scanning Support"
$Button_StopBrancheCache.add_Click({
    Disable-BranchCache
    $WaitTimer.start()

})

$Button_EnableBranchCache.Text = "Disable Check Scanning Support"
$Button_EnableBranchCache.add_Click({
    $WaitTimer.Stop()
    Enable-BranchCache
})

$Button_CloseApplication.Text = "Exit"
$Button_CloseApplication.add_Click({
    $WaitTimer.Stop()
    $NotifyIcon.Visible = $False
    $Form.Close()
    exit
})


# Reference Functions for Script Operation
function ProgramCheck {
    try{
        $Process = Get-Process pwecsrvc.exe -ErrorAction SilentlyContinue
        if($Null -eq $Process){
            Enable-BranchCache
        }
    }
    catch{
        Add-Content -Path $LogFilePath -Value "Failed to check if process is still running, Failing over to Disable-BranchCache : $(Get-Date)"
        Disable-BranchCache
    }
}

function Disable-BranchCache { 
    try{
        Stop-Service "PeerDistSvc" -PassThru -ErrorAction Stop
        $NotifyIcon.Icon =  $iconOk
        Add-Content -Path $LogFilePath -Value "Branch Cache is Disabled : $(Get-Date)"
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Disabling BranchCache service has failed. Unable to compleate check scanner mode configurations.`nYour user account may not have the requied permissions to execute the changes.`nIf this error continues please contact support.", 'Warning!')
        Add-Content -Path $LogFilePath -Value "Branch Cache is Failed to Disable : $(Get-Date)"
    }
}

function Enable-BranchCache {
    try{
        Start-Service "PeerDistSvc" -ErrorAction Stop
        Add-Content -Path $LogFilePath -Value "Branch Cache is Enabled : $(Get-Date)"
        $NotifyIcon.Icon =  $icon
    }
    catch{
        [System.Windows.Forms.MessageBox]::Show("Enabling BranchCache service has failed. Unable to reverse check scanner mode configurations.`nYour user account may not have the requied permissions to execute the changes.`nIf this error continues please contact support.", 'Warning!')
        Add-Content -Path $LogFilePath -Value "Branch Cache is Failed to Enable : $(Get-Date)"
    }
}

function PrepareLog {

    $Message = "Log Started - $(Get-Date)"

    if (Test-Path $LogFilePath){
        Add-Content -Path $LogFilePath -Value "Program Started : $(Get-Date)"
    }
    else{
        New-Item -ItemType "Directory" -Path $LogFileDirectory
        New-Item -ItemType "File" -Path $LogFilePath
        Add-Content -Path $LogFilePath -Value $Message
    }
}

PrepareLog
# Run the Form
[void][System.Windows.Forms.Application]::Run($Form)
