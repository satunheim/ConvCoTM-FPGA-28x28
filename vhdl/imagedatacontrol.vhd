library IEEE;
use IEEE.STD_LOGIC_1164.ALL;  
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all; 
use IEEE.std_logic_unsigned.all; 
use work.FF.all;
use work.SETTINGS_ConvCoTM.all;
use work.MainFSMDefinitions.all;  
  
entity imagedatacontrol is      
    port (
        i_clk               : in std_logic; 
        i_rst               : in std_logic; 
        i_start             : in std_logic;  
        i_MainFSMstate      : in std_logic_vector(SWIDTH-1 downto 0);
        i_ByCounterValue    : in std_logic_vector(4 downto 0);
                 
        i_image_data        : in std_logic_vector(7 downto 0); 
        i_imagedata_valid   : in std_logic;
        o_data_ready        : out std_logic;
        
        o_ImagevectorRow0   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow1   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow2   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow3   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow4   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow5   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow6   : out std_logic_vector(ImageSize-1 downto 0);  
        o_ImagevectorRow7   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow8   : out std_logic_vector(ImageSize-1 downto 0);          
        o_ImagevectorRow9   : out std_logic_vector(ImageSize-1 downto 0); 
        o_ImagevectorRow10  : out std_logic_vector(ImageSize-1 downto 0);  -- The 11th row. Controlled by i_ByCounterValue.
        o_ImageLabel        : out std_logic_vector(3 downto 0);        
        
        o_intr              : out std_logic                             
        );   
                                
end imagedatacontrol;

architecture rtl of imagedatacontrol is 

    constant IDLE               : std_logic_vector(12 downto 0) := "00000" & "00000001";
    constant RD_DATA_INITIAL    : std_logic_vector(12 downto 0) := "00000" & "00000010";
    constant WAIT_INITIAL       : std_logic_vector(12 downto 0) := "00000" & "00000100";
    constant SETINTR_INITIAL    : std_logic_vector(12 downto 0) := "00000" & "00001000";
    constant CLRINTR_INITIAL    : std_logic_vector(12 downto 0) := "00000" & "00010000";
    constant RD_DATA_B          : std_logic_vector(12 downto 0) := "00000" & "00100000";
    constant WAIT_B             : std_logic_vector(12 downto 0) := "00000" & "01000000";
    constant SETINTR_B          : std_logic_vector(12 downto 0) := "00000" & "10000000";
    constant CLRINTR_B          : std_logic_vector(12 downto 0) := "00001" & "00000000";
    constant RD_DATA_A          : std_logic_vector(12 downto 0) := "00010" & "00000000";
    constant WAIT_A             : std_logic_vector(12 downto 0) := "00100" & "00000000";
    constant SETINTR_A          : std_logic_vector(12 downto 0) := "01000" & "00000000";
    constant CLRINTR_A          : std_logic_vector(12 downto 0) := "10000" & "00000000";
    

    signal w_ImagevectorRowA0       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowA1       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowA2       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowA3       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowA4       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowA5       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowA6       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowA7       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowA8       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowA9       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowA10      : std_logic_vector(ImageSize-1 downto 0);
    
    signal w_ImagevectorRowB0       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowB1       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowB2       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowB3       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowB4       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowB5       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowB6       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowB7       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowB8       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowB9       : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImagevectorRowB10      : std_logic_vector(ImageSize-1 downto 0);
    
    signal w_ImageLabelA            : std_logic_vector(3 downto 0);
    signal w_ImageLabelB            : std_logic_vector(3 downto 0);
    
    signal w_imageBufferData_enwrite0 : std_logic;
    signal w_imageBufferData_enwrite1 : std_logic;
    signal w_mux_select               : std_logic;
    
    signal w_Kfinished              : std_logic;
    signal w_kregout                : std_logic_vector(8 downto 0);
    signal w_resetK                 : std_logic;
    
    type   kArray is array (0 to BytesPerImage-1) of std_logic_vector(8 downto 0);
    signal w_kAddr : kArray;
    
    signal w_next1                  : std_logic_vector(12 downto 0);
    signal w_nextstate              : std_logic_vector(12 downto 0);
    signal w_currentstate           : std_logic_vector(12 downto 0);
    
    signal w_enablebyte_in_buffer0   : std_logic_vector(BytesPerImage-1 downto 0);
    signal w_enablebyte_in_buffer1   : std_logic_vector(BytesPerImage-1 downto 0);
    
    signal w_intr                    : std_logic;
    signal w_o_data_ready            : std_logic;

