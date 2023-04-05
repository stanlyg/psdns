Param (
    [Parameter(mandatory)][string]$CsvFile
)

$DnsServer = "ad1"
$AllZones = Get-DnsServerZone -ComputerName $DnsServer
$ReverseZones = $AllZones | Where-Object -Property IsReverseLookupZone

$theList = New-Object System.Collections.ArrayList

foreach ( $rZone in $ReverseZones ) {
    $rZoneDetails = Get-DnsServerResourceRecord -ComputerName $DnsServer -ZoneName $rZone.ZoneName -RRType Ptr
    $split = $rZone.ZoneName.Split('.')
    $ForwardIP = "$($split[2]).$($split[1]).$($split[0])."
    foreach ( $rEntry in $rzoneDetails ) {

        $item = New-Object psobject
        $item | Add-Member -MemberType NoteProperty -Name 'Hostname' -Value $rEntry.RecordData.PtrDomainName
        $item | Add-Member -MemberType NoteProperty -Name 'IP' -Value "$($ForwardIP)$($rEntry.HostName)"
        $theList.add($item)
    }
}

$theList | Export-Csv -Path $CsvFile -NoTypeInformation
