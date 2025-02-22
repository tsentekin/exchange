param (
    $MailboxEmail = $null
    , $company = $null
    , $DisplayName = $null
    , $PrimaryOwner = $null
    , $Owners = $null 
    , $FullAccessMembers = $null
)

function AddtoOwnerForGroup {
    param ($GroupEmail, $MemberEmail)

    $GroupsObject = Get-Recipient -Identity $GroupEmail -ErrorAction SilentlyContinue

    if (($null -ne $GroupsObject) -and ($GroupsObject.RecipientType -match "Universal" )) {

        $GroupDN = $GroupsObject.DistinguishedName

        $GroupFound = $GroupsObject.SamAccountName

        $GroupMember = Get-Recipient -Identity $MemberEmail -ErrorAction SilentlyContinue

        if (($null -ne $GroupsObject ) ) {
            
            $MemberFound = $GroupMember.SamAccountName

            $MemberDN = $GroupMember.DistinguishedName

            $MemberName = $GroupMember.Name
            $CheckOWner = Get-DistributionGroup $GroupDN -ErrorAction SilentlyContinue  | Select-Object -ExpandProperty ManagedBY | Where-Object -FilterScript { $PSItem -match $MemberName }

            if ( $null -eq $CheckOWner) {

                if ($Action -eq "set") {

                    Set-DistributionGroup -Identity $GroupDN -ErrorAction SilentlyContinue -BypassSecurityGroupManagerCheck -ManagedBy @{Add = $MemberDN } -Confirm:$false
                    Write-Output "$(Get-Date),Owner Added,$GroupEmail,$MemberEmail" | Out-File -Append $logFile

                }

            }
            else {

                Write-Output "$(Get-Date),Owner already in Group,$GroupEmail,$MemberEmail" | Out-File -Append $logFile
      
            }

            $CheckOWner = Get-DistributionGroup $GroupDN -ErrorAction SilentlyContinue  | Select-Object -ExpandProperty ManagedBy |  Where-Object -FilterScript { $PSItem -match $MemberName }

            if ($null -eq $CheckOWner) {

                if ($Action -eq "set" ) {

                    Write-host "$(Get-Date),Error adding Owner to Group,$GroupEmail,$MemberEmail"  -ForegroundColor RED
                    Write-Output "$(Get-Date),Error adding Owner to Group,$GroupEmail,$MemberEmail" | Out-File -Append $logFile
                    $OwnerShipSet = "FALSE"

                }

            }
            else {

                Write-host "$(Get-Date),Owner added to Group,$GroupEmail,$MemberEmail"  -ForegroundColor Green
                $OwnerShipSet = "TRUE"

            }            

        }
        else {

            Write-Output "$(Get-Date),$(Get-Date),Member Not Found in AD,$GroupEmail,$MemberEmail" | Out-File -Append $logFile
            Write-host "$(Get-Date),Member Not Found in AD,$GroupEmail,$MemberEmail" -ForegroundColor Red
            $MemberFound = "FALSE"

        }

    }
    else {

        Write-Output "$(Get-Date), $GroupEmail,Group Notfound" | Out-File -Append $logFile
        $GroupFound = "FALSE"
        $MemberShipSet = "FALSE"  
    
        $GroupMember = Get-Recipient -Identity $MemberEmail -ErrorAction SilentlyContinue

        if (($null -ne $GroupMember) ) {

            $MemberFound = $GroupMember.SamAccountName

        }
        else {

            $MemberFound = "FALSE"

        } 

    }

}


function AddMemberToDLGroup {
    param ($GroupEmail, $MemberEmail)

    $GroupsObject = Get-Recipient -Identity $GroupEmail -ErrorAction SilentlyContinue

    if (($null -ne $GroupsObject) -and ($GroupsObject.RecipientType -match "Universal" )) {

        $GroupDN = $GroupsObject.DistinguishedName

        $GroupFound = $GroupsObject.SamAccountName

        $GroupMember = Get-Recipient -Identity $MemberEmail -ErrorAction SilentlyContinue

        if (($null -ne $GroupMember) ) {

            $MemberFound = $GroupMember.SamAccountName

            $MemberDN = $GroupMember.DistinguishedName
     
            $CheckMemberShip = Get-DistributionGroupMember -Identity $GroupDN | Where-Object -FilterScript { $PSItem.PrimarySmtpAddress -eq "$MemberEmail" }

            if ($null -eq $CheckMemberShip) {

                if ($Action -eq "set" ) {

                    Add-DistributionGroupMember -Identity $GroupDN -Member $MemberDN -BypassSecurityGroupManagerCheck -Confirm:$false

                    Write-Output "$(Get-Date),Member Added,$GroupEmail,$MemberEmail" | Out-File -Append $logFile

                }

            }
            else {

                Write-Output "$(Get-Date),Member already in Group,$GroupEmail,$MemberEmail" | Out-File -Append $logFile
          
            }

            $CheckMemberShip = Get-DistributionGroupMember $GroupDN  | Where-Object -FilterScript { $PSItem.PrimarySmtpAddress -eq "$MemberEmail" }
    
            if ($null -eq $CheckMemberShip) {

                if ($Action -eq "set" ) {

                    Write-host "$(Get-Date),Error adding Member to Group,$GroupEmail,$MemberEmail" -ForegroundColor Red
                    Write-Output "$(Get-Date),Error adding Member to Group,$GroupEmail,$MemberEmail" | Out-File -Append $logFile
     
                }

            }
            else {

                Write-host "$(Get-Date),Member added to Group,$GroupEmail,$MemberEmail" -ForegroundColor Green
                $MemberShipSet = "TRUE"       

            }

        }
        else {

            Write-Output "$(Get-Date),$(Get-Date),Member Not Found in AD,$GroupEmail,$MemberEmail" | Out-File -Append $logFile
            $MemberFound = "FALSE"

        }

    }
    else {

        Write-Output "$(Get-Date), $GroupEmail,Group Notfound" | Out-File -Append $logFile
        $GroupFound = "FALSE"
        $MemberShipSet = "FALSE"  
    
        $GroupMember = Get-Recipient -Identity $MemberEmail -ErrorAction SilentlyContinue

        if ($null -ne $GroupMember) {

            $MemberFound = $GroupMember.SamAccountName

        }
        else {

            $MemberFound = "FALSE"

        } 

    }

}


