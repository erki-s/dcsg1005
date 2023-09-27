## Lager scheduled task for å gjenta scriptet.
$taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\backup.ps1"
## Kjører scriptet hvert 30'nde minutt etter scriptet først ble kjørt.
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 30)
## Gjør at task'en kjøres som administrator, som trengs for endringer ved mounting/unmounting, brannmuren og nettverksadaptere.
$taskPrincipal = New-ScheduledTaskPrincipal -UserId 'Admin' -RunLevel Highest
## Sjekker om task'en finnes, slik at den ikke viser en feilmelding hver gang om at task'en allerede finnes.
if(!(Get-ScheduledTask -TaskName "RansomwareProtection")) {
    Register-ScheduledTask -TaskName "RansomwareProtection" -Action $taskAction -Trigger $trigger -Principal $taskPrincipal
}

################
# Definerer mappene som kopieres fra og til.
$source = "C:\source\"
$locBackups1 = "C:\backups1\"
$locBackups2 = "C:\backups2\"
$locBackups3 = "C:\backups3\"
$extBackups = "H:\backups\"
$extBackups2 = "D:\backups\"
$cloudBackups = "C:\Users\USERNAME\OneDrive\backups"

## Finner tallet, bokstaven og rooten av de eksterne diskene.
$extDriveLet = (Get-Item $extBackups).PSDrive.Name
$extDriveNum = (Get-Partition -DriveLetter $extDriveLet | Get-Disk).Number
$extDriveRoot = (Get-PSDrive $extDriveLet).Root

$extDriveLet2 = (Get-Item $extBackups2).PSDrive.Name
$extDriveNum2 = (Get-Partition -DriveLetter $extDriveLet2 | Get-Disk).Number
$extDriveRoot2 = (Get-PSDrive $extDriveLet2).Root
################


################
## Kopierer filer lokalt inni mappene for backups. Lager ny mappe automatisk hvis den ikke finnes.
## Backup mappe 1
Copy-Item -Path $source -Destination $locBackups1 -Force -Recurse
## Backup mappe 2
Copy-Item -Path $source -Destination $locBackups2 -Force -Recurse
## Backup mappe 3
Copy-Item -Path $source -Destination $locBackups3 -Force -Recurse
################


################
## Mount
Get-Disk -Number $extDriveNum | Get-Partition | Add-PartitionAccessPath -AccessPath $extDriveRoot
Get-Disk -Number $extDriveNum2 | Get-Partition | Add-PartitionAccessPath -AccessPath $extDriveRoot2

    # Kopierer filene til de eksterne diskene.
    Copy-Item -Path $source -Destination $extBackups -Force -Recurse
    Copy-Item -Path $source -Destination $extBackups2 -Force -Recurse

## Unmount
Get-Volume -Drive $extDriveLet | Get-Partition | Remove-PartitionAccessPath -AccessPath $extDriveRoot
Get-Volume -Drive $extDriveLet2 | Get-Partition | Remove-PartitionAccessPath -AccessPath $extDriveRoot2
################


################
## Backup til OneDrive
Copy-Item -Path $source -Destination $cloudBackups -Force -Recurse
################


## Aktiverer brannmuren hvis den er skrudd av, gjør ingenting hvis den er på allerede.
Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled true

## Sjekker om source-mappen har noen filer med typiske ransomware extensions, og skrur av internettadaptere hvis slike filer blir funnet. Denne listen inneholder bare noen få extensions.
if(Get-ChildItem -Path $source -Include("*.micro", "*.zepto", "*.locky", "*.crypt", "*.enc", "*.lcked", "*.encrypted", "*.Whereisyourfiles") -Recurse) {
    Disable-NetAdapter -Name “*”
}
