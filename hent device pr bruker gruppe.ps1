<#
Script for å hente inn enheter for alle brukere i en gitt grupe.
Deretter trigger en "sync device" action på enhet i intune.
#>


# Logg inn på Microsoft Graph
#Connect-MgGraph -Scopes "Group.Read.All DeviceManagementManagedDevices.Read.All"
#For å synke enhet i tillegg trengs mer rettigheter..
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All,DeviceManagementManagedDevices.PrivilegedOperations.All"

# Angi Display Name for gruppen
$displayName = "SEUS-Alle elever i 9. trinn på Stor-Elvdal ungdomsskole"
# Finn gruppen basert på Display Name
$uri = "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$displayName'"
$group = Invoke-MgGraphRequest -Method GET -Uri $uri

# Sjekk resultatet og vis gruppe-ID
if ($group.value.Count -eq 1) {
    $groupId = $group.value[0].id
    Write-Host "Gruppe-ID funnet: $groupId"
} elseif ($group.value.Count -gt 1) {
    Write-Host "Flere grupper funnet med samme navn. Vennligst sjekk manuelt."
    $group.value | ForEach-Object { Write-Host "Gruppe-ID: $($_.id), Navn: $($_.displayName)" }
} else {
    Write-Host "Ingen grupper funnet med navnet: $displayName"
}




# Angi gruppe-ID for gruppen du vil søke i
#$groupId = "DIN-GRUPPE-ID"

# Hent gruppemedlemmene
$uriMembers = "https://graph.microsoft.com/v1.0/groups/$groupId/members"
$groupMembers = Invoke-MgGraphRequest -Method GET -Uri $uriMembers

# Lagre brukere (filtrer kun User-objekter)
$users = $groupMembers.value | Where-Object { $_."@odata.type" -eq "#microsoft.graph.user" }

# Initialiser liste over PC-er
$deviceList = @()

# Hent Intune-enheter for hver bruker
foreach ($user in $users) {
    $userPrincipalName = $user.userPrincipalName
    Write-Host ("Søker etter enheter for bruker: "+$userPrincipalName+ " ("+$user.displayname+")")

    # Hent enheter for brukeren basert på eierskap
    $uriDevices = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=userPrincipalName eq '$userPrincipalName'"
    $devices = Invoke-MgGraphRequest -Method GET -Uri $uriDevices

    # Legg til enhetene i listen
    $deviceList += $devices.value | ForEach-Object {
        [PSCustomObject]@{
            User                 = $user.displayName
            UserPrincipalName    = $userPrincipalName
            DeviceName           = $_.deviceName
            OperatingSystem      = $_.operatingSystem
            ComplianceState      = $_.complianceState
            LastSyncDateTime     = $_.lastSyncDateTime
            "@odata.type"        = "`#microsoft.graph.Device" 
            DeviceId             = $_.azureADDeviceId
            id                   = $_.id
            accountEnabled       = $_.accountEnabled
            model                = $_.model
            manufacturer         = $_.manufacturer
            serialNumber         = $_.serialNumber
        }
    }
}

# Vis listen over enheter
$deviceList | select User,DeviceName,OperatingSystem,ComplianceState,LastSyncDateTime|Format-Table -AutoSize

# Valgfritt: Eksporter til CSV
#$deviceList | Export-Csv -Path "PCerPerBruker.csv" -NoTypeInformation -Encoding UTF8





# Sjekk og trigge synkronisering for hver enhet
foreach ($device in $deviceList) {
    if ($device."@odata.type" -eq "#microsoft.graph.managedDevice" -and $device.accountEnabled -eq $true) {
        #Write-Host "Synkroniserer enhet: $($device.id)"
        Write-Host "Synkroniserer enhet: $($device.displayname)"
        $deviceid=$device.id
        $url="https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$deviceid/syncDevice"
        #$url
        Invoke-MgGraphRequest -Method POST -Uri $url
    }
    if ($device."@odata.type" -eq "#microsoft.graph.Device") {
        Write-host "henter intune enhet basert på device id"
        $deviceid=$device.deviceid
        $uri1 = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=azureADDeviceId eq '$deviceid'"
        $uri1
        $intuneDevice = Invoke-MgGraphRequest -Method GET -Uri $uri1
        #$intuneDevice

        #Write-Host "Synkroniserer enhet: $($device.id)"
        Write-Host "Synkroniserer enhet: $($device.displayname)"
        $deviceid=$intuneDevice.value.id
        $url="https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$deviceid/syncDevice"
        #$url
        Invoke-MgGraphRequest -Method POST -Uri $url
    }
}
