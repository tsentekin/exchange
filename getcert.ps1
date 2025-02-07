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

    # Loop through each certificate and add it to the results array
    foreach ($cert in $serverCertificates) {
        $certificates += [PSCustomObject]@{
            ServerName = $serverName
            CertificateName = $cert.FriendlyName
            Thumbprint = $cert.Thumbprint
        }
    }
}

# Display the results
$certificates | Format-Table -AutoSize

# Optionally, export the results to a CSV file
$certificates | Export-Csv -Path "C:\ExchangeCertificates.csv" -NoTypeInformation
