#include <stdio.h>
#include "platform.h"
#include "xparameters.h"
#include "xil_printf.h"
#include "limits.h"
#include "xaxidma.h"
#include "sleep.h"
#include "xgpio.h"
#include <stdlib.h>
#include "xil_io.h"
#include<math.h>

#include "MNISTtrainDataSingleArray.h"
#include "MNISTtestDataSingleArray.h"

u32 checkHalted(u32 baseAddress, u32 offset);
u32 checkIdle(u32 baseAddress, u32 offset);

unsigned trainingsampleindex[60000] = {0};

long int TESTSAMPLES;
long int TRAININGSAMPLES;
long int sample;

int ActualAndPredicted, Actual, Predicted;
long int errors;
float accuracyTest;
float accuracyTestAverage;
float accuracyTestArray[100]={ 0.0 };

int EK; // For for loops
int randomdelay;
int NumberOfRuns;
int NumberOfEpochs;

int CoTMstatus;
int testloops_cont;
int testruns;
int MenuSelect;
long int imagebyteindex;
long int configurationword;
int selLFSR;

int epochseed;
unsigned Ntrainingsamples = sizeof(trainingsampleindex)/ sizeof(trainingsampleindex[0]);

u32 statusDMA;
u32 statusHalted;
u32 statusIdle;

/////////////////////////////////////////////////////////////////////////////////////////////////////////

XGpio MainControl;
XGpio Statusreg;
XGpio Result;
XGpio Configure;
XGpio LFSRselect;

XAxiDma_Config *myDmaConfig;
XAxiDma myDma;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

