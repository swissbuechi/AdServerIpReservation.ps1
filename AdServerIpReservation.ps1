
function IsIpAddressUsed {
    # Firewall Rule for allow Ping: netsh advFirewall Firewall add rule name="OSRadar Rule PING IPv4" protocol=icmpv4:8,any dir=in action=allow 
    param (
        [system.net.ipaddress] $ipAddress
    )
    if (!(Test-Connection -ComputerName $ipAddress -Count 1 -Quiet)) {
        return $ipAddress
    }
    else {
        while ($true) {
            $ip = $ipAddress.GetAddressBytes()
            $ip[3]++
            $ipAddress = [system.net.ipaddress] "$($ip[0]).$($ip[1]).$($ip[2]).$($ip[3])"
            if (!(Test-Connection -ComputerName $ipAddress -Count 1 -Quiet)) {
                return $ipAddress
            }
        } 
    }
}

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
    $dhcpScopes = Get-DhcpServerv4Scope -ScopeId $dhcpScopeId
    $dhcpScopes | Format-Table
    $continue = Read-Host "`nWould you like to configure an excluded Range now? `n(yes, y to continue or no, n to cancle)"
    if (($continue -eq "y") -or ($continue -eq "yes")) {
        [system.net.ipaddress] $StartRange = Read-Host "Start IP"
        [system.net.ipaddress] $EndRange = Read-Host "End IP"
        Add-DhcpServerv4ExclusionRange -ScopeId $dhcpScopeId -StartRange $StartRange -EndRange $EndRange
    }
    else {
        exit
    }
}

$dhcpScopes = Get-DhcpServerv4Scope

if ($null -eq $dhcpScopes) {
    Write-Host "No DHCP-Scope configured"
    Write-Host "You need to configure a DHCP-Scope to use this script"
    exit
}

$dhcpScopesCount = $dhcpScopes | Measure-Object

if ($dhcpScopesCount.Count -eq 1) {
    [system.net.ipaddress] $dhcpScopeId = $dhcpScopes.ScopeId.IPAddressToString
}
else {
    $dhcpScopes | Format-Table
    [system.net.ipaddress] $dhcpScopeId = Read-Host "`nPlease Enter the ScopeId of your DHCP-Scope you want to use"
}
$dnsSuffix = Get-DhcpServerv4OptionValue -ScopeId $dhcpScopeId -OptionId 15

$dhcpExcludedScopes = Get-DhcpServerv4ExclusionRange -ScopeId $dhcpScopeId
$dhcpExcludedScopeCount = $dhcpExcludedScopes | Measure-Object

if ($null -eq $dhcpExcludedScopes) {
    AddDhcpExcludedRange
}

$dhcpExcludedScopes = Get-DhcpServerv4ExclusionRange -ScopeId $dhcpScopeId
$dhcpExcludedScopeCount = $dhcpExcludedScopes | Measure-Object

if ($dhcpExcludedScopeCount.Count -eq 1) {
    Write-Host "This is your current DHCP excluded Scope:`n"
    $dhcpExcludedScopes | Format-Table
    $ipAddress = $dhcpExcludedScopes.StartRange
}
else {
    Write-Host "These are your current DHCP excluded Scopes:`n"
    $dhcpExcludedScopes | Format-Table
    [system.net.ipaddress] $ipAddress = Read-Host "`nPlease Enter the StartRange of your DHCP Excluded Scope you want to use"
    $dhcpExcludedScopes = Get-DhcpServerv4ExclusionRange -ScopeId $dhcpScopeId | Where-Object { $_.StartRange -eq $ipAddress }
}

$ip = $ipAddress.GetAddressBytes()
$ip[3]--
$ipAddress = [system.net.ipaddress] "$($ip[0]).$($ip[1]).$($ip[2]).$($ip[3])"

$servers = Get-ADComputer -Filter { OperatingSystem -like "*windows*server*" } | Select-Object -Property name
foreach ($server in $servers) {
    # Firewall Rule for Remote Wmi-Object: netsh advfirewall firewall set rule group="Windows Management Instrumentation (WMI)" new enable=yes
    $nics = Get-WmiObject win32_networkadapterconfiguration -ComputerName $server.name | Where-Object { $_.DNSDomain -eq $dnsSuffix.Value }
    foreach ($nic in $nics) {
        $ip = $ipAddress.GetAddressBytes()
        $ip[3]++
        $ipAddress = [system.net.ipaddress] "$($ip[0]).$($ip[1]).$($ip[2]).$($ip[3])"
        $ipAddress = IsIpAddressUsed -ipAddress $ipAddress
        if (!(IsIpAddressInRange -ipAddress $ipAddress -fromAddress $dhcpExcludedScopes.StartRange -toAddress $dhcpExcludedScopes.EndRange)) {
            Write-Host "Your DHCP Excluded Range is full"
            Write-Host "Please extend your DHCP Excluded Range and re-run the script"
            exit
        }
        if ($null -ne $nic) {
            $mac = $nic.MACAddress
            Add-DhcpServerv4Reservation -ScopeId $DhcpScopeId -IPAddress $ipAddress -ClientId $mac.Replace(":", "-") -Description "Reservation for server $($server.name)"
            Write-Host "`nNew Reservation created:" $server.name $ipAddress
        }
    }
}
