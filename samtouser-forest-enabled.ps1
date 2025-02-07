# Define the path to the input file and output file
$inputFilePath = "C:\users\tsenteki.adm\desktop\SAMAccountNames.txt"
$outputFilePath = "C:\users\tsenteki.adm\desktop\SAP33-ExportedUsers.csv"

# Read the list of SAMAccount names
$samAccountNames = Get-Content -Path $inputFilePath

# Initialize an empty array to store the results
$results = @()

# Get all domains in the forest
$forest = Get-ADForest
$domains = $forest.Domains

foreach ($samAccountName in $samAccountNames) {
    $userFound = $false

    foreach ($domain in $domains) {
        if ($userFound) { break }

        # Get the user from the current domain
        $user = Get-ADUser -Server $domain -Filter {SamAccountName -eq $samAccountName} -Property SamAccountName, DisplayName, Surname, GivenName, EmailAddress, Enabled

        if ($user) {
            # Create a custom object to store the desired properties
            $userInfo = [PSCustomObject]@{
                SamAccountName = $user.SamAccountName
                GivenName = $user.GivenName
                Surname = $user.Surname
                EmailAddress = $user.EmailAddress
                Domain = $domain
                Enabled = $user.Enabled
            }

            # Add the custom object to the results array
            $results += $userInfo
            $userFound = $true
        }
    }

    if (-not $userFound) {
        Write-Output "User $samAccountName not found in any domain."
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path $outputFilePath -NoTypeInformation

Write-Output "Export completed. Check the file at $outputFilePath"
