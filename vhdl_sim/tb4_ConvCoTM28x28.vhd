-----------------------------------------------
--
-- This repository includes VHDL code for an FPGA implementation of a Convolutional Coalesced 
-- Tsetlin Machine (ConvCoTM)-based Image Classification Accelerator with On-Device Training.
-- The design is described in the paper "Tsetlin Machine-Based Image Classification FPGA Accelerator With On-Device Training" 
-- in IEEE Transactions on Circuits and Systems I: Regular Papers: https://ieeexplore.ieee.org/document/10812055.
-- 
-- This testbench is used to thest the following:
-- * AXI interface and image data transfer
-- * TA and weight initialization
-- * Training  
-- * Testing 
--
-- As full simulation of training over several epochs is very demanding and time consuming, a simplified dataset 
-- "MNIST_train_100_samples_repeated_20.txt" is utilized. Here 100 training samples are included and repeated 20 times. 
--------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.all;  
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.SETTINGS_ConvCoTM.all;  
use work.MainFSMDefinitions.all;
use std.textio.all;     
use IEEE.std_logic_textio.all; 

entity tb4_ConvCoTM28x28 is
end tb4_ConvCoTM28x28;

architecture test of tb4_ConvCoTM28x28 is

    -- INPUTS:
    signal clk                  : std_logic;
    
    signal w_ctrl               : std_logic_vector(7 downto 0);
    
    signal w_rst                : std_logic;
    signal w_start              : std_logic;
    signal w_learn              : std_logic;
    signal w_initialize         : std_logic;
    signal w_LoadModel          : std_logic;
    signal w_config             : std_logic_vector(31 downto 0);
    signal w_lengthLFSRs        : std_logic_vector(2 downto 0);
    signal w_en_LFSRs_init      : std_logic;
    signal w_image_buffer_reset : std_logic;
    
    signal w_TA_high_threshold  : std_logic_vector(7 downto 0);
    signal w_T_hyper            : std_logic_vector(7 downto 0);
    signal w_s_hyper            : std_logic_vector(3 downto 0);
    --signal w_length_LFSRs       : std_logic;
    signal w_weightMAX          : std_logic_vector(7 downto 0);

    -- OUTPUTS:
    signal w_blinkout                   : STD_LOGIC;
    signal w_LED1_InitialState          : STD_LOGIC;
    signal w_LED2_FinishedInference     : STD_LOGIC;
    signal w_LED3_FinishedLearn         : STD_LOGIC;
    
    -- AXI INTERFACE:
    signal axi_clk              : std_logic;
    signal axi_reset_n          : std_logic;
    
    signal w_i_data_valid       : std_logic;
    signal w_i_data             : std_logic_vector(7 downto 0);
    signal w_o_data_ready       : std_logic;
             
    -- Interrupts:
    signal w_o_intr             : std_logic; 
    signal w_intr2              : std_logic; -- 
    
    signal w_correctPrediction  : std_logic;
    signal w_Result             : std_logic_vector(7 downto 0);
    signal w_ImageLabel         : std_logic_vector(3 downto 0);
    
    signal w_statereg           : std_logic_vector(7 downto 0);
    
    --
    -- Housekeeping:
    signal samplecount          : integer;
    signal errors               : integer;
    signal noTrainSamples       : integer;
    signal noTestSamples        : integer;
    
    -- Testing:
    signal w_test               : std_logic_vector(2 downto 0);
    
    
    --------------------------------------------------------------------------------------------------------------    

