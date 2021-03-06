library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity paddle is
	port (
		clk : in std_logic;
		rst : in std_logic;
		catch_ball : in std_logic; -- catch the ball onto the paddle
		ps2_data : in std_logic_vector (7 downto 0);
		ps2_strobe : in std_logic;
		set_ball_strobe : out std_logic; -- indicate that set_ball is correct address
		set_ball_position : out positionT;
		-- visible representation
		rgb_for_position : in positionT;
		rgb : out rgbT;
		-- collision detection
		ball_position : in positionT;
		collision_speed_effect_edge : out std_logic_vector(2 downto 0);
		paddle_collision_vector : out collision_vectorT
	);
end entity paddle;
 

architecture RTL of paddle is
constant PADDLE_SIZE_X : integer := 50;
constant PADDLE_SIZE_Y : integer := 5;

signal paddle_begin : x_pos := to_unsigned (140, x_pos'length) ;
signal paddle_begin_Next : x_pos := to_unsigned (140, x_pos'length) ;
type tState is  (Start, Idle ,Ignore, Move_Right , Move_Left);
signal State : tState := Idle;
signal NextState : tState;
signal cnt: unsigned (17 downto 0):= (others => '0') ;
signal cnt_old: unsigned (17 downto 0):= (others => '0') ;
signal ps2_strobe_old : std_logic;
signal ps2_strobe_edge : std_logic;
signal action : std_logic;
signal right_signal : std_logic:= '0';
signal left_signal : std_logic:= '0';
signal release_ball : std_logic := '0';
signal stop : std_logic:= '0'; 

signal paddle_collision_tmp : std_logic;
signal paddle_collision_tmp_old : std_logic;
signal paddle_collision_tmp_edge : std_logic;
signal collision_speed_effect: std_logic_vector(2 downto 0);

type paddleState is (ball_catched, ball_free);
signal State_1: paddleState := ball_catched ;
signal NextState_1: paddleState;

signal current_position : positionT; -- left upper corner of paddle
	
begin
right_signal <= '1' when ps2_data = x"74" and ps2_strobe_edge = '1' else '0';
left_signal <= '1' when ps2_data = x"6B" and ps2_strobe_edge = '1' else '0';
release_ball <= '1' when ps2_data = x"73" and ps2_strobe_edge = '1' else '0';
stop <= '1' when ps2_data = x"F0" and ps2_strobe_edge = '1' else '0';
action <= cnt(cnt'left) and not cnt_old(cnt_old'left);
ps2_strobe_edge <= ps2_strobe and not ps2_strobe_old;
current_position <= (x => paddle_begin , y=>TO_UNSIGNED(225,y_pos'length));
set_ball_position <= (x => (paddle_begin + (PADDLE_SIZE_X/2)) , y => (to_unsigned(225, y_pos'length) - 1)); 

collision_detection : process (ball_position,current_position)
begin
	paddle_collision_tmp <= '0';
	if ball_position.x >= current_position.x and  
	   current_position.x + PADDLE_SIZE_X >= ball_position.x and
		ball_position.y = current_position.y then 
			paddle_collision_tmp <= '1';
	end if;
end process;

process (clk, rst)
begin
  if rising_edge (clk) then 
    if rst = '1' then 
		State <= Start;
		State_1 <= ball_free;
		cnt <= (others => '0');
	 else 
	   State <= NextState;
		State_1 <= NextState_1;
		cnt <= cnt+1;
		cnt_old <= cnt;
		ps2_strobe_old <= ps2_strobe;
		paddle_begin <= paddle_begin_Next;
		paddle_collision_tmp_old <= paddle_collision_tmp;
	 end if;
  end if;
end process;

movement_state_machine : process (State,cnt,paddle_begin,right_signal,left_signal,stop,action)
begin
  -- default values
  NextState <= State;
  paddle_begin_Next <= paddle_begin;
  case (State) is 
    when Start =>  
	   paddle_begin_Next <= to_unsigned (140,paddle_begin_Next'length) ;
		NextState <= Idle;
    when Idle =>
	   if right_signal = '1'  then
		  NextState <= Move_Right;
		end if;
		if left_signal = '1' then
		  NextState <= Move_Left;
		end if;
	 when Move_Right =>
	   if action = '1' and (paddle_begin + PADDLE_SIZE_X)<= to_unsigned(329, paddle_begin'length) then 
		  paddle_begin_Next <= paddle_begin + 1;
		end if;
		if stop = '1' then
		  NextState <= Ignore;
		end if;
	 when Move_Left =>
	   if action = '1' and paddle_begin >= to_unsigned(1, paddle_begin'length) then 
		  paddle_begin_Next <= paddle_begin -1;
		end if; 
		if stop= '1' then
		  NextState <= Ignore;
		end if;
	 when Ignore =>
		if right_signal = '1' or left_signal = '1' then
		  NextState <= Idle;
		end if;
	 when others => Null;
  end case;
end process;

catch_ball_state_machine : process (State_1, release_ball , catch_ball)
begin
	NextState_1 <= State_1;
	case (State_1) is 
		when ball_catched => 
			set_ball_strobe <= '1';
			if release_ball = '1' then 
					NextState_1 <= ball_free;
			end if;
		when ball_free =>
			set_ball_strobe <= '0';
			if catch_ball = '1' then 
				NextState_1 <= ball_catched;
			end if;
		when others => Null;
	end case;
end process;

-- paddle and Lives Drawing
rgb_writer : process (rgb_for_position,paddle_begin)
begin 
  rgb <= "000";
  if (rgb_for_position.x > paddle_begin) and (rgb_for_position.x < (paddle_begin + PADDLE_SIZE_X )) and (rgb_for_position.y > 225) and (rgb_for_position.y < 230)then 
    rgb <= "001";
  end if;
end process; -- Paddle and Lives Drawing

-- effekt on ball speed according to collisions position

--000     001                              010      011			code for signal "collision_speed_effect"
------l--------l------------------------l--------l-------
------l--------l------------------------l--------l-------

process (paddle_collision_tmp_edge,paddle_begin ,ball_position)
begin
	collision_speed_effect <= "111";
	if paddle_collision_tmp_edge = '1' then 
		if ball_position.x <= paddle_begin + (PADDLE_SIZE_X/6) then
			collision_speed_effect <= "000";
		elsif (ball_position.x  >=  paddle_begin+ (PADDLE_SIZE_X/6)) and (ball_position.x <=  paddle_begin+ (PADDLE_SIZE_X/3)) then
			collision_speed_effect <= "001";
		elsif (ball_position.x >=  paddle_begin+ ((2*PADDLE_SIZE_X)/3)) and (ball_position.x <=  paddle_begin+ ((5*PADDLE_SIZE_X)/6)) then
			collision_speed_effect <= "010";
		elsif (ball_position.x >=  paddle_begin+ ((5*PADDLE_SIZE_X)/6)) then
			collision_speed_effect <= "011";
		end if;
	end if;
end process;

paddle_collision_vector <= paddle_collision_tmp & '0';
paddle_collision_tmp_edge <= paddle_collision_tmp and not paddle_collision_tmp_old;
collision_speed_effect_edge <= collision_speed_effect when paddle_collision_tmp_edge= '1' else "111";

end architecture RTL;
