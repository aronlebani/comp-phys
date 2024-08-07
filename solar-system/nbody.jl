#!/usr/bin/env julia

using GLMakie
using TOML

function usage()
	println("Usage: julia $(PROGRAM_FILE) [OPTIONS] datafile")
end

const G = 1.487E-10	# au^3.(10^24)kg^-1.day^-2

const Vector3d = Vector{Float64}

struct Body
	r::Vector3d
	v::Vector3d
	m::Float64
end

struct Settings
	# Initial values for the positions of the bodies.
	r_init::Array{Vector3d}

	# Initial values for the velocities of the bodies.
	v_init::Array{Vector3d}

	# Masses of the bodies.
	m::Array{Float64}

	# Relative sizes of the bodies.
	# See <https://docs.makie.org/stable/reference/plots/scatter#markersize>
	# for an explanation of marker sizes.
	sizes::Array{Float64}

	# Colours of the bodies.
	colours::Array{String}

	# The step size, representing a time interval.
	dt::Float64

	# The number of iterations, representing the total time to run the
	# simulation over.
	iterations::Int

	# Delay between calculating steps. This is used so that the plot appears
	# to animate. Otherwise it will happen too quickly to see anything.
	delay::Float64

	# The number of bodies to simulate. Must be <= length(r_init).
	nbodies::Int

	# The body sizes are scaled by this number. Pick something that makes
	# the simulation look nice.
	scale_factor::Float64
end

function read_settings_from_file(file)
	raw = TOML.parsefile(file)

	m			 = raw["m"]
	r_init		 = raw["r_init"]
	v_init		 = raw["v_init"]
	nbodies		 = haskey(raw, "nbodies") ? raw["nbodies"] : length(r_init)
	dt			 = haskey(raw, "dt") ? raw["dt"] : 1.0
	sizes		 = haskey(raw, "sizes") ? raw["sizes"] : []
	colours		 = haskey(raw, "colours") ? raw["colours"] : []
	delay		 = haskey(raw, "delay") ? raw["delay"] : 0.03
	iterations   = haskey(raw, "iterations") ? raw["iterations"] : 365
	scale_factor = haskey(raw, "scale_factor") ? raw["scale_factor"] : 1.0

	Settings(r_init, v_init, m, sizes, colours, dt, iterations, delay,
		nbodies, scale_factor)
end

function gravitation(i::Int, bodies::Array{Body})::Vector3d
	# Calculates the acceleration of the body at index i in bodies due to the
	# gravitational force of the other bodies.

	nbodies = length(bodies)

	gravitation_1d = (x) -> begin
		sum = 0.0

		for j = 1:nbodies
			j == i && continue

			dist = sqrt(
				(bodies[j].r[1] - bodies[i].r[1])^2 +
				(bodies[j].r[2] - bodies[i].r[2])^2 +
				(bodies[j].r[3] - bodies[i].r[3])^2
			)
			sum = sum + bodies[j].m * (bodies[j].r[x] - bodies[i].r[x]) / dist^3
		end

		G * sum
	end
	
	[gravitation_1d(x) for x = 1:3]
end

function leapfrog(bodies::Array{Body}, dt::Float64)
	# Solves the n-body problem using the leapfrog method. Models the system of
	# equations:
	#
	#	v = dx / dt
	#	a = f(x) / m
	#
	# where f is the graviational force on body i due to all the other bodies.
	# The leapfrog method is better at conserving energy over time than other
	# integration methods, but only works for the special case where the
	# acceleration is dependent only on position (which is the case for the
	# graviational n-body problem). For more information on leapfrog
	# integration, see <https://en.wikipedia.org/wiki/Leapfrog_integration>.
	
	nbodies = length(bodies)

	force = (i, body) -> gravitation(i, bodies)

	position = (body, a) ->
		[body.r[x] + body.v[x] * dt + 0.5 * a[x] * dt^2 for x = 1:3]

	velocity = (body, a1, a2) ->
		[body.v[x] + 0.5 * (a1[x] + a2[x]) * dt for x = 1:3]

	a = [force(i, bodies) for i = 1:nbodies]
	r_new = [position(bodies[i], a[i]) for i = 1:nbodies]
	a_new = [force(i, bodies) for i = 1:nbodies]
	v_new = [velocity(bodies[i], a[i], a_new[i]) for i = 1:nbodies]

	[Body(r_new[i], v_new[i], bodies[i].m) for i in 1:nbodies]
end

function get_limits(r)
	# Calculates the plot limits, by finding the largest orbital radius
	# from the initial position vectors. Multiplies by a factor of 1.1 since
	# orbits are elliptical and the body might not be at it's major axis at
	# t = 0.
	
	rs = [sqrt(r[i][1]^2 + r[i][2]^2 + r[i][3]^2) for i = 1:length(r)]
	zs = [abs(r[i][3]) for i = 1:length(r)]

	max_r = 1.1 * maximum(rs)
	max_z = 1.1 * maximum(zs)

	(-max_r, max_r, -max_r, max_r, -max_z, max_z)
end

function simulate(settings::Settings)
	# Runs the simulation with the provided settings.
	
	nbodies		 = settings.nbodies
	m			 = settings.m[1:nbodies]
	r_init		 = settings.r_init[1:nbodies]
	v_init		 = settings.v_init[1:nbodies]
	sizes		 = settings.sizes[1:nbodies]
	colours		 = settings.colours[1:nbodies]
	dt			 = settings.dt
	delay		 = settings.delay
	iterations	 = settings.iterations
	scale_factor = settings.scale_factor

	bodies = Observable([Body(r_init[i], v_init[i], m[i]) for i = 1:nbodies])

	x = @lift([$bodies[i].r[1] for i = 1:nbodies])
	y = @lift([$bodies[i].r[2] for i = 1:nbodies])
	z = @lift([$bodies[i].r[3] for i = 1:nbodies])

	figure = Figure()
	axis = Axis3(figure[1, 1], aspect = :data, limits = get_limits(r_init))
	scatter!(axis, x, y, z, color = colours, markersize = sizes .* scale_factor)
	display(figure)

	for step = 1:iterations
		sleep(delay)
		bodies[] = leapfrog(bodies[], dt)
	end

	println("Press any key to exit...")
	readline()
end

if abspath(PROGRAM_FILE) == @__FILE__
	if length(ARGS) == 0
		usage()
		exit(1)
	end

	settings = read_settings_from_file(ARGS[1])

	if settings.nbodies > length(settings.r_init)
		println("nbodies must be <= length(r_init)")
		exit(1)
	end

	if length(settings.r_init) !=
		length(settings.v_init) !=
		length(settings.m) !=
		length(settings.sizes) !=
		length(settings.colours)
		println("r_init, v_init, m, sizes, colours must have the same length")
		exit(1)
	end

	simulate(settings)
end
