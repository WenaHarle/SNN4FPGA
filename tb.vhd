library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_lif_neuron_struct is end;

architecture sim of tb_lif_neuron_struct is
  constant DATA_W : integer := 12;
  constant ACC_W  : integer := 24;

  signal clk, rst, en : std_logic := '0';
  signal x1, x2, x3   : std_logic := '0';
  signal w1, w2, w3   : signed(DATA_W-1 downto 0);
  signal spike        : std_logic;
  signal v_out        : signed(ACC_W-1 downto 0);

  constant Tclk : time := 10 ns;

  procedure step(n:integer) is
  begin
    for i in 1 to n loop
      wait until rising_edge(clk);
    end loop;
  end procedure;

begin
  -- Clock
  clk <= not clk after Tclk/2;

  -- DUT (PERHATIKAN: THRESH=700, LEAK_SHIFT=3)
  dut: entity work.lif_neuron_struct
    generic map (
      DATA_W     => DATA_W,
      ACC_W      => ACC_W,
      THRESH     => 700,
      LEAK_SHIFT => 3
    )
    port map (
      clk   => clk,
      rst   => rst,
      en    => en,
      x1    => x1,
      x2    => x2,
      x3    => x3,
      w1    => w1,
      w2    => w2,
      w3    => w3,
      spike => spike,
      v_out => v_out
    );

  -- Stimulus
  stim: process
  begin
    -- Reset & init
    rst <= '1'; en <= '0';
    w1 <= to_signed(128, DATA_W);
    w2 <= to_signed( 64, DATA_W);
    w3 <= to_signed( 32, DATA_W);
    x1 <= '0'; x2 <= '0'; x3 <= '0';
    step(2);

    rst <= '0'; en <= '1';

    -- Integrasi bertahap
    x1 <= '1'; x2 <= '0'; x3 <= '0'; step(3);  -- +128
    x1 <= '0'; x2 <= '1'; x3 <= '0'; step(2);  -- +64
    x1 <= '0'; x2 <= '0'; x3 <= '1'; step(2);  -- +32

    -- Leak (idle)
    x1 <= '0'; x2 <= '0'; x3 <= '0'; step(6);

    -- Trigger spike (semua aktif) - perpanjang agar menembus ambang
    x1 <= '1'; x2 <= '1'; x3 <= '1'; step(10);

    -- Non-enable: hold (tidak spike)
    en <= '0'; x1 <= '1'; x2 <= '1'; x3 <= '1'; step(4);

    wait;
  end process;

  -- Monitor (bantu debug)
  monitor: process(clk)
  begin
    if rising_edge(clk) then
      report "t=" & time'image(now)
        & " x=" & std_logic'image(x1) & std_logic'image(x2) & std_logic'image(x3)
        & " v_out=" & integer'image(to_integer(v_out))
        & " spike=" & std_logic'image(spike);
    end if;
  end process;

end architecture;
