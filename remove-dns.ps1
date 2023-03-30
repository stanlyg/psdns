Param (
    [Parameter(mandatory)][string]$CsvFile,
    [switch]$Delete,
    [switch]$DeleteMismatched,
    [switch]$DeleteMismatchedPtr
)

$RecordList = Import-Csv -Path $CsvFile
$ThisDomain = 'contoso.com'
$DNSServer = 'ad1'

function SplitInto-HostAndDomain {
    Param(
        [Parameter(mandatory)][string]$Domain,
        [Parameter(mandatory)][string]$FQDN
    )
    $FQDN.Substring(0,$FQDN.IndexOf($Domain)-1)
    $Domain

}
function Get-DNSARecord {
    Param(
        [Parameter(mandatory)][string]$DNSServer,
        [Parameter(mandatory)][string]$FQDN
    )
    $Hostname, $Domain = SplitInto-HostAndDomain -Domain $ThisDomain -FQDN $FQDN
    
    Get-DnsServerResourceRecord -ZoneName $Domain -ComputerName $DNSServer -Name $Hostname -RRType A -ErrorAction Ignore
}
function SplitInto-HostAndArpaZone {
    Param(
        [Parameter(mandatory)][string]$IPAddress
    )

    $IPBytes = [System.Net.IPAddress]::Parse($IPAddress).GetAddressBytes()
    [Array]::Reverse($IPBytes)
    $ReversedIP = $IPBytes -join '.'
    # Return Values
    $ReversedIP.Substring(0,$ReversedIP.IndexOf('.'))
    -join($ReversedIP.Substring($ReversedIP.IndexOf('.')+1),'.in-addr.arpa')
}
function Get-DNSPtrRecord {
    Param(
        [Parameter(mandatory)][string]$DNSServer,
        [Parameter(mandatory)][string]$IPAddress
    )
    $PtrRecord = $null
    $LastOctet, $ArpaZone = SplitInto-HostAndArpaZone -IPAddress $IPAddress
    Try {
        $PtrRecord = Get-DnsServerResourceRecord -ZoneName $ArpaZone -ComputerName $DNSServer -Name $LastOctet -RRType Ptr -ErrorAction Ignore
    }
    Catch {
        Write-Host -ForegroundColor Red "Could not find $($ArpaZone) on $($DNSServer)"
        $PtrRecord = $null
        Return $PtrRecord
    }
    Return $PtrRecord
}

# # # # # Main # # # # #

If (-not $Delete) {
    Write-Host -ForegroundColor Cyan "No records will be deleted. Informational output only. Add -delete to actually perform the deletions."
}

Foreach ($Item in $RecordList) {
    $Found = ''
    $RetrievedIP = ''
    $RetrievedHostname = ''

    #Write-Host "Checking: $($Item.Host), $($Item.IP)"

    $DnsRecord = Get-DNSARecord -DNSServer $DNSServer -FQDN $Item.Host
    
    # Print Retrieved Record
    If ($DnsRecord) {
        $DnsRecord
        $RetrievedIP = $DNSRecord.RecordData.IPv4Address.IPAddressToString
        $HostName = $DNSRecord.Hostname


        If ($RetrievedIP -ne $Item.IP) {
            Write-Host "The IP in DNS ($($RetrievedIP)) does not match the IP given ($($Item.IP))"
            If ($DeleteMismatched) {
                "Deleting mismatched A record ($($Item.Host) $($RetrievedIP))"
                Remove-DnsServerResourceRecord -ZoneName $ThisDomain -ComputerName $DNSServer -Name $Hostname -RRType A
            }
        }
        else {
            If ($Delete) {
                "Deleting A record for ($($Item.Host) $($Item.IP))"
                Remove-DnsServerResourceRecord -ZoneName $ThisDomain -ComputerName $DNSServer -Name $Hostname -RRType A
            }
        }
    }
    
    $PtrRecord = Get-DNSPtrRecord -DNSServer $DNSServer -IPAddress $Item.IP
    # Print Retrieved Record
    If ($PtrRecord) {
        $PtrRecord
        $RetrievedHostname = $PtrRecord.RecordData.PtrDomainName.Trim('.')
    
        If ($RetrievedHostname -ne $Item.Host) {
            Write-Host "The hostname in DNS ($($RetrievedHostname)) does not match the hostname give ($($Item.Host))"
            If ($DeleteMismatchedPtr) { 
                "Deleting mismatched PTR Record ($($Item.IP) $($RetrievedHostname))"
                Remove-DnsServerResourceRecord -ZoneName $ArpaZone -ComputerName $DNSServer -Name $LastOctet -RRType Ptr
            }
        }
        else {
            If ($Delete) {
                "Deleting PTR record for ($($Item.IP) $($Item.Host))"
                $LastOctet, $ArpaZone = SplitInto-HostAndArpaZone -IPAddress $Item.IP
                Remove-DnsServerResourceRecord -ZoneName $ArpaZone -ComputerName $DNSServer -Name $LastOctet -RRType Ptr

            }
        }
    }
}
