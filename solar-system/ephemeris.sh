#!/usr/bin/env bash

# ephemeris.sh
#
# Helper script to fetch ephemeris data for each planet from the JPL
# Horizons system. See ./jpl-horizons.
#
# Aron Lebani <aron@lebani.dev>

# The object Ids for the barycenter each of the planets n the JPL Horizons
# system. We use the barycenters of each planet because otherwise the results
# contain oscillations of e.g. the earth relative to the earth-moon barycenter.
#
mercury=1
venus=2
earth=3
mars=4
jupiter=5
saturn=6
uranus=7
neptune=8
pluto=9		# I still love you

planets=(
	"$mercury"
	"$venus"
	"$earth"
	"$mars"
	"$jupiter"
	"$saturn"
	"$uranus"
	"$neptune"
	"$pluto"
)

extract_coord() {
	re=" $1 {0,1}= {0,1}[+-.E0-9]+"

	cat "$2" \
		| grep -E -o -m1 "$re" \
		| sed "s/ //g" \
		| cut -d "=" -f2
}

for planet in "${planets[@]}"; do
	data_file="./data/$planet.txt"

	# Fetch ephemeris data for each planet using the jpl-horizons script
	#
	if [ ! -f "$data_file" ]; then
		./jpl-horizons "$planet" "$data_file"
	fi

	# Parse data and extract position and velocity vectors
	#
	x=$(extract_coord 'X' "$data_file")
	y=$(extract_coord 'Y' "$data_file")
	z=$(extract_coord 'Z' "$data_file")
	vx=$(extract_coord 'VX' "$data_file")
	vy=$(extract_coord 'VY' "$data_file")
	vz=$(extract_coord 'VZ' "$data_file")

	echo "r$planet = [$x, $y, $z]"
	echo "v$planet = [$vx, $vy, $vz]"
done
