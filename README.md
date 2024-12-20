# ConvCoTM-FPGA-28x28
VHDL code and C-program for an FPGA implementation of a Convolutional Coalesced Tsetlin Machine (ConvCoTM)-based Image Classification Accelerator with On-Device Training.

The design has been implemented and verified on a AMD/Xilinx ZCU104 FPGA development board. Design tools used are AMD Vivado 2022.2 and Vitis 2022.2.

The design is described in the paper: TBD  
DOI	:   
Weblink	:  

The Coalesced Tsetlin Machine (CoTM) is described in:   
https://doi.org/10.48550/arXiv.2108.07594  

The MNIST data samples are booleanized by simple thresholding, i.e., pixel values above 75 are set to 1 and to 0 otherwise.

The VHDL coding style applied is based on the book "Digital Design Using VHDL: A Systems Approach" by William J. Dally, R. Curtis Harting, and Tor M. Aamodt, Cambridge University Press, 2016. In particular, the principle that "All state should be in explicitly declared registers" has been carefully followed.