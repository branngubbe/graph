$allIntuneDevices = Get-MgbetaDeviceManagementManagedDevice -All
$outputFilePath = "C:\temp\IntuneDevices.txt"
$outputFilePathCsv = "C:\temp\IntuneDevices.csv"
#ethernet address blir ikke med når man spør etter alle...
foreach ($intuneDevice in $allIntuneDevices) {
  $singelDevice = Get-MgbetaDeviceManagementManagedDevice -ManagedDeviceId $intuneDevice.ID | Select DeviceName,AzureAdDeviceId,id, EthernetMacAddress, WiFiMacAddress,OperatingSystem,UserDisplayName,UserPrincipalName,Manufacturer,ComplianceState
#$id=$intuneDevice.ID 
#  $singelDevice | Export-Csv -Path $outputFilePathCsv -Delimiter ";" -Encoding utf8 -Append
#$ext=Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/devices/$ID/extensionAttributes"
$displayName=$intuneDevice.DeviceName
#$deviceId=$intuneDevice.id
#$ext=Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/devices/?`$filter=startswith(displayName, '$displayName')"
$ext=Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/devices/?`$filter=displayName eq '$displayName'"#$
#$ext=Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/devices/?`$filter=deviceid eq '$deviceId'" #Her er device id nøkkel mellom intune enhet og entra device.


  #or in your format
  $output = [pscustomobject]@{
            DeviceName =   $singelDevice. DeviceName
            AzureAdDeviceId =   $singelDevice. AzureAdDeviceId
            id =   $singelDevice.id
            EthernetMacAddress =  $singelDevice.EthernetMacAddress
            #WiFiMacAddress=($matchingItem|select @{Name="LastLogonDate";Expression={[datetime]::FromFileTime($_.lastlogontimestamp)}}).LastLogonDate
			WiFiMacAddress =  $singelDevice.WiFiMacAddress
            OperatingSystem =  $singelDevice.OperatingSystem
            UserDisplayName =   $singelDevice.UserDisplayName
            UserPrincipalName =  $singelDevice.UserPrincipalName
			Manufacturer =  $singelDevice.Manufacturer
			ComplianceState =   $singelDevice.ComplianceState
			extensionAttribute9 = $ext.Values.extensionAttributes.extensionAttribute9
			extensionAttribute8 = $ext.Values.extensionAttributes.extensionAttribute8
			extensionAttribute7 = $ext.Values.extensionAttributes.extensionAttribute7
			extensionAttribute6 = $ext.Values.extensionAttributes.extensionAttribute6
			extensionAttribute5 = $ext.Values.extensionAttributes.extensionAttribute5
			extensionAttribute4 = $ext.Values.extensionAttributes.extensionAttribute4
			extensionAttribute3 = $ext.Values.extensionAttributes.extensionAttribute3
			extensionAttribute2 = $ext.Values.extensionAttributes.extensionAttribute2
			extensionAttribute1 = $ext.Values.extensionAttributes.extensionAttribute1
			extensionAttribute14 = $ext.Values.extensionAttributes.extensionAttribute14
			extensionAttribute15 = $ext.Values.extensionAttributes.extensionAttribute15
			extensionAttribute12 = $ext.Values.extensionAttributes.extensionAttribute12
			extensionAttribute13 = $ext.Values.extensionAttributes.extensionAttribute13
			extensionAttribute10 = $ext.Values.extensionAttributes.extensionAttribute10
			extensionAttribute11 = $ext.Values.extensionAttributes.extensionAttribute11
			}
  
  
  $output| Export-Csv -Path $outputFilePathCsv -Delimiter ";" -Encoding utf8 -Append
  $output
  #OperatingSystem: $($singelDevice.OperatingSystem)
  #EthernetMAC: $($singelDevice.EthernetMacAddress)
  #WifiMAC: $($singelDevice.WiFiMacAddress)"
  #Write-Output $output
  #$output | Out-File -FilePath $outputFilePath -Append



}


#$equal=Compare-Object -DifferenceObject $wifiClients -ReferenceObject $intuneDevice -Property WiFiMacAddress -IncludeEqual -PassThru -ExcludeDifferent