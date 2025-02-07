# Prompt user to enter the target email address
$EmailAddress = Read-Host "Please enter the email address to search"

# Import the Exchange Management Shell module
if (!(Get-Module -Name ExchangeOnlineManagement)) {
    Import-Module 'C:\Program Files\Microsoft\Exchange Server\V15\Bin\RemoteExchange.ps1'
    Connect-ExchangeServer -auto
}

# Search for the mailbox associated with the email address
$Mailbox = Get-Mailbox -Identity $EmailAddress -ErrorAction SilentlyContinue

if ($Mailbox) {
    Write-Host "Mailbox found:"
    Write-Host "Display Name: $($Mailbox.DisplayName)"
    Write-Host "Primary Email: $($Mailbox.PrimarySmtpAddress)"
    Write-Host "Aliases: $($Mailbox.EmailAddresses -join ', ')"
} else {
    Write-Host "No mailbox found with the email address: $EmailAddress"
}

# Additionally, search for the email address in mail contacts (in case it's an external contact)
$MailContact = Get-MailContact -Identity $EmailAddress -ErrorAction SilentlyContinue

if ($MailContact) {
    Write-Host "Mail contact found:"
    Write-Host "Display Name: $($MailContact.DisplayName)"
    Write-Host "Email: $($MailContact.PrimarySmtpAddress)"
} else {
    Write-Host "No mail contact found with the email address: $EmailAddress"
}

# Additionally, search for the email address in mail users (in case it's a mail-enabled user)
$MailUser = Get-MailUser -Identity $EmailAddress -ErrorAction SilentlyContinue

if ($MailUser) {
    Write-Host "Mail user found:"
    Write-Host "Display Name: $($MailUser.DisplayName)"
    Write-Host "Email: $($MailUser.PrimarySmtpAddress)"
} else {
    Write-Host "No mail user found with the email address: $EmailAddress"
}
