library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lif_membrane is
  generic(WIDTH : integer := 24; THRESH : integer := 700);
  port(
    clk, rst, en : in std_logic;
    v_in   : in  signed(WIDTH-1 downto 0);  -- v_next_pre dari top
    v_mem  : out signed(WIDTH-1 downto 0);
    spike  : out std_logic
  );
end entity;

architecture rtl of lif_membrane is
  signal v_reg,  v_next_en, v_next_rst : signed(WIDTH-1 downto 0);
  signal spk_reg, spk_next, spk_next_rst : std_logic;
  signal ge_thresh, spike_en : std_logic;
begin
  -- Komparasi ambang (pure logic)
  ge_thresh <= '1' when v_in >= to_signed(THRESH, WIDTH) else '0';
  spike_en  <= '1' when (en='1' and ge_thresh='1') else '0';

  -- Mux enable: spike_en reset, en commit, selain itu hold
  v_next_en <= (others => '0')  when spike_en='1' else
               v_in             when en='1'       else
               v_reg;

  spk_next  <= '1' when spike_en='1' else '0';

  -- Reset sinkron via mux (satu titik)
  v_next_rst    <= (others => '0') when rst='1' else v_next_en;
  spk_next_rst  <= '0'             when rst='1' else spk_next;

  -- Register tunggal (IF hanya untuk edge clock)
  process(clk)
  begin
    if rising_edge(clk) then
      v_reg   <= v_next_rst;
      spk_reg <= spk_next_rst;
    end if;
  end process;

  v_mem <= v_reg;
  spike <= spk_reg;
end architecture;
