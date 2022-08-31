# Polyphase FIR Filter

Verilog written Raised Cosine Polyphase transmitter filter for fpga implementation.
Includes a 9 bit pseudo random bit sequence generator for testing purposes.
Filter coefficients are obtained from jupyter simulation file. Baud period, number of bauds, oversampling factor can be modified in order to get a different frequency/impulse response and hence different coefficients.
Simulation implements fixed point arithmetic using _fixedInt.py module from deModel library.
The deModel library is free software. It can be redistributed and/or modified under the terms of the GNU Lesser General Public License as published by the Free Software Foundation.
