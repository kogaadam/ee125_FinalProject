library ieee;
use ieee.std_logic_1164.all;

entity pong_image_gen is
		generic (
			H_HIGH: natural;
			V_HIGH: natural);
		port (
			clk_vga, Hactive, Vactive, dena, Hsync: in std_logic;
			left_button, right_button: in std_logic;
			R, G, B: out std_logic_vector(3 downto 0));
end entity;

	
architecture structural of pong_image_gen is

	signal rect_clock_sig: std_logic;
	signal rect_center: natural := 320;
	signal ball_center_x: natural := 320;
	signal ball_center_y: natural := 435;
	signal angle: natural := 45;

begin

	process(clk_vga)
		variable counter: natural;
		variable rect_clock: std_logic;
	begin
		if rising_edge(clk_vga) then
			counter := counter + 1;
			if counter = 250000 then
				counter := 0;
				rect_clock := not rect_clock;
			end if;
		end if;
		rect_clock_sig <= rect_clock;
	end process;
	
	process(rect_clock_sig)
	begin
		if rising_edge(rect_clock_sig) then
			if not left_button and right_button then
				if rect_center = 40 then
					rect_center <= H_HIGH - 40;
				else
					rect_center <= rect_center - 5;
				end if;
			elsif not right_button and left_button then
				if rect_center = H_HIGH - 40 then
					rect_center <= 40;
				else
					rect_center <= rect_center + 5;
				end if;
			end if;
			
			if angle >= 0 and angle < 90 then
				if ball_center_x = H_HIGH - 5 then
					angle <= 135;
				elsif ball_center_y = 5 then
					angle <= 315;
				else
					ball_center_x <= ball_center_x + 5;
					ball_center_y <= ball_center_y - 5;
				end if;
			elsif angle >= 90 and angle < 180 then
				if ball_center_x = 5 then
					angle <= 45;
				elsif ball_center_y = 5 then
					angle <= 225;
				else
					ball_center_x <= ball_center_x - 5;
					ball_center_y <= ball_center_y - 5;
				end if;
			elsif angle >= 180 and angle < 270 then
				if ball_center_x = 5 then
					angle <= 315;
				elsif ball_center_y = V_HIGH - 5 then
					angle <= 135;
				elsif ball_center_y = 435 and
						ball_center_x > rect_center - 40 and ball_center_x < rect_center + 40 then
					angle <= 135;
				else
					ball_center_x <= ball_center_x - 5;
					ball_center_y <= ball_center_y + 5;
				end if;
			else
				if ball_center_x = H_HIGH - 5 then
					angle <= 225;
				elsif ball_center_y = V_HIGH - 5 then
					angle <= 45;
				elsif ball_center_y = 435 and
						ball_center_x > rect_center - 40 and ball_center_x < rect_center + 40 then
					angle <= 45;
				else
					ball_center_x <= ball_center_x + 5;
					ball_center_y <= ball_center_y + 5;
				end if;
			end if;
			
		end if;
		
	end process;
	
	-- Image creation
	process(all)
		variable line_count: natural range 0 to V_HIGH;
		variable col_count: natural range 0 to H_HIGH;
	begin
				
		if rising_edge(Hsync) then
			if Vactive then
				line_count := line_count + 1;
			else
				line_count := 0;
			end if;
		end if;
		
		if rising_edge(clk_vga) then
			if Hactive then
				col_count := col_count + 1;
			else
				col_count := 0;
			end if;
		end if;
		
		if dena then
			-- Position of ball
			if line_count > ball_center_y - 5 and line_count < ball_center_y + 5
				and col_count = ball_center_x then
				R <= (others => '0');
				G <= (others => '1');
				B <= (others => '0');

			elsif line_count = ball_center_y and
					col_count > ball_center_x - 5 and col_count < ball_center_x + 5 then
				R <= (others => '0');
				G <= (others => '1');
				B <= (others => '0');
					
			-- Postion of rectangle
			elsif line_count > 440 and line_count < 460 and
					col_count > rect_center - 40 and col_count < rect_center + 40 then
				R <= (others => '0');
				G <= (others => '1');
				B <= (others => '0');
			else
				R <= (others => '0');
				G <= (others => '0');
				B <= (others => '0');
			end if;
			
		else
			R <= (others => '0');
			G <= (others => '0');
			B <= (others => '0');
		end if;
	end process;
	
end architecture;