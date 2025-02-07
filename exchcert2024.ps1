$domainlist = get-content c:\temp\domain_list.txt

$Data=New-ExchangeCertificate -generaterequest -KeySize 2048 -subjectname "CN=webmail.itss.global,OU=Domain Control Validated" -domainname $domainlist -PrivateKeyExportable $true

Set-Content -path "c:\temp\certrequest-2024.req" -Value $Data


Invoke-MonitoringProbe Outlook.Proxy\OutlookMapiHttpProxyTestMonitor -Server sspr-excmbx06 | Format-List  

$servers=get-exchangeserver
foreach ($server in $servers
 Get-ServerHealth | Format-Table Server,CurrentHealthSetState,Name,HealthSetName,AlertValue,HealthGroupName -Auto
 )
 
 
 
 
Your support request number is
2406190030010030
A Microsoft support engineer will contact Tolga Sentekin at Tolga.Sentekin@sefe-mt.com or +447760925620.

05-06
11-21
17-27
18-28
11-27 -- mbx-uk-db66 mbx-uk-db67



