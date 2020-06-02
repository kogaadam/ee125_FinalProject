library ieee;
use ieee.std_logic_1164.all;

entity pong_image_gen is
	generic(
		H_HIGH: natural := 640;
		V_HIGH: natural := 480);
	port (
		h_sync, v_sync: in std_logic;
		h_active, v_active, d_ena: in std_logic;
		r_switch, g_switch, b_switch: in std_logic;
		r, g, b: out std_logic_vector(3 downto 0));
end entity;

architecture structural of pong_image_gen is

begin

	process(all)
		variable line_count: natural range 0 to V_HIGH;
	begin
		if rising_edge(h_sync) then
			if v_active then
				line_count := line_count + 1;
			else
				line_count := 0;
			end if;
		end if;
		
		if d_ena then
			case line_count is
				when 0 =>
					r <= (others => '1');
					g <= (others => '0');
					b <= (others => '0');
				when 1 | 2 | 479 =>
					r <= (others => '0');
					g <= (others => '1');
					b <= (others => '0');
				when 3 to 5 =>
					r <= (others => '0');
					g <= (others => '0');
					b <= (others => '1');
				when others =>
					r <= (others => r_switch);
					g <= (others => g_switch);
					b <= (others => b_switch);
			end case;
		else
			r <= (others => '0');
			g <= (others => '0');
			b <= (others => '0');
		end if;
	end process;

end architecture;