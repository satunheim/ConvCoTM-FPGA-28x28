library IEEE;
use IEEE.STD_LOGIC_1164.ALL;  
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all; 
use IEEE.std_logic_unsigned.all; 
use work.FF.all;
use work.SETTINGS_ConvCoTM.all;
use work.MainFSMDefinitions.all;  
  
entity ImageBuffer is      
    port (
        i_clk               : in std_logic; 
        i_rst               : in std_logic; 
        i_enable            : in std_logic_vector(BytesPerImage-1 downto 0);
        i_ByCounterValue    : in std_logic_vector(4 downto 0);
                 
        i_image_data        : in std_logic_vector(7 downto 0); 
        --------------------------------                    
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
        o_ImageLabel        : out std_logic_vector(3 downto 0)
               
        );    
                                
end ImageBuffer;

architecture rtl of ImageBuffer is 

    constant ImageSizeHalf: Integer := ImageSize/2; 
    type imageROWarray is array (0 to ImageSizeHalf-1) of std_logic_vector(ImageSize-1 downto 0);
    signal w_RowA           : imageROWarray;
    signal w_RowB           : imageROWarray;
    signal w_Row10          : std_logic_vector(ImageSize-1 downto 0);
    signal w_ImageLabel_A   : std_logic_vector(7 downto 0);
    signal w_ImageLabel_B   : std_logic_vector(3 downto 0);
    
    type bufferarray is array(0 to BytesPerImage-1) of std_logic_vector(7 downto 0);
    -- Note: The last byte is used for the image label (0-9).
    signal w_bufferAnext    : bufferarray;
    signal w_bufferAcurrent : bufferarray;
-----------------------------------------------------------------------------------------

    begin
           -- The image buffer consits of 28*28=784 bit. 
           -- This is equivalent to 98 bytes. 
           -- plus 1 byte for the label (4 extra bits in the label byte is not needed at this stage, but can be used for problems with more classes later.)
           -- *** I.e., a total of 99 bytes per sample. *** 
 
      IMAGEBUFFER: FOR j in 0 to BytesPerImage-1 GENERATE  
 
            ImageByteA:  vDFFce generic map(8) 
                                port map
                                    (
                                    clk     => i_clk, 
                                    clk_en  => i_enable(j), 
                                    D       => w_bufferAnext(j), 
                                    Q       => w_bufferAcurrent(j)  
                                    );
          
            w_bufferAnext(j) <= (others => '0') when i_rst='1' else i_image_data when i_enable(j)='1' else w_bufferAcurrent(j); 

            --NOTE: w_bufferAcurrent(98) for j=BytesperImage-1=99-1=98 contains the sample's label.
            
      END GENERATE IMAGEBUFFER;
      
      --
      
      OUTPUTROWS: FOR jn in 0 to 13 GENERATE   
       -- There are 56 bit (i.e. 7 byte) per two rows
        w_RowA(jn)  <= w_bufferAcurrent(jn*7)(7 downto 0) & w_bufferAcurrent(jn*7+1)(7 downto 0) & w_bufferAcurrent(jn*7+2)(7 downto 0) & w_bufferAcurrent(jn*7+3)(7 downto 4);
        w_RowB(jn)  <= w_bufferAcurrent(jn*7+3)(3 downto 0) & w_bufferAcurrent(jn*7+4)(7 downto 0) & w_bufferAcurrent(jn*7+5)(7 downto 0) & w_bufferAcurrent(jn*7+6)(7 downto 0);
      END GENERATE OUTPUTROWS;
        
        w_ImageLabel_A <=w_bufferAcurrent(BytesPerImage-1);
        w_ImageLabel_B <=w_ImageLabel_A(3 downto 0);
        o_ImageLabel <= w_ImageLabel_B;
        
        o_ImagevectorRow0 <= w_RowA(0);
        o_ImagevectorRow1 <= w_RowB(0);
        o_ImagevectorRow2 <= w_RowA(1);
        o_ImagevectorRow3 <= w_RowB(1);
        o_ImagevectorRow4 <= w_RowA(2);
        o_ImagevectorRow5 <= w_RowB(2);
        o_ImagevectorRow6 <= w_RowA(3);
        o_ImagevectorRow7 <= w_RowB(3);
        o_ImagevectorRow8 <= w_RowA(4);
        o_ImagevectorRow9 <= w_RowB(4);     
        o_ImagevectorRow10 <= w_Row10;   -- The 11th row.  

        with i_ByCounterValue select
            w_Row10 <=                                                         
                    w_RowA(5)  when "00000",
                    w_RowB(5)  when "00001", 
                    w_RowA(6)  when "00010",
                    w_RowB(6)  when "00011",
                    w_RowA(7)  when "00100",
                    w_RowB(7)  when "00101",   
                    w_RowA(8)  when "00110",
                    w_RowB(8)  when "00111",
                    w_RowA(9)  when "01000",
                    w_RowB(9)  when "01001",
                    w_RowA(10) when "01010",   
                    w_RowB(10) when "01011",
                    w_RowA(11) when "01100",
                    w_RowB(11) when "01101",
                    w_RowA(12) when "01110",
                    w_RowB(12) when "01111",   
                    w_RowA(13) when "10000",
                    w_RowB(13) when "10001",  
                    "00000000000000" & "00000000000000" when others; -- 28 bits
                                              
end rtl;
