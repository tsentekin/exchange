# Fetch all mail-enabled groups
$mailEnabledGroups = Get-DistributionGroup -ResultSize Unlimited

# Initialize an array to store the output
$output = @()

foreach ($group in $mailEnabledGroups) {
    # Get the email addresses of the group
    $emailAddresses = $group.EmailAddresses | Where-Object { $_ -match "SMTP:" -or $_ -match "smtp:" }

    foreach ($email in $emailAddresses) {
        # Convert email object to string for processing
        $emailString = $email.ToString()

        # Check if it's the default email (case-sensitive 'SMTP:' indicates default)
        if ($emailString -cmatch "^SMTP:") {  # Use -cmatch for case-sensitive regex match
            $isDefault = "Yes"
        } else {
            $isDefault = "No"
        }

        # Clean up the email address (remove SMTP: or smtp:)
        $emailAddressCleaned = $emailString -replace "SMTP:", "" -replace "smtp:", ""

        # Add the information to the output array
        $output += [PSCustomObject]@{
            GroupName       = $group.DisplayName
            GroupPrimarySmtpAddress = $group.PrimarySmtpAddress
            EmailAddress    = $emailAddressCleaned
            IsDefault       = $isDefault
        }
    }
}

# Export the output to a CSV file
$output | Export-Csv -Path "ExchangeMailEnabledGroupsEmailAddresses.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Export completed. Output saved to 'ExchangeMailEnabledGroupsEmailAddresses.csv' in the current directory." -ForegroundColor Green
