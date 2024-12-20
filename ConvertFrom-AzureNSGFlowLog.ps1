using namespace Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel
#requires -version 7
#requires -module Az.Storage
import-module Az.Storage

# Connect-AzAccount og velg ritig subscription først.
function Get-AzNSGFlowLog {
  <#
  .SYNOPSIS
  Fetches all Network Security Group Flow logs in a given container and formats them into Powershell Objects
  tilpasset videre til vnet flow logs.
  .EXAMPLE
  Get-AzStorageAccount -name something -resourcegroupname something | Get-AzStorageContainer | Get-AzNSGFlowLog | select -exclude resourceId | Out-GridView
  $all=Get-AzStorageAccount | Get-AzStorageContainer | Get-AzNSGFlowLog 
  $all|where -Property FlowState -eq 'D'|select ruleName,src,srcprt,dst,dstprt,timestamp|ft
  $all|where {$_.FlowDirection -eq 'I' -and $_.flowstate -ne 'd'}|select ruleName,src,srcprt,dst,dstprt,timestamp|ft

  .EXAMPLE
  Hente loggdata for siste timen: (Dette handler  i korte trekk om hvilke hele timer den henter data for, så i praksis vil dette hente for inneværende + forrige time). Resultatet kan evnt videre sorteres med timestamp hvis nødvendig.
  $all=Get-AzStorageAccount | Get-AzStorageContainer | Get-AzNSGFlowLog  -After (get-date).AddHours(-1)

  #>
  [CmdletBinding()]
  param(
    #An Azure Storage Container fetched via Get-AzStorageContainer
    [Parameter(Mandatory, ValueFromPipeline)][object]$Container,
    #Filter to a particular NSG. Supports regex for the name
    [String]$NSGName,
    #Only show records after a certain date. Can be combined with -Before
    [DateTime]$After,
    #Only show records before a certain date. Can be combined with -After
    [DateTime]$Before
  )

  process {
    $Container
    | Get-AzStorageBlob
    | Where-Object {
      if (-not $After) { $PSItem }
      if ($After -and $PSItem.LastModified -gt $After ) { $PSItem }
    }
    | Where-Object {
      if (-not $Before) { $PSItem }
      if ($Before -and $PSItem.LastModified -gt $Before) { $PSItem }
    }
    | Where-Object {
      if (-not $NSGName) { $PSItem }
      if ($NSGName -and $PSItem.Name -match "NETWORKSECURITYGROUPS/$NSGNAME/") { $PSItem }
    }
    | ForEach-Object {
      $PSItem.blobclient.DownloadContent().Value.Content
    }
    | ConvertFrom-AzureNSGFlowLog
  }
}

filter ConvertFrom-AzureNSGFlowLog {
  [CmdletBinding()]
  param([Parameter(ValueFromPipeline)][string]$flowLogJson)

  $records = $flowLogJson
  | ConvertFrom-Json
  | Select-Object -Expand records


  foreach ($record in   $records) {
    foreach ($flow in $record.flowRecords.flows) {
    foreach ($flowGroups in $flow.flowGroups){
      foreach ($tuple in $flowGroups.flowTuples) {
        $id, $src, $dst, $srcPrt, $dstPrt, $protocolNr,$FlowDirection,$FlowState,$FlowEncryption,$PacketsSent,$ByteSent,$PacketsReceived,$ByteReceived, $options = $tuple -split ','
        [datetime]$origin = '1970-01-01 00:00:00'
        
        [PSCustomObject]@{
          macAddress = $record.macAddress
          time       = $record.time
          resourceId = $record.flowLogResourceID
          targetResourceID = $record.targetResourceID
          ruleName       = $flowGroups.rule
          id         = $id #er vel egenltig timestamp..
          timestamp = $origin.AddMilliseconds($id)
          src        = $src
          srcPrt     = $srcPrt
          dst        = $dst
          dstPrt     = $dstPrt
          protocolNr = $protocolNr
          FlowDirection = $FlowDirection
          FlowState = $FlowState
          FlowEncryption = $FlowEncryption
          PacketsSent = $PacketsSent
          ByteSent = $ByteSent
          PacketsReceived = $PacketsReceived
          options    = $options
        }
      }
      }
    }
  }

}




# tilleggs info
# install get-ipinfo:
# Install-Module -Name Get-IPInfo

<#
Import-Module Get-IPInfo
Install-Module -Name Get-IPInfo
For å hente ip info for loggene man ønsker å se på... 
$allIPinfo=($all|where {$_.FlowState -eq 'D' -and $_.src -eq '10.128.x.x' -and $_.dstprt -eq '443'}|select dst -Unique)|foreach {get-ipinfo $_.dst -raw}

#>