begin
            
        DUT:  entity work.ConvCoTM28x28(RTL)
                    port map(
                                clk                      => clk,
                                
                                i_ctrl                   => w_ctrl,
                                i_config                 => w_config,
                                i_lengthLFSRs            => w_lengthLFSRs,
                                
                                -- AXI INTERFACE:
                                axi_clk                  => axi_clk,
                                axi_reset_n              => axi_reset_n,
                                     
                                -- Slave interface:
                                i_data_valid             => w_i_data_valid,
                                i_data                   => w_i_data,
                                o_data_ready             => w_o_data_ready,
                                     
                                -- Interrupt:
                                o_intr                      => w_o_intr,
                                
                                ----------
                                o_correctPrediction         => w_correctPrediction,
                                o_Result                    => w_Result,
                                o_ImageLabel                => w_ImageLabel,
                                o_intr2                     => w_intr2,
         
                                o_LED1_InitialState         => w_LED1_InitialState,
                                o_LED2_FinishedInference    => w_LED2_FinishedInference,
                                o_LED3_FinishedLearn        => w_LED3_FinishedLearn,
         
                                o_statereg                  => w_statereg,
                                o_blinkout                  => w_blinkout
                            );

    
    
        w_ctrl(0) <= w_rst;
        w_ctrl(1) <= w_start;
        w_ctrl(2) <= w_learn;
        w_ctrl(3) <= w_en_LFSRs_init;
        w_ctrl(4) <= w_initialize;
        w_ctrl(5) <= w_LoadModel;
        w_ctrl(6) <= w_image_buffer_reset;
        w_ctrl(7) <= '0'; -- Not used.

        w_config <=  w_TA_high_threshold & w_T_hyper & w_weightMAX & w_s_hyper & '0' & w_test; 
        -- Map i_config signals:
        --    w_TA_high_threshold         <= i_config(31 downto 24); -- Here: UNSIGNED. 
        --    w_T_hyper                   <= i_config(23 downto 16); -- UNSIGNED. 
        --    w_W_Threshold_Weight_High   <= i_config(15 downto 8);  -- UNSIGNED. 
        --    w_s_hyper                   <= i_config(7 downto 4);   -- UNSIGNED.
        --    w_config(3)                 <= i_config(3); Not used. 
        --    w_test                      <= i_config(2 downto 0);
                                          -- w_test(2) not used.
                                          -- w_test(1) if 1: The patch generation for Negative Target Class is skipped
                                          -- w_test(0) not used. 
        
        w_TA_high_threshold     <= "11111111"; -- unsigned number
        w_T_hyper               <= "1101" & "0000"; -- UNSIGNED format. 
        w_weightMAX             <= "0110" & "0000"; -- UNSIGNED format. 0x60 = dec 96 = 0.75*128 (number of clauses)
        w_s_hyper               <= "1000";
