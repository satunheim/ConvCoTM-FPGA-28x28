library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.SETTINGS_ConvCoTM.all;
 
entity MUX_clause_weights is  
    Port (
          i_clauseWeightsGroup0   : in array32ofClauseWeights;
          i_clauseWeightsGroup1   : in array32ofClauseWeights;
          i_clauseWeightsGroup2   : in array32ofClauseWeights;
          i_clauseWeightsGroup3   : in array32ofClauseWeights;
          i_clauseWeightsGroup4   : in array32ofClauseWeights;
          i_clauseWeightsGroup5   : in array32ofClauseWeights;
          i_clauseWeightsGroup6   : in array32ofClauseWeights;
          i_clauseWeightsGroup7   : in array32ofClauseWeights;
          i_clauseWeightsGroup8   : in array32ofClauseWeights;
          i_clauseWeightsGroup9   : in array32ofClauseWeights;
          i_clauseWeightsGroup10  : in array32ofClauseWeights;
          i_clauseWeightsGroup11  : in array32ofClauseWeights;
          i_clauseWeightsGroup12  : in array32ofClauseWeights;
          i_clauseWeightsGroup13  : in array32ofClauseWeights;
          i_clauseWeightsGroup14  : in array32ofClauseWeights;
          i_clauseWeightsGroup15  : in array32ofClauseWeights;
          
          i_sel                   : in  std_logic_vector(NBitsClauseAddr-1 downto 0);
          o_MuxOut                : out signed(NBitsIW-1 downto 0)
          ); 
end MUX_clause_weights;

architecture RTL_128 of MUX_clause_weights is

    signal w_ClauseWeightsA       : array4ofClauseWeights;

begin

    -- FIRST SECTION (COLUMN) of 4 MUXes (a 32 inputs)
        MUX0 : entity work.sub_MUX_32to1_clauseweights(RTL)
            Port map 
                 (i_clauseWeights   => i_clauseWeightsGroup0,
                  i_sel             => i_sel(4 downto 0),
                  o_MuxOut          => w_ClauseWeightsA(0)
                  );
                  
        MUX1 : entity work.sub_MUX_32to1_clauseweights(RTL)
            Port map 
                 (i_clauseWeights  => i_clauseWeightsGroup1,
                  i_sel             => i_sel(4 downto 0),
                  o_MuxOut          => w_ClauseWeightsA(1)
                  );
                  
        MUX2 : entity work.sub_MUX_32to1_clauseweights(RTL)
            Port map 
                 (i_clauseWeights  => i_clauseWeightsGroup2,
                  i_sel             => i_sel(4 downto 0),
                  o_MuxOut          => w_ClauseWeightsA(2)
                  );
                  
        MUX3 : entity work.sub_MUX_32to1_clauseweights(RTL)
            Port map 
                 (i_clauseWeights  => i_clauseWeightsGroup3,
                  i_sel             => i_sel(4 downto 0),
                  o_MuxOut          => w_ClauseWeightsA(3)
                  );
                  
       
-----------------------------------------------------------------------
        -- FINAL MUX (4 to 1):
        PatchMUX4to1 : entity work.sub_MUX_4to1_clauseweights(RTL)
            Port map 
                 (i_clauseWeights    => w_ClauseWeightsA,
                  i_sel               => i_sel(NBitsClauseAddr-1 downto 5),
                  o_MuxOut            => o_MuxOut
                  );
end RTL_128;
