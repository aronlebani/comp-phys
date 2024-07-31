#!/usr/bin/env python3

from numpy import arange

y_lower = -1.2
y_upper = 1.2
y_step = 0.05

x_lower = -2.05
x_upper = 0.55
x_step = 0.03

def mandelbrot(c):
    z = 0
    for n in range(10):
        z = z*z + c
        if(abs(z) > 2):
            return "."
    return "*"
  
s = ""
for y in arange(y_lower, y_upper, y_step):
    for x in arange(x_lower, x_upper, x_step):
        s += mandelbrot(complex(x,y))
    s += "\n"
  
print(s)
