#!/usr/bin/env julia

using Base.Threads
using GLMakie
using TOML

function read_settings_from_file(file)
	raw = TOML.parsefile(file)

	density = haskey(raw, "density") ? raw["density"] : 1000
	iterations = haskey(raw, "iterations") ? raw["iterations"] : 100

	x_min = haskey(raw, "x_min") ? raw["x_min"] : -2.0
	x_max = haskey(raw, "x_max") ? raw["x_max"] : 2.0
	y_min = haskey(raw, "y_min") ? raw["y_min"] : -2.0
	y_max = haskey(raw, "y_max") ? raw["y_max"] : 2.0

	((x_min, x_max), (y_max, y_min), density, iterations)
end

function range_from_bounds(bound)
	range(bound[1], bound[2], length=density)
end

function mandelbrot(x, y)
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

function compute_z(x, y)
	[mandelbrot(i, j) for i in x, j in y]
end

function compute_z_threaded(x, y)
	res = Array{Int}(undef, density, density)

	@threads for t = 1:n_threads
		for i = 1:segment_height
			ii = i + (t - 1) * segment_height
			for j = 1:density
				try
					# The last segment might take up more indices than are left
					# if density is not a multiple of nthreads().
					res[ii, j] = mandelbrot(x[ii], y[j])
				catch BoundsError
					break
				end
			end
		end
	end

	res
end

x_bound, y_bound, density, iterations = read_settings_from_file(ARGS[1])

# Cache number of threads so we don't have to calculate it on each
# iteration.
n_threads = nthreads()

# Round up in case density is not an even multiple of nthreads(). This way
# we'll overshoot the bounds rather than falling short (see comment below).
segment_height::Int = ceil(density / n_threads)

x = Observable(range_from_bounds(x_bound))
y = Observable(range_from_bounds(y_bound))
z = lift(compute_z_threaded, x, y)

figure, axis = heatmap(x, y, z, colormap = Reverse(:deep))
display(figure)

on(events(figure).scroll, priority = 10) do _
	x[] = range_from_bounds(axis.xaxis.attributes.limits[])
	y[] = range_from_bounds(axis.yaxis.attributes.limits[])
end

println("Press any key to exit...")
readline()
