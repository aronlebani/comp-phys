#!/usr/bin/env julia

f = open("data/1.txt", "r")
raw = read(f)

start_delim = "\$\$SOE"
end_delim = "\$\$EOE"
data = split(split(raw, start_delim)[2], end_delim)[1]

x_re = r" X \=[ \-\.E0-9]+ "