## Execution Start here

$DateFile = (Get-date -Format "dd-MM-yy-HHmm")

$logFilePath = "C:\Script\CreateSharedMailbox\Logs"

#$emailaddressFormat = Import-Csv "EmailAddressDomainFormat.csv"

#$Width = 200
#$Height = 150

$UserDN = $null
$WaitTime = 10
$Action = "Set"

#$host.UI.RawUI.BufferSize = New-Object -TypeName System.Management.Automation.Host.Size -ArgumentList ($Width, $host.UI.RawUI.BufferSize.Height)
#$Host.UI.RawUI.BackgroundColor = "DarkBlue"

if ( (Test-Path $logFilePath) -eq $false) {

    New-Item $logFilePath -ItemType Directory

}

$logFile = $logFilePath + "\LogCreateMailbox-$DateFile.Log"

$ErrorActionPreference = "STOP"

$AdminUser = "$($env:USERNAME)"


Write-Output "$(Get-Date),Script Started by $($env:USERDOMAIN)\$($env:USERNAME) on $($env:ComputerName)" | Out-File -Append $logFile

# Make sure ExchangeOnlineManagement module is available
Try {

    Import-Module -Name "ExchangeOnlineManagement" -ErrorAction Stop

}
Catch {

    Write-Host "Cannot Import ExchangeOnlineManagement module, verify module is installed" -ForegroundColor Red 
    Write-Output "Cannot Import ExchangeOnlineManagement module, verify module is installed" |  Out-File -Append $logFile
    Return

}

# Connect to Exchange Online
Try {

    $null = Get-AcceptedDomain -ErrorAction Stop

}
Catch {

    Try {

        Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop

    }
    Catch {

        Write-Host "Cannot connect to Exchange Online, verify server is availble and check your credential have permission to Exchange" -ForegroundColor Red 
        Write-Output "Cannot connect to Exchange Online, verify server is availble and check your credential have permission to Exchange" |  Out-File -Append $logFile
        Return

    }

}

# Set the Company
$companyList = "SMT", "SE", "WING", "SEFE"

$company = $null

$ValidateData = $false

While ($ValidateData -ne $true) {

    if ($null -eq $company) {

        $company = Read-Host "Enter the Company of the Owner of the mailbox $($companyList -join ",") (default WING):"

        if ($company -eq "") {

            $company = "WING"

        }
    }

    if ($companyList -notcontains $company) {

        Write-Host "Company name have to be one of $($companyList -join ",") Try again" -ForegroundColor red
        $company = $null

    }
    else {

        $ValidateData = $true

    }

}

$company = $company.ToUpper()

if ( ($company -eq "SMT")) {

    $ITSSdomain = "@globalitss.onmicrosoft.com"
    $SMGroupPrefix = "AG-UG-$($company)-SM_"

}
elseif ($company -eq "SE") {

    $ITSSdomain = "@globalitss.onmicrosoft.com"
    $SMGroupPrefix = "AG-UG-$($company)-SM_"

}
elseif ($company -eq "WING") {

    $ITSSdomain = "@globalitss.onmicrosoft.com"
    $SMGroupPrefix = "AG-UG-WG-SM_"

}
elseif ($company -eq "SEFE") {

    $ITSSdomain = "@globalitss.onmicrosoft.com"
    $SMGroupPrefix = "AG-UG-SEFE-SM_"
    
}

# REMOVE BEFORE USE
#$ITSSdomain = "@0slhk.onmicrosoft.com"


if ($company -eq "WING") {
    $HelpFormattext = "Please make sure the format of the Mailbox is consistent with these naming conversion. If it is not clear then verify with Wingas GFI team and requester before you run this script
Note: the script is not going to validate your input regarding the format to allow some flexibility so you need to make sure input is given in correct format.
"

    Write-host $HelpFormattext -ForegroundColor Green
    $emailaddressFormat | Format-Table -AutoSize

}

$AllowRerun = $true

<#
$AllowRerun = $false

$checkRights = Get-ADUser -Filter { SamaccountName -eq $AdminUser } -Properties memberof | Select-Object -ExpandProperty Memberof | Where-Object -FilterScript { ($PSItem -match "GM&T Server Team adm") -or ($PSItem -match "GM&T Infrastructure Support Team") }

if ($null -ne $checkRights) {

    $AllowRerun = $true

}

#>



if ($null -eq $MailboxEmail) {

    Write-Host "Enter the email address of the Shared mailbox required in the format:" -ForegroundColor Green 
    $MailboxEmail = Read-Host "MailboxEmail"

    if (($MailboxEmail -eq "" ) -or ($MailboxEmail -match " " ) -or ($MailboxEmail -match "#" )  ) {

        Write-Host "MailboxEmail is NULL or invalid. Cannot be include # symbol or Spaces  - Exit script" -ForegroundColor Red
        Write-Output "$(Get-Date),MailboxEmail Cannot be Null - Exit script" | Out-File -Append $logFile
        Write-host "$(Get-Date),Script Completed. Check logfile for more detail:$logfile" -ForegroundColor Green
        EXIT

    }

}


