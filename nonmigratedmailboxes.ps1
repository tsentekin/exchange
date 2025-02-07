# Import Active Directory Module (if not already available)
Import-Module ActiveDirectory

# Get all **user** mailboxes that are non-migrated and active (excluding disabled users)
$userMailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object { 
    $_.RecipientTypeDetails -eq "UserMailbox" -and 
    $_.RemoteRecipientType -eq "None" -and 
    $_.AccountDisabled -eq $false  # Exclude disabled accounts only for user mailboxes
}

# Get all **shared** mailboxes that are non-migrated (without filtering by disabled status)
$sharedMailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object { 
    $_.RecipientTypeDetails -eq "SharedMailbox" -and 
    $_.RemoteRecipientType -eq "None"
}

# Combine both user and shared mailboxes into one list
$allNonMigratedMailboxes = $userMailboxes + $sharedMailboxes

# Total count of all non-migrated mailboxes
$TotalAllNonMigrated = $allNonMigratedMailboxes.Count

# Fetch AD users whose OU contains "Service Accounts"
$serviceAccountUsers = Get-ADUser -Filter * -Properties DistinguishedName | Where-Object {
    $_.DistinguishedName -like "*Service Accounts*"
}

# Extract the list of service account usernames (SamAccountName or Alias)
$serviceAccountNames = $serviceAccountUsers.SamAccountName

# Filter service accounts from all non-migrated mailboxes
$svcMailboxes = $allNonMigratedMailboxes | Where-Object { $_.Alias -in $serviceAccountNames }
$svcMailboxesCount = $svcMailboxes.Count

# Remove service accounts from the general mailbox list
$filteredMailboxes = $allNonMigratedMailboxes | Where-Object { $_.Alias -notin $serviceAccountNames }

# Count the filtered mailboxes (Non-Migrated, Non-Service Accounts)
$TotalFilteredMailboxes = $filteredMailboxes.Count

# Initialize variables for total size
$TotalSizeMB = 0
$MailboxDetails = @()

foreach ($mailbox in $filteredMailboxes) {
    # Using Alias (or DistinguishedName if Alias is missing)
    $identity = if ($mailbox.Alias) { $mailbox.Alias } else { $mailbox.DistinguishedName }

    $stats = Get-MailboxStatistics -Identity $identity -ErrorAction SilentlyContinue

    if ($stats) {
        $sizeInMB = [math]::Round(($stats.TotalItemSize.Value.ToString() -replace '[\D]', '') / 1MB, 2)
        $TotalSizeMB += $sizeInMB

        # Determine mailbox type (Standard or Shared)
        $MailboxType = if ($mailbox.RecipientTypeDetails -eq "SharedMailbox") { "Shared" } else { "Standard" }

        # Store mailbox details
        $MailboxDetails += [PSCustomObject]@{
            Name = $mailbox.DisplayName
            Alias = $mailbox.Alias
            PrimarySMTP = $mailbox.PrimarySmtpAddress
            MailboxType = $MailboxType  # Standard or Shared
            RemoteRecipientType = $mailbox.RemoteRecipientType  # Added RemoteRecipientType
            SizeMB = $sizeInMB
            SizeTB = [math]::Round($sizeInMB / 1048576, 6)  # Convert MB to TB
        }
    }
}

# Convert total size from MB to TB
$TotalSizeTB = [math]::Round($TotalSizeMB / 1048576, 6)

# Output results
Write-Host "----------------------------------------------"
Write-Host "Total Non-Migrated Mailboxes (ALL): $TotalAllNonMigrated"
Write-Host "Total Non-Migrated Service Account Mailboxes: $svcMailboxesCount"
Write-Host "Total Non-Migrated Mailboxes (excluding Service Accounts): $TotalFilteredMailboxes"
Write-Host "Total Mailbox Size (TB): $TotalSizeTB"
Write-Host "----------------------------------------------"

# Export results to CSV
$CsvPath = "C:\Temp\NonMigratedMailboxes.csv"
$MailboxDetails | Export-Csv -Path $CsvPath -NoTypeInformation
Write-Host "Report saved to: $CsvPath"

# Show the mailbox details in table format
$MailboxDetails | Format-Table -AutoSize
