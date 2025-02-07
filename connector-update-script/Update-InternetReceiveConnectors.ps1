### Update On-Prem Internet Receive Connector IPs with Microsoft Office365 IPs ###

####################################################################
if (-not (Get-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction SilentlyContinue)) {
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
}

####################################################################
$url = "https://endpoints.office.com/endpoints/worldwide?clientrequestid=b10c5ed1-bad1-445f-b386-b919946339a7"
$connectorName = "Internet Receive Connector"
$scriptName = "Update_Receive_Connector"
$timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")

####################################################################
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$outputCsv = Join-Path $scriptDir "Office365_IPv4_Addresses.csv"
$logFile = Join-Path $scriptDir "${scriptName}_${timestamp}.log"

####################################################################
$fromAddress = "exchange.subsystem@gazprom-mt.com"
$toAddresses = @("tolga.sentekin.ext@sefe.eu", "IR.infSupport.P2@sefe-mt.com", "gm&tserverteam@sefe-mt.com", "ServerTeamGroupInbox@sefe-mt.com")
$smtpServer = "sefe-eu.mail.protection.outlook.com"
$subject = "Exchange Receive Connector Update Log - $timestamp"
$smtpPort = 25  # Common port for TLS/SSL connections

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

####################################################################
try {
    $jsonData = Invoke-RestMethod -Uri $url -UseBasicParsing
    Log-Message "Successfully downloaded JSON data."
} catch {
    Log-Message "Failed to download JSON data from $url"
    return
}

####################################################################
$filteredData = $jsonData | Where-Object { $_.id -in 1, 2, 9, 10 } | ForEach-Object {
    $ipv4Addresses = $_.ips | Where-Object { $_ -notmatch ":" } # Exclude IPv6 addresses
    [PSCustomObject]@{
        ID            = $_.id
        ServiceArea   = $_.serviceAreaDisplayName
        IPv4Addresses = $ipv4Addresses -join "; "
    }
}

####################################################################
try {
    $filteredData | Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8
    Log-Message "CSV file created at $outputCsv."
} catch {
    Log-Message "Failed to export data to CSV file at $outputCsv."
}

####################################################################
$csvPath = $outputCsv  # Use the updated path
$office365Data = Import-Csv -Path $csvPath
$desiredIPs = @()
foreach ($row in $office365Data) {
    $desiredIPs += $row.IPv4Addresses -split ";"
}
$desiredIPs = $desiredIPs | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

####################################################################
$csvIPs = $filteredData | ForEach-Object { $_.IPv4Addresses -split "; " } | Select-Object -Unique

#################################################################

try {
    $connectors = Get-ExchangeServer | Get-ReceiveConnector | Where-Object { $_.Name -like "*$connectorName*" }
    if ($connectors) {
        Log-Message "Successfully retrieved IPs from connectors matching '$connectorName'."
    } else {
        Log-Message "No connectors found matching '$connectorName'."
        return
    }
} catch {
    Log-Message "Failed to retrieve connectors matching $connectorName."
    return
}

#################################################################

foreach ($connector in $connectors) {
    # Get existing IP ranges
    $connectorIPs = $connector.RemoteIPRanges | ForEach-Object { $_.ToString() }
    
 
    $missingIPs = $csvIPs | Where-Object { $connectorIPs -notcontains $_ }

    if ($missingIPs) {
        Log-Message "The following IPs are missing from '$($connector.Identity)' and will be added:"
        $missingIPs | ForEach-Object { Log-Message $_ }

        # Create an updated list of IP ranges by adding missing IPs
        $updatedIPRanges = $connector.RemoteIPRanges + ($missingIPs | ForEach-Object {
            try {
                [Microsoft.Exchange.Data.IPRange]::Parse($_)
            } catch {
                Log-Message "Invalid IP or CIDR notation '$_'. Skipping."
                $null
            }
        })

        ####################################################################
        try {
            Set-ReceiveConnector -Identity $connector.Identity -RemoteIPRanges $updatedIPRanges
            Log-Message "Successfully updated '$($connector.Identity)' with missing IPs."
        } catch {
            Log-Message "Failed to update the connector '$($connector.Identity)' with missing IPs."
        }
    } else {
        Log-Message "All IPs from the JSON data are already present in '$($connector.Identity)'. No update needed."
    }
}

Log-Message "Script execution completed."

####################################################################


try {
      if (-not (Test-Path $logFile)) {
        Log-Message "Log file not found at $logFile. Email will not be sent."
        return
    }

    $mailParams = @{
        From        = $fromAddress
        To          = $toAddresses
        Subject     = $subject
        Body        = "Please find attached the log file for the Receive Connector update script."
        Attachments = $logFile
        SmtpServer  = $smtpServer
        #Port        = $smtpPort
        #UseSsl      = $true
    }

    # Optional: If authentication is required, uncomment and set the credentials
     #$smtpUsername = "username"
     #$smtpPassword = "password"
     #$securePassword = ConvertTo-SecureString $smtpPassword -AsPlainText -Force
     #$credential = New-Object System.Management.Automation.PSCredential ($smtpUsername, $securePassword)
     #$mailParams.Credential = $credential

    Send-MailMessage @mailParams
    Log-Message "Email sent successfully to $($toAddresses -join ', ')"
} catch {
    Log-Message "Failed to send email using TLS. Error: $_"
}
