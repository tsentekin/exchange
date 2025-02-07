
###Update Internet Receive Connector IPs with Microsoft Office365 IPs##

if (-not (Get-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction SilentlyContinue)) {
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
}

$url = "https://endpoints.office.com/endpoints/worldwide?clientrequestid=b10c5ed1-bad1-445f-b386-b919946339a7"
$connectorName = "Internet Receive Connector"
$outputCsv = ".\Office365_IPv4_Addresses.csv"
$scriptName = "Update_Receive_Connector"
$timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")
$logFile = ".\${scriptName}_${timestamp}.log"

####################################################################

function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $message"
    $logEntry | Out-File -FilePath $logFile -Append
    Write-Output $logEntry
}


try {
    $jsonData = Invoke-RestMethod -Uri $url -UseBasicParsing
    Log-Message "Successfully downloaded JSON data."
} catch {
    Log-Message "Failed to download JSON data from $url"
    return
}


$filteredData = $jsonData | Where-Object { $_.id -in 1, 2, 9, 10 } | ForEach-Object {
    $ipv4Addresses = $_.ips | Where-Object { $_ -notmatch ":" } # Exclude IPv6 addresses
    [PSCustomObject]@{
        ID            = $_.id
        ServiceArea   = $_.serviceAreaDisplayName
        IPv4Addresses = $ipv4Addresses -join "; "
    }
}

try {
    $filteredData | Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8
    Log-Message "CSV file created at $outputCsv."
} catch {
    Log-Message "Failed to export data to CSV file at $outputCsv."
}

$csvIPs = $filteredData | ForEach-Object { $_.IPv4Addresses -split "; " } | Select-Object -Unique


#################################################################
try {
    $connector = Get-ReceiveConnector -Identity $connectorName
    $connectorIPs = $connector.RemoteIPRanges | ForEach-Object { $_.ToString() }
    Log-Message "Successfully retrieved IPs from '$connectorName'."
} catch {
    Log-Message "Failed to retrieve IPs from the connector named $connectorName."
    return
}


#################################################################

$missingIPs = $csvIPs | Where-Object { $connectorIPs -notcontains $_ }

if ($missingIPs) {
    Log-Message "The following IPs are missing from '$connectorName' and will be added:"
    $missingIPs | ForEach-Object { Log-Message $_ }

    # Create an updated list of IP ranges by adding missing IPs
    $updatedIPRanges = $connector.RemoteIPRanges + ($missingIPs | ForEach-Object { [System.Net.IPAddress]::Parse($_) })

    # Update the Receive Connector with the new list of IPs
     # Update the Receive Connector with the new list of IPs
     try {
        Get-ExchangeServer | Get-ReceiveConnector | Where-Object { $_.Name -like "*Internet Receive Connector*" } | Set-ReceiveConnector -RemoteIPRanges $updatedIPRanges
        Log-Message "Successfully appended missing IPs to '$connectorName'."
    } catch {
        Log-Message "Failed to update the connector with missing IPs."
    }
} else {
    Log-Message "All IPs from the JSON data are already present in '$connectorName'. No update needed."
}

Log-Message "Script execution completed."