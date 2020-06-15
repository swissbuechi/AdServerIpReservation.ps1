    if (Get-DhcpServerv4ExclusionRange -eq $null) {
        Write-Host "There is currently no IPv4 DHCP excluded range configured"
        $DhcpScope = Get-DhcpServerv4Scope
        Write-Host "This is your current DHCP-Range:" $DhcpScope
    
        $continue = Read-Host "Would you like to configure an excluded Range now? `n(Yes, Y to continue or No, N to cancle)"
        if (($continue.ToLower -eq "y") -or ($continue.ToLower -eq "yes")) {
            Write-Host "Please enter the start IP-Address of your new DHCP excluded Range"
            $StartRange = Read-Host
            Write-Host "Please enter the end IP-Address of your new DHCP excluded Range"
            $EndRange = Read-Host

            try {
                Add-DhcpServerv4ExclusionRange -StartRange $StartRange -EndRange $EndRange
            }
            catch {
                Write-Host "Could not create your new DCHP excluded Range: start $StartRange end: $EndRange"
                Write-Host "Please check if your start and end IP-Address is inside your DHCP Scope: $DhcpScope"
            }

        }

        if (($continue.ToLower -eq "n") -or ($continue.ToLower -eq "no")) {
            exit
        }
    }


#$Servers = Get-AdComputer -filter * | where {$_.OperatingSystem -like "*server*"}
#foreach ($Server in $Servers) {
#}