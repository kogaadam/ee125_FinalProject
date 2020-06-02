library ieee;
use ieee.std_logic_1164.all;

entity pong_control_gen is
	generic(
		H_LOW: natural := 96;
		HBP: natural := 48;
		H_HIGH: natural := 640;
		HFP: natural := 16;
		V_LOW: natural := 2;
		VBP: natural := 33;
		V_HIGH: natural := 480;
		VFP: natural := 10);
	port (
		sys_clk: in std_logic;
		vga_clk: out std_logic;
		h_active, v_active, d_ena: out std_logic;
		h_sync, v_sync: out std_logic;
		blank_n, sync_n: out std_logic);
end entity;

architecture structural of pong_control_gen is
	signal vga_clk_sig: std_logic;
begin

	blank_n <= '1';
	sync_n <= '0';
	
	-- Create VGA clock (50MHz -> 25 MHz)
	process (sys_clk)
	begin
		if rising_edge(sys_clk) then
			vga_clk_sig <= not vga_clk_sig;
		end if;
	end process;
	
	-- Create horizontal signals
	process(vga_clk_sig)
		variable Hcount: natural range 0 to H_LOW + HBP + H_HIGH + HFP;
	begin
		if rising_edge(vga_clk_sig) then
			Hcount := Hcount + 1;
			if Hcount = H_LOW then
				h_sync <= '1';
			elsif Hcount = H_LOW + HBP then
				h_active <= '1';
			elsif Hcount = H_LOW + HBP + H_HIGH then
				h_active <= '0';
			elsif Hcount = H_LOW + HBP + H_HIGH + HFP then
				h_sync <= '0';
				Hcount := 0;
			end if;
		end if;
	end process;

	-- Create horizontal signals
	process(vga_clk_sig)
		variable Vcount: natural range 0 to V_LOW + VBP + V_HIGH + VFP;
	begin
		if rising_edge(vga_clk_sig) then
			Vcount := Vcount + 1;
			if Vcount = V_LOW then
				V_sync <= '1';
			elsif Vcount = V_LOW + VBP then
				V_active <= '1';
			elsif Vcount = V_LOW + VBP + V_HIGH then
				V_active <= '0';
			elsif Vcount = V_LOW + VBP + V_HIGH + VFP then
				V_sync <= '0';
				Vcount := 0;
			end if;
		end if;
	end process;
	
	-- Enable display
	d_ena <= h_active and v_active;
	vga_clk <= vga_clk_sig;

end architecture;