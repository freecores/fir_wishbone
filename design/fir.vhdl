/* FIR Filter.
	
	Copyright© 2012 Daniel C.K. Kho. All rights reserved.
	This core is free hardware design; you can redistribute it and/or
	modify it under the terms of the GNU Library General Public
	License as published by the Free Software Foundation; either
	version 2 of the License, or (at your option) any later version.
	
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	Library General Public License for more details.
	
	You should have received a copy of the GNU Library General Public
	License along with this library; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
	
	License: LGPL.
	
	@dependencies: 
	@designer: Daniel C.K. Kho [daniel.kho@gmail.com] | [daniel.kho@tauhop.com] | [daniel.kho@sophicdesign.com.my]
	@info: 
	Revision History: @see Mercurial log for full list of changes.
	
	This notice and disclaimer must be retained as part of this text at all times.
*/
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.math_real.all;			-- log,sin

--entity fir is generic(numCoeffs:positive:=145; width:positive:=28);
entity fir is generic(numCoeffs:positive:=31; width:positive:=16);
	port(
		/* General settings. */
		reset:in std_ulogic;			-- asserting reset will start protocol sequence transmission. To restart the re-transmission of the sequence, re-assert this reset signal, and the whole SPI sequence will be re-transmitted again.
		clk:in std_ulogic:='0';
		
		/* Filter ports. */
		u:in unsigned(width-1 downto 0):=(others=>'0');
		y:buffer unsigned(width*2-1 downto 0)
	);
end entity fir;

architecture rtl of fir is
--	/* Memories. */
--	type rfbFsm_vector is array(natural range <>) of rfbFsm;
--	
	/* Memory I/Os: */
	signal q:unsigned(width-1 downto 0):=(others=>'0');
	
	--signal c:unsigned(positive(ceil(log2(real(numCoeffs))))-1 downto 0);	--counter:5bits
	
	/* Memory arrays: */
	/* TODO: Change these arrays to internal process variables instead. */
	/* Read-only Memory (ROM). */
	type unsigned_vector is array(natural range <>) of unsigned(width-1 downto 0);		-- 32-by-N matrix array structure (as in RAM). Similar to integer_vector, difference being base vector is 32-bit unsigned.
	type unsignedx2_vector is array(natural range<>) of unsigned(width*2-1 downto 0);
	
	constant b:unsigned_vector(0 to numCoeffs-1):=(
		x"FFEF",
		x"FFED",
		x"FFE8",
		x"FFE6",
		x"FFEB",
		x"0000",
		x"002C",
		x"0075",
		x"00DC",
		x"015F",
		x"01F4",
		x"028E",
		x"031F",
		x"0394",
		x"03E1",
		x"03FC",
		x"03E1",
		x"0394",
		x"031F",
		x"028E",
		x"01F4",
		x"015F",
		x"00DC",
		x"0075",
		x"002C",
		x"0000",
		x"FFEB",
		x"FFE6",
		x"FFE8",
		x"FFED",
		x"FFEF"
	);
	/*Memory Addressing*/
	--signal c:natural range b'range;
	
	/* Pipes and delay chains. */
	signal u_pipe:unsigned_vector(b'range):=(others=>(others=>'0'));
	signal y_pipe:unsignedx2_vector(b'range):=(others=>(others=>'0'));
	
	
	/* Counters. */
--	signal cnt:integer range 31 downto -1;			-- symbol / bit counter. Counts the bits transmitted on the serial line.
	
--	/* memory pointers (acts as the read/write address for the synchronous RAM). */
--	signal instrPtr:natural range rfbSequencesCache'range;		--RFB sequence memory addressing. Acts as instruction pointer. Points to the current SPI instruction to be transmitted on MOSI. Size is one more than the instruction cache size, so it points past the last valid address (used for counting).
	/* [end]: Memories. */
	
	/* Signal preservations. */
--	attribute keep:boolean;
--	attribute keep of u_pipe:signal is true;
--	attribute keep of b:constant is true;
--	attribute keep of y_pipe:signal is true;
	
	/* Explicitly define all multiplications with the "*" operator to use dedicated DSP hardware multipliers. */
	--altera:
--	attribute multstyle:string; attribute multstyle of rtl:architecture is "dsp";
--	--xilinx:
--	attribute mult_style:string; attribute mult_style of fir:entity is "block";
	
begin
----	/* 1-Dimensional Synchronous ROM. */
--	readCoeffs: process(clk) is begin
--		if rising_edge(clk) then
--			if reset='1' then q<=(others=>'0');
--			else q<=b(c);
--			end if;
--		end if;
--	end process readCoeffs;
	
	u_pipe(0)<=u;
	u_dlyChain: for i in 1 to u_pipe'high generate
		delayChain: process(clk) is begin
			if rising_edge(clk) then u_pipe(i)<=u_pipe(i-1); end if;
		end process delayChain;
	end generate u_dlyChain;
	
	y_pipe(0)<=b(0)*u;
	y_dlyChain: for i in 1 to y_pipe'high generate
		--y_pipe(i-1)<=b(i)*u_pipe(i) + y_pipe(i-2);		--b(i-1)*u_pipe(i-1);
		y_pipe(i)<=q*u_pipe(i) + y_pipe(i-1);		--b(i-1)*u_pipe(i-1);
		--y_pipe(c)<=q*u_pipe(c) + y_pipe(c-1);		--b(i-1)*u_pipe(i-1);
	end generate y_dlyChain;
	
	y<=y_pipe(y_pipe'high) when reset='0' else (others=>'0');
end architecture rtl;
