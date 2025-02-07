$startDate = (Get-Date).AddDays(-1)
$endDate = Get-Date

Get-MessageTrace -StartDate $startDate -EndDate $endDate | Where-Object {$_.Status -eq "Pending"}
