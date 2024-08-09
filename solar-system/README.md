# n-body

Software for solving and simulating the gravitational n-body problem.

## Usage

Create a `.toml` file with the configuration data. The fields in the file
should match the fields in the `Config` struct in `nbody.jl`. Documentation
for the fields can be found there.

The provided `planets.toml` is an example configuration which models the
barycenters of the planets in the solar system. To run the simulation with
this configuration file:

    julia nbody.jl planets.toml

## Querying data from Horizons

Most of the scripts here are just utility scripts to automate querying data
from the Horizons database and grepping the relevant bits in order to build
the config files. Once you have a config file, that's all you need to actually
run the simulation (as described above). Documenation for each of these scripts
can be found in the scripts themselves.

`planets.txt` contains a list of planet-moon barycenter Ids from the Horizons
database. `ephemeris.sh` uses this file as input to query the Horizons database
and extract the position and velocity vectors at a specified date [^1]. It does
this by calling the `jpl-horizons` script, which does the actual querying by
automating a telnet sesson [^2]. `body.sh` is similar to `ephemeris.sh`, but it
extracts the body data (mass and radius).

Once you've got the position and velocity vectors at a given time, and the mass
and radii, you can use them to create the `.toml` config files for the
simulation.

## Examples

Query Horizons for all planet-moon barycenters, and get the position and
velocity vectors at a specified time.

    ephemeris.sh planets.txt

Run the simulation with the planet-moon barycenters.

    julia nbody.jl planets.toml

## Future work

I've started collecting data for all the moons in the solar system
(`moons.txt`, `moons.toml`), but a lot of them don't have masses in the
Horizons database. There are a LOT of moons, so I'm not sure how to automate
getting this data just yet... So the `moons.toml` config is incomplete at this
point.

[^1]: The date is currently hard-coded into the `jpl-horizons.exp` script.

[^2]: Horizons now has a nice API which can be used to query the database, and
    there are even third-party client libraries in various languages for the
    API. But I opted for the telnet interface because it was fun to learn about
    telnet, and how to automate interactive programs in unix.

