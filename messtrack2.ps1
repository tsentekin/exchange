# Define the email address to track
$emailAddress = "CIE-EY@sefe.eu"

# Define the date range (adjust as needed)
$startDate = (Get-Date).AddDays(-180)
$endDate = Get-Date

# Get a list of all Mailbox servers
$servers = Get-ExchangeServer | Where-Object {$_.ServerRole -like "*Mailbox*"}

# Initialize an array to hold custom objects
$customLogEntries = @()

# Loop through each server and collect message tracking logs
foreach ($server in $servers) {
    Write-Host "Retrieving logs from server: $($server.Name)"
    
    $trackingLogs = Get-MessageTrackingLog -Server $server.Name -Recipients $emailAddress -Start $startDate -End $endDate
    
    # Process each log entry and create a custom object
    foreach ($logEntry in $trackingLogs) {
        $customObject = New-Object PSObject -Property @{
            MessageID = $logEntry.MessageId
            Timestamp = $logEntry.Timestamp
            Sender = $logEntry.Sender
            Recipients = ($logEntry.Recipients -join ', ')
            Subject = $logEntry.MessageSubject
            Event = $logEntry.EventId
            Server = $server.Name
        }

        # Add the custom object to the array
        $customLogEntries += $customObject
    }
}

# Export the array of custom objects to a CSV file
$csvPath = ".\3messagetracking.csv"
$customLogEntries | Export-Csv -Path $csvPath -NoTypeInformation

Write-Host "Tracking log has been exported to CSV file at: $csvPath"
