Get-Mailbox -RecipientTypeDetails SharedMailbox | ForEach-Object {
 $SharedMBX = $_.PrimarySmtpAddress.Address;
 echo $SharedMBX;
 Set-Mailbox $SharedMBX -MessageCopyForSentAsEnabled $True;
 Set-Mailbox $SharedMBX -MessageCopyForSendOnBehalfEnabled $True;
}