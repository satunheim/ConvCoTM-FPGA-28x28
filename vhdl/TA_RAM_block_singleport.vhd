library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;    
use IEEE.numeric_std.all; 
use std.textio.all;
use work.SETTINGS_ConvCoTM.all;
 
entity TA_RAM_block_singleport is
 port( 
  clk   : in  std_logic;
  we    : in  std_logic; 
  en    : in  std_logic;  
  addr  : in  std_logic_vector(NBitsClauseAddr-1 downto 0);
  di    : in  std_logic_vector(71 downto 0); 
  do    : out std_logic_vector(71 downto 0)
 );
end TA_RAM_block_singleport;

-- ********************************************************************

architecture syn1 of TA_RAM_block_singleport is
   type RamType is array (0 to NClauses-1) of bit_vector(71 downto 0);
   -- The first row in the file will be address 0.
   -- With 9 bits in each TA, we here have room for 8 TAs. 
   -- We need 272 TAs in total, one for each literal. Thus, we need 272/8=34 such TA_RAM_blocks PER clause.
        
    impure function InitRamFromFile(RamFileName : in string) return RamType is
        FILE RamFile : text open read_mode is RamFileName; 
        variable RamFileLine : line;
        variable RAM         : RamType; 
     begin
            for I in RamType'range loop
                readline(RamFile, RamFileLine);  
                read(RamFileLine, RAM(I));
            end loop;
        return RAM;
     end function;
     
      signal RAM : RamType;

begin  

-- WRITE FIRST MODE: 
 process(clk)
 begin
    if clk'event and clk = '1' then
        if en = '1' then
            if we = '1' then     
                RAM(to_integer(unsigned(addr))) <= to_bitvector(di);
                do <=di;
            else
                do <= to_stdlogicvector(RAM(to_integer(unsigned(addr))));
            end if;
        end if;
    end if;
 end process;

end syn1;