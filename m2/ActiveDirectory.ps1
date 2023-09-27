# Kjøres i dc1

# Lager variabler
$CompGroup = "OU=AD-Computers,DC=sec,DC=core"
$UserGroup = "OU=AD-Users,DC=sec,DC=core"


################### Setter opp OUer, grupper, og brukere ######################################################################################

# Hovedmapper
New-ADOrganizationalUnit "AD-Users" -Description "Inneholder OUer og brukere" 
New-ADOrganizationalUnit "AD-Computers" -Description "Inneholder servere of workstations" 
New-ADOrganizationalUnit "Ressurser" -Description "Innholder bedriftens ressurser"

# Undermapper
New-ADOrganizationalUnit "AD-Servers" -Description "Inneholder servere"  -Path $CompGroup
New-ADOrganizationalUnit "AD-Workstations" -Description "Inneholder workstations" -Path $CompGroup
New-ADOrganizationalUnit "IT-Drift" -Description "OU for IT Drift" -Path $UserGroup
New-ADOrganizationalUnit "Developer Team" -Description "OU for Developer Team" -Path $UserGroup
New-ADOrganizationalUnit "Regnskap" -Description "OU for Regnskap" -Path $UserGroup
New-ADOrganizationalUnit "Renhold" -Description "OU for Renhold" -Path $UserGroup
New-ADOrganizationalUnit "Human Resources" -Description "OU for Human Resources" -Path $UserGroup

# Legger til de eksisterende datamaskinene i mappene de tilhører
Get-ADComputer "srv1" | Move-ADObject -TargetPath "OU=AD-Servers,OU=AD-Computers,DC=sec,DC=core"
Get-ADComputer "cl1" | Move-ADObject -TargetPath "OU=AD-Workstations,OU=AD-Computers,DC=sec,DC=core"

# Lager grupper
New-ADGroup -GroupCategory Security -GroupScope Global -Name "g_itdrift" -Path "OU=IT-Drift,OU=AD-Users,DC=sec,DC=core" -SamAccountName "g_itdrift"
New-ADGroup -GroupCategory Security -GroupScope Global -Name "g_developers" -Path "OU=Developer Team,OU=AD-Users,DC=sec,DC=core" -SamAccountName "g_developers"
New-ADGroup -GroupCategory Security -GroupScope Global -Name "g_regnskap" -Path "OU=Regnskap,OU=AD-Users,DC=sec,DC=core" -SamAccountName "g_regnskap"
New-ADGroup -GroupCategory Security -GroupScope Global -Name "g_renhold" -Path "OU=Renhold,OU=AD-Users,DC=sec,DC=core" -SamAccountName "g_renhold"
New-ADGroup -GroupCategory Security -GroupScope Global -Name "g_hr" -Path "OU=Human Resources,OU=AD-Users,DC=sec,DC=core" -SamAccountName "g_hr"


# Lager brukere
$userList = Import-Csv users.csv -Delimiter ";"
$counter = 0

foreach ($user in $userList)
{
    $name = $user.FirstName + " " + $user.Surname
    $tempUsername = (($user.FirstName).substring(0,3)).ToLower() + (($user.Surname).substring(0,3)).ToLower()
    $tempUsername = $tempUsername -replace "ø","o" -replace "æ","e" -replace "å","a"

    # Legger til et tall bak brukernavnet hvis den allerede er tatt
    if(Get-ADUser -Filter "sAMAccountname -eq '$($tempUsername)'") {
        $counter++;
        $username = $tempUsername + $counter.ToString()
    } else {
        $username = $tempUsername
    }

    New-ADUser `
    -SamAccountName $username `
    -UserPrincipalName $user.UserPrincipalName `
    -Name $name `
    -GivenName $user.FirstName `
    -Surname $user.Surname `
    -Enabled $true `
    -ChangePasswordAtLogon $false `
    -DisplayName $user.Displayname `
    -Department $user.Department `
    -Path $user.path `
    -AccountPassword (ConvertTo-SecureString $user.Password -AsPlainText -Force)
}

# Skriver logg for hver bruker som blir lagt
Get-WinEvent -LogName Security | Where-Object {$_.id -eq 4720}

# Legger brukere i grupper
$ITDriftGroup = Get-ADUser -Filter * -Properties department | Where-Object {$_.department -Like "IT-Drift"} | Select-Object sAMAccountName
$DevteamGroup = Get-ADUser -Filter * -Properties department | Where-Object {$_.department -Like "Developer Team"} | Select-Object sAMAccountName
$RegnskapGroup = Get-ADUser -Filter * -Properties department | Where-Object {$_.department -Like "Regnskap"} | Select-Object sAMAccountName
$RenholdGroup = Get-ADUser -Filter * -Properties department | Where-Object {$_.department -Like "Renhold"} | Select-Object sAMAccountName
$HRGroup = Get-ADUser -Filter * -Properties department | Where-Object {$_.department -Like "Human Resources"} | Select-Object sAMAccountName

Add-ADGroupMember -Identity 'g_itdrift' -Members $ITDriftGroup
Add-ADGroupMember -Identity 'g_developers' -Members $DevteamGroup
Add-ADGroupMember -Identity 'g_regnskap' -Members $RegnskapGroup
Add-ADGroupMember -Identity 'g_renhold' -Members $RenholdGroup
Add-ADGroupMember -Identity 'g_hr' -Members $HRGroup

# Lager ressurser og legger til brukere til disse.
$ressurser=@('printere','adgangskort')
$ressurser | ForEach-Object { New-ADGroup -Name $_ -Path "OU=ressurser,DC=sec,DC=core" -GroupCategory Security -GroupScope DomainLocal }

# Gir alle tilgang til adgangskort.
$adgangskort=@($ITDriftGroup, $DevteamGroup, $RegnskapGroup, $RenholdGroup, $HRGroup)
$adgangskort | ForEach-Object { Add-ADGroupMember -Identity 'adgangskort' -Members $_ }

# Gir alle utenom renhold tilgang til printere.
$printere=@($ITDriftGroup, $DevteamGroup, $RegnskapGroup, $HRGroup)
$printere | ForEach-Object { Add-ADGroupMember -Identity 'printere' -Members $_ }


###############################################################################################################################################
