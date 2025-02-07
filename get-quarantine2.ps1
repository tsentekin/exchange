# Prompt the user for input
$RecipientAddress = Read-Host "Enter the recipient's email address"
$SenderAddress = Read-Host "Enter the sender's email address"
$StartReceivedDate = Read-Host "Enter the start received date (YYYY-MM-DD format)"
$EndReceivedDate = Read-Host "Enter the end received date (YYYY-MM-DD format)"

# Convert dates to proper format
$StartReceivedDate = Get-Date $StartReceivedDate -Format "yyyy-MM-ddTHH:mm:ss"
$EndReceivedDate = Get-Date $EndReceivedDate -Format "yyyy-MM-ddTHH:mm:ss"

# Get the quarantined items based on the specified criteria
$quarantinedItems = Get-QuarantineMessage -RecipientAddress $RecipientAddress `
                                          -SenderAddress $SenderAddress `
                                          -StartReceivedDate $StartReceivedDate `
                                          -EndReceivedDate $EndReceivedDate

# Display the quarantined items in an Excel-like table format
$quarantinedItems | Format-Table Subject, Received, QuarantineReason, PolicyType, ReleaseStatus, Expires -AutoSize

# Commented out section for exporting the results to CSV
# Uncomment and modify the path to use this section later
# $quarantinedItems | Select-Object Subject, Received, QuarantineReason, PolicyType, ReleaseStatus, Expires |
# Export-Csv -Path "C:\Path\To\Output\quarantined_items.csv" -NoTypeInformation
