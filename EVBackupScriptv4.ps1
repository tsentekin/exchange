## Script to Backup EV databases and EV DataStore using NatApp Snapshot 
## Script scheduled on NETappom01lonuk to run everyday at 4AM 

## Create Date 07/06/2013 
## Created by - Faisal Saleem 
## Modified by - Deepak Khandelwal

## Modified Date - 28/10/2020
## Modification - 10/09/2013 - Change SQL JOB to run FULL backup job on Friday and DIFF on any other day
## Modification - 26/09/2013 - New Volumes were added to EV for new Partiontion. Script change to backup these addtional volume
## Modification - 13/11/2013 - New INDEX volumes H:\ added to EV. Script change to backup these addtional voluome
## Modification - 20/01/2015 - Improved scripts, configured the script to run from EV server and remote to Netapp0m01lonuk when needed. This is done as EV services were not letting to PS remote in after few days.
## Modificarion - 06/05/2015 - added new ev backup location on fasnod02pr for \\evfs02pr\ev_vaultstores_4
## Modification - 09/09/2015 - New INDEX volumes J:\ added to EV. Script change to backup these addtional voluome



## Modification: Following CIFS Volume are added ev_vaultstores_2 and ev_vaultstores_3 EV partiontion. TO backup the new volume new dataset is cretaed in DFM called 
## DS_CIFS_EV_PROD_2 with both of above volume part of the protection group. 

## Modified by - Andrei Oveshkov
## Modification - 28/10/2020 - New INDEX volumes J:\ added to EV. Script change to backup these addtional voluome


## The script do following tasks.
## 1. Configure EV server to Backup mode
## 2. Start SQL Backup Maintenance Job on the SQL Server. Note: Job is preconfigured in SQL server, This script only start the job and wait for it to finish
## 3. Create Snapshot for EV data presented using CIFS share (\\evfs01pr\ev_vaultstores\) via NatApp DFM job for Datastore DS_CIFS_EV_PROD
## 5. Create Trigger file on relevent partition 
## 6. Remove EV server from Backup mode


##Requirement 
## TO Run the script, Service account would require EV admin rights, Netapp rights and SQL rights
## TO be local admin on netappom01lonuk
## to reduce giving additional account the script is scheduled to run as EV service account svc-live-ev
## Require PS remoting enabled on EV server
## Require netapp ontap powershell module


## SQL backup are stored here \\FASSQL01BK\sqlpr_silver_backups_01\EVSQL01LONUK

## List of volumes used by EV presented via CIFS (Update the list if more addded)

#SSPR-FASCLU10::> qtree sho -vser SVMGMT01PR -qtree EV* -fields qtree,volume
#vserver    volume              qtree
#---------- ------------------- ------------------------
#SVMGMT01PR SVMGMT01PR_APP_C_10 EV_EVUSL01_IndexMetaData
#SVMGMT01PR SVMGMT01PR_APP_C_10 EV_EVUSL01_IndexStore1
#SVMGMT01PR SVMGMT01PR_APP_C_10 EV_EVUSL01_IndexStore2
#SVMGMT01PR SVMGMT01PR_APP_C_10 EV_EVUSL01_IndexStore3
#SVMGMT01PR SVMGMT01PR_APP_C_10 EV_EVUSL02_IndexMetaData
#SVMGMT01PR SVMGMT01PR_APP_C_10 EV_EVUSL02_IndexStore1
#SVMGMT01PR SVMGMT01PR_APP_C_11 EV_EVUSL01_IndexStore4
#SVMGMT01PR SVMGMT01PR_APP_C_11 EV_EVUSL02_IndexStore2
#6 entries were displayed.

#SSPR-FASCLU10::> qtree sho -vser SVMGMT01PR -qtree ev* -fields qtree,volume
#vserver    volume              qtree
#---------- ------------------- --------
#SVMGMT01PR SVMGMT01PR_APP_B_01 evo_prod
#SVMGMT01PR SVMGMT01PR_APP_E_10 ev_vaultstores
#SVMGMT01PR SVMGMT01PR_APP_E_11 ev_vaultstores_FilePtn1
#SVMGMT01PR SVMGMT01PR_APP_E_11 ev_vaultstores_JRNPtn1
#SVMGMT01PR SVMGMT01PR_APP_E_11 ev_vaultstores_MBXPtn1
#SVMGMT01PR SVMGMT01PR_APP_E_12 ev_vaultstores_2
#SVMGMT01PR SVMGMT01PR_APP_E_12 ev_vaultstores_5
#SVMGMT01PR SVMGMT01PR_APP_E_13 ev_vaultstores_3
#SVMGMT01PR SVMGMT01PR_APP_E_14 ev_vaultstores_4
#SVMGMT01PR SVMGMT01PR_APP_E_15 ev_vaultstores_6
#SVMGMT01PR SVMGMT01PR_APP_E_16 ev_vaultstores_7



