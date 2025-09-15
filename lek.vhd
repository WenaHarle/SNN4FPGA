library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lif_leak is
  generic(WIDTH : integer := 24; SHIFT : integer := 3);
  port(
    v_in  : in  signed(WIDTH-1 downto 0);
    v_out : out signed(WIDTH-1 downto 0)
  );
end entity;

architecture rtl of lif_leak is
begin
  -- v_out = v_in - v_in/2^SHIFT  (β = 1 - 1/2^SHIFT)
  v_out <= v_in - shift_right(v_in, SHIFT);
end architecture;
