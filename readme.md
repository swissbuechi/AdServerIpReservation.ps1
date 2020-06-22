# Features

* Every Server gets an DHCP IP reservation
* Every IP is in an DHCP excluded range
* Missing DHCP excluded ranges can be created
* Every IP gets testet and only used if free

# Restrictions
* Only works for /24 networks
## Required firewall rules:
	netsh advfirewall firewall set rule group="Windows Management Instrumentation (WMI)" new enable=yes
	netsh advFirewall Firewall add rule name="OSRadar Rule PING IPv4" protocol=icmpv4:8,any dir=in action=allow