int main()
{
    init_platform();

    printf("\n");
    printf("----------------------------------------------- \n");
    printf("----------------------------------------------- \n");
    printf("Convolutional CoTM (ConvCoTM) accelerator for.\n");
    printf("classification of 28x28 Boolean images.\n");
    printf("Full on-device training is supported.\n");
    printf("Ready on Xilinx Zynq Ultrascale+ ZCU104! \n");
    printf("----------------------------------------------- \n");
    printf("----------------------------------------------- \n");
    printf("\n");

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    randomdelay = 0;
    TRAININGSAMPLES = 60000;
    TESTSAMPLES=10000;
    errors=0;
    NumberOfRuns=1;
    NumberOfEpochs=250;
    MenuSelect = 0;

    //////////////////////////////////////////////////////////////////////////
    while(1)
    {
		XGpio_Initialize(&MainControl, XPAR_AXI_GPIO_0_DEVICE_ID);
		XGpio_Initialize(&Statusreg, XPAR_AXI_GPIO_4_DEVICE_ID);
		XGpio_Initialize(&Result, XPAR_AXI_GPIO_2_DEVICE_ID);
		XGpio_Initialize(&Configure, XPAR_AXI_GPIO_1_DEVICE_ID);
		XGpio_Initialize(&LFSRselect, XPAR_AXI_GPIO_3_DEVICE_ID);

		XGpio_SetDataDirection(&Configure,1,0x00000000);
		XGpio_SetDataDirection(&Result,1,0xFF);
		XGpio_SetDataDirection(&MainControl,1,0x00);
			// Bit 0: Reset (active high)
			// Bit 1: Start
			// Bit 2: Learn
			// Bit 3: i_enLFSRs_init (used for setting the start time for operation of LFSRs - before initialization). Affects random setting of weights.
			// Bit 4: i_initialize
			// Bit 5: Not implemented: i_loadModel (model has to be initialized in RAM - from VHDL)
			// Bit 6: i_image_buffer_reset (should be reset before each training or test session)

			// Thus: We have the following commands:
			// -------------------------------------
			// Reset				:	Write 1
			// Start Inference		:   Write 2
			// Start Learning		:   Write 6
			// Enable LFSRs			:   Write 8
			// Initialize 			:   Write 24 (Both i_enLFSRs_init and i_initialize should be high)
			// Load Model			: 	Write 32 (Not implemented)
			// Reset Image Buffer	: 	Write 64 (Needed before a new session).


		XGpio_SetDataDirection(&LFSRselect,1,0x0);
			// LFSRselect = 000  => LFSR16
			// LFSRselect = 001  => LFSR24
			// LFSRselect = 010  => LFSR14
			// LFSRselect = 011  => LFSR12
			// LFSRselect = 100  => LFSR10
			// LFSRselect = 101  => LFSR9
			// LFSRselect = 110  => LFSR8
			// LFSRselect = 111  => LFSR7

		XGpio_SetDataDirection(&Statusreg,1,0xFF);
			// Bit 0: Initialstate
			// Bit 1: Finished Inference
			// Bit 2: Finished Learning
			// Bit 3: Finished Initialize
			// Bit 4: Finished load model
			// Bit 5: Finished write model  // Write model not implemented.

			////////////////////////////////////////////////////////////////////////////////////////////////////////////
			//DMA Controller Configuration

			myDmaConfig = XAxiDma_LookupConfigBaseAddr(XPAR_AXI_DMA_0_BASEADDR);

			statusDMA = XAxiDma_CfgInitialize(&myDma, myDmaConfig);
			if(statusDMA != XST_SUCCESS){
				printf("DMA initialization failed\n");
			}
			else {
				printf("DMA initialization succeeded\n");
			}

			///////////////////////////
			// MAIN Menu:

			configurationword = 0xffc02488; // default value
			XGpio_DiscreteWrite(&Configure,1,configurationword);

			selLFSR = 0x1; // default value (LFSR24)
			XGpio_DiscreteWrite(&LFSRselect,1,selLFSR);

			while (MenuSelect !=1 && MenuSelect !=2 && MenuSelect !=3 && MenuSelect !=4 && MenuSelect !=5 && MenuSelect !=6 && MenuSelect !=7)
			{
				printf(" \n");
				printf("----------------\n");
				printf("Main Menu:\n");
				printf("----------------\n");
				printf("1. Enter configuration word (default is: 0xffc02488)) \n");
				printf("2. TRAINING followed by single TEST\n");
				printf("3. TEST (single) \n");
				printf("4. Input number of epochs used for training (default is 250) \n");
				printf("5. TEST (long loop, for power measurement) \n");
				printf("6. Multiple runs in sequence (reset between each run) \n");
				printf("7. Enter LFSR selection word \n");
				printf(" \n");
				printf("Enter main menu selection: \n");
				scanf("%d", &MenuSelect);

				if (MenuSelect==1) {
					printf("Configuration bits: \n");
					printf("Bit  31-24: TA_threshold_high \n");
					printf("Bit  23-16: T hyperparameter \n");
					printf("Bit  15-8 : Max weight \n");
					printf("Bit 7-4   : s hyperparameter \n");
					printf("Bit 3     : 0 => 16 bit LFSR, 1 => 24 bit LFSR \n");
					printf("Bit 2-0   : Test (normally set to 0) \n");
					//printf("          : Bit 2 - not used \n");
					//printf("          : Bit 1 - set normally to 0 for special test mode - skip patch generation for Negative Target Class\n");
					//printf("          : Bit 0 - not used\n");
					printf("Enter configuration word (TA_threshold_high, T, weightMAX, s, '0' & test(3 bits) ) in hex: \n");
					printf("Default is: 0xffc02488) \n");
					// default is 0xffc02488
					scanf("%x", &configurationword);
					XGpio_DiscreteWrite(&Configure,1,configurationword);
					printf("Configuration word entered (hex): %x\n", configurationword);
					printf(" \n");
				   }
				else if (MenuSelect==2) {
					TrainCoTM();
					TestCoTM();
				}
				else if (MenuSelect==3) {
					TestCoTM();
				}
				else if (MenuSelect==4) {
					printf("------------------------------------- \n");
					printf("Number of training epochs?: \n");
					scanf("%d", &NumberOfEpochs);
					printf("------------------------------------- \n");
				}
				else if (MenuSelect==5) {
					// Perform many tests in a loop, for power measurement during this mode:
					printf("Number of test loops ?\n");
					scanf("%d", &testloops_cont);

					for(int i=0; i<testloops_cont; i++)
						{
						TestCoTM();
						}
					printf("Finished with test loops! \n");

				}
				else if (MenuSelect==6) {
					accuracyTestAverage=0.0;
					printf("------------------------------------- \n");
					printf("Number of runs ?\n");
					scanf("%d", &NumberOfRuns);

					for(int i=0; i<100; i++)
						{
						accuracyTestArray[i]=0.0;
						}

					for(int i=0; i<NumberOfRuns; i++)
						{
						printf("------------------------------------- \n");
						printf("Run no.: %d\n", i);
						printf("------------------------------------- \n");
						TrainCoTM();
						TestCoTM();
						accuracyTestAverage = accuracyTestAverage+accuracyTest;
						accuracyTestArray[i]=accuracyTest;
						}
					accuracyTestAverage = accuracyTestAverage/NumberOfRuns;

					printf("------------------------------------- \n");
					printf("All runs completed!\n");
					printf("Average test accuracy : %.2f\n", accuracyTestAverage);
					printf("Configuration word (hex) : %x\n", configurationword);
					printf("------------------------------------- \n");

					printf("Array of test accuracy results : \n");
					printf("--------------------------------\n");

					for(int i=0; i<NumberOfRuns; i++)
						{
						printf("%.2f\n", accuracyTestArray[i]);
						}
				}
				else if (MenuSelect==7) {
					printf("LFSR selection bits: \n");
					printf("LFSRselect = 0  => LFSR16 \n");
					printf("LFSRselect = 1  => LFSR24 \n");
					printf("LFSRselect = 2  => LFSR14 \n");
					printf("LFSRselect = 3  => LFSR12 \n");
					printf("LFSRselect = 4  => LFSR10 \n");
					printf("LFSRselect = 5  => LFSR9 \n");
					printf("LFSRselect = 6  => LFSR8 \n");
					printf("LFSRselect = 7  => LFSR7 \n");
					printf("Default is: 1 (24 bit LFSR) \n");

					// LFSRselect = 000  => LFSR16
					// LFSRselect = 001  => LFSR24
					// LFSRselect = 010  => LFSR14
					// LFSRselect = 011  => LFSR12
					// LFSRselect = 100  => LFSR10
					// LFSRselect = 101  => LFSR9
					// LFSRselect = 110  => LFSR8
					// LFSRselect = 111  => LFSR7

					scanf("%x", &selLFSR);
					XGpio_DiscreteWrite(&LFSRselect,1,selLFSR);

					printf("LFSR selection word entered (hex): %x\n", selLFSR);
					printf(" \n");
				   }

				else {

					MenuSelect = 0;
					// Do nothing - bring up main menu again.
				}

		MenuSelect = 0;


		} 	// belongs to while(MenuSelect)


    } 	// belongs to while(1)

    cleanup_platform();
    return 0;

} // End of main

