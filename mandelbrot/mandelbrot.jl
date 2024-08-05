#!/usr/bin/env julia

using Base.Threads
using Observables
using GLMakie
using TOML

struct Settings
	x_bound::Tuple{Float64, Float64}
	y_bound::Tuple{Float64, Float64}
	density::Int
	iterations::Int
end

function usage()
	println("Usage: julia $(PROGRAM_FILE) [OPTIONS] datafile")
end

function read_settings_from_file(file)
	raw = TOML.parsefile(file)

	density = haskey(raw, "density") ? raw["density"] : 1000
	iterations = haskey(raw, "iterations") ? raw["iterations"] : 100

	x_min = haskey(raw, "x_min") ? raw["x_min"] : -2.0
	x_max = haskey(raw, "x_max") ? raw["x_max"] : 2.0
	y_min = haskey(raw, "y_min") ? raw["y_min"] : -2.0
	y_max = haskey(raw, "y_max") ? raw["y_max"] : 2.0

	Settings((x_min, x_max), (y_min, y_max), density, iterations)
end

function range_from_bounds(bound, density)
	range(bound[1], bound[2], length=density)
end

function mandelbrot(x, y, iterations)
	i = 0
	z = 0
	c = x + y * im

	while true
		i = i + 1
		z = z^2 + c

		abs(z) > 2 && return i
		i > iterations && return 0
	end
end

function compute_z_threaded(x, y, density, iterations, n_threads)
	res = Array{Int}(undef, density, density)

	# Round up in case density is not an even multiple of n_threads. This way
	# we'll overshoot the bounds rather than falling short (see comment below).
	segment_height::Int = ceil(density / n_threads)

	@threads for t = 1:n_threads
		for i = 1:segment_height
			ii = i + (t - 1) * segment_height
			for j = 1:density
				try
					# The last segment might take up more indices than are left
					# if density is not a multiple of nthreads().
					res[ii, j] = mandelbrot(x[ii], y[j], iterations)
				catch BoundsError
					break
				end
			end
		end
	end

	res
end

function main(file)
	settings = read_settings_from_file(file)

	n_threads = nthreads()

	figure = Figure()
	axis = Axis(figure[1, 1], aspect = DataAspect())

	density = Observable(settings.density)
	iterations = Observable(settings.iterations)
	x_bound = Observable(settings.x_bound)
	y_bound = Observable(settings.y_bound)

	x = @lift(range_from_bounds($x_bound, $density))
	y = @lift(range_from_bounds($y_bound, $density))
	z = @lift(compute_z_threaded($x, $y, $density, $iterations, n_threads))

	heatmap!(axis, x, y, z, colormap = Reverse(:deep))

	on(events(figure).scroll, priority = 10) do _
		x_bound[] = axis.xaxis.attributes.limits[]
		y_bound[] = axis.yaxis.attributes.limits[]
	end
	
	display(figure)
	println("Press any key to exit...")
	readline()
end

if abspath(PROGRAM_FILE) == @__FILE__
	if length(ARGS) == 0
		usage()
		exit(1)
	end

	main(ARGS[1])
end