$UserObject = $null

Try {

    $UserObject = Get-Recipient -Identity $MailboxEmail -ErrorAction Stop

}
Catch {

    $UserObject = $null

}

if ($null -ne $UserObject) {

    if ($AllowRerun -eq $true) {

        Write-Host "The Mailbox already Exists - Are you sure you want to rerun for the same mailbox $($UserObject.Name)" 
        $checkanswer = Read-Host "Type yes to rerun"
        if ($checkanswer -ne "yes") {

            Write-Host "Terminating.." 
            Exit

        }
    }
    else {

        Write-Host "The Mailbox already Exists - You are you sure the email address is correct. if it is you are not allowed to rerun the script. Ask INF Support Team or Server Team to do it for you" -ForegroundColor Red 
        Write-Output "The Mailbox already Exists - You are you sure the email address is correct. if it is you are not allowed to rerun the script. Ask INF Support Team or Server Team to do it for you" | Out-File -Append $logFile

        Write-host "$(Get-Date),Script Completed. Check logfile for more detail:$logfile" -ForegroundColor Green
        EXIT

    }

}

$EmailDomain = ($MailboxEmail -split "@")[1]

if (!(Get-AcceptedDomain | Where-Object -FilterScript { $PSItem.DomainName -eq $EmailDomain })) {

    Write-Host "MailboxEmail $MailboxEmail you have trying to create is not valid - Terminiating" -ForegroundColor red  
    Write-host "$(Get-Date),Script Completed. Check logfile for more detail:$logfile" -ForegroundColor Green
    EXIT

}



if ($null -eq $DisplayName) {

    Write-Host "Enter the Display Name of the Shared mailbox required in the format:" -ForegroundColor Green
    $DisplayName = Read-Host "DisplayName"

    if ($DisplayName -eq "") {

        Write-Host "DisplayName Cannot be Null - Exit script" -ForegroundColor Red
        Write-Output "$(Get-Date),DisplayName Cannot be Null - Exit script" | Out-File -Append $logFile
        Write-host "$(Get-Date),Script Completed. Check logfile for more detail:$logfile" -ForegroundColor Green
        EXIT

    }

}



$ValidateData = $false

While ($ValidateData -ne $true) {

    if ($null -eq $PrimaryOwner) {

        Write-Host "Enter the email address of the Primary Owner of the Shared mailbox:" -ForegroundColor Green
        $PrimaryOwner = Read-Host "Primary Owner" 

        if ($PrimaryOwner -eq "" ) {

            Write-Host "PrimaryOwner Cannot be Null - Exit script" -ForegroundColor Red
            Write-Output "$(Get-Date),PrimaryOwner Cannot be Null - Exit script" | Out-File -Append $logFile
            Write-host "$(Get-Date),Script Completed. Check logfile for more detail:$logfile" -ForegroundColor Green
            EXIT

        }

    }

    $PrimaryOwner = $PrimaryOwner -replace '"', ""

    $PrimaryOwnerDN = (Get-Recipient -Identity $PrimaryOwner -ErrorAction SilentlyContinue).DistinguishedName

    if ($null -ne $PrimaryOwnerDN) {

        $ValidateData = $true
        	
    }
    else {

        Write-Host "Email address is not valid - try again" -ForegroundColor Red
        $PrimaryOwner = $null
        $ValidateData = $false

    }

}



$ValidateData = $false

#[Array] $Owners = $null

While ($ValidateData -ne $true) {

    if ($null -eq $Owners) {

        Write-Host "Enter the email address of the Others Owners of the Shared mailbox`nif more than one then separate by Commas (eg AdeleV@domain.com,AlexW@domain.com):" -ForegroundColor Green
        $Owners = Read-Host "Other Owners"
        $Owners = $Owners -split "," | ForEach-Object -Process { ($PSItem).trim() } | ForEach-Object -Process { $PSItem -replace '"', "" }

    }

    $ValidateData = $true

    $Owners | ForEach-Object -Process { 

        $OwnerDN = ( Get-Recipient -Identity $PSItem -ErrorAction SilentlyContinue).DistinguishedName

        if ($null -eq $OwnerDN) {
     	
            Write-Host "Email address $($PSItem) is not valid - try again" -ForegroundColor Red
            $ValidateData = $false
            $Owners = $null

        }

    }

}


$ValidateData = $false

#[Array] $Owners = $null

While ($ValidateData -ne $true) {

    #[Array] $Owners = $null

    if ($null -eq $FullAccessMembers) {

        Write-Host "Enter the email address of the users who need full Access to the Shared mailbox, including owner if required`nif more than one then separate by Commas (eg Dktest.WIEH1@partners.wieh.de):" -ForegroundColor Green
        $FullAccessMembers = Read-Host "FullAccess Users"
        $FullAccessMembers = $FullAccessMembers -split "," | ForEach-Object -Process { ($PSItem).trim() } | ForEach-Object -Process { $PSItem -replace '"', "" }

    }


    $ValidateData = $true

    $FullAccessMembers | ForEach-Object -Process { 

        $UserDN = ( Get-Recipient -Identity $PSItem -ErrorAction SilentlyContinue).DistinguishedName

        if ($null -eq $UserDN) {
     	
            Write-Host "Email address $($PSItem) is not valid - try again" -ForegroundColor Red
            $ValidateData = $false
            $FullAccessMembers = $null

        }

    }

}


