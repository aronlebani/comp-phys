#!/usr/bin/env julia

# TODO: get sun data from horizons instead of assuming it's zero
# TODO: option to plot orbits rather than animate
# TODO: compare with horizons data
# TODO: read data from file

using GLMakie

# Units: length [au], speed [au/day], mass [10^24kg]
# 1 au = 149597870.700 km
# 1 day = 86400.0 s

r0 = [0.0, 0.0, 0.0]
r1 = [-3.402601730088687E-01, 1.257380156009652E-01, 4.129040039622117E-02]
r2 = [6.279426619259824E-01, -3.562033725630361E-01, -4.130359917159482E-02]
r3 = [-9.869590552630176E-01, -2.013971933355488E-01, 2.221166323008200E-04]
r4 = [9.323469172397169E-01, -1.028657114522833E+00, -4.433183072193011E-02]
r5 = [2.954696103674583E+00, 4.028931681704677E+00, -8.281906108005221E-02]
r6 = [9.141819155576036E+00, -3.246210197126632E+00, -3.075366872946332E-01]
r7 = [1.197915465347892E+01, 1.550207278454441E+01, -9.761728478456538E-02]
r8 = [2.984889928791262E+01, -1.506893245412775E+00, -6.568665962198431E-01]
r9 = [1.745740062908738E+01, -3.026244415471665E+01, -1.811454296537819E+00]

v0 = [0.0, 0.0, 0.0]
v1 = [-1.598667710740211E-02, -2.503512357722125E-02, -5.785842341945019E-04]
v2 = [9.702477953335994E-03, 1.759438539039441E-02, -3.178680652927808E-04]
v3 = [3.132919374915658E-03, -1.693485245568787E-02, 8.593334598140016E-07]
v4 = [1.084948762876459E-02, 1.064791821102798E-02, -4.276831224893623E-05]
v5 = [-6.168961029575225E-03, 4.820989357997514E-03, 1.180234156599592E-04]
v6 = [1.555666076098922E-03, 5.246164204536639E-03, -1.531613280803843E-04]
v7 = [-3.141074462615362E-03, 2.221635798541796E-03, 4.894306671264082E-05]
v8 = [1.375319161300344E-04, 3.153758735666645E-03, -6.811529860056854E-05]
v9 = [2.801110724872505E-03, 8.788160093271012E-04, -9.042855319117322E-04]

m0 = 1990000
m1 = 0.330
m2 = 4.87
m3 = 5.97
m4 = 0.642
m5 = 1898
m6 = 568
m7 = 86.8
m8 = 102
m9 = 0.0130

const G = 1.487E-10 # au^3.(10^24)kg^-1.day^-2

const Vector3d = Vector{Float64}

mutable struct Body
	r::Vector3d
	v::Vector3d
	mass::Float64
end

function gravitation_1d(x::Int, i::Int, bodies::Array{Body})::Float64
	nbodies = length(bodies)
	sum = 0.0

	for j = 1:nbodies
		j == i && continue

		dist = sqrt(
			(bodies[j].r[1] - bodies[i].r[1])^2 +
			(bodies[j].r[2] - bodies[i].r[2])^2 +
			(bodies[j].r[3] - bodies[i].r[3])^2
		)
		sum = sum + bodies[j].mass * (bodies[j].r[x] - bodies[i].r[x]) / dist^3
	end

	G * sum
end

function gravitation(i::Int, bodies::Array{Body})::Vector3d
	[gravitation_1d(x, i, bodies) for x = 1:3]
end

function position(body::Body, a::Vector3d, dt::Float64)::Vector3d
	[body.r[x] + body.v[x] * dt + 0.5 * a[x] * dt^2 for x = 1:3]
end

function velocity(body::Body, a1::Vector3d, a2::Vector3d, dt::Float64)::Vector3d
	[body.v[x] + 0.5 * (a1[x] + a2[x]) * dt for x = 1:3]
end

function leapfrog(bodies::Array{Body}, dt::Float64)
	working_bodies = bodies
	nbodies = length(working_bodies)

	a1 = [gravitation(i, working_bodies) for i = 1:nbodies]
	[working_bodies[i].r = position(working_bodies[i], a1[i], dt) for i = 1:nbodies]
	a2 = [gravitation(i, working_bodies) for i = 1:nbodies]
	[working_bodies[i].v = velocity(working_bodies[i], a1[i], a2[i], dt) for i = 1:nbodies]

	working_bodies
end

function main()
	bodies = Observable([
		Body(r0, v0, m0),
		Body(r1, v1, m1),
		Body(r2, v2, m2),
		Body(r3, v3, m3),
		Body(r4, v4, m4),
		Body(r5, v5, m5),
		Body(r6, v6, m6),
		Body(r7, v7, m7),
		Body(r8, v8, m8),
		Body(r9, v9, m9),
	])

	dt = 1.0

	nbodies = length(bodies[])

	x = @lift([$bodies[i].r[1] for i = 1:nbodies])
	y = @lift([$bodies[i].r[2] for i = 1:nbodies])
	z = @lift([$bodies[i].r[3] for i = 1:nbodies])

	figure = Figure()
	axis = Axis3(figure[1, 1], aspect = :data, limits = (-30.0, 30.0, -30.0, 30.0, -2.0, 2.0))
	scatter!(axis, x, y, z)
	display(figure)

	for step = 1:365
		sleep(0.03)
		bodies[] = leapfrog(bodies[], dt)
	end

	println("Press any key to exit...")
	readline()
end


if abspath(PROGRAM_FILE) == @__FILE__
	main()
end