$remoteServer = "NETAPPOM01LONUK"

$GMTSVMs = @("SVMGMT01PR.GAZPROMUK.INTRA","SVMGMT01DR.GAZPROMUK.INTRA") 
$GMTcreds = New-Object System.Management.Automation.PSCredential -ArgumentList "gazpromuk\SVC-LIVE-EV-CdotSnap", $(Import-Clixml -Path "C:\scripts\Credentials\SVC-LIVE-EV-CdotSnap_ForUser_$([Environment]::UserName).xml")
$GMTConsistanBackupSnapName = "EVConsistent.$(get-date -Format "yyyy-MM-dd_HHmm")"
$GMTConsistanBackupSnapMirrorLabel = "EVConsistent"
#$GMTExpecteNumberOfVolumes = 4

$EVVOlumes = @("SVMGMT01PR_APP_C_10","SVMGMT01PR_APP_C_11","SVMGMT01PR_APP_E_10","SVMGMT01PR_APP_E_11","SVMGMT01PR_APP_E_12","SVMGMT01PR_APP_E_13","SVMGMT01PR_APP_E_14","SVMGMT01PR_APP_E_15", "SVMGMT01PR_APP_E_16")
$GMTExpecteNumberOfVolumes = $EVVOlumes.Count

if ( (Test-Path ( "C:\Scripts\EVBackupScript" )) -eq $false )
{
	New-Item "C:\Scripts\EVBackupScript" -ItemType directory

}
$logfile = "C:\Scripts\EVBackupScript\EVBackupScriptlog.txt"

Write-Output "$(get-date):Script started on $($env:COMPUTERNAME) by $($env:USERNAME)" | Out-File $logfile



## Import OnTap powershell module



## Function to query SQL Database and return output as object.
Function Invoke-SQL
{
param(
$dataSource,
$database,
$sqlCommand
)


					Set-StrictMode -Version Latest
					$Timeout = 500
					
					## Prepare the authentication information. By default, we pick
					## Windows authentication
					$authentication = "Integrated Security=SSPI;"

					## Prepare the connection string out of the information they
					## provide
					$connectionString = "Provider=sqloledb; " +
					                    "Data Source=$dataSource; " +
					                    "Initial Catalog=$database; " +
					                    "$authentication; "

					## If they specify an Access database or Excel file as the connection
					## source, modify the connection string to connect to that data source
					if($dataSource -match '\.xls$|\.mdb$')
					{
					    $connectionString = "Provider=Microsoft.Jet.OLEDB.4.0; " +
					        "Data Source=$dataSource; "

					    if($dataSource -match '\.xls$')
					    {
					        $connectionString += 'Extended Properties="Excel 8.0;"; '

					        ## Generate an error if they didn't specify the sheet name properly
					        if($sqlCommand -notmatch '\[.+\$\]')
					        {
					            $error = 'Sheet names should be surrounded by square brackets, ' +
					                'and have a dollar sign at the end: [Sheet1$]'
					            Write-Error $error
					            return
					        }
					    }
					}

					## Connect to the data source and open it
					$connection = New-Object System.Data.OleDb.OleDbConnection $connectionString
					$connection.Open()

					foreach($commandString in $sqlCommand)
					{
					    $command = New-Object Data.OleDb.OleDbCommand $commandString,$connection
					    $command.CommandTimeout = $timeout

					    ## Fetch the results, and close the connection
					    $adapter = New-Object System.Data.OleDb.OleDbDataAdapter $command
					    $dataset = New-Object System.Data.DataSet
					    [void] $adapter.Fill($dataSet)

					    ## Return all of the rows from their query
					    $dataSet.Tables | Select-Object -Expand Rows
					}
					

}



## Main Execution Start here

Add-PSSnapin Symantec.EnterpriseVault.PowerShell.Snapin | Out-File $logfile -Append

