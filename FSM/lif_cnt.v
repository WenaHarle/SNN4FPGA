`timescale 1ns/1ps
module lif_cnt #(
  parameter integer N_OUT = 30,
  parameter integer N_IN  = 30
)(
  input  wire       clk,
  input  wire       rst_n,
  input  wire       clr_all,
  input  wire       acc_init,
  input  wire       acc_step,
  input  wire       next_out,
  output wire [5:0] outi,
  output wire [5:0] ini,
  output wire       ini_last,
  output wire       out_last
);

  reg [5:0] outi_ps, outi_ns;
  reg [5:0] ini_ps,  ini_ns;

  localparam [5:0] OUT_LAST = N_OUT-1;
  localparam [5:0] IN_LAST  = N_IN-1;

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      outi_ps <= 6'd0;
      ini_ps  <= 6'd0;
    end else begin
      outi_ps <= outi_ns;
      ini_ps  <= ini_ns;
    end
  end

  always @(*) begin
    outi_ns = outi_ps;
    ini_ns  = ini_ps;

    if (clr_all) begin
      outi_ns = 6'd0;
      ini_ns  = 6'd0;
    end

    if (acc_init) begin
      ini_ns = 6'd0;
    end

    if (acc_step && (ini_ps != IN_LAST)) begin
      ini_ns = ini_ps + 6'd1;
    end

    if (next_out && (outi_ps != OUT_LAST)) begin
      outi_ns = outi_ps + 6'd1;
    end
  end

  assign outi     = outi_ps;
  assign ini      = ini_ps;
  assign ini_last = (ini_ps  == IN_LAST);
  assign out_last = (outi_ps == OUT_LAST);

endmodule
