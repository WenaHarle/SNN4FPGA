library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lif_adder3 is
  generic(WIDTH : integer := 24);
  port(
    a, b : in  signed(WIDTH-1 downto 0);
    c    : in  signed(WIDTH-1 downto 0);
    sum  : out signed(WIDTH-1 downto 0)
  );
end entity;

architecture rtl of lif_adder3 is
begin
  sum <= a + b + c;
end architecture;
