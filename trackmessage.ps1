# Define the Exchange server to connect to
$ExchangeServer = "sspr-excmbx17"

# Prompt for the sender and recipient email addresses
$senderEmail = Read-Host "Enter sender email (leave blank to include all senders)"
$recipientEmail = Read-Host "Enter recipient email (leave blank to include all recipients)"

# Define the date range for the message tracking
$startDate = (Get-Date).AddDays(-7)  # Last 7 days
$endDate = Get-Date

# Prepare the filter based on input
$filter = @{
    Server = $ExchangeServer
    Start = $startDate
    End = $endDate
}

if ($senderEmail) {
    $filter.Sender = $senderEmail
}

if ($recipientEmail) {
    $filter.Recipients = $recipientEmail
}

# Get message tracking logs with the prepared filter
$trackingLogs = Get-MessageTrackingLog @filter

# Display the tracking logs
$trackingLogs | Select-Object Timestamp,Sender,Recipients,MessageSubject,EventId | Format-Table -AutoSize

# Save the tracking logs to a CSV file
$trackingLogs | Select-Object Timestamp,Sender,Recipients,MessageSubject,EventId | Export-Csv -Path ".\MessageTrackingLogs.csv" -NoTypeInformation
