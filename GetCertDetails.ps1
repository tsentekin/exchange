# Get all Exchange certificates
$certificates = Get-ExchangeCertificate

# Initialize an array to hold the results
$results = @()

# Loop through each certificate
foreach ($cert in $certificates) {
    # Extract certificate details
    $thumbprint = $cert.Thumbprint
    $certificateDomains = $cert.CertificateDomains -join ", "
    $notAfter = $cert.NotAfter
    $issuer = $cert.Issuer
    $subject = $cert.Subject

    # Create TLS certificate name
    $tlscertificatename = "<i>$issuer<s>$subject"
    
    # Create a custom object for the certificate details
    $result = [PSCustomObject]@{
        Thumbprint           = $thumbprint
        CertificateDomains   = $certificateDomains
        NotAfter             = $notAfter
        Issuer               = $issuer
        Subject              = $subject
        TLSCertificateName   = $tlscertificatename
    }

    # Add the result to the array
    $results += $result
}

# Output the results in a table format
$results | Format-Table -AutoSize
