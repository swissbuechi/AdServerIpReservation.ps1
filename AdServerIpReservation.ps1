$Servers = Get-AdComputer -filter * | where {$_.OperatingSystem -like "*server*"}
foreach ($Server in $Servers) {
    # Do some Stuff
}