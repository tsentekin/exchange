# Specify the thumbprint of the certificate
$thumbprint = "D8B449F171CC49EFCF4FEE6AD7D7CC9C607654CB"

# Get the specific Exchange certificate by thumbprint
$cert = Get-ExchangeCertificate -Thumbprint $thumbprint

if ($cert) {
    # Extract certificate details
    $issuer = $cert.Issuer
    $subject = $cert.Subject

    # Create TLS certificate name in the correct format
    $tlscertificatename = "<i>$issuer<s>$subject"
    
    # Output certificate details including the TLS certificate name
    [PSCustomObject]@{
        Thumbprint           = $thumbprint
        Issuer               = $issuer
        Subject              = $subject
        TLSCertificateName   = $tlscertificatename
    }

    # Update the Send connector with the TLS certificate name
    try {
        Set-SendConnector -Identity "External Mails via PostFix - DC2 - pfx4" -TlsCertificateName $tlscertificatename
        Write-Output "Updated Send connector with TLS certificate name: $tlscertificatename"
    } catch {
        Write-Error "Failed to update Send connector: $_"
    }
} else {
    Write-Error "Certificate with thumbprint $thumbprint not found."
}
