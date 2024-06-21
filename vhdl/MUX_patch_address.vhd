library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.SETTINGS_ConvCoTM.all;
 
entity MUX_patch_address is  
    Port (
          i_addrFromReg0  : array32ofPatchAddresses;
          i_addrFromReg1  : array32ofPatchAddresses;
          i_addrFromReg2  : array32ofPatchAddresses;
          i_addrFromReg3  : array32ofPatchAddresses;
          i_addrFromReg4  : array32ofPatchAddresses;
          i_addrFromReg5  : array32ofPatchAddresses;
          i_addrFromReg6  : array32ofPatchAddresses;
          i_addrFromReg7  : array32ofPatchAddresses;
          i_addrFromReg8  : array32ofPatchAddresses;
          i_addrFromReg9  : array32ofPatchAddresses;
          i_addrFromReg10 : array32ofPatchAddresses;
          i_addrFromReg11 : array32ofPatchAddresses;
          i_addrFromReg12 : array32ofPatchAddresses;
          i_addrFromReg13 : array32ofPatchAddresses;
          i_addrFromReg14 : array32ofPatchAddresses;
          i_addrFromReg15 : array32ofPatchAddresses;
          
          i_sel             : in std_logic_vector(NBitsClauseAddr-1 downto 0);
          o_MuxOut          : out std_logic_vector(8 downto 0) 
          ); 
end MUX_patch_address;

architecture RTL_128 of MUX_patch_address is

    signal w_addrA       : array4ofPatchAddresses;

begin 

        MUX0 : entity work.sub_MUX_32to1_addr(RTL)
            Port map 
                 (i_addrFromReg     => i_addrFromReg0,
                  i_sel             => i_sel(4 downto 0),
                  o_MuxOut          => w_addrA(0)
                  );
                  
        MUX1 : entity work.sub_MUX_32to1_addr(RTL)
            Port map 
                 (i_addrFromReg     => i_addrFromReg1,
                  i_sel             => i_sel(4 downto 0),
                  o_MuxOut          => w_addrA(1)
                  );
                  
        MUX2 : entity work.sub_MUX_32to1_addr(RTL)
            Port map 
                 (i_addrFromReg     => i_addrFromReg2,
                  i_sel             => i_sel(4 downto 0),
                  o_MuxOut          => w_addrA(2)
                  );
                  
        MUX3 : entity work.sub_MUX_32to1_addr(RTL)
            Port map 
                 (i_addrFromReg     => i_addrFromReg3,
                  i_sel             => i_sel(4 downto 0),
                  o_MuxOut          => w_addrA(3)
                  );
                  
                  
-----------------------------------------------------------------------
        -- FINAL MUX 
        PatchMUX4to1 : entity work.sub_MUX_4to1_addr(RTL)
            Port map 
                 (i_addrFromReg       => w_addrA,
                  i_sel               => i_sel(NBitsClauseAddr-1 downto 5),
                  o_MuxOut            => o_MuxOut
                  );
end RTL_128;