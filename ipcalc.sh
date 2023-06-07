#!/usr/bin/env bash

## Convert a network prefix and echoes the binary equalient in octets
# @param prefix to convert
# @result bitmask in octets
prefix_to_netmaskBin() {
	local prefix="$1"
	local bitbase='11111111111111111111111111111111'
	local ones
	local netmaskBin

	# print $prefix amount of space and save to $spaces
	printf -v spaces '%*s' $((32 - prefix))
	# replace space with zeros
	ones=${spaces// /0}

	# the prefix number is how many ones that is needed, so make take a
	# substring of that length of the bitbase and append the zeroes
	netmaskBin="${bitbase:0:prefix}${ones}"

	# put spaces between every 8th character (return octets)
	echo "${netmaskBin:0:8} ${netmaskBin:8:8} ${netmaskBin:16:8} ${netmaskBin:24:8}"
}

## Convert a binary netmask to decimal wildcard separated with space
# @param binary netmask in octets
# @result space separated wild card mask in decimal form
netmaskBin_to_wildcard() {
	local netmaskBin="$1"
	local wildcard_mask

	for octet in $netmaskBin; do
		wildcard_mask="${wildcard_mask}${wildcard_mask:+.}$((255 - 2#$octet))"
	done

	echo "$wildcard_mask"
}

## Convert binary ip to decimal ip
# @param binary ip in octets separated with space
# @result dot separated ip
# netmask bin = rätt, netmask to ip = wrong last octet for 32
binary_to_ip() {
	local binary="$1"
	local ip

	for octet in $binary; do
		ip="${ip}${ip:+.}$((2#$octet))"
	done

	echo "$ip"
}

## Convert an integer to binary
# @param integer to convert
# @result binary representation of $1
int_to_bin() {
	local int="$1"
	local binary

	# not the most optimal way but it works
	for i in {0..7}; do
		binary="$((int % 2))$binary"
		int=$((int / 2))
	done

	echo "$binary"
}

ip_to_binary() {
	local ip="$1"
	local binary

	IFS='.' read -ra ip_octet <<<"$ip"
	for i in {0..3}; do
		binary="${binary}${binary:+ }$(int_to_bin ${ip_octet[i]})"
	done

	echo "$binary"
}

## Makes IP ranges in bash suntax (eg 192.168.0.{0..255} for 192.168.0.0/24)
# @param wildcard_mask a space separated wildcard mask in decimal form
# (eg 0 0 0 255)
# @param dot separated network address (eg 192.168.0.0)
# @result IP range that bash can expland (eg 192.168.0.{0..255})
generate_bash_range() {
	local wildcard_mask="$1"
	local net="$2"
	local net_range
	local octet_range

	IFS='.' read -ra net_octet <<<"$net"
	IFS='.' read -ra wildcard_octet <<<"$wildcard_mask"

	for i in {0..3}; do
		if [ "${wildcard_octet[i]}" -gt 0 ]; then
			octet_range="{0..${wildcard_octet[i]}}"
		else
			octet_range="${net_octet[i]}"
		fi
		net_range="${net_range}${net_range:+.}${octet_range}"
	done

	echo "$net_range"
}

is_valid_ip() {
	local ip="$1"

	IFS='.' read -ra ip_octet <<<"$ip"

	# An IP must always be 4 octes
	if [ ${#ip_octet[@]} -ne 4 ]; then
		return 1
	fi

	for i in {0..3}; do
		# Check if the octet is a number
		if [ -n "${ip_octet[i]//[0-9]/}" ]; then
			return 1
		# The octet must be between 0 and 255
		elif [ "${ip_octet[i]}" -gt 255 ] || [ "${ip_octet[i]}" -lt 0 ]; then
			return 1
		fi
	done

	return 0
}

die() {
	echo "Error: $*" >&2
	exit 1
}

usage() {
	cat <<EOF
Usage:
$(basename "$0") [OPTIONS] NETWORK
  -r,--print-ip-range   Print all IPs in the range, one per line.
  -h,--help             Print this help message.

NETWORK is an IP and a prefix or netmark separated with a slash. For example:
- 192.168.0.1/24
- 192.168.0.1/255.255.255.0
EOF

}

# Set default values for options
print_ip_range="${PRINT_IP_RANGE=false}"

# Process all the command line options
while [ $# -gt 0 ]; do
	case $1 in
	# Two hyphens ends the options parsing
	--)
		shift
		break
		;;
	-h | --help)
		usage
		exit
		;;
	-r | --print-ip-range) print_ip_range=true ;;
	# Anything remaining that starts with a dash triggers a fatal error
	-?*)
		usage
		die "Option '$1' is unknown"
		;;
	# Anything remaining is treated as content not a parseable option
	*)
		break
		;;
	esac
	shift
done

for network in "$@"; do
	# Address
	address=${network%%/*}
	if ! is_valid_ip "$address"; then
		die "Invalid IP: $address"
	fi
	addressBin=$(ip_to_binary "$address")

	# Prefix/netmask
	prefix=${network##*/}
	if is_valid_ip "$prefix"; then
		netmaskBin=$(ip_to_binary "$prefix")
	elif [ -z "${prefix//[0-9]/}" ]; then
		netmaskBin=$(prefix_to_netmaskBin "$prefix")
	else
		die "Invalid prefix or netmask: $prefix"
	fi
	netmaskDec=$(binary_to_ip "$netmaskBin")

	# Wildcard
	wildcard_mask=$(netmaskBin_to_wildcard "$netmaskBin")
	wildcard_maskBin=$(ip_to_binary "$wildcard_mask")
	wildcard_zeros=${wildcard_maskBin//[ 1]/}
	prefix=${#wildcard_zeros}

	# IP range list
	ip_with_range=$(generate_bash_range "$wildcard_mask" "$address")
	ip_list=($(eval echo "$ip_with_range"))
	broadcast=${ip_list[-1]}

	if [ ${#ip_list[@]} -gt 2 ]; then
		number_of_hosts=$((${#ip_list[@]} - 2))
	else
		# This isn't really a network
		number_of_hosts=1
	fi

	cat <<-EOF
		Address (dec): $address
		Address (bin): $addressBin
		Wildcard mask (dec): $wildcard_mask
		Wildcard mask (bin): $wildcard_maskBin
		Netmask (dec): $netmaskDec
		Netmask (bin): $netmaskBin
		Prefix: $prefix
		Number of hosts: $number_of_hosts
		CIDR: ${ip_list[0]}/${prefix}
		Broadcast: $broadcast
	EOF

	if [[ $print_ip_range == true ]]; then
		for ip in "${ip_list[@]}"; do
			echo "$ip"
		done
	fi

	echo
done
