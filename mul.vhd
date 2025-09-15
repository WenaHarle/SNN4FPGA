library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lif_mult_bit is
  generic(DATA_W : integer := 12);
  port(
    x : in  std_logic;                           -- spike 1-bit
    w : in  signed(DATA_W-1 downto 0);           -- weight signed
    p : out signed(2*DATA_W-1 downto 0)          -- "produk" (gate)
  );
end entity;

architecture rtl of lif_mult_bit is
begin
  -- Gate murni: jika x='1' => p=resize(w), else 0
  p <= resize(w, p'length) when x='1' else (others => '0');
end architecture;