//////////////////////////////////////////////////////////////////////////////////////////////

void TrainCoTM(void)
	{

    for(unsigned i=0; i<Ntrainingsamples; i++)
    	{
    	trainingsampleindex[i]=i;
    	}

	printf("------------------------------------- \n");
	printf("Start Training! \n");
	printf("------------------------------------- \n");

	// Perform Reset
	XGpio_DiscreteWrite(&MainControl,1,1); // set reset=1
	for(int i=0; i<=100; i++)
		{
		}
	XGpio_DiscreteWrite(&MainControl,1,0); // set reset=0

//Initialize
	randomdelay = rand();
	XGpio_DiscreteWrite(&MainControl,1,8);
	for(int i=0; i<=(randomdelay % 177); i++)
		{
		}
	XGpio_DiscreteWrite(&MainControl,1,24);

	CoTMstatus = XGpio_DiscreteRead(&Statusreg,1);
	while(CoTMstatus != 8) {
		CoTMstatus = XGpio_DiscreteRead(&Statusreg,1);
	}

	printf("Initialization of TAs and weights finished! \n");
	XGpio_DiscreteWrite(&MainControl,1,0);
	sleep(1);

	/////////////////////////////////////////////////////////////////////
	// Start training (with NumberOfEpochs) and testing:
	/////////////////////////////////////////////////////////////////////

	for(EK=0; EK<NumberOfEpochs; EK++)
		{

		// Perform Image Buffer Reset
		XGpio_DiscreteWrite(&MainControl,1,64);
		for(int i=0; i<=100; i++)
			{
			}
		XGpio_DiscreteWrite(&MainControl,1,0);

		imagebyteindex = trainingsampleindex[0];

		statusDMA = XAxiDma_SimpleTransfer(&myDma, (u32)&MNISTtrainData[imagebyteindex], 99, XAXIDMA_DMA_TO_DEVICE);

		if(statusDMA != XST_SUCCESS)
			{
				printf("DMA transfer failed - first sample\n");
			}

		statusIdle = checkIdle(XPAR_AXI_DMA_0_BASEADDR,0x4);
			while(statusIdle == 0){
				statusIdle = checkIdle(XPAR_AXI_DMA_0_BASEADDR,0x4);
			}

		for(sample=1; sample<TRAININGSAMPLES; sample++)
			{
				XGpio_DiscreteWrite(&MainControl,1,4);

				randomdelay = rand();
					for(int i=0; i<=(randomdelay % 29); i++)
						{
						}

				XGpio_DiscreteWrite(&MainControl,1,6);

				imagebyteindex = trainingsampleindex[sample]*99;

				statusDMA = XAxiDma_SimpleTransfer(&myDma, (u32)&MNISTtrainData[imagebyteindex], 99, XAXIDMA_DMA_TO_DEVICE);

				if(statusDMA != XST_SUCCESS){
					printf("DMA transfer failed\n");
					printf("Image index during fail: %ld\n", sample);
				}

				statusIdle = checkIdle(XPAR_AXI_DMA_0_BASEADDR,0x4);
					while(statusIdle == 0){
						statusIdle = checkIdle(XPAR_AXI_DMA_0_BASEADDR,0x4);
					}

				CoTMstatus = XGpio_DiscreteRead(&Statusreg,1);
				while(CoTMstatus != 4){
					CoTMstatus = XGpio_DiscreteRead(&Statusreg,1);
				}

				XGpio_DiscreteWrite(&MainControl,1,0); // Go to initialstate
			} // TRAININGSAMPLES

		// Processing the last training sample:
		XGpio_DiscreteWrite(&MainControl,1,4);
		XGpio_DiscreteWrite(&MainControl,1,6);

		CoTMstatus = XGpio_DiscreteRead(&Statusreg,1);
		while(CoTMstatus != 4){
			CoTMstatus = XGpio_DiscreteRead(&Statusreg,1);
		}
		XGpio_DiscreteWrite(&MainControl,1,0);

		//////////////////////////////
		// Shuffle indices:

		shuffle (trainingsampleindex, TRAININGSAMPLES);

		if(EK % 10 == 0)
			{
			printf("\n");
			printf("Results after epoch number: %ld\n", EK);
			TestCoTM();
			}

	} // Epochs
	printf("Training completed \n");
}

