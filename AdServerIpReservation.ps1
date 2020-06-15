$Servers = Get-AdComputer -filter * | where {$_.OperatingSystem -like "*server*"}
foreach ($Server in $Servers) {
    # Do some Stuff
    Get-DhcpServerv4Scope
    if (Get-DhcpServerv4ExclusionRange -eq null) {
        Write-Host "There is currently no IPv4 DHCP excluded range configured"
        Write-Host "This is your current DHCP-Range:" Get-DhcpServerv4Scope
        Write-Host 

        $confirm = Read-Host "Would you like to configure an excluded Range now? `n(Yes, Y to confirm or No, N to cancle)"
        if (($confirm.ToLower -eq "y") -or ($confirm.ToLower -eq "yes")) {
            Write-Host "Please enter the start IP-Address of your new DHCP excluded Range"
            $StartRange = Read-Host
            Write-Host "Please enter the end IP-Address of your new DHCP excluded Range"
            $EndRange = Read-Host

            try {
                Add-DhcpServerv4ExclusionRange -StartRange $StartRange -EndRange $EndRange
            }
            catch {
                
            }

        }

        if ($confirm -eq )

        Add-DhcpServer4ExclusionRange
    }
    
}