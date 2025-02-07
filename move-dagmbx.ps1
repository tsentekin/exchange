
$ServerName = Read-Host "Enter the Server Name (e.g., srv1)"


$Target = Read-Host "Enter the Target Server Name (e.g., srv2)"


$DomainSuffix = "gazpromuk.intra"


$TargetFQDN = "$Target.$DomainSuffix"


Write-Host "Target FQDN: $TargetFQDN"

# Execute the Move-ActiveMailboxDatabase cmdlet
Get-MailboxServer $ServerName | Move-ActiveMailboxDatabase -ActivateOnServer $Target