## sendas  access prompt 

$ValidateData = $false

#[Array] $Owners = $null


$SendASAccessMembers = $null 

While ($ValidateData -ne $true) {

    #[Array] $Owners = $null

    if ($null -eq $SendASAccessMembers) {

        Write-host "Do you want to set SendAs permission" 
        $a1 = Read-Host "Type yes to set SendAs Permssion"

        if ($a1 -eq "yes") {
  
            $SendAsPermissionRequired = $true
            $SendASAccessMembers1 = $FullAccessMembers -join "," 
            $SendASAccessMembers = Read-Host -Prompt "Enter the email address of the users who need sendAs Access to the Shared mailbox , including owner if required`nif more than one then separate by Commas or enter to accept this value same as fullacess member $SendASAccessMembers1 "
        
            if ($SendASAccessMembers -eq "") {

                $SendASAccessMembers = $SendASAccessMembers1

            }

            $SendASAccessMembers = $SendASAccessMembers -split "," | ForEach-Object -Process { ($PSItem).trim() } | ForEach-Object -Process { $PSItem -replace '"', "" }

            $ValidateData = $true

            $SendASAccessMembers | ForEach-Object -Process { 

                $UserDN = ( Get-Recipient -Identity $PSItem -ErrorAction SilentlyContinue).DistinguishedName
                if ($null -eq $UserDN) {
     	
                    Write-Host "Email address $($PSItem) is not valid - try again" -ForegroundColor Red
                    $ValidateData = $false
                    $SendASAccessMembers = $null

                }

            }

        }
        else {

            $SendAsPermissionRequired = $false
            $ValidateData = $true

        }

    }

}



$Name = $MailboxEmail -replace "@", "."

$Name = $name -replace "&" , ""
$Name = $name -replace "#" , ""


[string]$MailboxAlias = "$Name"


$PrimaryAddress = "SMTP:" + $MailboxEmail


Write-Output "Input Company: $($company)" |  Out-File -Append $logFile
Write-Output "Input MailboxEmail: $($MailboxEmail)" |  Out-File -Append $logFile
Write-Output "Input DisplayName: $($DisplayName)" |  Out-File -Append $logFile
Write-Output "Input PrimaryOwner: $($PrimaryOwner)" |  Out-File -Append $logFile
Write-Output "Input Owner: $($Owners)" |  Out-File -Append $logFile
Write-Output "Input FullAccess: $($FullAccessMembers)" |  Out-File -Append $logFile


#region Create mailbox

$a = 0

Write-Progress -Activity "Working..." -CurrentOperation "$a% complete"  -Status "Please wait."

$UserObject = Get-Recipient -Identity $MailboxEmail -ErrorAction SilentlyContinue

if ($null -eq $UserObject) {

    if ($Action -eq "set" ) {

        $null = New-Mailbox -Shared -DisplayName $DisplayName -FirstName $DisplayName -Alias $MailboxAlias -PrimarySmtpAddress $MailboxEmail -Name $Name

    }
}
else {

    Write-Output "$(Get-Date),$MailboxEmail,$MailboxEmail already exists" | Out-File -Append $logFile
    Write-host "$(Get-Date),$MailboxEmail,$MailboxEmail already exists"	

}

$UserObject = Get-Recipient -Identity $MailboxEmail -ErrorAction SilentlyContinue

$StopTime = (Get-Date).AddMinutes($WaitTime) 

while (( $null -eq $UserObject) -and ( ( (Get-Date) -le $StopTime )) ) {

    Start-Sleep -Seconds 60
    $UserObject = Get-Recipient -Identity $MailboxEmail -ErrorAction SilentlyContinue

}

$a = $a + 10
Write-Progress -Activity "Working..." -CurrentOperation "$a% complete"  -Status "Please wait."



if ($null -ne $UserObject) {
	    
    if ($Action -eq "set" ) {

        Write-Host "$(Get-Date),Success,$MailboxEmail Created" -ForegroundColor Green

        $UserDN = $UserObject.DistinguishedName
        Write-Output "$(Get-Date),DN Found $UserDN" | Out-File -Append $logFile
		
        Set-Mailbox -Identity $UserDN -CustomAttribute10 "SharedMailbox"

        Write-Output "$(Get-Date), Disable Pop and IMPA, $MailboxEmail" | Out-File -Append $logFile
        Set-CASMailbox -Identity $UserDN -PopEnabled:$false -ImapEnabled:$false

        Write-Output "$(Get-Date), Disable ActiveSync, $MailboxEmail" | Out-File -Append $logFile
        Set-CASMailbox $UserDN -ActiveSyncEnabled:$false #-ActiveSyncMailboxPolicy "Gazprom Default Policy"

        Write-Output "$(Get-Date), configure MessagesCopyforSendAsenabled and MessageCopyForSendOnBehalfEnabled, $MailboxEmail" | Out-File -Append $logFile

        Set-Mailbox -Identity $MailboxEmail -MessageCopyForSendOnBehalfEnabled:$true -MessageCopyForSentAsEnabled:$true

    }

}
else {

    Write-Output "$(Get-Date),Error Creating mailbox,$MailboxEmail, $($Error[0])" | Out-File -Append $logFile
    Write-host "$(Get-Date),Error Creating mailbox,$MailboxEmail, $($Error[0]), check log file $logFile " 	
    Write-host "$(Get-Date),Script Completed. Check logfile for more detail:$logfile" -ForegroundColor Green
    Exit

}  

	

#endregion

[string] $SharedMailbox = $MailboxEmail

$MailboxObject = Get-Recipient -Identity $SharedMailbox -ErrorAction SilentlyContinue

