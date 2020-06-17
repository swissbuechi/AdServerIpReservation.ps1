$servers = Get-ADComputer -Filter { OperatingSystem -like "*windows*server*" } | Select-Object -Property name
$dhcpScopes = Get-DhcpServerv4Scope
$dhcpScopesCount = $dhcpScopes | Measure-Object
$dhcpExcludedScope = Get-DhcpServerv4ExclusionRange
$dhcpExcludedScopeCount = $dhcpExcludedScope | Measure-Object


function IsIpAddressUsed {
    # Firewall Rule for allow Ping: netsh advFirewall Firewall add rule name="OSRadar Rule PING IPv4" protocol=icmpv4:8,any dir=in action=allow 
    param (
        [system.net.ipaddress] $ipAddress
    )
    if (!Test-Connection -ComputerName $ipAddress -Count 3 -Quiet) {
        return $ipAddress
    }
    else {
        while ($true) {
            $ip = $ipAddress.GetAddressBytes()
            $ip[3]++
            $ipAddress = [system.net.ipaddress] "$($ip[0]).$($ip[1]).$($ip[2]).$($ip[3])"
            if (!Test-Connection -TargetName $ipAddress -Count 3 -Quiet) {
                return $ipAddress
            }
        } 
    }
}

#IsIpAddressInRange -ipAddress 172.16.1.36 -fromAddress 172.16.1.30 -toAddress 172.16.1.40

function IsIpAddressInRange {
    param(
        [string] $ipAddress,
        [string] $fromAddress,
        [string] $toAddress
    )
    $ip = [system.net.ipaddress]::Parse($ipAddress).GetAddressBytes()
    [array]::Reverse($ip)
    $ip = [system.BitConverter]::ToUInt32($ip, 0)
    $from = [system.net.ipaddress]::Parse($fromAddress).GetAddressBytes()
    [array]::Reverse($from)
    $from = [system.BitConverter]::ToUInt32($from, 0)
    $to = [system.net.ipaddress]::Parse($toAddress).GetAddressBytes()
    [array]::Reverse($to)
    $to = [system.BitConverter]::ToUInt32($to, 0)
    $from -le $ip -and $ip -le $to
}

function AddDhcpExcludedRange {
    Write-Host "There is currently no IPv4 DHCP excluded range configured`n"
    Write-Host "This is your current DHCP-Range:`n"
    $dhcpScopes
    $continue = Read-Host "`nWould you like to configure an excluded Range now? `n(yes, y to continue or no, n to cancle)"
    if (($continue -eq "y") -or ($continue -eq "yes")) {
        if ($dhcpScopesCount.Count -eq 1) {
            $dhcpScopeId = $dhcpScopes.dhcpScopeId.IPAddressToString
        }
        else {
            $dhcpScopeId = Read-Host "Scope Id"
        }
        $StartRange = Read-Host "Start IP"
        $EndRange = Read-Host "End IP"
        Add-DhcpServerv4ExclusionRange -DhcpScopeId $dhcpScopeId -StartRange $StartRange -EndRange $EndRange
    }
    else {
        exit
    }
}

if ($null -eq $dhcpScopes) {
    Write-Host "No DHCP-Scope configured"
    Write-Host "You need to configure a DHCP-Scope to use this script"
    exit
}

if ($null -eq $dhcpExcludedScope) {
    AddDhcpExcludedRange
}

if ($dhcpScopesCount.Count -eq 1) {
    $dhcpScopeId = $dhcpScopes.dhcpScopeId.IPAddressToString
    $DnsSuffix = Get-DhcpServerv4OptionValue -ScopeId $dhcpScopeId -OptionId 15
}
else {
    # Figure out which scope to use... ??? :-(
}

Write-Host "This is your current DHCP excluded Scope:`n"
$dhcpExcludedScope

if ($dhcpExcludedScopeCount.Count -eq 1) {
    $dhcpExcludedScopeId = $dhcpExcludedScope.ScopeId
}

$ipAddress = $dhcpExcludedScope.StartRange

foreach ($server in $servers) {
    # $ipAddress = IsIpAddressUsed -ipAddress $ipAddress
    # foreach ($NIC in $NICs) {$NIC.EnableStatic("10.0.0.$(($ipaddress++))", "255.255.255.0")
    # Firewall Rule for Remote Wmi-Object: netsh advfirewall firewall set rule group="Windows Management Instrumentation (WMI)" new enable=yes
    $nics = Get-WmiObject win32_networkadapterconfiguration -ComputerName $server.name | Where-Object { $_.DNSDomain -eq $DnsSuffix.Value }

    foreach ($nic in $nics) {
        $ip = $ipAddress.GetAddressBytes()
        $ip[3]++
        $ipAddress = [system.net.ipaddress] "$($ip[0]).$($ip[1]).$($ip[2]).$($ip[3])"
        if ($null -ne $nic) {
            $mac = $nic.MACAddress
            Add-DhcpServerv4Reservation -ScopeId $dhcpExcludedScopeId -IPAddress $ipAddress -ClientId $mac.Replace(":", "-") -Description "Reservation for server $($server.name)"
            Write-Host "New Reservation created:" $server.name $ipAddress
        }
    }
}

