$ServerName = Read-Host "Enter the Server Name (e.g., srv1)"
(Get-MailboxDatabaseCopyStatus | ? {$_.ActivationPreference -eq 1}).DatabaseName | Move-ActiveMailboxDatabase -ActivateOnServer $ServerName