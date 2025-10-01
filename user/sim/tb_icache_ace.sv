`timescale 1ns/1ns
`include "../src/gpgpu_top/define.svh"
`include "../src/gpgpu_top/define_ace.svh"
import i_cache::*;

module tb_icache_ace;

  // Clock and reset
  logic clk;
  logic rst_n;

  // Core interface signals
  logic                            core_req_valid_i;
  logic [`KIANA_XLEN-1:0]          core_req_addr_i;
  logic [`KIANA_NUM_FETCH-1:0]     core_req_mask_i;
  logic [`KIANA_DEPTH_WARP-1:0]    core_req_wid_i;

  logic                            flush_pipe_valid_i;
  logic [`KIANA_DEPTH_WARP-1:0]    flush_pipe_wid_i;

  logic                            core_rsp_valid_o;
  logic [`KIANA_XLEN-1:0]          core_rsp_addr_o;
  logic [`KIANA_NUM_FETCH*`KIANA_XLEN-1:0] core_rsp_data_o;
  logic [`KIANA_NUM_FETCH-1:0]     core_rsp_mask_o;
  logic [`KIANA_DEPTH_WARP-1:0]    core_rsp_wid_o;
  logic                            core_rsp_status_o;

  // ACE interface signals
  logic                            ace_arvalid_o;
  logic                            ace_arready_i;
  logic [`ACE_ID_WIDTH-1:0]        ace_arid_o;
  logic [`ACE_ADDR_WIDTH-1:0]      ace_araddr_o;
  logic [7:0]                      ace_arlen_o;
  logic [2:0]                      ace_arsize_o;
  logic [1:0]                      ace_arburst_o;
  logic [1:0]                      ace_arlock_o;
  logic [3:0]                      ace_arcache_o;
  logic [2:0]                      ace_arprot_o;
  logic [3:0]                      ace_arqos_o;
  logic [3:0]                      ace_arregion_o;
  logic [`ACE_AR_SNOOP_WIDTH-1:0]  ace_arsnoop_o;
  logic [1:0]                      ace_ardomain_o;
  logic [1:0]                      ace_arbar_o;
  logic [`ACE_USER_WIDTH-1:0]      ace_aruser_o;

  logic                            ace_rvalid_i;
  logic                            ace_rready_o;
  logic [`ACE_ID_WIDTH-1:0]        ace_rid_i;
  logic [`ACE_DATA_WIDTH-1:0]      ace_rdata_i;
  logic [1:0]                      ace_rresp_i;
  logic                            ace_rlast_i;
  logic [`ACE_USER_WIDTH-1:0]      ace_ruser_i;

  logic                            ace_acvalid_i;
  logic                            ace_acready_o;
  logic [3:0]                      ace_acaddr_i;
  logic [2:0]                      ace_acsnoop_i;
  logic [2:0]                      ace_acprot_i;

  logic                            ace_crvalid_o;
  logic                            ace_crready_i;
  logic [3:0]                      ace_crresp_o;

  logic                            ace_cdvalid_o;
  logic                            ace_cdready_i;
  logic                            ace_cdlast_o;
  logic [`ACE_DATA_WIDTH-1:0]      ace_cddata_o;

  // Test variables
  logic [`ACE_ID_WIDTH-1:0]        expected_id;
  logic [`ACE_DATA_WIDTH-1:0]      test_data;
  int                              test_count;
  int                              pass_count;
  int                              fail_count;

  // Instantiate the instruction cache
  instruction_cache dut (
    .clk               (clk               ),
    .rst_n             (rst_n             ),
    .invalid_i         (1'b0              ),
    .core_req_valid_i  (core_req_valid_i  ),
    .core_req_addr_i   (core_req_addr_i   ),
    .core_req_mask_i   (core_req_mask_i   ),
    .core_req_wid_i    (core_req_wid_i    ),
    .flush_pipe_valid_i(flush_pipe_valid_i),
    .flush_pipe_wid_i  (flush_pipe_wid_i  ),
    .core_rsp_valid_o  (core_rsp_valid_o  ),
    .core_rsp_addr_o   (core_rsp_addr_o   ),
    .core_rsp_data_o   (core_rsp_data_o   ),
    .core_rsp_mask_o   (core_rsp_mask_o   ),
    .core_rsp_wid_o    (core_rsp_wid_o    ),
    .core_rsp_status_o (core_rsp_status_o ),
    .ace_arvalid_o     (ace_arvalid_o     ),
    .ace_arready_i     (ace_arready_i     ),
    .ace_arid_o        (ace_arid_o        ),
    .ace_araddr_o      (ace_araddr_o      ),
    .ace_arlen_o       (ace_arlen_o       ),
    .ace_arsize_o      (ace_arsize_o      ),
    .ace_arburst_o     (ace_arburst_o     ),
    .ace_arlock_o      (ace_arlock_o      ),
    .ace_arcache_o     (ace_arcache_o     ),
    .ace_arprot_o      (ace_arprot_o      ),
    .ace_arqos_o       (ace_arqos_o       ),
    .ace_arregion_o    (ace_arregion_o    ),
    .ace_arsnoop_o     (ace_arsnoop_o     ),
    .ace_ardomain_o    (ace_ardomain_o    ),
    .ace_arbar_o       (ace_arbar_o       ),
    .ace_aruser_o      (ace_aruser_o      ),
    .ace_rvalid_i      (ace_rvalid_i      ),
    .ace_rready_o      (ace_rready_o      ),
    .ace_rid_i         (ace_rid_i         ),
    .ace_rdata_i       (ace_rdata_i       ),
    .ace_rresp_i       (ace_rresp_i       ),
    .ace_rlast_i       (ace_rlast_i       ),
    .ace_ruser_i       (ace_ruser_i       ),
    .ace_acvalid_i     (ace_acvalid_i     ),
    .ace_acready_o     (ace_acready_o     ),
    .ace_acaddr_i      (ace_acaddr_i      ),
    .ace_acsnoop_i     (ace_acsnoop_i     ),
    .ace_acprot_i      (ace_acprot_i      ),
    .ace_crvalid_o     (ace_crvalid_o     ),
    .ace_crready_i     (ace_crready_i     ),
    .ace_crresp_o      (ace_crresp_o      ),
    .ace_cdvalid_o     (ace_cdvalid_o     ),
    .ace_cdready_i     (ace_cdready_i     ),
    .ace_cdlast_o      (ace_cdlast_o      ),
    .ace_cddata_o      (ace_cddata_o      )
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test stimulus
  initial begin
    // Initialize signals
    rst_n = 0;
    core_req_valid_i = 0;
    core_req_addr_i = 0;
    core_req_mask_i = 0;
    core_req_wid_i = 0;
    flush_pipe_valid_i = 0;
    flush_pipe_wid_i = 0;
    
    ace_arready_i = 1;
    ace_rvalid_i = 0;
    ace_rid_i = 0;
    ace_rdata_i = 0;
    ace_rresp_i = 0;
    ace_rlast_i = 0;
    ace_ruser_i = 0;
    
    ace_acvalid_i = 0;
    ace_acaddr_i = 0;
    ace_acsnoop_i = 0;
    ace_acprot_i = 0;
    
    ace_crready_i = 1;
    ace_cdready_i = 1;
    
    test_count = 0;
    pass_count = 0;
    fail_count = 0;
    expected_id = 0;

    // Reset sequence
    #20 rst_n = 1;
    #10;

    $display("=== ACE ICache Test Started ===");

    // Test 1: Cache hit scenario
    test_cache_hit();
    
    // Test 2: Cache miss scenario
    test_cache_miss();
    
    // Test 3: ACE snoop scenario
    test_ace_snoop();
    
    // Test 4: Multiple requests
    test_multiple_requests();
    
    // Test 5: Flush scenario
    test_flush();

    #100;
    $display("=== ACE ICache Test Completed ===");
    $display("Total Tests: %0d", test_count);
    $display("Passed: %0d", pass_count);
    $display("Failed: %0d", fail_count);
    
    if (fail_count == 0) begin
      $display("*** ALL TESTS PASSED ***");
    end else begin
      $display("*** SOME TESTS FAILED ***");
    end
    
    $finish;
  end

  // Test task: Cache hit
  task test_cache_hit();
    begin
      test_count++;
      $display("Test %0d: Cache Hit", test_count);
      
      // Send a request
      @(posedge clk);
      core_req_valid_i = 1;
      core_req_addr_i = 32'h1000_0000;
      core_req_mask_i = 2'b11;
      core_req_wid_i = 2'b01;
      
      @(posedge clk);
      core_req_valid_i = 0;
      
      // Wait for response
      wait(core_rsp_valid_o);
      @(posedge clk);
      
      if (core_rsp_status_o == 1'b0) begin // Hit
        $display("  Cache hit detected - PASS");
        pass_count++;
      end else begin
        $display("  Cache hit expected but got miss - FAIL");
        fail_count++;
      end
      
      #20;
    end
  endtask

  // Test task: Cache miss
  task test_cache_miss();
    begin
      test_count++;
      $display("Test %0d: Cache Miss", test_count);
      
      // Send a request to a new address
      @(posedge clk);
      core_req_valid_i = 1;
      core_req_addr_i = 32'h2000_0000;
      core_req_mask_i = 2'b11;
      core_req_wid_i = 2'b10;
      
      @(posedge clk);
      core_req_valid_i = 0;
      
      // Wait for ACE read request
      wait(ace_arvalid_o);
      @(posedge clk);
      
      // Check ACE request attributes
      if (ace_arsnoop_o == `ACE_ICACHE_READ_SHARED &&
          ace_arprot_o == 3'b110 &&
          ace_arcache_o == 4'b1111) begin
        $display("  ACE read request generated correctly - PASS");
        
        // Simulate ACE response
        ace_rvalid_i = 1;
        ace_rid_i = ace_arid_o;
        ace_rdata_i = {32'hDEADBEEF, 32'hCAFEBABE, 32'h12345678, 32'h9ABCDEF0};
        ace_rresp_i = 2'b00; // OKAY
        ace_rlast_i = 1;
        
        @(posedge clk);
        ace_rvalid_i = 0;
        ace_rlast_i = 0;
        
        // Wait for cache response
        wait(core_rsp_valid_o);
        @(posedge clk);
        
        if (core_rsp_status_o == 1'b1) begin // Miss
          $display("  Cache miss handled correctly - PASS");
          pass_count++;
        end else begin
          $display("  Cache miss expected but got hit - FAIL");
          fail_count++;
        end
      end else begin
        $display("  ACE request attributes incorrect - FAIL");
        fail_count++;
      end
      
      #20;
    end
  endtask

  // Test task: ACE snoop
  task test_ace_snoop();
    begin
      test_count++;
      $display("Test %0d: ACE Snoop", test_count);
      
      // Send a snoop request
      @(posedge clk);
      ace_acvalid_i = 1;
      ace_acaddr_i = 4'b0001;
      ace_acsnoop_i = `ACE_ICACHE_READ_SHARED;
      ace_acprot_i = 3'b110;
      
      @(posedge clk);
      ace_acvalid_i = 0;
      
      // Wait for snoop response
      wait(ace_crvalid_o);
      @(posedge clk);
      
      if (ace_crresp_o == `ACE_CR_OKAY) begin
        $display("  ACE snoop response correct - PASS");
        pass_count++;
      end else begin
        $display("  ACE snoop response incorrect - FAIL");
        fail_count++;
      end
      
      #20;
    end
  endtask

  // Test task: Multiple requests
  task test_multiple_requests();
    begin
      test_count++;
      $display("Test %0d: Multiple Requests", test_count);
      
      // Send multiple requests
      for (int i = 0; i < 3; i++) begin
        @(posedge clk);
        core_req_valid_i = 1;
        core_req_addr_i = 32'h3000_0000 + (i * 4);
        core_req_mask_i = 2'b11;
        core_req_wid_i = i[1:0];
        
        @(posedge clk);
        core_req_valid_i = 0;
        
        // Wait for response
        wait(core_rsp_valid_o);
        @(posedge clk);
      end
      
      $display("  Multiple requests handled - PASS");
      pass_count++;
      
      #20;
    end
  endtask

  // Test task: Flush
  task test_flush();
    begin
      test_count++;
      $display("Test %0d: Flush", test_count);
      
      // Send a request
      @(posedge clk);
      core_req_valid_i = 1;
      core_req_addr_i = 32'h4000_0000;
      core_req_mask_i = 2'b11;
      core_req_wid_i = 2'b11;
      
      @(posedge clk);
      core_req_valid_i = 0;
      
      // Send flush
      @(posedge clk);
      flush_pipe_valid_i = 1;
      flush_pipe_wid_i = 2'b11;
      
      @(posedge clk);
      flush_pipe_valid_i = 0;
      
      // Check that response is not generated
      #50;
      if (!core_rsp_valid_o) begin
        $display("  Flush handled correctly - PASS");
        pass_count++;
      end else begin
        $display("  Flush not handled correctly - FAIL");
        fail_count++;
      end
      
      #20;
    end
  endtask

  // Monitor for debugging
  always @(posedge clk) begin
    if (ace_arvalid_o && ace_arready_i) begin
      $display("ACE Read Request: ID=%0d, Addr=0x%08h, Snoop=%0d", 
               ace_arid_o, ace_araddr_o, ace_arsnoop_o);
    end
    
    if (ace_rvalid_i && ace_rready_o) begin
      $display("ACE Read Response: ID=%0d, Data=0x%032h, Resp=%0d", 
               ace_rid_i, ace_rdata_i, ace_rresp_i);
    end
    
    if (ace_acvalid_i && ace_acready_o) begin
      $display("ACE Snoop Request: Addr=%0d, Snoop=%0d", 
               ace_acaddr_i, ace_acsnoop_i);
    end
    
    if (ace_crvalid_o && ace_crready_i) begin
      $display("ACE Snoop Response: Resp=%0d", ace_crresp_o);
    end
    
    if (core_rsp_valid_o) begin
      $display("Core Response: Addr=0x%08h, Data=0x%016h, Status=%0d", 
               core_rsp_addr_o, core_rsp_data_o, core_rsp_status_o);
    end
  end

endmodule

