# Load Exchange management shell
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

# Specify the distribution group name
$distributionGroupName = "Sefe Group All"

# Get the distribution group
$group = Get-DistributionGroup -Identity $distributionGroupName

if ($group -ne $null) {
    Write-Host "Distribution Group:" $group.Name
    Write-Host "Email Address:" $group.PrimarySmtpAddress
    Write-Host "Members:"

    # Get the members of the distribution group
    $members = Get-DistributionGroupMember -Identity $group.Identity

    # Display each member
    foreach ($member in $members) {
        Write-Host $member.Name " <" $member.PrimarySmtpAddress ">"
    }

    # Optionally, export the members to a CSV file
    $members | Select-Object Name, PrimarySmtpAddress | Export-Csv -Path "C\users\tsenteki\out:\groupmembers.csv" -NoTypeInformation
} else {
    Write-Host "Distribution group not found."
}
