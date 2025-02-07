$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://testmail.itss.global/PowerShell/ -Authentication Negotiate -Credential $UserCredential
#Import-PSSession $Session

