-- The Convolutional Coalesced TM (ConvCoTM) Structure

-- Literals = Features & not(Features)  (defined in component AllClauses)

-- States: 
-- 0 to N-1 => Exclude 
-- N to 2N-1 => Include
 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

package SETTINGS_ConvCoTM is

	constant ImageSize: Integer := 28; 
	-- Assuming quadratic images, i.e. ImageSize x ImageSize

    constant BytesPerImage: Integer := (ImageSize*ImageSize/8)+1; 
	-- With 28x28 booleanized images, and one byte for the label BytesPerImage=99

	constant WSize: Integer := 10; 	 	
	-- Window (patch) size. Assuming quadratic patch 

    constant pixelResolution: Integer :=1; 
    -- Set to 1 for booleanized images
    -- Set to 8 for Cifar-10 with 8 bit pixel resolution

	constant d: Integer := 1; 	 	
	-- Window step size 
	
	constant Bx: Integer := ((ImageSize-WSize)/d)+1;
	constant By: Integer := ((ImageSize-WSize)/d)+1;
	-- Bx and By are the number of times the Window is moved in x and y directions respectively.
	
	constant B: Integer := Bx*By;
	-- B is the number of patches
	
	constant NBitsPatchAddr: Integer := 9;
	-- Number of bits used for the Patch Address. 
	
	constant FSize: Integer := WSize*WSize*pixelResolution+(ImageSize-WSize)+(ImageSize-WSize);
	-- FSize is the number of features per patch.
	-- The terms (ImageSize-WSize)+(ImageSize-WSize) represent the number of bits for position thermometer encoding in the X and Y directions.
	
	constant NClauses: Integer := 128;	
	-- Number of Clauses
	
	constant NBitsClauseAddr: Integer := 7;
	-- Number of bits used for the Clause Address. MUST equal 2**NBitsClauseAddr=NClauses

	constant Pcounterbits: Integer := 9;	
	-- Number of bits in the P-counter (patch counter).

	constant NClasses: Integer :=10;		
	-- Number of Classes
    
    constant NBitsIW: Integer := 9;
	-- Number of bits used for the Integer Weights (for the clauses).
	-- This includes a sign bit, as the weights are in 2's complement format

	constant NBsum: Integer :=NBitsIW+NBitsClauseAddr;		
	-- Number of bits in sum outputs of the first column of adders for the clauses
	-- The theoretical maximum class sum is NClauses*Max(weight)
	-- For 128 clauses and 9 bit weights (incl sign bit) this equals:
	-- 32640. This is "0111111110000000" in binary format.
	-- With 15 bits just for the unsigned part there should be sufficient range. 
	-- NBitsIW+NBitsClauseAddr = 16 bits in this case. 
    
    type clause_weights is array (0 to NClauses-1) of signed(NBitsIW-1 downto 0);
    
    type array32ofClauseWeights is array (0 to 31) of signed(NBitsIW-1 downto 0);
    type array16ofClauseWeights is array (0 to 15) of signed(NBitsIW-1 downto 0);
    type array4ofClauseWeights is array (0 to 3) of signed(NBitsIW-1 downto 0);

    type include_exclude_signals is array (0 to NClauses-1) of std_logic_vector(2*FSize-1 downto 0);
    
    constant NLFSRs: Integer := 2*FSize+1;	
	-- Number of LFSRs. Should be set to MAX(2*FSize+1, 2*NClauses)
	
	type LFSRrandomnumbers is array (0 to NLFSRs-1) of std_logic_vector(23 downto 0); 
    --type LFSRrandomnumbers is array (0 to NLFSRs-1) of std_logic_vector(23 downto 0); 
    
    constant c_AdderPipelineStages : Integer := 3;
    
    type arrayOfPatchAddresses is array (0 to NClauses-1) of std_logic_vector(8 downto 0);
    type array32ofPatchAddresses is array (0 to 31) of std_logic_vector(8 downto 0);
    type array16ofPatchAddresses is array (0 to 15) of std_logic_vector(8 downto 0);
    type array4ofPatchAddresses is array (0 to 3) of std_logic_vector(8 downto 0);
    
    type arrayOfPatchCounters is array (0 to NClauses-1) of std_logic_vector(8 downto 0);
    
    type updateflagsPerClause is array (0 to NClauses-1) of std_logic;
    
    type updateflagsPerLiteral is array (0 to 2*FSize-1) of std_logic;

end package;
