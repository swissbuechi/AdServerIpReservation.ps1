$DhcpExcludedScope = Get-DhcpServerv4ExclusionRange
if ($null -eq $DhcpExcludedScope) {
    Write-Host "There is currently no IPv4 DHCP excluded range configured`n"
    $DhcpScopes = Get-DhcpServerv4Scope
    Write-Host "This is your current DHCP-Range:`n"
    $DhcpScopes

    $continue = Read-Host "Would you like to configure an excluded Range now? `n(yes, y to continue or no, n to cancle)"
    if (($continue -eq "y") -or ($continue -eq "yes")) {
        $DhcpScopesCount = $DhcpScopes | Measure-Object
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
    Write-Host "Test"


$Servers = Get-AdComputer -filter * | where {$_.OperatingSystem -like "*server*"}
foreach ($Server in $Servers) {
}