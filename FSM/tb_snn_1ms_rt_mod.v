`timescale 1ns/1ps
module tb_snn_1ms_rt_mod;

  localparam integer N_IN   = 30;
  localparam integer TSTEPS = 64;

  localparam integer CLK_HALF_NS = 5;
  localparam time    PERIOD_1MS  = 1_000_000;

  reg clk;
  reg rst_n;
  reg start;
  reg [N_IN-1:0] spikes_in_bits;

  wire done;
  wire [4:0] spikes_out_bits;

  snn_ecg_net_mod dut(
    .clk(clk), .rst_n(rst_n),
    .start(start),
    .spikes_in_bits(spikes_in_bits),
    .done(done),
    .spikes_out_bits(spikes_out_bits)
  );

  reg [31:0] stim [0:TSTEPS-1];
  integer t;

  initial begin
    clk = 1'b0;
    forever #CLK_HALF_NS clk = ~clk;
  end

  initial begin
    $readmemh("spikes_F.mem", stim);

    rst_n = 1'b0;
    start = 1'b0;
    spikes_in_bits = {N_IN{1'b0}};
    #100;
    rst_n = 1'b1;

    for (t = 0; t < TSTEPS; t = t + 1) begin
      spikes_in_bits = stim[t][N_IN-1:0];

      @(posedge clk);
      start <= 1'b1;
      @(posedge clk);
      start <= 1'b0;

      wait(done == 1'b1);
      @(posedge clk);

      #(PERIOD_1MS);
    end

    #1000;
    $finish;
  end

endmodule
