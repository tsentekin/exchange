# Load Exchange management shell
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

# Get a list of all Exchange 2019 servers
$servers = Get-ExchangeServer -Identity *

# Initialize an array to hold the results
$certificates = @()

# Loop through each server and get the certificates
foreach ($server in $servers) {
    $serverName = $server.Name
    Write-Host "Fetching certificates from server: $serverName"

    # Get the certificates for the current server
    $serverCertificates = Get-ExchangeCertificate -Server $serverName

    # Get all send connectors (without -Server parameter)
    $connectors = Get-SendConnector

    # Loop through each certificate and check if it's assigned to any connector
    foreach ($cert in $serverCertificates) {
        # Check for send connectors that use this certificate
        $assignedConnectors = $connectors | Where-Object { $_.TlsCertificateThumbprint -eq $cert.Thumbprint }

        # Loop through the assigned connectors
        foreach ($connector in $assignedConnectors) {
            $certificates += [PSCustomObject]@{
                ServerName = $serverName
                CertificateName = $cert.FriendlyName
                Thumbprint = $cert.Thumbprint
                ConnectorName = $connector.Name
            }
        }

        # If no connectors found, list the certificate without connectors
        if ($assignedConnectors.Count -eq 0) {
            $certificates += [PSCustomObject]@{
                ServerName = $serverName
                CertificateName = $cert.FriendlyName
                Thumbprint = $cert.Thumbprint
                ConnectorName = 'None'
            }
        }
    }
}

# Display the results
$certificates | Format-Table -AutoSize

# Export the results to a CSV file, including the certificate names
$certificates | Export-Csv -Path "C:\ExchangeCertificatesAndConnectors.csv" -NoTypeInformation
