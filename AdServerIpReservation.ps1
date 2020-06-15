$DhcpExcludedScope = Get-DhcpServerv4ExclusionRange
if ($null -eq $DhcpExcludedScope) {
    Write-Host "There is currently no IPv4 DHCP excluded range configured"
    $DhcpScopes = Get-DhcpServerv4Scope
    Write-Host "This is your current DHCP-Range:"
    $DhcpScopes

    $continue = Read-Host "Would you like to configure an excluded Range now? `n(yes, y to continue or no, n to cancle)"
    if (($continue -eq "y") -or ($continue -eq "yes")) {
        $ScopeId = Read-Host "Scope Id: "
        $StartRange = Read-Host "Start IP-Address: "
        $EndRange = Read-Host "End IP-Address: "
        try {
            Add-DhcpServerv4ExclusionRange -ScopeId $ScopeId -StartRange $StartRange -EndRange $EndRange
        }
        catch {
            Write-Host "Could not create your new DCHP excluded Range: start $StartRange end: $EndRange"
            Write-Host "Please check if your start and end IP-Address is inside your DHCP Scope:"
            $DhcpScopes
        }
    }
}


#$Servers = Get-AdComputer -filter * | where {$_.OperatingSystem -like "*server*"}
#foreach ($Server in $Servers) {
#}