Write-Output "$(get-date):Set EV into backup mode" | Out-File $logfile -Append
#set-vaultstorebackupmode -name 'Vault Store Group01' -evservername EVUSL01LONUK VaultStoreGroup | Out-File $logfile -Append
#Set-IndexLocationBackupMode EVUSL01LONUK | Out-File $logfile -Append
Set-VaultStoreBackupMode -Name EVGAZPROM -EVServerName EVUSL01LONUK -EVObjectType Site | Out-File $logfile -Append
Set-IndexLocationBackupMode -EVServerName EVUSL01LONUK -EVSiteName EVGAZPROM | Out-File $logfile -Append


##Check Backup mode
get-vaultstorebackupmode Name EVGAZPROM -EVServerName EVUSL01LONUK -EVObjectType Site | Out-File $logfile -Append

get-indexlocationbackupmode -EVServerName EVUSL01LONUK -EVSiteName EVGAZPROM | Out-File $logfile -Append



#region SQL Backup
## Start Database backup by running the Server Maintenance Plan created on the SQL server.
	#Vars for Server and JobName
	$Server = "EVASQL\EVA_PROD"

	
	if ((get-date).DayOfWeek -eq "Thursday")
	{
		$JobName = "Backup_All_Databases_FULL"
		#$JobName = "Backup_All_Databases_DIFF"
	}
	else
	{
		$JobName = "Backup_All_Databases_DIFF"
		#$JobName = "Backup_All_Databases_FULL"
	
	}

## uncomment this after test

	#Create/Open Connection
	$sqlConn = new-object System.Data.SqlClient.sqlConnection "server=$Server;database=msdb;Integrated Security=sspi"
	
	Write-Output "Open SQL connection to $server" | Out-File $logfile -Append
	$sqlConn.Open()

	#Create Command Obj
	$sqlCommand = $sqlConn.CreateCommand()
	$sqlCommand.CommandText = "EXEC dbo.sp_start_job N'$JobName'"

	#Exec Command
	
	Write-Output "Excute SQL backup Maintenace job on $server" | Out-File $logfile -Append
	$sqlCommand.ExecuteReader()

	#Close Conneection
	$sqlConn.Close()
	
	##$checkstatuscmd = "EXEC dbo.sp_help_jobhistory @job_name=N'$JobName'"
	
	## Wait for SQL to start the job.
	Start-Sleep -Seconds 15
	
	Write-Output "$(get-date):Verify if SQL backup Maintenace job on $server is running and wait until it is finish running status" | Out-File $logfile -Append
	Write-Host "$(get-date):Verify SQL job status and wait for it to finish"
	$loopCheck = 1
	#To stop the script from looping and waiting continuely. the loop will wait max of 20 min 
	$stoplooptime = (Get-Date).AddMinutes(120)

	while( ( $loopcheck -eq 1) -and ($stoplooptime -gt (Get-Date) ))
	{
		
		$checkstatuscmd = "EXEC MSDB.dbo.sp_help_job @job_name = N'$JobName', @job_aspect = 'JOB'"
		$checkJob1 = Invoke-SQL $Server 'msdb' $checkstatuscmd 
		#$checkJob1
		if($checkJob1.current_execution_status -ne "1")
		{
			$loopCheck = 0
			Write-Output "$(get-date):SQL backup Maintenace job on $server is finish with execution status $($checkJob1.current_execution_status)" | Out-File $logfile -Append
			Write-Host "$(get-date):SQL backup Maintenace job on $server is finish with execution status $($checkJob1.current_execution_status)"
		
		}
		Write-Host ".$($checkJob1.current_execution_status)." -NoNewline
		Write-output "SQLbackup job status:$($checkJob1.current_execution_status)." | Out-File -Append $logfile
		Start-Sleep -Seconds 15	
		
	}

#endregion

