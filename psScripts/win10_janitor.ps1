#Requires -RunAsAdministrator

# Initialize necessary variables
$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$p = New-Object System.Diagnostics.Process

# Init PowerShell Gui
Add-Type -AssemblyName System.Windows.Forms

# Define the question dialog box
$dialog = New-Object system.Windows.Forms.Form
$dialog.ClientSize = '310,85'
$dialog.BackColor  = "#ffffff"
$dialog.text = "User interaction needed"

$question = New-Object system.Windows.Forms.Label
$question.text     = "Placeholder Text"
$question.Font     = 'Microsoft Sans Serif,10'
$question.width    = 300
$question.height    = 30
$question.location = New-Object System.Drawing.Point(20,1)

$dialogOKButton           = New-Object system.Windows.Forms.Button
$dialogOKButton.BackColor = "#a4ba67"
$dialogOKButton.text      = "OK"
$dialogOKButton.width     = 90
$dialogOKButton.height    = 30
$dialogOKButton.location  = New-Object System.Drawing.Point(20,40)
$dialogOKButton.Font      = 'Microsoft Sans Serif,10'
$dialogOKButton.ForeColor = "#ffffff"
$dialogOKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK

$dialogCancelBtn              = New-Object system.Windows.Forms.Button
$dialogCancelBtn.BackColor    = "#ffffff"
$dialogCancelBtn.text         = "Cancel"
$dialogCancelBtn.width        = 90
$dialogCancelBtn.height       = 30
$dialogCancelBtn.location     = New-Object System.Drawing.Point(120,40)
$dialogCancelBtn.Font         = 'Microsoft Sans Serif,10'
$dialogCancelBtn.ForeColor    = "#000"
$dialogCancelBtn.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

$dialog.AcceptButton = $dialogOKButton
$dialog.CancelButton = $cancelBtn
$dialog.Controls.Add($dialogOKButton)
$dialog.Controls.Add($cancelBtn)
$dialog.controls.AddRange(@($question, $dialogOKButton, $dialogCancelBtn))

# Clear the console
Clear-Host


# Starting Notification
Write-Host "###############################################"
Write-Host "### Janitor is starting to clean the system ###"
Write-Host "###############################################"

$windowsDir = $env:windir
$systemDrive = $windowsDir.split('\')[0]+"\"
$ccleaner = ((Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -Match "CCleaner")
Write-Host "`nSystem drive is:" $systemDrive
Write-Host "Windows location is:" $windowsDir

Write-Host "`n1/6 -> Run windows clean manager"
# Set cleanmgr configuration withing set 1
cleanmgr /sageset:1 | Out-Null

# Run cleanmgr with configuration of set 1 if user presses OK
$question.text = "Do you want to start the Clean Manager now?`nHint: This can take some time"
$result = $dialog.ShowDialog()

if($result -eq "OK") {
    cleanmgr /sagerun:1 | Out-Null
}

# Clean the Windows Temp folder
Write-Host "`n2/6 -> Cleaning Windows Temp Folder"
Remove-Item -Path $windowsDir\Temp\* -Recurse -ErrorAction Ignore

# Clean the Prefetch Folder
Write-Host "`n3/6 -> Cleaning Windows Prefetch Folder"
Remove-Item -Path $windowsDir\Prefetch\* -Recurse -ErrorAction Ignore

# Clean the Applications Temp folder
Write-Host "`n4/6 -> Cleaning Application Temp Folder"
Remove-Item -Path $env:LOCALAPPDATA\Temp\* -Recurse -ErrorAction Ignore

# Clear all .log .bak .tmp .gid .old files on the system
Write-Host "`n5/6 -> Delete unnecessary files on system drive"
Write-Host "`n- Cleaning gid files (.gid)"
Remove-Item -Path $systemDrive"\*" -Include *.gid -Recurse -ErrorAction Ignore
Write-Host "- Cleaning old files (.old)" 
Remove-Item -Path $systemDrive"\*" -Include *.old -Recurse -ErrorAction Ignore
Write-Host "- Cleaning temporary files (.tmp)"
Remove-Item -Path $systemDrive"\*" -Include *.tmp -Recurse -ErrorAction Ignore
Write-Host "- Cleaning backup files (.bak)"
Remove-Item -Path $systemDrive"\*" -Include *.bak -Recurse -ErrorAction Ignore
Write-Host "- Cleaning log files (.log)"
Remove-Item -Path $systemDrive"\*" -Include *.bak -Recurse -ErrorAction Ignore

# Shutdown windows update service and clean artifacts
Write-Host "`n6/6 -> Clean up windows updates`n"
$winUpdateService = Get-Service -Name "wuauserv"
if($winUpdateService.Status -eq "Running"){
    net stop wuauserv
}
Remove-Item -Path $windowsDir"\SoftwareDistribution\" -Include *.* -Recurse
net start wuauserv

# Run CCleaner if installed and user acknowledged
if($ccleaner -ne "") {
    $question.text = "CCleaner has been detected on your system. Do you want to run it now?"
    $result = $dialog.ShowDialog()
    if($result -eq "OK") {
        Write-Host "`n7/7 -> Run CCleaner`n"
        Start-Process -FilePath "ccleaner.exe" -ArgumentList "/auto" | Out-Null
        $question.text = "Do you want to clean your registry also? `nThis requires manual interaction"
        $result = $dialog.ShowDialog()
        if($result -eq "OK") {
            Start-Process -FilePath "ccleaner.exe" -ArgumentList "/registry" | Out-Null
        }
    }
}

# End of script
Write-Host "`n#######################################"
Write-Host "### Janitor finished his cleaning ###"
Write-Host "#######################################"