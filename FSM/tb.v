
// tb_snn_full.v
// Testbench: reads spikes.mem (packed 30-bit per line, hex) and runs T timesteps.
// IMPORTANT: This sim needs LONG runtime. Use "run -all" in XSim, or set runtime to e.g. 20ms.
`timescale 1ns/1ps
module tb_snn_full;
  reg clk;
  reg rst_n;
  reg start;
  reg [29:0] spikes_in_bits;
  wire done;
  wire [4:0] spikes_out_bits;

  // DUT
  snn_ecg_net dut(
    .clk(clk), .rst_n(rst_n),
    .start(start),
    .spikes_in_bits(spikes_in_bits),
    .done(done),
    .spikes_out_bits(spikes_out_bits)
  );

  // stimulus
  localparam integer TSTEPS = 64;
  reg [31:0] stim [0:TSTEPS-1];

  integer t;
  integer cnt0, cnt1, cnt2, cnt3, cnt4;

  // clock 100MHz
  initial clk = 1'b0;
  always #5 clk = ~clk;

  task step_timestep;
    input integer ti;
    begin
      spikes_in_bits = stim[ti][29:0];
      // pulse start for 1 cycle
      start = 1'b1;
      @(posedge clk);
      start = 1'b0;

      // wait done
      while(done !== 1'b1) begin
        @(posedge clk);
      end

      // count output spikes (5 classes)
      if(spikes_out_bits[0]) cnt0 = cnt0 + 1;
      if(spikes_out_bits[1]) cnt1 = cnt1 + 1;
      if(spikes_out_bits[2]) cnt2 = cnt2 + 1;
      if(spikes_out_bits[3]) cnt3 = cnt3 + 1;
      if(spikes_out_bits[4]) cnt4 = cnt4 + 1;

      $display("t=%0d in=0x%08h out=%b counts=[%0d %0d %0d %0d %0d]",
               ti, stim[ti], spikes_out_bits, cnt0,cnt1,cnt2,cnt3,cnt4);
    end
  endtask

  initial begin
    // init
    rst_n = 1'b0;
    start = 1'b0;
    spikes_in_bits = 30'd0;
    cnt0=0; cnt1=0; cnt2=0; cnt3=0; cnt4=0;

    // NOTE: using spikes.mem (provided). Each line should contain up to 30 bits in hex.
    $readmemh("spikes.mem", stim);

    // reset
    repeat(5) @(posedge clk);
    rst_n = 1'b1;
    repeat(2) @(posedge clk);

    for(t=0; t<TSTEPS; t=t+1) begin
      step_timestep(t);
    end

    $display("FINAL counts=[%0d %0d %0d %0d %0d]", cnt0,cnt1,cnt2,cnt3,cnt4);
    $finish;
  end
endmodule