//////////////////////////////////////////////////////////////////////////
void TestCoTM(void)
{

    // Perform Image Buffer Reset
    XGpio_DiscreteWrite(&MainControl,1,64);
    for(int i=0; i<=100; i++)
    	{
    	}
    XGpio_DiscreteWrite(&MainControl,1,0);

	// Send first image test sample to the Accelerator:
    statusDMA = XAxiDma_SimpleTransfer(&myDma, (u32)&MNISTtestData[0], 99, XAXIDMA_DMA_TO_DEVICE);
	if(statusDMA != XST_SUCCESS){
		printf("DMA transfer failed first sample test\n");
	}

	statusIdle = checkIdle(XPAR_AXI_DMA_0_BASEADDR,0x4);
		while(statusIdle == 0){
			statusIdle = checkIdle(XPAR_AXI_DMA_0_BASEADDR,0x4);
		}

	errors=0;
	accuracyTest=0;

	for(sample=1; sample<TESTSAMPLES; sample++) {

		XGpio_DiscreteWrite(&MainControl,1,2);

	    statusDMA = XAxiDma_SimpleTransfer(&myDma, (u32)&MNISTtestData[sample*99], 99, XAXIDMA_DMA_TO_DEVICE);
		if(statusDMA != XST_SUCCESS){
			printf("DMA transfer failed, test sample in for loop\n");
			printf("Image index during fail: %ld\n", sample);
			printf("Image byteindex during fail: %ld\n", imagebyteindex);
		}

		statusIdle = checkIdle(XPAR_AXI_DMA_0_BASEADDR,0x4);
			while(statusIdle == 0){
				statusIdle = checkIdle(XPAR_AXI_DMA_0_BASEADDR,0x4);
			}

	CoTMstatus = XGpio_DiscreteRead(&Statusreg,1);
	while(CoTMstatus != 2){
		CoTMstatus = XGpio_DiscreteRead(&Statusreg,1);
	}

	ActualAndPredicted = XGpio_DiscreteRead(&Result,1);
	Actual = ActualAndPredicted >> 4;
	Predicted = ActualAndPredicted & 0x0F;
	if (Actual != Predicted) {
			errors = errors+1;
	}

	XGpio_DiscreteWrite(&MainControl,1,0); // Go to initialstate

	} // TESTSAMPLES

	// Processing the last test sample:
	XGpio_DiscreteWrite(&MainControl,1,2);

	CoTMstatus = XGpio_DiscreteRead(&Statusreg,1);
	while(CoTMstatus != 2){
		CoTMstatus = XGpio_DiscreteRead(&Statusreg,1);
	}

	ActualAndPredicted = XGpio_DiscreteRead(&Result,1);
		Actual = ActualAndPredicted >> 4;
		Predicted = ActualAndPredicted & 0x0F;
		if (Actual != Predicted) {
			errors = errors+1;
		}

	accuracyTest=(float)(TESTSAMPLES-errors)*100.00/(float)TESTSAMPLES;


	if (MenuSelect!=5) {
		printf("------------------------------------------------\n");
		printf("Number of epochs: %d\n", NumberOfEpochs);
		printf("Training samples: %ld\n", TRAININGSAMPLES);
		printf("Test samples: %ld\n", TESTSAMPLES);
		printf("TEST errors : %ld\n", errors);
		printf("TEST accuracy : %.2f\n", accuracyTest);
		printf("Configuration word (hex) : %x\n", configurationword);
		printf("LFSR selection word (hex): %x\n", selLFSR);
		printf("------------------------------------------------\n");
	}
	XGpio_DiscreteWrite(&MainControl,1,0); // Go to initialstate
}