#region TakeSnapshotBackup and Create Trigger file

	
	#### Require sessions 
	
	Write-Output "$(get-date):Create Snapshot of EV data lun presented using CIFS Share" | Out-File $logfile -Append
	## Create Snapshot of the EV data presented via CFIS share. By connecting to Netapp Filer. 
	
	
	## connect to Netapp Controllers
	Write-Output "$(get-date):Open Connections to the Netapp Fillers $GMTSVMs server" | Out-File $logfile -Append
	
	$stoplooptime = (Get-Date).AddMinutes(10)
	
	$GMTSVMsSession = Connect-NcController $GMTSVMs -Credential $GMTcreds -HTTPS -ErrorVariable GMTerrors #connect to PR and DR SVM's
	
	while( ( $GMTSVMsSession -eq $null) -and ($stoplooptime -gt (Get-Date) ))
	{
		
		$GMTSVMsSession = Connect-NcController $GMTSVMs -Credential $GMTcreds -HTTPS -ErrorVariable GMTerrors #connect to PR and DR SVM's

		Write-Output "$(get-date):Error Creating session to Netapp server $GMTSVMs. $error[0]" | Out-File $logfile -Append
		Start-Sleep -Seconds 300
	}

	##Check if remote EV PS session is created. if not then terminate script.
	if ($GMTSVMsSession -ne $null)
	{
		
	
		$GMTActiveVolumesForEV = $null
		$GMTActiveVolumesForEV = $EVVOlumes | % { Get-NcVol -Controller $GMTSVMsSession -Name $_ | ? state -eq "online" | select Name,VolumeMirrorAttributes -ExpandProperty VolumeMirrorAttributes | ? IsDataProtectionMirror -EQ $false }
		
		if($GMTActiveVolumesForEV.count  -eq $GMTExpecteNumberOfVolumes )
		{
			## Take snapshot
			Write-Output "$(get-date):Take Snapshot on all active the EV volumes $EVVOlumes on Netapp Controller $GMTSVMs. $GMTActiveVolumesForEV" | Out-File $logfile -Append
		
			$GMTErrorsinSnapShotTaken = $GMTActiveVolumesForEV | New-NcSnapshot -SnapName $GMTConsistanBackupSnapName -SnapmirrorLabel  $GMTConsistanBackupSnapMirrorLabel  # take snapshpot on all active volumes
			
			if ($GMTErrorsinSnapShotTaken){
    		$GMTErrorsinSnapShotTaken | select -ExpandProperty VolumeErrors | Out-File $logfile -Append }
			
			$GMTErrorsinSnapShotTaken  | Out-File $logfile -Append
		
			## Check for snapshot
			$GMTLastConsistantSnapPerVol = ($GMTActiveVolumesForEV | Get-NcSnapshot -SnapName $GMTConsistanBackupSnapName  | Sort-Object Created -Descending | Group-Object volume) | %{$_.Group[0]}
			
			
			if (($GMTLastConsistantSnapPerVol | ? created -gt ((get-date).adddays(-1))).count -ne $GMTExpecteNumberOfVolumes)
			{
    			Write-Output "$(get-date): Couldn't verify that there is a Consistant snapshot from today on $GMTExpecteNumberOfVolumes volumes" | Out-File $logfile -Append
    			Write-Output "$(get-date): Snapshots $GMTLastConsistantSnapPerVol " | Out-File $logfile -Append
			
			}
			else
			{

                Write-Output "$(get-date): Snapshot taken sucessfully. following snapshot found" | Out-File $logfile -Append
                $GMTLastConsistantSnapPerVol | Out-File $logfile -Append

                #Region CreateTriggerFile
				

				## Create Trigger Files on All EV Partions locations
				Write-Output "$(get-date): Creating Trigger Files on all Partitions" | Out-File $logfile -Append
				
				#partition for File VS01
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_2\Enterprise Vault Stores\File VS01\File VS01 Ptn3\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_3\Enterprise Vault Stores\File VS01\File VS01 Ptn4\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_4\Enterprise Vault Stores\File VS01\File VS01 Ptn5\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_5\Enterprise Vault Stores\File VS01\File VS01 Ptn6\ignorearchivebittrigger.txt"
                Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_6\Enterprise Vault Stores\File VS01\File VS01 Ptn7\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_FilePtn1\Enterprise Vault Stores\File VS01 Ptn1\ignorearchivebittrigger.txt"
                Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_7\Enterprise Vault Stores\File VS01\File VS01 Ptn8\ignorearchivebittrigger.txt"
                Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_8\Enterprise Vault Stores\File VS01\File VS01 Ptn9\ignorearchivebittrigger.txt"
				
				#partition for IM VS01
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_FilePtn1\Enterprise Vault Stores\IM VS01 Ptn1\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores\Enterprise Vault Stores\IM VS01\IM VS01 Ptn2\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_2\Enterprise Vault Stores\IM VS01\IM VS01 Ptn3\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_3\Enterprise Vault Stores\IM VS01\IM VS01 Ptn4\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_4\Enterprise Vault Stores\IM VS01\IM VS01 Ptn5\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_7\Enterprise Vault Stores\IM VS01\IM VS01 Ptn6\ignorearchivebittrigger.txt"
                Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_8\Enterprise Vault Stores\IM VS01\IM VS01 Ptn7\ignorearchivebittrigger.txt"
				
				#Partitions for Public Folder VS01
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_FilePtn1\Enterprise Vault Stores\Public Folder VS01 Ptn1\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores\Enterprise Vault Stores\Public Folder VS01\Public Folder VS01 Ptn2\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_2\Enterprise Vault Stores\Public Folder VS01\Public Folder VS01 Ptn3\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_3\Enterprise Vault Stores\Public Folder VS01\Public Folder VS01 Ptn4\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_4\Enterprise Vault Stores\Public Folder VS01\Public Folder VS01 Ptn5\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_7\Enterprise Vault Stores\Public Folder VS01\Public Folder VS01 Ptn6\ignorearchivebittrigger.txt"
				
				
				#partitions for Mailbox VS01
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_MBXPtn1\Enterprise Vault Stores\Mailbox VS01 Ptn1\ignorearchivebittrigger.txt"
                Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores\Enterprise Vault Stores\Mailbox VS01\Mailbox VS01 Ptn2\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_2\Enterprise Vault Stores\Mailbox VS01\Mailbox VS01 Ptn3\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_3\Enterprise Vault Stores\Mailbox VS01\Mailbox VS01 Ptn4\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_4\Enterprise Vault Stores\Mailbox VS01\Mailbox VS01 Ptn5\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_4\Enterprise Vault Stores\Mailbox VS01\Mailbox VS01 Ptn6\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_5\Enterprise Vault Stores\Mailbox VS01\Mailbox VS01 Ptn7\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_5\Enterprise Vault Stores\Mailbox VS01\Mailbox VS01 Ptn8\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_6\Enterprise Vault Stores\Mailbox VS01\Mailbox VS01 Ptn9\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_6\Enterprise Vault Stores\Mailbox VS01\Mailbox VS01 Ptn10\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_7\Enterprise Vault Stores\Mailbox VS01\Mailbox VS01 Ptn11\ignorearchivebittrigger.txt"
                Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_8\Enterprise Vault Stores\Mailbox VS01\Mailbox VS01 Ptn12\ignorearchivebittrigger.txt"

				## Partitions for EV Journal VS01 
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores\Enterprise Vault Stores\Journal VS01\Journal VS01 Ptn2\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_2\Enterprise Vault Stores\Journal VS01\Journal VS01 Ptn3\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_3\Enterprise Vault Stores\Journal VS01\Journal VS01 Ptn4\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_4\Enterprise Vault Stores\Journal VS01\Journal VS01 Ptn5\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_4\Enterprise Vault Stores\Journal VS01\Journal VS01 Ptn6\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_4\Enterprise Vault Stores\Journal VS01\Journal VS01 Ptn7\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_4\Enterprise Vault Stores\Journal VS01\Journal VS01 Ptn8\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_5\Enterprise Vault Stores\Journal VS01\Journal VS01 Ptn9\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_5\Enterprise Vault Stores\Journal VS01\Journal VS01 Ptn10\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_6\Enterprise Vault Stores\Journal VS01\Journal VS01 Ptn11\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_6\Enterprise Vault Stores\Journal VS01\Journal VS01 Ptn12\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_JRNPtn1\Enterprise Vault Stores\Journal VS01 Ptn1\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_7\Enterprise Vault Stores\Journal VS01\Journal VS01 Ptn13\ignorearchivebittrigger.txt"
                Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_8\Enterprise Vault Stores\Journal VS01\Journal VS01 Ptn14\ignorearchivebittrigger.txt"
				
				
				## Partitions for for JournalVS02 Stores
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_4\Enterprise Vault Stores\Journal VS02\Journal VS02 Ptn1\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_4\Enterprise Vault Stores\Journal VS02\Journal VS02 Ptn2\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_4\Enterprise Vault Stores\Journal VS02\Journal VS02 Ptn3\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_5\Enterprise Vault Stores\Journal VS02\Journal VS02 Ptn4\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_5\Enterprise Vault Stores\Journal VS02\Journal VS02 Ptn5\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_5\Enterprise Vault Stores\Journal VS02\Journal VS02 Ptn6\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_6\Enterprise Vault Stores\Journal VS02\Journal VS02 Ptn7\ignorearchivebittrigger.txt"
				Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_6\Enterprise Vault Stores\Journal VS02\Journal VS02 Ptn8\ignorearchivebittrigger.txt"
                Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_7\Enterprise Vault Stores\Journal VS02\Journal VS02 Ptn9\ignorearchivebittrigger.txt"
                Write-output "enterprise vault trigger file - $(Get-date)" | Out-File  "\\itss.global\prod\GMT\APP\ev_vaultstores_8\Enterprise Vault Stores\Journal VS02\Journal VS02 Ptn10\ignorearchivebittrigger.txt"

                if((test-path "\\itss.global\prod\GMT\APP\ev_vaultstores_7\Enterprise Vault Stores\Journal VS02\Journal VS02 Ptn9\ignorearchivebittrigger.txt") -eq $true)
                {

                    Write-Output "$(get-date): Trigger Files on all Partitions created" | Out-File $logfile -Append
                }
                else
                {

                     Write-Output "$(get-date): ERROR:Trigger Files could not be created" | Out-File $logfile -Append
                }

                #endregion
			
			}
			
			
		}
		else
		{
					
			Write-Output "$(get-date):Error Could not find all active the EV volumes $EVVOlumes on Netapp Controller $GMTSVMs. $error[0]" | Out-File $logfile -Append
		
		}
		

	}
	else
	{
		Write-Output "$(get-date):Error Creating session to Netapp server $GMTSVMs. $error[0]" | Out-File $logfile -Append

	}
	
