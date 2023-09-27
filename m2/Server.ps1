# Kjøres i srv1

Install-WindowsFeature -Name Web-Server -IncludeManagementTools
Install-WindowsFeature -Name FS-DFS-Namespace,FS-DFS-Replication,RSAT-DFS-Mgmt-Con -IncludeManagementTools
Copy-Item -Path \\sec.core\files\production\webpage\* -Destination "C:\Website" -Recurse -Force


# Lager variabel for mappene
$folders=@('C:\Shares\itdrift','C:\Shares\hr', 'C:\Shares\regnskap', 'C:\Shares\developers')

# Lager mappene
$folders | ForEach-Object { mkdir -Path $_ }

# Deler mappene
$folders | ForEach-Object { $sharename = (Get-Item $_).name; New-SmbShare -Name $sharename -Path $_ -FullAccess Everyone}
$folders | Where-Object {$_ -Like "*shares*"} | ForEach-Object {$name = (Get-Item $_).name; $DfsPath = ('\\sec.core\files\' + $name); $targetPath = ('\\srv1\' + $name);New-DfsnFolderTarget -Path $DfsPath -TargetPath $targetPath }

$folders = ('\\sec\files\itdrift', '\\sec\files\hr', '\\sec\files\regnskap', '\\sec\files\developers')

# Gir rettigheter
$folders | ForEach-Object {
    $acl = Get-Acl $_
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($_.substring(2),"FullControl","Allow")
    $acl.SetAccessRule($AccessRule)
    $ACL | Set-Acl -Path $_
}

# Modifiserer rettigheter/protection
$folders | ForEach-Object {
    $ACL = Get-Acl -Path $_
    $ACL.SetAccessRuleProtection($true,$true)
    $ACL | Set-Acl -Path $_
}

$folders | ForEach-Object {
    $acl = Get-Acl $_
    $acl.Access | Where-Object {$_.IdentityReference -eq "BUILTIN\Users" } | ForEach-Object { $acl.RemoveAccessRuleSpecific($_) }
    Set-Acl $_ $acl
}

Clear-Host

(Get-WinEvent -LogName AD-Users
Get-AdUser
