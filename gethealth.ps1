$servers = Get-ExchangeServer
$results = foreach ($server in $servers) {
    Get-ServerHealth -Identity $server | Select-Object Server, CurrentHealthSetState, Name, HealthSetName, AlertValue, HealthGroupName
} -Credential $credential
$results | Export-Csv -Path "C:\Users\tsenteki\out\exchealth.csv" -NoTypeInformation