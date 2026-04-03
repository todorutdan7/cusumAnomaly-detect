// Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2016.4 (win64) Build 1756540 Mon Jan 23 19:11:23 MST 2017
// Date        : Thu Dec 04 13:29:31 2025
// Host        : DESKTOP-QVRQ7GA running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/Dan/CUSUM/CUSUM.srcs/sources_1/ip/axis_broadcaster_0/axis_broadcaster_0_stub.v
// Design      : axis_broadcaster_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tcpg236-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "top_axis_broadcaster_0,Vivado 2016.4" *)
module axis_broadcaster_0(aclk, aresetn, s_axis_tvalid, s_axis_tready, 
  s_axis_tdata, m_axis_tvalid, m_axis_tready, m_axis_tdata)
/* synthesis syn_black_box black_box_pad_pin="aclk,aresetn,s_axis_tvalid,s_axis_tready,s_axis_tdata[31:0],m_axis_tvalid[1:0],m_axis_tready[1:0],m_axis_tdata[63:0]" */;
  input aclk;
  input aresetn;
  input s_axis_tvalid;
  output s_axis_tready;
  input [31:0]s_axis_tdata;
  output [1:0]m_axis_tvalid;
  input [1:0]m_axis_tready;
  output [63:0]m_axis_tdata;
endmodule
