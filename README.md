# ConvCoTM-FPGA-28x28

This repository includes VHDL code for an FPGA implementation of a Convolutional Coalesced Tsetlin Machine (ConvCoTM)-based Image Classification Accelerator with On-Device Training. The design has been implemented and verified on an AMD/Xilinx ZCU104 FPGA development board. Design tools used are AMD Vivado 2022.2 and Vitis 2022.2. FPGA block diagram, some FPGA IP module configuration specifications and C-program for operating the accelerator are also included.

The design is described in the following paper in 
IEEE Transactions on Circuits and Systems I: Regular Papers: https://ieeexplore.ieee.org/document/10812055 <br/>
DOI: 10.1109/TCSI.2024.3519191   

The Coalesced Tsetlin Machine (CoTM) is described in: https://doi.org/10.48550/arXiv.2108.07594  

The MNIST data samples included in this reposotory, are booleanized by simple thresholding. I.e., pixel values above 75 are set to 1 and to 0 otherwise. The original MNIST dataset is found at https://yann.lecun.com/exdb/mnist/.