$SharedMBX = Get-Mailbox -Filter {recipienttypedetails -eq "SharedMailbox"} 
 ForEach-Object {
 echo $SharedMBX;
 Set-Mailbox $SharedMBX -MessageCopyForSentAsEnabled $True;
 Set-Mailbox $SharedMBX -MessageCopyForSendOnBehalfEnabled $True;
}