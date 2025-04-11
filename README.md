# ConvCoTM-FPGA-28x28

This repository includes VHDL code for an FPGA implementation of a Convolutional Coalesced Tsetlin Machine (ConvCoTM)-based Image Classification Accelerator with On-Device Training. The design has been implemented and verified on an AMD/Xilinx ZCU104 FPGA development board, The Design tools used are AMD Vivado 2022.2 and Vitis 2022.2. Use of the FPGA's DMA functionality was highly inspired by Youtube videos provided by Vipin Kizheppatt: https://www.youtube.com/@Vipinkmenon/videos.

The FPGA block diagram, some FPGA IP module configuration specifications and a C-program for operating the accelerator are included.

The design is described in the paper <i>"Tsetlin Machine-Based Image Classification FPGA Accelerator With On-Device Training"</i> in 
IEEE Transactions on Circuits and Systems I: Regular Papers: https://ieeexplore.ieee.org/document/10812055.   

In https://doi.org/10.48550/arXiv.2108.07594 the Coalesced Tsetlin Machine (CoTM) is presented.

The MNIST data samples included in this repository, are booleanized by simple thresholding: Pixel values above 75 are set to 1, and to 0 otherwise. The original MNIST dataset is found at https://yann.lecun.com/exdb/mnist/. Each booleanized MNIST image requires 98 bytes plus one byte for the label. In addition, 29 bytes of value 0 have been added to each sample, totalling 128 bytes per image, which is necessary for the reading of image data via the DMA for this FPGA configuration.

The VHDL coding style is based on Appendix A in <i>Digital Design Using VHDL: A Systems Approach</i>, Dally William J. Harting R. Curtis Aamodt Tor M., Cambrige University Press, 2016. In particular, the principle that <i>"All state should be in explicitly declared registers"</i> has been carefully followed.

## Related work

The repository at https://github.com/satunheim/ConvCoTM_Inference_Accelerator includes the source code for an ASIC implementation of a ConvCoTM-based image classification accelerator, described in the paper <i>An All-digital 8.6-nJ/Frame 65-nm Tsetlin Machine Image Classification Accelerator</i> at https://arxiv.org/abs/2501.19347. The inference part of the ASIC is based on the FPGA solution in the current repository.

In the article <i>Model Export for the Convolutional Coalesced Tsetlin Machine</i>, available at 
https://ieeexplore.ieee.org/document/10455048, it is described how to export a model from a trained ConvCoTM from the Tsetlin Machine Unified (TMU) GitHub repository: https://github.com/cair/tmu. 