////////////////////////////////////////////////////////////////////////////////////////////
u32 checkHalted(u32 baseAddress,u32 offset){
	u32 status1;
	status1 = (XAxiDma_ReadReg(baseAddress,offset))&XAXIDMA_HALTED_MASK;
	return status1;
}

////////////////////////////////////////////////////////////////////////////////////////////
u32 checkIdle(u32 baseAddress,u32 offset){
	u32 status2;
	status2 = (XAxiDma_ReadReg(baseAddress,offset))&XAXIDMA_IDLE_MASK;
	return status2;
}

////////////////////////////////////////////////////////////////////////////////////////////
// Utility function to swap elements `A[i]` and `A[j]` in an array
void swap(unsigned A[], unsigned i, unsigned j)
{
	unsigned temp = A[i];
    A[i] = A[j];
    A[j] = temp;
}

////////////////////////////////////////////////////////////////////////////////////////////
// Function to shuffle an array `A[]` of `n` elements
void shuffle(unsigned A[], unsigned n)
{
    // read array from the highest index to lowest
    for (unsigned i = n - 1; i >= 1; i--)
    {
        // generate a random number `j` such that `0 <= j <= i`
    	unsigned j = rand() % (i + 1);

        // swap the current element with the randomly generated index
        swap(A, i, j);
    }
}