if ($null -ne $MailboxObject) {

    $a = $a + 10
    Write-Progress -Activity "Working..." -CurrentOperation "$a% complete"  -Status "Please wait."

    if ($SharedMailbox.Length -gt 38) {

        $FAGroupName = "$SMGroupPrefix" + ($SharedMailbox -replace "@" , ".").Substring(0, 38) + "_FullAccess"

    }
    else {

        $FAGroupName = "$SMGroupPrefix" + ($SharedMailbox -replace "@" , ".") + "_FullAccess"

    }

    $FAGroupEmail = $FAGroupName + $ITSSdomain
    $Attribute6 = "SharedMailbox=[" + $SharedMailbox + "]"
    $FAGroupDesc = "$SharedMailbox SharedMailbox FullAccess"
    $GroupType = "Security"
    $GroupFound = "FALSE"
    $AccountFound = "FALSE"

    $CheckFullAccessGroup = Get-MailboxPermission -Identity $SharedMailbox -ErrorAction SilentlyContinue | Where-Object -FilterScript { ($PSItem.AccessRights -eq "FullAccess") -and ($PSItem.User -match "$SMGroupPrefix") -and ($PSItem.User -match "_FullAccess") } | Select-Object -First 1
    
    if ($null -ne $CheckFullAccessGroup) {

        $CheckFullAccessGroup.User

        $GroupObject = Get-Recipient -Identity $CheckFullAccessGroup.User -ErrorAction SilentlyContinue
        $FAGroupName = $GroupObject.Name
        $FAGroupEmail = $GroupObject.PrimarySmtpAddress
        
    }    


    Write-Output "Computed FAGroupName : $($FAGroupName)" |  Out-File -Append $logFile
    Write-Output "Computed FAGroupEmail : $($FAGroupEmail)" |  Out-File -Append $logFile
        
    ############
    Write-Host "$(Get-Date),$SharedMailbox,Working on Group $FAGroupEmail" 
    Write-Output "$(Get-Date),$SharedMailbox,Working on Group $FAGroupEmail" | Out-File -Append $logFile

    $GroupObject = $null
    $GroupObject = Get-Recipient -Identity $FAGroupEmail -ErrorAction SilentlyContinue

    if ($null -eq $GroupObject) {

        Write-Output "$(Get-Date),$SharedMailbox,Group Not Found $FAGroupEmail" | Out-File -Append $logFile

        if (($Action -eq "set")) {

            Write-Output "$(Get-Date),$SharedMailbox,Creating Group  $FAGroupEmail" | Out-File -Append $logFile
            $GP = New-DistributionGroup -Name $FAGroupName -DisplayName $FAGroupName -Alias $FAGroupName -PrimarySmtpAddress $FAGroupEmail -Type $GroupType

        }



        if ($null -eq $GP) {

            Write-Output "$(Get-Date),$SharedMailbox,Error Creating Group,$FAGroupEmail, $($Error[0]) " | Out-File -Append $logFile
            Write-host "$(Get-Date),$SharedMailbox,Error Creating Group,$FAGroupEmail, $($Error[0]), check log file $logFile " 	
            Write-host "$(Get-Date),Script Completed. Check logfile for more detail:$logfile" -ForegroundColor Green
            Exit

        }

    }
    else {
        
        $FAGroupFound = $GroupObject.PrimarySmtpAddress
        Write-host "$(Get-Date),$SharedMailbox,GroupFound already exists $FAGroupEmail"
        Write-Output "$(Get-Date),$SharedMailbox,GroupFound  $FAGroupEmail" | Out-File -Append $logFile

    }

    $a = $a + 10
    Write-Progress -Activity "Working..." -CurrentOperation "$a% complete"  -Status "Please wait."
   
    $GroupObject = Get-Recipient -Identity $FAGroupEmail -ErrorAction SilentlyContinue

    $StopTime = (Get-date).AddMinutes($WaitTime) 

    while (($null -eq $GroupObject) -and (Get-Date -le $StopTime)) {

        Start-Sleep -Seconds 60
        Get-Recipient -Identity $FAGroupEmail -ErrorAction SilentlyContinue
        $FAGroupFound = "FALSE"

    }

    if ($null -ne $GroupObject) {
	       
        Write-Host "$(Get-Date),Success,Permission Group $FAGroupEmail Created" -ForegroundColor Green

        $GroupDN = $GroupObject.DistinguishedName

	       Write-Output "$(Get-Date),$SharedMailbox,DN Found $GroupDN" | Out-File -Append $logFile
	       Write-Output "$(Get-Date),$SharedMailbox,Set-DistributionGroup $GroupDN -CustomAttribute6  $($Attribute6)" | Out-File -Append $logFile

	       Set-DistributionGroup -Identity $GroupDN -CustomAttribute6 $Attribute6 -Confirm:$false

	       Write-Output "$(Get-Date),$SharedMailbox,Set-DistributionGroup $GroupDN -Description $FAGroupDesc" | Out-File -Append $logFile
              
	       Set-DistributionGroup -Identity $GroupDN -Description $FAGroupDesc -Confirm:$false
          
        $PrimaryOwnerDN = $null

        $PrimaryOwnerDN = (Get-Recipient -Identity $PrimaryOwner -ErrorAction SilentlyContinue).DistinguishedName

        if ($null -ne $PrimaryOwnerDN) {

            Set-DistributionGroup -Identity $GroupDN -ManagedBy $PrimaryOwnerDN -Confirm:$false

        }
        else {

            Write-Host "Primary Owner not found - Set the Managed by for the group $FAGroupEmail" -ForegroundColor red
            Write-Output "$(Get-Date),$SharedMailbox,Primary Owner not found - Set the Managed by for the group $FAGroupEmail" | Out-File -Append $logFile

        }
            
        $a = $a + 10
        Write-Progress -Activity "Working..." -CurrentOperation "$a% complete"  -Status "Please wait."
	        
        $Owners | ForEach-Object -Process {
            
            AddtoOwnerForGroup -GroupEmail $FAGroupEmail -MemberEmail $PSItem
        
        }

        $a = $a + 10
        Write-Progress -Activity "Working..." -CurrentOperation "$a% complete"  -Status "Please wait."


        $FullAccessMembers | ForEach-Object -Process {
            
            AddMemberToDLGroup -GroupEmail $FAGroupEmail -MemberEmail $PSItem
        
        }

        $FAGroupFound = $GroupObject.PrimarySmtpAddress

    }
    else {

        Write-Output "$(Get-Date),$SharedMailbox,Error Creating Group,$FAGroupEmail,$($Error[0])" | Out-File -Append $logFile
        Write-Host "$(Get-Date),$SharedMailbox,Error Creating Group,$FAGroupEmail, $($Error[0]) - Check Logfile $logFile" -ForegroundColor red
        $FAGroupFound = "FALSE"
        Write-host "$(Get-Date),Script Completed. Check logfile for more detail:$logfile" -ForegroundColor Green
        Exit

    }


    $a = $a + 10
    Write-Progress -Activity "Working..." -CurrentOperation "$a% complete"  -Status "Please wait."

    $GroupObject = $null
    $GroupObject = Get-Recipient -Identity $FAGroupEmail  -ErrorAction SilentlyContinue
       
    if ( $null -ne $GroupObject) {

        $DelegateDN = $GroupObject.DistinguishedName
        $MailboxDN = $MailboxObject.DistinguishedName
        $DelegateAccess = "FullAccess"
        $DelegateEmail = $GroupObject.PrimarySmtpAddress
        $DelegateName = $GroupObject.Name
        
        $CheckRights = Get-MailboxPermission -Identity $MailboxDN  -User $DelegateDN | Where-Object -FilterScript { $PSItem.AccessRights -eq $DelegateAccess }

  
        if ($null -eq $CheckRights) {

            if ($Action -eq "set" ) {

                $null = Add-MailboxPermission $MailboxDN -User $DelegateDN -AccessRights $DelegateAccess -Confirm:$false

                if ($MailboxObject.NOTES -notMatch "$GroupObject.Name") {

                    Set-User -Identity $MailboxDN -Notes "FullAccess:$($GroupObject.Name)" -Confirm:$false
                    $Notes = "FullAccess:$($GroupObject.Name)"

                }	
				
                Write-Output "$(Get-Date),$SharedMailbox,Permission Added,$DelegateEmail,$DelegateAccess" | Out-File -Append $logFile
            }
        }
        else {

            Write-Output "$(Get-Date),$SharedMailbox,Permission Exists,$DelegateEmail,$DelegateAccess" | Out-File -Append $logFile
            $PermissionSet = "$DelegateAccess"

        }

        $CheckRights = Get-MailboxPermission $MailboxDN -User $DelegateDN | Where-Object -FilterScript { $PSItem.AccessRights -eq $DelegateAccess }

  
        if ($null -eq $CheckRights) {

            if ($Action -eq "set" ) {

                Write-host "$(Get-Date),$SharedMailbox,ERROR Adding Permission,$DelegateEmail,$DelegateAccess" -ForegroundColor Red 
                Write-Output "$(Get-Date),$SharedMailbox,ERROR Adding Permission,$DelegateEmail,$DelegateAccess" | Out-File -Append $logFile

            }
        }
        else {

            Write-Output "$(Get-Date),$MailboxEmail,Permission Exists,$DelegateEmail,$DelegateAccess" | Out-File -Append $logFile
            Write-host "$(Get-Date),$MailboxEmail,Permission Added,$DelegateEmail,$DelegateAccess" -ForegroundColor Green
            $PermissionSet = "$DelegateAccess"

        }
		
        $a = $a + 10
        Write-Progress -Activity "Working..." -CurrentOperation "$a% complete"  -Status "Please wait."
		
        ## Grant Sendon Behalf permission 
        $DelegateAccess = "GrantSendOnBehalfTo"
        $CheckRights = (Get-Mailbox -Identity $MailboxDN | Select-Object -ExpandProperty GrantSendOnBehalfTo) | Where-Object -FilterScript { $PSItem -match $DelegateName } 
       
        if ($null -eq $CheckRights) {

            if ($Action -eq "set" ) {

                Set-Mailbox -Identity $MailboxDN -GrantSendOnBehalfTo $DelegateDN -Confirm:$false

                Write-Output "$(Get-Date),$MailboxEmail,Permission Added,$DelegateEmail,$DelegateAccess" | Out-File -Append $logFile

            }
        }
        else {

            Write-Output "$(Get-Date),$MailboxEmail,Permission Exists,$DelegateEmail,$DelegateAccess" | Out-File -Append $logFile
            $PermissionSet = "$DelegateAccess"
            
        }

        $CheckRights = (Get-Mailbox -Identity $MailboxDN | Select-Object -ExpandProperty GrantSendOnBehalfTo ) | Where-Object -FilterScript { $PSItem -match $DelegateName } 
      
        
        if ($null -eq $CheckRights) {

            if ($Action -eq "set" ) {

                Write-host "$(Get-Date),$MailboxEmail,ERROR Adding Permission,$DelegateEmail,$DelegateAccess,$($Error[0])" -ForegroundColor red
                Write-Output "$(Get-Date),$MailboxEmail,ERROR Adding Permission,$DelegateEmail,$DelegateAccess,$($Error[0])" | Out-File -Append $logFile

            }
        }
        else {

            #Write-Output "$(Get-Date),$MailboxEmail,Permission Exists,$DelegateEmail,$DelegateAccess" | Out-File -Append $logFile
            Write-host "$(Get-Date),$MailboxEmail,Permission Added,$DelegateEmail,$DelegateAccess" -ForegroundColor Green
            $PermissionSet = "$DelegateAccess"

        }	

    }

    $a = 100
    Write-Progress -Activity "Working..." -CurrentOperation "$a% complete"  -Status "Please wait." -PercentComplete $a 

}


