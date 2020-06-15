$DhcpScopes = Get-DhcpServerv4Scope
$Servers = Get-ADComputer -Filter {OperatingSystem -like "*windows*server*"} | Select-Object -Property name
$DhcpExcludedScope = Get-DhcpServerv4ExclusionRange
$DhcpScopesCount = $DhcpScopes | Measure-Object

if ($null -eq $DhcpScopes) {
    Write-Host "No DHCP-Range configured"
    exit
}

if ($null -eq $DhcpExcludedScope) {
    Write-Host "There is currently no IPv4 DHCP excluded range configured`n"
    $DhcpScopes = Get-DhcpServerv4Scope
    Write-Host "This is your current DHCP-Range:`n"
    $DhcpScopes

    $continue = Read-Host "`nWould you like to configure an excluded Range now? `n(yes, y to continue or no, n to cancle)"
    if (($continue -eq "y") -or ($continue -eq "yes")) {
        if ($DhcpScopesCount.Count -eq 1) {
            $ScopeId = $DhcpScopes.ScopeId.IPAddressToString
        } else {
            $ScopeId = Read-Host "Scope Id"
        }
        $StartRange = Read-Host "Start IP"
        $EndRange = Read-Host "End IP"
        Add-DhcpServerv4ExclusionRange -ScopeId $ScopeId -StartRange $StartRange -EndRange $EndRange
    } else {
        exit
    }
}

if ($DhcpScopesCount.Count -eq 1) {
    $ScopeId = $DhcpScopes.ScopeId.IPAddressToString
    $DnsSuffix = Get-DhcpServerv4OptionValue -ScopeId $ScopeId -OptionId 15
}

foreach ($Server in $Servers) {
    $Server.name
    # Firewall Rule for Remote Wmi-Object: netsh advfirewall firewall set rule group="Windows Management Instrumentation (WMI)" new enable=yes
    $NIC = Get-WmiObject win32_networkadapterconfiguration -ComputerName $Server.name | Where-Object{$_.DNSDomain -eq $DnsSuffix.Value}
    $Mac = $NIC.MACAddress 
    $Mac
}

# prps: DNSHostName, Enabled , Name  ,  IPv4Address 