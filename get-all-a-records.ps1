Param (
    [Parameter(mandatory)][string]$CsvFile
)

$ThisDomain = 'contoso.com'
$DNSServer = 'ad1'

$allARecords = Get-DnsServerResourceRecord -ZoneName $ThisDomain -ComputerName $DNSServer -RRType A -ErrorAction Ignore

$theList = New-Object System.Collections.ArrayList

ForEach ($DnsRecord in $allARecords) {
    $dnsentry = New-Object psobject
    $props = [ordered]@{HostName=$DnsRecord.HostName;Domain=$ThisDomain;RecordType=$DnsRecord.RecordType;Timestamp=$DnsRecord.Timestamp;TimeToLive=$DnsRecord.TimeToLive;RecordData=$DnsRecord.RecordData.IPv4Address.IPAddressToString}
    $dnsentry | Add-Member -NotePropertyMembers $props

    
    $theList.add($dnsentry) | Out-Null
 }

 $theList | Export-Csv -Path $CsvFile -NoTypeInformation