## for send as permission 

if (( $null -ne $MailboxObject) -and ($SendAsPermissionRequired -eq $true)) {

    $a = $a + 10
    Write-Progress -Activity "Working..." -CurrentOperation "$a% complete"  -Status "Please wait."

    if ($SharedMailbox.Length -gt 38) {

        $SAGroupName = "$SMGroupPrefix" + ($SharedMailbox -replace "@" , ".").Substring(0, 38) + "_SendAs"

    }
    else {

        $SAGroupName = "$SMGroupPrefix" + ($SharedMailbox	-replace "@" , ".") + "_SendAs"

    }

    $SAGroupEmail = $SAGroupName + $ITSSdomain
    $Attribute6 = "SharedMailbox=[" + $SharedMailbox + "]"
    $SAGroupDesc = "$SharedMailbox SharedMailbox SendAs Access"
    $GroupType = "Security"
    $GroupFound = "FALSE"
    $AccountFound = "FALSE"
     

    $CheckSendAccessGroup = Get-MailboxPermission -Identity $SharedMailbox -ErrorAction SilentlyContinue | Where-Object -FilterScript { ($PSItem.AccessRights -eq "ExtendedRight") -and ($PSItem.User -match "$SMGroupPrefix") -and ($PSItem.User -match "_SendAs") } | Select-Object -First 1
    
    if ($null -ne $CheckSendAccessGroup) {

        $CheckSendAccessGroup.User

        $GroupObject = Get-Recipient -Identity $CheckSendAccessGroup.User -ErrorAction SilentlyContinue
        $SAGroupName = $GroupObject.Name
        $SAGroupEmail = $GroupObject.PrimarySmtpAddress

    }


    Write-Output "Computed SAGroupName : $($SAGroupName)" | Out-File -Append $logFile
    Write-Output "Computed SAGroupEmail : $($SAGroupEmail)" | Out-File -Append $logFile
        
    ############
    Write-Host "$(Get-Date),$SharedMailbox,Working on Group $SAGroupEmail" 
    Write-Output "$(Get-Date),$SharedMailbox,Working on Group $SAGroupEmail" | Out-File -Append $logFile

    $GroupObject = $null
    $GroupObject = Get-Recipient -Identity $SAGroupEmail -ErrorAction SilentlyContinue

    if (( $null -eq $GroupObject) ) {

        Write-Output "$(Get-Date),$SharedMailbox,Group Not Found $SAGroupEmail" | Out-File -Append $logFile

        if (($Action -eq "set")) {

            Write-Output "$(Get-Date),$SharedMailbox,Creating Group  $SAGroupEmail" | Out-File -Append $logFile
            $GP = New-DistributionGroup -Name $SAGroupName -DisplayName $SAGroupName -Alias $SAGroupName -PrimarySmtpAddress $SAGroupEmail -Type $GroupType

        }



        if ($null -eq $GP) {

            Write-Output "$(Get-Date),$SharedMailbox,Error Creating Group,$SAGroupEmail, $($Error[0]) " | Out-File -Append $logFile
            Write-host "$(Get-Date),$SharedMailbox,Error Creating Group,$SAGroupEmail, $($Error[0]), check log file $logFile " 	
            Write-host "$(Get-Date),Script Completed. Check logfile for more detail:$logfile" -ForegroundColor Green
            Exit

        }

    }
    else {

        $SAGroupFound = $GroupObject.PrimarySmtpAddress
        Write-host "$(Get-Date),$SharedMailbox,GroupFound already exists $SAGroupEmail"
        Write-Output "$(Get-Date),$SharedMailbox,GroupFound  $SAGroupEmail" | Out-File -Append $logFile

    }

    $a = $a + 10
    Write-Progress -Activity "Working..." -CurrentOperation "$a% complete"  -Status "Please wait."
   
    $GroupObject = Get-Recipient -Identity $SAGroupEmail -ErrorAction SilentlyContinue

    $StopTime = (Get-date).AddMinutes($WaitTime) 

    while (($null -eq $GroupObject) -and (Get-Date -le $StopTime )) {

        Start-Sleep -Seconds 60
        $GroupObject = Get-Recipient -Identity $SAGroupEmail -ErrorAction SilentlyContinue
        $SAGroupFound = "FALSE"

    }

    if ($null -ne $GroupObject) {
	       
        Write-Host "$(Get-Date),Success,Permission Group $SAGroupEmail Created" -ForegroundColor Green

        $GroupDN = $GroupObject.DistinguishedName

        Write-Output "$(Get-Date),$SharedMailbox,DN Found $GroupDN" | Out-File -Append $logFile
        Write-Output "$(Get-Date),$SharedMailbox,Set-DistributionGroup $GroupDN -CustomAttribute6 $($Attribute6)" | Out-File -Append $logFile

        Set-DistributionGroup -Identity $GroupDN -CustomAttribute6 $Attribute6 -Confirm:$false

        Write-Output "$(Get-Date),$SharedMailbox,Set-DistributionGroup $GroupDN -Description $SAGroupDesc " | Out-File -Append $logFile

        Set-DistributionGroup -Identity $GroupDN -Description $SAGroupDesc -Confirm:$false
          
        $PrimaryOwnerDN = $null

        $PrimaryOwnerDN = ( Get-Recipient -Identity $PrimaryOwner -ErrorAction SilentlyContinue).DistinguishedName

        if ($null -ne $PrimaryOwnerDN) {

            Set-DistributionGroup -Identity $GroupDN -ManagedBy $PrimaryOwnerDN -BypassSecurityGroupManagerCheck -Confirm:$false

        }
        else {

            Write-Host "Primary Owner not found - Set the Managed by for the group $SAGroupEmail" -ForegroundColor red
            Write-Output "$(Get-Date),$SharedMailbox,Primary Owner not found - Set the Managed by for the group $SAGroupEmail" | Out-File -Append $logFile

        }
            
        $a = $a + 10
        Write-Progress -Activity "Working..." -CurrentOperation "$a% complete"  -Status "Please wait."
	        
        $Owners | ForEach-Object -Process {
            
            AddtoOwnerForGroup -GroupEmail $SAGroupEmail -MemberEmail $PSItem
        
        }

        $a = $a + 10
        Write-Progress -Activity "Working..." -CurrentOperation "$a% complete"  -Status "Please wait."


        $SendASAccessMembers | ForEach-Object -Process {
            
            AddMemberToDLGroup -GroupEmail $SAGroupEmail -MemberEmail $PSItem
        
        }

        $SAGroupFound = $GroupObject.PrimarySmtpAddress

    }
    else {

        Write-Output "$(Get-Date),$SharedMailbox,Error Creating Group,$SAGroupEmail,$($Error[0])" | Out-File -Append $logFile
        Write-Host "$(Get-Date),$SharedMailbox,Error Creating Group,$SAGroupEmail, $($Error[0]) - Check Logfile $logFile" -ForegroundColor red
        $FAGroupFound = "FALSE"
        Write-host "$(Get-Date),Script Completed. Check logfile for more detail:$logfile" -ForegroundColor Green
        Exit

    }


    $a = $a + 10
    Write-Progress -Activity "Working..." -CurrentOperation "$a% complete"  -Status "Please wait."

    $GroupObject = $null
    $GroupObject = Get-Recipient -Identity $SAGroupEmail -ErrorAction SilentlyContinue
       
    if ( $null -ne $GroupObject) {

        $DelegateDN = $GroupObject.DistinguishedName
        $MailboxDN = $MailboxObject.DistinguishedName
        $DelegateAccess = "SendAs"
        $DelegateEmail = $GroupObject.PrimarySmtpAddress
        $DelegateName = $GroupObject.Name
 
        $CheckRights = Get-MailboxPermission -Identity $MailboxDN -ErrorAction SilentlyContinue -User $DelegateDN | Where-Object -FilterScript { ($PSItem.AccessRights -eq "ExtendedRight") } | Select-Object -First 1
  
        if ($null -eq $CheckRights) {

            if ($Action -eq "set" ) {

                $null = Add-RecipientPermission -Identity $MailboxDN -AccessRights $DelegateAccess -Trustee $DelegateDN -Confirm:$false

                if ($MailboxObject.NOTES -notMatch "$GroupObject.Name") {

                    $Notes = $Notes + " | " + "SendAs:$($GroupObject.Name)"

                    Set-User -Identity $MailboxDN -Notes "$Notes" -Confirm:$false
                    
                }
				
                Write-Output "$(Get-Date),$SharedMailbox,Permission Added,$DelegateEmail,$DelegateAccess" | Out-File -Append $logFile
            }
        }
        else {

            Write-Output "$(Get-Date),$SharedMailbox,Permission Exists,$DelegateEmail,$DelegateAccess" | Out-File -Append $logFile
            $PermissionSet = "$DelegateAccess"

        }

        $CheckRights = Get-RecipientPermission -Identity $MailboxDN -ErrorAction SilentlyContinue -Trustee $DelegateDN | Where-Object -FilterScript { $PSItem.AccessRights -eq "SendAs" } | Select-Object -First 1  
  
        if ($null -eq $CheckRights) {

            if ($Action -eq "set" ) {

                Write-host "$(Get-Date),$SharedMailbox,ERROR Adding Permission,$DelegateEmail,$DelegateAccess" -ForegroundColor Red 
                Write-Output "$(Get-Date),$SharedMailbox,ERROR Adding Permission,$DelegateEmail,$DelegateAccess" | Out-File -Append $logFile

            }
        }
        else {

            Write-Output "$(Get-Date),$MailboxEmail,Permission Exists,$DelegateEmail,$DelegateAccess" | Out-File -Append $logFile
            Write-host "$(Get-Date),$MailboxEmail,Permission Added,$DelegateEmail,$DelegateAccess" -ForegroundColor Green
            $PermissionSet = "$DelegateAccess"

        }
		
        $a = $a + 10
        Write-Progress -Activity "Working..." -CurrentOperation "$a% complete"  -Status "Please wait."			

    }
    
    $a = 100
    Write-Progress -Activity "Working..." -CurrentOperation "$a% complete"  -Status "Please wait." -PercentComplete $a 

}


Disconnect-ExchangeOnline -Confirm:$false

Write-host "$(Get-Date),Script Completed. Check logfile for more detail:$logfile" -ForegroundColor Green