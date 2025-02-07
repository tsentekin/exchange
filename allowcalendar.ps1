# Define variables for the mailbox and user
$mailbox = Read-Host "mailbox to share calendar"
$user = Read-Host  "mailbox to add to security"

# Check if the mailbox exists
$mailboxCheck = Get-Mailbox -Identity $mailbox -ErrorAction SilentlyContinue

if ($null -eq $mailboxCheck) {
    Write-Host "Mailbox '$mailbox' not found. Please check the email address and try again." -ForegroundColor Red
    exit
}

# Get the calendar folder statistics for the mailbox
$calendarFolder = Get-MailboxFolderStatistics -Identity $mailbox -FolderScope Calendar | select name -First 1

if ($null -eq $calendarFolder) {
    Write-Host "Calendar folder not found in mailbox '$mailbox'. Please check if the calendar folder exists." -ForegroundColor Red
    exit
}

# Get the correct folder path and format it
$folderPath = $calendarFolder.FolderPath -replace '/', '\'  # Replace '/' with '\'

Write-Host "Calendar folder found: '$folderPath'. Proceeding to set permissions..." -ForegroundColor Green

# Set the permission on the calendar folder
try {
    Add-MailboxFolderPermission -Identity "$mailbox$folderPath" -User $user -AccessRights Editor
    Write-Host "Permission granted successfully to $user on $mailbox$folderPath" -ForegroundColor Green
}
catch {
    Write-Host "An error occurred while setting the permission: $_" -ForegroundColor Red
}
