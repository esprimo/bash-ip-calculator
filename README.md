# bash-ip-calculator

Calculate network ranges, CIDRs etc. Written in pure Bash. I probably wrote it around 2015 and found it now while wiping an old laptop. Made for fun rather than being useful.

```
$ ./ipcalc.sh -h
Usage:
ipcalc.sh [OPTIONS] NETWORK
  -r,--print-ip-range	Print all IPs in the range, one per line.
  -h,--help				Print this help message.

NETWORK is an IP and a prefix or netmark separated with a slash. For example:
- 192.168.0.1/24
- 192.168.0.1/255.255.255.0
```

Example using CIDR:

```
$ ./ipcalc.sh 192.168.1.13/27
Address (dec): 192.168.1.13
Address (bin): 11000000 10101000 00000001 00001101
Wildcard mask (dec): 0.0.0.31
Wildcard mask (bin): 00000000 00000000 00000000 00011111
Netmask (dec): 255.255.255.224
Netmask (bin): 11111111 11111111 11111111 11100000
Prefix: 27
Number of hosts: 30
CIDR: 192.168.1.0/27
Broadcast: 192.168.1.31
```

Example using IP and netmask:

```
$ ./ipcalc.sh 10.0.2.0/255.255.255.0
Address (dec): 10.0.2.0
Address (bin): 00001010 00000000 00000010 00000000
Wildcard mask (dec): 0.0.0.255
Wildcard mask (bin): 00000000 00000000 00000000 11111111
Netmask (dec): 255.255.255.0
Netmask (bin): 11111111 11111111 11111111 00000000
Prefix: 24
Number of hosts: 254
CIDR: 10.0.2.0/24
Broadcast: 10.0.2.255
```

Example printing all IPs:

```
$ ./ipcalc.sh --print-ip-range 127.0.0.0/29
Address (dec): 127.0.0.0
Address (bin): 01111111 00000000 00000000 00000000
Wildcard mask (dec): 0.0.0.7
Wildcard mask (bin): 00000000 00000000 00000000 00000111
Netmask (dec): 255.255.255.248
Netmask (bin): 11111111 11111111 11111111 11111000
Prefix: 29
Number of hosts: 6
CIDR: 127.0.0.0/29
Broadcast: 127.0.0.7
127.0.0.0
127.0.0.1
127.0.0.2
127.0.0.3
127.0.0.4
127.0.0.5
127.0.0.6
127.0.0.7
```

Example using multilpe networks:

```
$ ./ipcalc.sh 192.168.1.13/27 10.0.2.0/255.255.255.0
Address (dec): 192.168.1.13
Address (bin): 11000000 10101000 00000001 00001101
Wildcard mask (dec): 0.0.0.31
Wildcard mask (bin): 00000000 00000000 00000000 00011111
Netmask (dec): 255.255.255.224
Netmask (bin): 11111111 11111111 11111111 11100000
Prefix: 27
Number of hosts: 30
CIDR: 192.168.1.0/27
Broadcast: 192.168.1.31

Address (dec): 10.0.2.0
Address (bin): 00001010 00000000 00000010 00000000
Wildcard mask (dec): 0.0.0.255
Wildcard mask (bin): 00000000 00000000 00000000 11111111
Netmask (dec): 255.255.255.0
Netmask (bin): 11111111 11111111 11111111 00000000
Prefix: 24
Number of hosts: 254
CIDR: 10.0.2.0/24
Broadcast: 10.0.2.255
```