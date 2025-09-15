library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lif_neuron_struct is
  generic(
    DATA_W     : integer := 12;   -- lebar bobot (signed)
    ACC_W      : integer := 24;   -- lebar akumulator membran
    THRESH     : integer := 700;  -- ambang spike
    LEAK_SHIFT : integer := 3     -- β = 1 - 1/2^SHIFT
  );
  port(
    clk, rst, en : in std_logic;
    x1, x2, x3   : in std_logic;                            -- 1-bit spikes
    w1, w2, w3   : in signed(DATA_W-1 downto 0);            -- weights
    spike        : out std_logic;
    v_out        : out signed(ACC_W-1 downto 0)
  );
end entity;

architecture structural of lif_neuron_struct is
  signal p1, p2, p3 : signed(2*DATA_W-1 downto 0);
  signal s1, s2, s3 : signed(ACC_W-1 downto 0);
  signal sum_in     : signed(ACC_W-1 downto 0);
  signal v_leak     : signed(ACC_W-1 downto 0);
  signal v_mem      : signed(ACC_W-1 downto 0);
  signal v_next_pre : signed(ACC_W-1 downto 0);
begin
  -- Gate bobot oleh spike 1-bit
  m1: entity work.lif_mult_bit
    generic map ( DATA_W => DATA_W )
    port map ( x => x1, w => w1, p => p1 );

  m2: entity work.lif_mult_bit
    generic map ( DATA_W => DATA_W )
    port map ( x => x2, w => w2, p => p2 );

  m3: entity work.lif_mult_bit
    generic map ( DATA_W => DATA_W )
    port map ( x => x3, w => w3, p => p3 );

  -- Resize produk ke ACC_W untuk adder
  s1 <= resize(p1, ACC_W);
  s2 <= resize(p2, ACC_W);
  s3 <= resize(p3, ACC_W);

  add3: entity work.lif_adder3
    generic map ( WIDTH => ACC_W )
    port map ( a => s1, b => s2, c => s3, sum => sum_in );

  leak: entity work.lif_leak
    generic map ( WIDTH => ACC_W, SHIFT => LEAK_SHIFT )
    port map ( v_in => v_mem, v_out => v_leak );

  -- v_next_pre = leak(v_mem) + sum_in (murni concurrent)
  v_next_pre <= v_leak + sum_in;

  -- Membran
  mem: entity work.lif_membrane
    generic map ( WIDTH => ACC_W, THRESH => THRESH )
    port map (
      clk   => clk,
      rst   => rst,
      en    => en,
      v_in  => v_next_pre,
      v_mem => v_mem,
      spike => spike
    );

  v_out <= v_mem;
end architecture;
