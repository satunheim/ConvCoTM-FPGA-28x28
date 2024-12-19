# ConvCoTM
VHDL code and C-program for an FPGA implementation of a Convolutional Coalesced Tsetlin Machine (ConvCoTM)-based Image Classification Accelerator with On-Device Training.

The design has been implemented and verified on a AMD/Xilinx ZCU104 FPGA development board. Design tools used are AMD Vivado 2022.2 and Vitis 2022.2.

The design is described in the paper: TBD
DOI	: 
Weblink	:

The Coalesced Tsetlin Machine (CoTM) is described in: 
https://doi.org/10.48550/arXiv.2108.07594

The MNIST data samples are booleanized according to the procedure described in the papers above: Simple thresholding is applied, where pixel values above 75 are set to 1 and 0  otherwise.
  
