----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:49:02 04/27/2012 
-- Design Name: 
-- Module Name:    vga - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga is
 port ( 
        clk25 : in  STD_LOGIC;
        reset : in  STD_LOGIC;
        x_out : out unsigned(9 downto 0);
        y_out : out unsigned(9 downto 0);
        pixel_in : in  STD_LOGIC_VECTOR (2 downto 0);
        vga_r : out  STD_LOGIC;
        vga_g : out  STD_LOGIC;
        vga_b : out  STD_LOGIC;
        vga_hs : out  STD_LOGIC;
        vga_vs : out  STD_LOGIC
      );
end vga;

architecture Behavioral of vga is

signal cnt_h : unsigned (9 downto 0) := "0000000000";
signal cnt_v : unsigned (9 downto 0) := "0000000000";
signal visible : STD_LOGIC := '0';

begin
visible <= '1' when cnt_h >= 144 and cnt_h <= 784 and cnt_v >= 31 and cnt_v <= 510 else '0';

x_out <= cnt_h - 144 when visible = '1' else (others => '0');
y_out <= cnt_v - 31 when visible = '1' else (others => '0');

vga_r <= pixel_in(0) when visible = '1' else '0';
vga_g <= pixel_in(1) when visible = '1' else '0';
vga_b <= pixel_in(2) when visible = '1' else '0';

vga_hs <= '0' when cnt_h >= 0 and cnt_h <= 95 else '1';
vga_vs <= '0' when cnt_v >= 0 and cnt_v <= 2 else '1';

process (clk25)
begin 
	if rising_edge(clk25) then
		if reset = '1' then
		   cnt_h <= to_unsigned(0,10);
			cnt_v <=to_unsigned(0,10); 
		end if;
		cnt_h <= cnt_h+1;
		if cnt_h = to_unsigned(800,10) then
			cnt_v <= cnt_v+1;
			cnt_h <= to_unsigned(0,10);
		end if;
		if cnt_v = to_unsigned(521,10) then 
			cnt_v <= to_unsigned(0,10);
		end if;
	end if;
end process;



end Behavioral;