#endregion


#Region Clear Backup Mode


	Write-Output "$(get-date):Clear EV from backup mode" | Out-File $logfile -Append
	## Take EV server out of backup mode
#	clear-vaultstorebackupmode -name 'Vault Store Group01' -evservername EVUSL01LONUK VaultStoreGroup
#	clear-indexlocationbackupmode -evservername EVUSL01LONUK 

 
	Clear-VaultStoreBackupMode -Name EVGAZPROM -EVServerName EVUSL01LONUK -EVObjectType Site
	Clear-IndexLocationBackupMode -EVServerName EVUSL01LONUK -EVSiteName EVGAZPROM

	
	##Check Backup mode
	$cmdoutput = get-vaultstorebackupmode -Name EVGAZPROM -EVServerName EVUSL01LONUK -EVObjectType Site
	
	$cmdoutput | Out-File $logfile -Append
	
	if ($cmdoutput[0].backupmode -eq $true)
	{
		Write-Output "$(get-date):Could not clear Vault store in EV from backup mode.See previous errors" | Out-File $logfile -Append
		
		Write-Output "Retry to clear from backup mode" | Out-File $logfile -Append
    
        Clear-VaultStoreBackupMode -Name EVGAZPROM -EVServerName EVUSL01LONUK -EVObjectType Site
	    Clear-IndexLocationBackupMode -EVServerName EVUSL01LONUK -EVSiteName EVGAZPROM

	}
	else
	{

		Write-Output "$(get-date):Successfully cleared Vault store group 01 from backup mode" | Out-File $logfile -Append
	}



	$cmdoutput = get-indexlocationbackupmode -EVServerName EVUSL01LONUK -EVSiteName EVGAZPROM

	$cmdoutput | Out-File $logfile -Append

	if ($cmdoutput[0].backupmode -eq $true)
	{
		Write-Output "$(get-date):Could not clear Vault store in EV from backup mode.See previous errors" | Out-File $logfile -Append
		
		Write-Output "Retry to clear from backup mode" | Out-File $logfile -Append

		Clear-VaultStoreBackupMode -Name EVGAZPROM -EVServerName EVUSL01LONUK -EVObjectType Site
		Clear-IndexLocationBackupMode -EVServerName EVUSL01LONUK -EVSiteName EVGAZPROM
			
	}
	else
	{

		Write-Output "$(get-date):Successfully cleared Vault store in EV from backup mode" | Out-File $logfile -Append
	}


#Endregion


Write-Output "$(get-date):Close PS session to EV server" | Out-File $logfile -Append
#Close PS Session from remote server
Remove-PSSession $RemoteSession

Write-Output "$(get-date):Script finished" | Out-File $logfile -Append
