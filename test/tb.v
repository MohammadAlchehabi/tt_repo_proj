`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Replace tt_um_example with your module name:
  tt_um_example user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

   // Clock generation: 10 ns period
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        clk    = 0;
        ui_in  = 8'b00000000;
        uio_in = 8'b00000000;
        ena    = 1;
        rst_n  = 0;  // Assert active-low reset

        // ---------------------------------
        // TEST 1: Reset
        // ---------------------------------
        #12;
        if (uo_out[3:0] !== 4'd0)
            $display("FAIL: Reset test");
        else
            $display("PASS: Reset test");

        // Release reset
        rst_n = 1;

        // ---------------------------------
        // TEST 2: Count UP
        // Expected: 1, 2, 3, 4, 5
        // ---------------------------------
        ui_in[0] = 1;
        repeat (5) @(posedge clk);
        #1;
        if (uo_out[3:0] !== 4'd5)
            $display("FAIL: Count-up test, got %0d",
                     uo_out[3:0]);
        else
            $display("PASS: Count-up test");

        // ---------------------------------
        // TEST 3: Count DOWN
        // Expected: 4, 3, 2
        // ---------------------------------
        ui_in[0] = 0;
        repeat (3) @(posedge clk);
        #1;
        if (uo_out[3:0] !== 4'd2)
            $display("FAIL: Count-down test, got %0d",
                     uo_out[3:0]);
        else
            $display("PASS: Count-down test");

        // ---------------------------------
        // TEST 4: Count-up rollover
        // Count from 2 through 15 to 0
        // ---------------------------------
        ui_in[0] = 1;
        repeat (14) @(posedge clk);
        #1;
        if (uo_out[3:0] !== 4'd0)
            $display("FAIL: Up-rollover test, got %0d",
                     uo_out[3:0]);
        else
            $display("PASS: Up-rollover test");

        // ---------------------------------
        // TEST 5: Count-down rollover
        // 0 -> 15
        // ---------------------------------
        ui_in[0] = 0;
        @(posedge clk);
        #1;
        if (uo_out[3:0] !== 4'd15)
            $display("FAIL: Down-rollover test, got %0d",
                     uo_out[3:0]);
        else
            $display("PASS: Down-rollover test");

        // ---------------------------------
        // TEST 6: Reset while counting
        // ---------------------------------
        #2;
        rst_n = 0;
        #1;
        if (uo_out[3:0] !== 4'd0)
            $display("FAIL: Asynchronous reset test");
        else
            $display("PASS: Asynchronous reset test");

        #10;
        rst_n = 1;

        // Finish
        #10;
        $display("--------------------------------");
        $display("Simulation completed.");
        $finish;
    end

endmodule
