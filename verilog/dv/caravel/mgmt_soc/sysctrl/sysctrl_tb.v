// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`timescale 1 ns / 1 ps

`include "__uprj_netlists.v"
`include "caravel_netlists.v"
`include "spiflash.v"

module sysctrl_tb;
	reg clock;
	reg RSTB;
	reg csb_set;
	reg power1, power2;

	wire gpio;
	wire [5:0] checkbits;
	wire [31:0] spivalue;
	wire [37:0] mprj_io;
	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;
	wire SDO;

	assign checkbits = mprj_io[37:32];
	assign spivalue  = mprj_io[31:0];

	// mrpj_io[3] = CSB needs to be set until the program disables the SPI.
	assign mprj_io[3] = (csb_set) ? 1'b1 : 1'bz;

	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.

	always #10 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	initial begin
		$dumpfile("sysctrl.vcd");
		$dumpvars(0, sysctrl_tb);
		repeat (25) begin
			repeat (1000) @(posedge clock);
			$display("+1000 cycles");
		end
		$display("%c[1;31m",27);
		`ifdef GL
			$display ("Monitor: Timeout, Test Sysctrl (GL) Failed");
		`else
			$display ("Monitor: Timeout, Test Sysctrl (RTL) Failed");
		`endif
		 $display("%c[0m",27);
		$finish;
	end

	// Monitor
	initial begin
	    wait(checkbits == 6'h04);
			`ifdef GL
            	$display("Monitor: Test Sysctrl (GL) Started");
			`else
			    $display("Monitor: Test Sysctrl (RTL) Started");
			`endif
	    wait(checkbits == 6'h05);
            $display("   Chip ID value = 0x%x (should be 0x00045611)", spivalue);
            if(spivalue !== 32'h00045611) begin
                $display("Monitor: Test Sysctrl Failed");
                $finish;
            end
	    wait(checkbits == 6'h06);
            $display("   User ID value = 0x%x (should be 0x00000000)", spivalue);
            if(spivalue !== 32'h00000000) begin
                $display("Monitor: Test Sysctrl Failed");
                $finish;
            end
	    wait(checkbits == 6'h07);
            $display("   PLL enables value = 0x%x (should be 0x00000002)", spivalue);
            if(spivalue !== 32'h00000002) begin
                $display("Monitor: Test Sysctrl Failed");
                $finish;
            end
	    wait(checkbits == 6'h08);
            $display("   PLL bypass value = 0x%x (should be 0x00000001)", spivalue);
            if(spivalue !== 32'h00000001) begin
                $display("Monitor: Test Sysctrl Failed");
                $finish;
            end
	    wait(checkbits == 6'h09);
            $display("   PLL trim value = 0x%x (should be 0x03ffefff)", spivalue);
            if(spivalue !== 32'h03ffefff) begin
                $display("Monitor: Test Sysctrl Failed");
                $finish;
            end
	    wait(checkbits == 6'h0a);
            $display("   PLL divider value = 0x%x (should be 0x00000012)", spivalue);
            if(spivalue !== 32'h00000012) begin
                $display("Monitor: Test Sysctrl Failed");
                $finish;
            end
	    wait(checkbits == 6'h0b);
            $display("   PLL source value = 0x%x (should be 0x00000004)", spivalue);
            if(spivalue !== 32'h00000004) begin
                $display("Monitor: Test Sysctrl Failed");
                $finish;
            end
	    wait(checkbits == 6'h0c);
            $display("   GPIO config value = 0x%x (should be 0x00001809)", spivalue);
            if(spivalue !== 32'h00001809) begin
                $display("Monitor: Test Sysctrl Failed");
                $finish;
            end


	    wait(checkbits == 6'h0d);
		 	`ifdef GL
            	$display("Monitor: Test Sysctrl (GL) Passed");
			`else
		        $display("Monitor: Test Sysctrl (RTL) Passed");
			`endif
            $finish;
	end

	initial begin
		RSTB <= 1'b0;
		#1000;
		RSTB <= 1'b1;	    // Release reset
		#2000;
	end

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		csb_set <= 1'b1;
		#200;
		power1 <= 1'b1;
		#200;
		power2 <= 1'b1;
		#200000;
		csb_set <= 1'b0;	// Release CSB after SPI is disabled
	end

	always @(checkbits) begin
		#1 $display("GPIO state = %b ", checkbits);
	end

	wire VDD3V3;
	wire VDD1V8;
	wire VSS;
	
	assign VDD3V3 = power1;
	assign VDD1V8 = power2;
	assign VSS = 1'b0;

	
	caravel uut (
		.vddio	  (VDD3V3),
		.vddio_2  (VDD3V3),
		.vssio	  (VSS),
		.vssio_2  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (VDD3V3),
		.vdda1_2  (VDD3V3),
		.vdda2    (VDD3V3),
		.vssa1	  (VSS),
		.vssa1_2  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (VDD1V8),
		.vccd2	  (VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock    (clock),
		.gpio     (gpio),
		.mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("sysctrl.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

endmodule
`default_nettype wire
