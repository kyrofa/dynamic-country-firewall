#!/bin/bash

# Check parameters
if [ $# -lt 3 ]; then
	echo "Usage: $0 ip_set_name database_file interface"
	exit 0;
else
	IPSET_NAME=$1
	DATABASE_FILE=$2
	INTERFACE=$3

	if [ ! -f "$DATABASE_FILE" ]; then
		echo "Database file doesn't exist!"
		exit 1
	fi

	# Attempt to create network. If that succeeds, add it as the first
	# rule in IPTABLES
	echo "Making sure ipset is created..."
	/usr/sbin/ipset create $IPSET_NAME hash:net &> /dev/null 
	if [ $? == 0 ]; then
		# Drop traffic from any IP address not in the whitelist set
		echo "Adding ipset to first place in INPUT chain..."
		/sbin/iptables -I INPUT 1 -m set ! --match-set $IPSET_NAME src -i $INTERFACE -j DROP
	fi
	
	# Create temporary set
	TEMPORARY_SET=${IPSET_NAME}_${RANDOM}
	/usr/sbin/ipset create $TEMPORARY_SET hash:net
	if [ $? != 0 ]; then
		echo "Unable to create temporary set!"
		exit 2
	fi

	echo "Adding local networks to ipset..."
	/usr/sbin/ipset add $TEMPORARY_SET 10.0.0.0/8
	/usr/sbin/ipset add $TEMPORARY_SET 172.16.0.0/12
	/usr/sbin/ipset add $TEMPORARY_SET 192.168.0.0/16

	echo "Loading database into ipset..."
	# Parse database file and add every network into temporary set
	while read LINE
	do
		/usr/sbin/ipset add $TEMPORARY_SET $LINE
		if [ $? != 0 ]; then
			echo "Unable to add network $LINE to set $TEMPORARY_SET!"
			# Remove temporary set
		        /usr/sbin/ipset -X $TEMPORARY_SET
			exit 3
		fi
	done < $DATABASE_FILE

	# Move the temporary set into the desired set
	echo "Activating ipset..."
	/usr/sbin/ipset swap $IPSET_NAME $TEMPORARY_SET

	# Remove temporary set
	echo "Cleaning up..."
	/usr/sbin/ipset -X $TEMPORARY_SET

	echo "Done."

	exit 0;
fi
