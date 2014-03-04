library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fir is end entity tb_fir;

architecture sim of tb_fir is
	signal clk,reset:std_ulogic:='0';
	signal u: unsigned(16-1 downto 0);
	signal y: unsigned(16*2-1 downto 0);
	signal count: unsigned(3 downto 0);
	signal pwrUpCnt:unsigned(3 downto 0):=(others=>'0');
	
begin
	clk<=not clk after 10 ns;
	process(clk) is begin
		if pwrUpCnt<10 then reset<='1';
		else reset<='0';
		end if;
	end process;
	
	fir_test: entity work.fir(rtl)
	port map (
		reset =>	reset,
		clk => clk,
		
		/* Filter ports. */
		u => u,
		y => y
	
	);

	process(reset,clk) is begin
		if reset = '1' then count <= (others =>'0');
		elsif rising_edge(clk) then
			if count<10 then count<=count+1; end if;
		end if;
	end process;
	
	process(clk) is begin
		if rising_edge(clk) then
			if pwrUpCnt<10 then pwrUpCnt<=pwrUpCnt+1; end if;
		end if;
	end process;
	
	u<= x"0001" when count=5 else x"0000";
	
end architecture sim;
