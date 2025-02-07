# Fetch all shared mailboxes
$sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited

# Initialize an array to store the output
$output = @()

foreach ($mailbox in $sharedMailboxes) {
    # Get the email addresses of the shared mailbox
    $emailAddresses = $mailbox.EmailAddresses | Where-Object { $_ -match "SMTP:" -or $_ -match "smtp:" }

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
            SharedMailboxName    = $mailbox.DisplayName
            SharedMailboxPrimarySmtpAddress = $mailbox.PrimarySmtpAddress
            EmailAddress         = $emailAddressCleaned
            IsDefault            = $isDefault
        }
    }
}

# Export the output to a CSV file
$output | Export-Csv -Path "ExchangeSharedMailboxesEmailAddresses.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Export completed. Output saved to 'ExchangeSharedMailboxesEmailAddresses.csv' in the current directory." -ForegroundColor Green