--        w_length_LFSRs          <= '1';
        w_test                  <= "001";
        w_lengthLFSRs           <= "111";

      
        noTrainSamples <= 1500;
        noTestSamples  <= 150;
               
    process begin
        clk <= '1'; wait for 5ns;
        clk <= '0'; wait for 5ns;
    end process;
    
    -- Process for the AXI interface
    process begin
        axi_clk <= '0'; wait for 2ns;
        axi_clk <= '1'; wait for 5ns;
        axi_clk <= '0'; wait for 3ns;
    end process;

    process
          
          --file text_file : text open read_mode is "C:\Users\satun\OneDrive\Dokumenter\fg_ConvCoTM28x28\MNISTdata\MNIST_train_60_ksamples.txt";
          file text_file : text open read_mode is "C:\Users\satun\OneDrive\Dokumenter\fg_ConvCoTM28x28\MNISTdata\MNIST_train_100_samples_repeated_20.txt";    
          
          variable text_line : line;
          variable var_imagedata : std_logic_vector(7 downto 0);
          
          --file text_file2 : text open read_mode is "C:\Users\satun\OneDrive\Dokumenter\fg_ConvCoTM28x28\MNISTdata\MNIST_test_10k_samples.txt";
          file text_file2 : text open read_mode is "C:\Users\satun\OneDrive\Dokumenter\fg_ConvCoTM28x28\MNISTdata\MNIST_train_100_samples_repeated_20.txt";
          variable text_line2 : line;
          variable var_imagedata2 : std_logic_vector(7 downto 0);
          
                
    begin

            w_i_data_valid <='0';

            -- TRAINING:
            axi_reset_n <='1';
            wait for 3ns;
            axi_reset_n <='0';
            wait for 133ns;
            axi_reset_n <='1';

            wait until rising_edge(w_learn);
                   
            wait for 100ns;
            wait until rising_edge(axi_clk);
            for i in 0 to 98 loop
                readline(text_file, text_line);
                read(text_line, var_imagedata);  
                wait until rising_edge(axi_clk);
                w_i_data <= var_imagedata; 
                w_i_data_valid <='1';                       
            end loop;  
            wait until rising_edge(axi_clk); 
            w_i_data_valid <='0';
        
             for j in 0 to noTrainSamples-2 loop  
                wait until rising_edge(w_start);                  
                wait until rising_edge(axi_clk);
                for i in 0 to 98 loop
                    readline(text_file, text_line);
                    read(text_line, var_imagedata);  
                    wait until rising_edge(axi_clk);
                    w_i_data <= var_imagedata; 
                    w_i_data_valid <='1';               
                end loop;  
                wait until rising_edge(axi_clk); 
                w_i_data_valid <='0';
             end loop; 

            -- 
            -- TESTING:
            

            wait for 300ns;
            wait until falling_edge(w_learn);  -- needed for simulation purposes to avoid too early loading of new sample.
            wait until falling_edge(w_image_buffer_reset); -- needed for simulation purposes to avoid too early loading of new sample.
            
            wait for 200ns;
            wait until rising_edge(axi_clk);
            for i in 0 to 98 loop
                readline(text_file2, text_line2);
                read(text_line2, var_imagedata2);  
                wait until rising_edge(axi_clk);
                w_i_data <= var_imagedata2; 
                w_i_data_valid <='1';                       
            end loop;  
            wait until rising_edge(axi_clk); 
            w_i_data_valid <='0';
        
             for j in 0 to noTestSamples-2 loop  
                wait until rising_edge(w_start);
                wait until rising_edge(axi_clk);
                for i in 0 to 98 loop
                    readline(text_file2, text_line2);
                    read(text_line2, var_imagedata2);  
                    wait until rising_edge(axi_clk);
                    w_i_data <= var_imagedata2; 
                    w_i_data_valid <='1';               
                end loop;  
                wait until rising_edge(axi_clk); 
                w_i_data_valid <='0';
             end loop; 

             wait until falling_edge(w_start);  -- Just to avoid that this process terminates the simulation before the inference/training is completed.
             wait until falling_edge(w_start);  --  Two times are needed! Just to avoid that this process terminates the simulation before the inference/training is completed.
             
             wait for 10000ns;
             
             std.env.stop(0);
    
    end process;
    

    process begin
        
        samplecount <= 0;
        errors <= 0;
        
        w_image_buffer_reset <='0';
        w_en_LFSRs_init <='0';
        w_rst <='1';
        w_LoadModel <='0';
        w_initialize <='0';
        w_start <='0'; 
        w_learn <='0';
        
        wait for 7ns;
        wait for 20 ns;
        w_rst <='0';
        wait for 1000 ns;
        
       --
       -- INITIALIZE: (Set all TAs in state N (all 1s) and the weights randomly to -1 and +1
       -- First we let the LFSRs that controls this run for a period from when w_learn goes high to w_initialize goes high.
       -- This time can be determined (randomly if wanted) by the system processor.
       w_en_LFSRs_init <='1';
       wait for 300ns;
       w_initialize <='1';
       wait for 512*10ns;
       wait for 100ns;
       w_initialize <='0';
       wait for 100ns;
       w_en_LFSRs_init <='0';
       wait for 200ns;
       
--           -- We can safely set w_en_LFSRs_init and w_initialize both low immediately after i_Initialize has been set to 1, because the 
--           -- rest of the initialization process does not depend on these signals (but on w_ClauseCounterFinished). However, we need to wait some time until the initialization
--           -- process has finished. 
       
       --
       -- Start Training: 
       w_learn <='1';
       wait for 300ns; -- Let the LFSRs in the TrainCoTM module run for some time before we start Training. 
                       -- This time can be determined (randomly if wanted) by the system processor.
       
       wait until rising_edge(w_o_intr);
       wait for 200ns;

       for d in 0 to noTrainSamples-2 loop
               w_start <='1'; 
               wait until rising_edge(w_o_intr);
               wait for 20ns;
               w_start <='0';
               wait for 20ns;
               samplecount <= samplecount + 1;
               wait for 50ns;
       end loop;  
       
       w_start <='1'; 
       wait until rising_edge(w_intr2); 
       wait for 20ns;
       w_start <='0';
       wait for 20ns;
       samplecount <= samplecount + 1;
       wait for 50ns;

       w_learn <='0';
       wait for 2000ns;
       
       ---------------------------------------------------------------------------
       -- Start Inference:
       w_image_buffer_reset <='1';
       wait for 200ns;
       w_image_buffer_reset <='0';
       samplecount <= 0;
       errors <= 0;
       wait for 200ns; 
       
       wait until rising_edge(w_o_intr);
       wait for 200ns;

       for d in 0 to noTestSamples-2 loop
               w_start <='1'; 
               wait until rising_edge(w_intr2);
               wait for 20ns;
               samplecount <= samplecount + 1;
               IF w_correctPrediction='0' THEN
                         errors <= errors+1;
               END IF;
               w_start <='0';
               wait for 100ns;
       end loop;  
       
       -- Process the last sample:
       w_start <='1'; 
       wait until rising_edge(w_intr2); 
       wait for 20ns;
       samplecount <= samplecount + 1;
       IF w_correctPrediction='0' THEN
                 errors <= errors+1;
       END IF;
       w_start <='0';

       wait for 500ns;
       
       std.env.stop(0);

    end process;

end test;