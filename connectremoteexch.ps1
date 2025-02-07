$UserCredential = Get-Credential -UserName "gazpromuk\tsenteki.adm"
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://sspr-excmbx12/PowerShell/ -Authentication Kerberos -Credential $UserCredential
Import-PSSession $Session -DisableNameChecking