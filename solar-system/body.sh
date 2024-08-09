#!/usr/bin/env bash

# body.sh
#
# Helper script to fetch body data for each planet from the JPL Horizons
# system. See ./jpl-horizons.exp.
#
# Works the same as ./ephemeris.sh, but queries the body data instead of the
# ephemeris data. It dumps the data into the `bodies` directory, and greps for
# mass and radius.
#
# Aron Lebani <aron@lebani.dev>

extract_mass() {
	re="Mass[, ]*x10\^[0-9]{2} \(kg\)[ ]*=[ ]*[.0-9]+"

	raw=$(cat "$1" | grep -E -o -i -m1 "$re")
		
	val=$(echo "$raw" | sed "s/ //g" | cut -d "=" -f2 | cut -d "+" -f1)
	exp=$(echo "$raw" | cut -d "x" -f2 | cut -d " " -f1 | sed "s/10^//g")

	echo "$val"E"$exp"
}

extract_radius() {
	re="Vol. Mean Radius \(km\)[ ]*=[ ]*[.0-9]+"

	cat "$1" \
		| grep -E -o -i -m1 "$re" \
		| sed "s/ //g" \
		| cut -d "=" -f2 \
		| cut -d "+" -f1
}

query() {
	data_file="./bodies/$1.txt"

	# Fetch body data for each planet using the jpl-horizons script
	#
	echo "Querying body data for <$1>"
	if [ ! -f "$data_file" ]; then
		./jpl-horizons.exp --body "$1" "$data_file"
	else
		echo "...already exists"
	fi
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

echo "Mass:"
for id in "${ids[@]}"; do
	data_file="./bodies/$id.txt"
	extract_mass "$data_file"
done

echo "Radius:"
for id in "${ids[@]}"; do
	data_file="./bodies/$id.txt"
	extract_radius "$data_file"
done
