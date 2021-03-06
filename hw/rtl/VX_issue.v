`include "VX_define.vh"

module VX_issue #(
    parameter CORE_ID = 0
) (
    `SCOPE_IO_VX_issue

    input wire          clk,
    input wire          reset,

    VX_decode_if        decode_if,
    VX_writeback_if     writeback_if,   
    VX_csr_to_issue_if  csr_to_issue_if, 
    
    VX_alu_req_if       alu_req_if,
    VX_lsu_req_if       lsu_req_if,    
    VX_csr_req_if       csr_req_if,
    VX_mul_req_if       mul_req_if,    
    VX_fpu_req_if       fpu_req_if,    
    VX_gpu_req_if       gpu_req_if
);
    VX_decode_if    ibuf_deq_if();
    VX_decode_if    execute_if();
    VX_gpr_req_if   gpr_req_if();
    VX_gpr_rsp_if   gpr_rsp_if();

    wire scoreboard_delay;
    wire [`NW_BITS-1:0] deq_wid_next;

    VX_ibuffer #(
        .CORE_ID(CORE_ID)
    ) ibuffer (
        .clk            (clk),
        .reset          (reset), 
        .freeze         (~gpr_req_if.ready),
        .ibuf_enq_if    (decode_if),
        .deq_wid_next   (deq_wid_next),
        .ibuf_deq_if    (ibuf_deq_if)      
    );

    VX_scoreboard #(
        .CORE_ID(CORE_ID)
    ) scoreboard (
        .clk            (clk),
        .reset          (reset), 
        .ibuf_deq_if    (ibuf_deq_if),
        .writeback_if   (writeback_if),
        .deq_wid_next   (deq_wid_next),
        .exe_delay      (~execute_if.ready),
        .gpr_delay      (~gpr_req_if.ready),
        .delay          (scoreboard_delay)
    );
        
    assign gpr_req_if.valid   = ibuf_deq_if.valid && ~scoreboard_delay;
    assign gpr_req_if.wid     = ibuf_deq_if.wid;
    assign gpr_req_if.PC      = ibuf_deq_if.PC;
    assign gpr_req_if.rs1     = ibuf_deq_if.rs1;
    assign gpr_req_if.rs2     = ibuf_deq_if.rs2;
    assign gpr_req_if.rs3     = ibuf_deq_if.rs3;
    assign gpr_req_if.use_rs3 = ibuf_deq_if.use_rs3;
    assign gpr_rsp_if.ready   = execute_if.ready;

    VX_gpr_stage #(
        .CORE_ID(CORE_ID)
    ) gpr_stage (
        .clk            (clk),      
        .reset          (reset),          
        .writeback_if   (writeback_if),
        .gpr_req_if     (gpr_req_if),
        .gpr_rsp_if     (gpr_rsp_if)
    );

    `UNUSED_VAR (gpr_rsp_if.valid);
    
    assign execute_if.valid     = ibuf_deq_if.valid && gpr_req_if.ready && ~scoreboard_delay;
    assign execute_if.wid       = ibuf_deq_if.wid;
    assign execute_if.tmask     = ibuf_deq_if.tmask;
    assign execute_if.PC        = ibuf_deq_if.PC;
    assign execute_if.ex_type   = ibuf_deq_if.ex_type;    
    assign execute_if.op_type   = ibuf_deq_if.op_type; 
    assign execute_if.op_mod    = ibuf_deq_if.op_mod;    
    assign execute_if.wb        = ibuf_deq_if.wb;
    assign execute_if.rd        = ibuf_deq_if.rd;
    assign execute_if.rs1       = ibuf_deq_if.rs1;
    assign execute_if.imm       = ibuf_deq_if.imm;        
    assign execute_if.rs1_is_PC = ibuf_deq_if.rs1_is_PC;
    assign execute_if.rs2_is_imm = ibuf_deq_if.rs2_is_imm;

    VX_instr_demux instr_demux (
        .clk            (clk),      
        .reset          (reset),
        .execute_if     (execute_if),
        .gpr_rsp_if     (gpr_rsp_if),
        .csr_to_issue_if(csr_to_issue_if),
        .alu_req_if     (alu_req_if),
        .lsu_req_if     (lsu_req_if),        
        .csr_req_if     (csr_req_if),
        .mul_req_if     (mul_req_if),
        .fpu_req_if     (fpu_req_if),
        .gpu_req_if     (gpu_req_if)
    );      

    `SCOPE_ASSIGN (scope_issue_valid,       ibuf_deq_if.valid);
    `SCOPE_ASSIGN (scope_issue_wid,         ibuf_deq_if.wid);
    `SCOPE_ASSIGN (scope_issue_tmask,       ibuf_deq_if.tmask);
    `SCOPE_ASSIGN (scope_issue_pc,          ibuf_deq_if.PC);
    `SCOPE_ASSIGN (scope_issue_ex_type,     ibuf_deq_if.ex_type);
    `SCOPE_ASSIGN (scope_issue_op_type,     ibuf_deq_if.op_type);
    `SCOPE_ASSIGN (scope_issue_op_mod,      ibuf_deq_if.op_mod);
    `SCOPE_ASSIGN (scope_issue_wb,          ibuf_deq_if.wb);
    `SCOPE_ASSIGN (scope_issue_rd,          ibuf_deq_if.rd);
    `SCOPE_ASSIGN (scope_issue_rs1,         ibuf_deq_if.rs1);
    `SCOPE_ASSIGN (scope_issue_rs2,         ibuf_deq_if.rs2);
    `SCOPE_ASSIGN (scope_issue_rs3,         ibuf_deq_if.rs3);
    `SCOPE_ASSIGN (scope_issue_imm,         ibuf_deq_if.imm);
    `SCOPE_ASSIGN (scope_issue_rs1_is_pc,   ibuf_deq_if.rs1_is_PC);
    `SCOPE_ASSIGN (scope_issue_rs2_is_imm,  ibuf_deq_if.rs2_is_imm);
    `SCOPE_ASSIGN (scope_issue_ready,       ibuf_deq_if.ready);
    `SCOPE_ASSIGN (scope_scoreboard_delay,  scoreboard_delay); 
    `SCOPE_ASSIGN (scope_gpr_delay,         ~gpr_req_if.ready); 
    `SCOPE_ASSIGN (scope_execute_delay,     ~execute_if.ready);     

    `SCOPE_ASSIGN (scope_gpr_rsp_valid,     gpr_rsp_if.valid);    
    `SCOPE_ASSIGN (scope_gpr_rsp_wid,       gpr_rsp_if.wid);
    `SCOPE_ASSIGN (scope_gpr_rsp_pc,        gpr_rsp_if.PC);    
    `SCOPE_ASSIGN (scope_gpr_rsp_a,         gpr_rsp_if.rs1_data);
    `SCOPE_ASSIGN (scope_gpr_rsp_b,         gpr_rsp_if.rs2_data);
    `SCOPE_ASSIGN (scope_gpr_rsp_c,         gpr_rsp_if.rs3_data);
            
    `SCOPE_ASSIGN (scope_writeback_valid,   writeback_if.valid);    
    `SCOPE_ASSIGN (scope_writeback_wid,     writeback_if.wid);
    `SCOPE_ASSIGN (scope_writeback_pc,      writeback_if.PC);  
    `SCOPE_ASSIGN (scope_writeback_rd,      writeback_if.rd);
    `SCOPE_ASSIGN (scope_writeback_data,    writeback_if.data);

`ifdef DBG_PRINT_PIPELINE
    always @(posedge clk) begin
        if (alu_req_if.valid && alu_req_if.ready) begin
            $display("%t: core%0d-issue: wid=%0d, PC=%0h, ex=ALU, tmask=%b, rs1_data=%0h, rs2_data=%0h", $time, CORE_ID, alu_req_if.wid, alu_req_if.PC, alu_req_if.tmask, alu_req_if.rs1_data, alu_req_if.rs2_data);   
        end
        if (lsu_req_if.valid && lsu_req_if.ready) begin
            $display("%t: core%0d-issue: wid=%0d, PC=%0h, ex=LSU, tmask=%b, rw=%b, byteen=%b, baddr=%0h, offset=%0h, data=%0h", $time, CORE_ID, lsu_req_if.wid, lsu_req_if.PC, lsu_req_if.tmask, lsu_req_if.rw, lsu_req_if.byteen, lsu_req_if.base_addr, lsu_req_if.offset, lsu_req_if.store_data);   
        end
        if (csr_req_if.valid && csr_req_if.ready) begin
            $display("%t: core%0d-issue: wid=%0d, PC=%0h, ex=CSR, tmask=%b, addr=%0h, mask=%0h", $time, CORE_ID, csr_req_if.wid, csr_req_if.PC, csr_req_if.tmask, csr_req_if.csr_addr, csr_req_if.csr_mask);   
        end
        if (mul_req_if.valid && mul_req_if.ready) begin
            $display("%t: core%0d-issue: wid=%0d, PC=%0h, ex=MUL, tmask=%b, rs1_data=%0h, rs2_data=%0h", $time, CORE_ID, mul_req_if.wid, mul_req_if.PC, mul_req_if.tmask, mul_req_if.rs1_data, mul_req_if.rs2_data);   
        end
        if (fpu_req_if.valid && fpu_req_if.ready) begin
            $display("%t: core%0d-issue: wid=%0d, PC=%0h, ex=FPU, tmask=%b, rs1_data=%0h, rs2_data=%0h, rs3_data=%0h", $time, CORE_ID, fpu_req_if.wid, fpu_req_if.PC, fpu_req_if.tmask, fpu_req_if.rs1_data, fpu_req_if.rs2_data, fpu_req_if.rs3_data);   
        end
        if (gpu_req_if.valid && gpu_req_if.ready) begin
            $display("%t: core%0d-issue: wid=%0d, PC=%0h, ex=GPU, tmask=%b, rs1_data=%0h, rs2_data=%0h", $time, CORE_ID, gpu_req_if.wid, gpu_req_if.PC, gpu_req_if.tmask, gpu_req_if.rs1_data, gpu_req_if.rs2_data);   
        end
    end
`endif

endmodule