begin

     w_o_data_ready <='1';
     o_data_ready <= w_o_data_ready;

     ModuleImage0: entity work.ImageBuffer(rtl) 
        port map (
            i_clk               => i_clk, 
            i_rst               => i_rst,
            i_enable            => w_enablebyte_in_buffer0,
            i_ByCounterValue    => i_ByCounterValue, 
                 
            i_image_data        => i_image_data,

            o_ImagevectorRow0   => w_ImagevectorRowA0,
            o_ImagevectorRow1   => w_ImagevectorRowA1,
            o_ImagevectorRow2   => w_ImagevectorRowA2,
            o_ImagevectorRow3   => w_ImagevectorRowA3,
            o_ImagevectorRow4   => w_ImagevectorRowA4,
            o_ImagevectorRow5   => w_ImagevectorRowA5,
            o_ImagevectorRow6   => w_ImagevectorRowA6,
            o_ImagevectorRow7   => w_ImagevectorRowA7,
            o_ImagevectorRow8   => w_ImagevectorRowA8,
            o_ImagevectorRow9   => w_ImagevectorRowA9,
            
            o_ImagevectorRow10  => w_ImagevectorRowA10, -- The 11th row. Controlled by i_ByCounterValue.
            
            o_ImageLabel        => w_ImageLabelA
           
            );
            
    ModuleImage1: entity work.ImageBuffer(rtl) 
        port map (
            i_clk               => i_clk, 
            i_rst               => i_rst,
            i_enable            => w_enablebyte_in_buffer1,
            i_ByCounterValue    => i_ByCounterValue, 
                 
            i_image_data        => i_image_data,    
              
            o_ImagevectorRow0   => w_ImagevectorRowB0,
            o_ImagevectorRow1   => w_ImagevectorRowB1,
            o_ImagevectorRow2   => w_ImagevectorRowB2,
            o_ImagevectorRow3   => w_ImagevectorRowB3,
            o_ImagevectorRow4   => w_ImagevectorRowB4,
            o_ImagevectorRow5   => w_ImagevectorRowB5,
            o_ImagevectorRow6   => w_ImagevectorRowB6,
            o_ImagevectorRow7   => w_ImagevectorRowB7,
            o_ImagevectorRow8   => w_ImagevectorRowB8,
            o_ImagevectorRow9   => w_ImagevectorRowB9,
            
            o_ImagevectorRow10  => w_ImagevectorRowB10, -- The 11th row. Controlled by i_ByCounterValue.
            
            o_ImageLabel        => w_ImageLabelB
            );
 
    w_mux_select <= '0' when w_currentstate=RD_DATA_B or w_currentstate=WAIT_B or w_currentstate=SETINTR_B or w_currentstate=CLRINTR_B else '1'; 
    
    MUXImageData: entity work.MUX_imagedata(rtl) 
        port map (
            i_select             => w_mux_select, 
            
            i_ImagevectorRow0A   => w_ImagevectorRowA0,
            i_ImagevectorRow1A   => w_ImagevectorRowA1,
            i_ImagevectorRow2A   => w_ImagevectorRowA2,
            i_ImagevectorRow3A   => w_ImagevectorRowA3,
            i_ImagevectorRow4A   => w_ImagevectorRowA4, 
            i_ImagevectorRow5A   => w_ImagevectorRowA5, 
            i_ImagevectorRow6A   => w_ImagevectorRowA6,
            i_ImagevectorRow7A   => w_ImagevectorRowA7,
            i_ImagevectorRow8A   => w_ImagevectorRowA8,
            i_ImagevectorRow9A   => w_ImagevectorRowA9,
            i_ImagevectorRow10A  => w_ImagevectorRowA10,  -- The 11th row. 
            i_ImageLabelA        => w_ImageLabelA, 
                        
            i_ImagevectorRow0B   => w_ImagevectorRowB0,
            i_ImagevectorRow1B   => w_ImagevectorRowB1,
            i_ImagevectorRow2B   => w_ImagevectorRowB2,
            i_ImagevectorRow3B   => w_ImagevectorRowB3, 
            i_ImagevectorRow4B   => w_ImagevectorRowB4,
            i_ImagevectorRow5B   => w_ImagevectorRowB5,
            i_ImagevectorRow6B   => w_ImagevectorRowB6,
            i_ImagevectorRow7B   => w_ImagevectorRowB7,
            i_ImagevectorRow8B   => w_ImagevectorRowB8,
            i_ImagevectorRow9B   => w_ImagevectorRowB9,
            i_ImagevectorRow10B  => w_ImagevectorRowB10,  -- The 11th row. 
            i_ImageLabelB        => w_ImageLabelB,   
            
            o_ImagevectorRow0   => o_ImagevectorRow0, 
            o_ImagevectorRow1   => o_ImagevectorRow1, 
            o_ImagevectorRow2   => o_ImagevectorRow2, 
            o_ImagevectorRow3   => o_ImagevectorRow3, 
            o_ImagevectorRow4   => o_ImagevectorRow4, 
            o_ImagevectorRow5   => o_ImagevectorRow5, 
            o_ImagevectorRow6   => o_ImagevectorRow6, 
            o_ImagevectorRow7   => o_ImagevectorRow7, 
            o_ImagevectorRow8   => o_ImagevectorRow8, 
            o_ImagevectorRow9   => o_ImagevectorRow9, 
            o_ImagevectorRow10  => o_ImagevectorRow10,  -- The 11th row. Controlled by i_ByCounterValue.
            o_ImageLabel        => o_ImageLabel      
            );   
 
 
 -- FSM for image control:
--  MAINSTATEREG: vDFF generic map(SWIDTH) port map(i_clk, w_nextstate, w_currentstate);
    imageFSM: vDFF generic map(13) port map(i_clk, w_nextstate, w_currentstate);
    
   w_nextstate <= IDLE when i_rst='1' else w_next1;
   
      process(
              w_currentstate, 
              w_Kfinished,
              i_rst,
              i_MainFSMstate
              ) 
      begin
              
        case w_currentstate is
        
            when IDLE =>  
                    w_intr <= '0';
                    IF i_rst='1' THEN
                        w_next1 <= IDLE;
                    ELSE w_next1<=RD_DATA_INITIAL;
                    END IF;
                        
            when RD_DATA_INITIAL => 
                    w_intr <= '0'; 
                    IF w_Kfinished='1' THEN 
                        w_next1 <= WAIT_INITIAL;
                    ELSE w_next1<=RD_DATA_INITIAL;
                    END IF;

             when WAIT_INITIAL => 
                    w_intr <= '0';
                    w_next1 <= SETINTR_INITIAL;

             when SETINTR_INITIAL => 
                    w_intr <= '1'; 
                    w_next1<=CLRINTR_INITIAL;
            
             when CLRINTR_INITIAL => 
                    w_intr <= '0'; 
                    w_next1<=RD_DATA_B;
            
            when RD_DATA_B =>
                    w_intr <= '0';
                    IF w_Kfinished='1' THEN 
                        w_next1 <= WAIT_B;
                    ELSE w_next1<=RD_DATA_B;
                    END IF;
             
             when WAIT_B => 
                    w_intr <= '0';
                    IF i_MainFSMstate=keepClassDecision or i_MainFSMstate=FinishedTraining THEN 
                        w_next1 <= SETINTR_B;
                    ELSE w_next1<=WAIT_B;
                    END IF;
                    
             when SETINTR_B => 
                    w_intr <= '1'; 
                    w_next1<=CLRINTR_B;

             when CLRINTR_B =>  
                    w_intr <= '0'; 
                    w_next1<=RD_DATA_A;
                    
             when RD_DATA_A =>
                    w_intr <= '0';
                    IF w_Kfinished='1' THEN 
                        w_next1 <= WAIT_A;
                    ELSE w_next1<=RD_DATA_A;
                    END IF;
             
             when WAIT_A => 
                    w_intr <= '0';
                    IF i_MainFSMstate=keepClassDecision or i_MainFSMstate=FinishedTraining THEN 
                        w_next1 <= SETINTR_A;
                    ELSE w_next1<=WAIT_A;
                    END IF;
                    
             when SETINTR_A => 
                    w_intr <= '1'; 
                    w_next1<=CLRINTR_A;

             when CLRINTR_A =>  
                    w_intr <= '0'; 
                    w_next1<=RD_DATA_B;

            when others =>
                   w_next1 <= IDLE;
                   w_intr <= '0';
                    
           end case;             
    end process;                               
    
     w_resetK <= '1' when w_intr='1' or w_currentstate=IDLE or w_currentstate=CLRINTR_INITIAL or w_currentstate=CLRINTR_B or w_currentstate=CLRINTR_A else '0'; 
     
     Module_K1_counter: entity work.k_counter(rtl) 
        port map (
            i_clk               => i_clk, 
            i_rst               => i_rst,
            i_resetK            => w_resetK,
            i_en                => i_imagedata_valid,
            o_k_counterFinished => w_Kfinished,
            o_k_value           => w_kregout
            );
    
        AY: FOR ja in 0 to BytesPerImage-1 GENERATE
                 w_Kaddr(ja) <= std_logic_vector(to_unsigned(ja, w_kAddr(ja)'length));   
                 w_enablebyte_in_buffer0(ja) <='1' when w_kregout=w_Kaddr(ja) and w_imageBufferData_enwrite0='1' else '0'; 
                 w_enablebyte_in_buffer1(ja) <='1' when w_kregout=w_Kaddr(ja) and w_imageBufferData_enwrite1='1' else '0';   
        end GENERATE AY; 


     w_imageBufferData_enwrite0 <= '1' when (w_currentstate=RD_DATA_INITIAL or w_currentstate=RD_DATA_A) and i_imagedata_valid='1' else '0';
     w_imageBufferData_enwrite1 <= '1' when w_currentstate=RD_DATA_B and i_imagedata_valid='1' else '0';
     
     ------------------------------------------
      o_intr <=w_intr;                     
     ------------------------------------------------------------------------------------------
                                              
end rtl;              