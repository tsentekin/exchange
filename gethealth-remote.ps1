
$UserCredential = Get-Credential -UserName "gazpromuk\tsenteki.adm"
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://sspr-excmbx12/PowerShell/ -Authentication Kerberos -Credential $UserCredential
Import-PSSession $Session -DisableNameChecking -AllowClobber

start-sleep -Seconds 5

$servers = Get-ExchangeServer
$results = @()

foreach ($server in $servers) {
    $serverName = $server.Name
    $serverHealth = Get-ServerHealth -Identity $serverName | Select-Object Server, CurrentHealthSetState, Name, HealthSetName, AlertValue, HealthGroupName
    $results += $serverHealth
}
$results | Export-Csv -Path "C:\Users\tsenteki\out\exchealth.csv" -NoTypeInformation
