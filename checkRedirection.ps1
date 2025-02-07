foreach ($i in (Get-Mailbox -ResultSize unlimited)) { Get-InboxRule -Mailbox $i.DistinguishedName | where {$_.ForwardTo} | fl MailboxOwnerID,Name,ForwardTo >> d:\Forward_Rule.txt }

foreach ($i in (Get-Mailbox -ResultSize unlimited)) { Get-InboxRule -Mailbox $i.DistinguishedName | where {$_.ReDirectTo} | fl MailboxOwnerID,Name,RedirectTo >> d:\Redirect_Rule.txt }