# Prompt the user for input
$RecipientAddress = Read-Host "Enter the recipient's email address"
$SenderAddress = Read-Host "Enter the sender's email address (Leave blank to include all senders)"
$StartReceivedDate = Read-Host "Enter the start received date (YYYY-MM-DD format)"
$EndReceivedDate = Read-Host "Enter the end received date (YYYY-MM-DD format)"

# Convert dates to proper format
$StartReceivedDate = Get-Date $StartReceivedDate -Format "yyyy-MM-ddTHH:mm:ss"
$EndReceivedDate = Get-Date $EndReceivedDate -Format "yyyy-MM-ddTHH:mm:ss"

# Get the quarantined items based on the specified criteria
if ([string]::IsNullOrEmpty($SenderAddress)) {
    # If $SenderAddress is empty, query all messages without filtering by sender
    $quarantinedItems = Get-QuarantineMessage -RecipientAddress $RecipientAddress `
                                              -StartReceivedDate $StartReceivedDate `
                                              -EndReceivedDate $EndReceivedDate
} else {
    # If $SenderAddress is provided, include it in the filter
    $quarantinedItems = Get-QuarantineMessage -RecipientAddress $RecipientAddress `
                                              -SenderAddress $SenderAddress `
                                              -StartReceivedDate $StartReceivedDate `
                                              -EndReceivedDate $EndReceivedDate
}

# Check if there are any quarantined items
if ($quarantinedItems) {
    # Display the quarantined items in an Excel-like table format
    $quarantinedItems | Format-Table Subject, Received, QuarantineReason, PolicyType, ReleaseStatus, Expires -AutoSize
    
    # Ask the user if they want to release all quarantined emails
    $releaseEmails = Read-Host "Do you want to release all quarantined emails? (Y/N)"

    # If user selects "Y", release all quarantined emails to all recipients automatically
    if ($releaseEmails -eq "Y" -or $releaseEmails -eq "y") {
        foreach ($item in $quarantinedItems) {
            try {
                # Release the email to all recipients
                Release-QuarantineMessage -Identity $item.Identity -ReleaseToAll
                Write-Host "Released email with Subject: $($item.Subject) to all recipients."
            } catch {
                Write-Host "Failed to release email with Subject: $($item.Subject)"
            }
        }
    } else {
        Write-Host "No emails were released."
    }
} else {
    Write-Host "No quarantined email items found for the specified criteria."
}

# Commented out section for exporting the results to CSV
# Uncomment and modify the path to use this section later
# $quarantinedItems | Select-Object Subject, Received, QuarantineReason, PolicyType, ReleaseStatus, Expires |
# Export-Csv -Path "C:\Path\To\Output\quarantined_items.csv" -NoTypeInformation
