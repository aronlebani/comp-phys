# nbody

Software for solving and simulating the gravitational nbody problem.

## Usage

To run the simulation with the provided configuration file,

    julia nbody planets.toml

## Querying data from Horizons

`jpl-horizons.exp`

This is the script that automates a telnet session to extract data from the JPL
Horizons database.

`planets.txt`

A list of planet-moon barycenter Ids from the Horizons database. Used as input
to the `ephemeris.sh` and `body.sh` scripts to query ephemeris and body data.

`moons.txt`

A list of planet and moon Ids from the Horizons database. Used as input to the
`ephemeris.sh` and `body.sh` scripts to query ephemeris and body data.

`ephemeris.sh`

Uses the `jpl-horizons.exp` script to query ephemeris data given a list of body
ids.

`body.sh`

Uses the `jpl-horizons.exp` script to query body data given a list of body
ids.

Examples:

    ephemeris.sh planets.txt
