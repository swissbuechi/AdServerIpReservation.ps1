$Servers = Get-AdComputer -filter * | where {$_.OperatingSystem -like "*server*"}
foreach ($Server in $Servers) {
    # Do some Stuff
    Get-DhcpServerv4Scope
    if (Get-DhcpServerv4ExclusionRange -eq null) {
        Add-DhcpServer4ExclusionRange
    }
    
}