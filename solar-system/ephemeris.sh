#!/usr/bin/env bash

# ephemeris.sh
#
# Helper script to fetch ephemeris data for each planet from the JPL Horizons
# system. See ./jpl-horizons.exp. Takes as input a list of Ids from the JPL
# Horizons major-body database, or a file with each line representing a body in
# the form <name>=<id>. If no input is provided, reads from stdin. Queries
# ephemeris data for each body. For example:
#
#	./ephemeris.sh planets.txt
#	./ephemeris.sh 1 2 3
#	cat planets.txt | cut -d '=' -f2 | tr '\n' ' ' | ./ephemeris.sh
#
# Prints the position and velocity vectors to stdout. These can be used to
# create the configuration files for nbody.jl.
#
# Aron Lebani <aron@lebani.dev>

extract_coord() {
	re=" $1 {0,1}= {0,1}[+-.E0-9]+"

	cat "$2" \
		| grep -E -o -m1 "$re" \
		| sed "s/ //g" \
		| cut -d "=" -f2
}

query() {
	data_file="./ephemeris/$1.txt"

	# Fetch ephemeris data for each planet using the jpl-horizons script
	#
	echo "Querying ephemeris data for <$1>"
	if [ ! -f "$data_file" ]; then
		./jpl-horizons.exp --eph "$1" "$data_file"
	else
		echo "...already exists"
	fi
}

parse_pos() {
	data_file="./ephemeris/$1.txt"

	# Parse data and extract position vectors
	#
	x=$(extract_coord 'X' "$data_file")
	y=$(extract_coord 'Y' "$data_file")
	z=$(extract_coord 'Z' "$data_file")

	echo "[$x, $y, $z]"
}

parse_vel() {
	data_file="./ephemeris/$1.txt"

	# Parse data and extract velocity vectors
	#
	vx=$(extract_coord 'VX' "$data_file")
	vy=$(extract_coord 'VY' "$data_file")
	vz=$(extract_coord 'VZ' "$data_file")

	echo "[$vx, $vy, $vz]"
}

if [ -f "$1" ]; then
	ids=($(cat $1 | cut -d '=' -f2 | tr '\n' ' '))
elif [ "$#" -gt 1 ]; then
	ids=($@)
else
	read -a ids
fi

for id in "${ids[@]}"; do
	query "$id"
done

echo "Position vectors:"
for id in "${ids[@]}"; do
	parse_pos "$id"
done

echo "Velocity vectors:"
for id in "${ids[@]}"; do
	parse_vel "$id"
done
