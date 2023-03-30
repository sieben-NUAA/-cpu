`include "./Para.v"
`include "./PC.v"
`include "./NPC.v"
`include "./PC_add.v"
`include "./IM.v"
`include "./IF_ID.v"
`include "./RegisterFile.v"
`include "./ID_EX.v"
`include "./ALU.v"
`include "./ALUCtrl.v"
`include "./EX_MEM.v"
`include "./DM.v"
`include "./MEM_WB.v"
`include "./EXT.v"
`include "./MUX.v"
// Hazard
`include "./Forward.v"
`include "./Hazard.v"
`include "./Branch.v"
`include "./Branch_PC.v"

module data_path (RegDst, Jump, Branch, MemRead, MemtoReg, ALUOp, 
    MemWrite, ALUSrc, RegWrite, ExtOp, Clock, Reset, IF_ID_instr_out, Ctrl_0_Ctrl, Ctrl_0_Data);
    
    input                  RegDst;
    input                  Jump;
    input                  Branch;
    input                  MemRead;
    input                  MemtoReg;
    input [`SIZE_ALUOP: 0] ALUOp;
    input                  MemWrite;
    input                  ALUSrc;
    input                  RegWrite;
    input                  ExtOp;

    input                  Clock;
    input                  Reset;

    output [31: 0]         IF_ID_instr_out;
    output                 Ctrl_0_Ctrl;
    output                 Ctrl_0_Data;

    // pipeline wire
    //IF_ID
    wire    [31:0] IF_ID_PC_out;
    wire    [31:0] IF_ID_instr_out;
    //ID_EX
    wire           ID_EX_MemtoReg_out;
    wire           ID_EX_RegWrite_out;
    wire           ID_EX_Branch_out;
    wire           ID_EX_Jump_out;
    wire           ID_EX_MemWrite_out;
    wire           ID_EX_MemRead_out;
    wire           ID_EX_RegDst_out;
    wire           ID_EX_ALUSrc_out;
    wire           ID_EX_ExtOp_out;
    wire    [`SIZE_ALUOP:0] ID_EX_ALUOp_out;
    wire    [31:0] ID_EX_PC_out;
    wire    [25:0] ID_EX_Jump_immed_out;
    wire    [31:0] ID_EX_Reg_data_1_out;
    wire    [31:0] ID_EX_Reg_data_2_out;
    wire    [15:0] ID_EX_Ext_out;
    wire    [4:0]  ID_EX_rt_out;
    wire    [4:0]  ID_EX_rd_out;
    wire    [4:0]  ID_EX_rs_out;
    // FIXME
    wire    [4:0]  ID_EX_shamt;
    //EX_MEM
    wire           EX_MEM_MemtoReg_out;
    wire           EX_MEM_RegWrite_out;
    wire           EX_MEM_Branch_out;
    wire           EX_MEM_Jump_out;
    wire           EX_MEM_MemWrite_out;
    wire           EX_MEM_MemRead_out;
    wire    [31:0] EX_MEM_PC_out;
    wire    [25:0] EX_MEM_Jump_immed_out;
    wire           EX_MEM_Zero_out;
    wire    [31:0] EX_MEM_ALURes_out;
    wire    [31:0] EX_MEM_Data_Write_out;
    wire    [31:0] EX_MEM_ExtOut_out;
    wire    [4:0]  EX_MEM_Reg_Write_out;
    wire    [4:0]  EX_MEM_RegRt_out;
    //MEM_WB
    wire           MEM_WB_MemtoReg_out;
    wire           MEM_WB_RegWrite_out;
    wire           MEM_WB_MemRead_out;
    wire    [31:0] MEM_WB_Mem_Data_out;
    wire    [31:0] MEM_WB_ALU_Data_out;
    wire    [4:0]  MEM_WB_Reg_Write_out;
    wire    [4:0]  MEM_WB_RegRt_out;

    // module wire
    wire    [31: 0] PC;             // value of pc
    wire    [31: 0] PC_add_4;             // value of pc + 4
    wire    [31: 0] NPC;            // next status of pc 
    wire    [31: 0] ExtOut;         // extention of 16-bit   
    wire    [31: 0] Instruction;    // instruction gotten by im
    wire            Zero;           // zero generated by ALU

    wire    [31: 0] RegfileOut1;    // out1 of regfile
    wire    [31: 0] RegfileOut2;    // out2 of regfile

    wire    [ 4: 0] MuxImRFOut;     // IM RF
    wire    [31: 0] MuxRFALUOut;    // RF ALU
    wire    [31: 0] MuxDmOut;       // DM OUT

    wire    [`SIZE_ALUCTRLOUT: 0] AluCtrlOut;     // out of alu controller
    wire    [31: 0] AluOut;         // out of alu
    wire    [31: 0] DmOut;          // out of dm
    wire    [31: 0] BeqPCOut;       // out of beq pc add 

    // Forward
    // Data Hazard
    wire    [1:0] ForwardA_Data;
    wire    [1:0] ForwardB_Data;
    wire    [1:0] ForwardC_Data;
    wire          PC_Sub_4_Ctrl;
    wire          Ctrl_0_Ctrl;    
    wire          PC_Sub_4_Data;
    wire          Ctrl_0_Data;
    wire          IF_ID_Flush_Data;
    wire          IF_ID_Flush_Ctrl;

    wire    [31:0] ForwardA_Rs_Mux; 
    wire    [31:0] ForwardB_Rt_Mux; 

    wire           Flag_Beq_out;
    wire           Flag_Jump_out;
    wire    [31:0] BEQ_imme_out;
    wire    [25:0] Jump_imme_out;

    wire    [31:0] BEQ_Mux_Rs;
    wire    [31:0] BEQ_Mux_Rt;

    wire    [31:0] BEQ_PC;
    // DATAPATH
    pc program_counter(
        .NPC(NPC),
        .Clock(Clock),
        .Reset(Reset),
        .PC_Sub_4_Ctrl(PC_Sub_4_Ctrl),
        .PC_Sub_4_Data(PC_Sub_4_Data),
        .Beq(Flag_Beq_out),
        .Jump(Flag_Jump_out),
        .BEQ_immed(BEQ_imme_out),
        .Jump_immed(Jump_imme_out),
        .Branch_PC(BEQ_PC),

        .PC(PC)
    );
    PC_add program_counter_add_4(
        .PC(PC),

        .PC_add_4(PC_add_4)
    );
    npc next_program_counter(
        .PC_add_4(PC_add_4),  // 这里原来写了EX_MEM_PC_out, 不对，导致没有正在流水线起来，可能因为会去等EX_MEM阶段的PC传来
        // .Branch(EX_MEM_Branch_out),
        // .Zero(EX_MEM_Zero_out),
        .PC_Sub_4_Ctrl(PC_Sub_4_Ctrl),
        .PC_Sub_4_Data(PC_Sub_4_Data),
        .Beq(Flag_Beq_out),
        .Jump(Flag_Jump_out),
        .BEQ_immed(BEQ_imme_out),
        .Jump_immed(Jump_imme_out),
        .Branch_PC(BEQ_PC),

        .NPC(NPC)
    );
    im instruction_memory(
        .PC(PC),

        .OutInstr(Instruction)
    );

    IF_ID IF_ID_pipeline(
        .clk(Clock),
        .PC_in(PC_add_4),
        .instr_in(Instruction),        
        .PC_old(IF_ID_PC_out),
        .instr_old(IF_ID_instr_out),
        .Flush_Data(IF_ID_Flush_Data),
        .Flush_Ctrl(IF_ID_Flush_Ctrl),

        .PC_out(IF_ID_PC_out),
        .instr_out(IF_ID_instr_out)
    );

    // initial begin
    //     // $monitor("value %d at the time %t.", RegWrite, $time);
    // end


    register_file register_files(
        .rs(IF_ID_instr_out[25:21]),
        .rt(IF_ID_instr_out[20:16]),
        .rd(MEM_WB_Reg_Write_out),
        .InputData(MuxDmOut),
        .RegWrite(MEM_WB_RegWrite_out),
        .Clock(Clock),
        .Reset(Reset),

        .rsData(RegfileOut1),
        .rtData(RegfileOut2)
    );
    mux_by_ForwardC Branch_Mux(
        .clk(Clock),
        .ForwardC(ForwardC_Data),
        .EX_MEM_ALURes(EX_MEM_ALURes_out),
        .Rs(RegfileOut1),
        .Rt(RegfileOut2),
        
        .BEQ_Rs(BEQ_Mux_Rs),
        .BEQ_Rt(BEQ_Mux_Rt)
    );
    Branch branch(
        .clk(Clock),
        .Opcode(IF_ID_instr_out[31:26]),
        .Immediate(IF_ID_instr_out[25:0]),
        .Rs(BEQ_Mux_Rs),
        .Rt(BEQ_Mux_Rt),

        .Flag_Beq(Flag_Beq_out),
        .BEQ_imme_out(BEQ_imme_out),
        .Flag_Jump(Flag_Jump_out),
        .Jump_imme_out(Jump_imme_out)
    );

    ID_EX ID_EX_pipeline(
        .clk(Clock),
        .MemtoReg_in(MemtoReg),
        .RegWrite_in(RegWrite),
        .Branch_in(Branch),
        .Jump_in(Jump),
        .MemWrite_in(MemWrite),
        .MemRead_in(MemRead),
        .RegDst_in(RegDst),
        .ALUSrc_in(ALUSrc),
        .ExtOp_in(ExtOp),
        .ALUOp_in(ALUOp),
        .PC_in(IF_ID_PC_out),
        .Jump_immed_in(IF_ID_instr_out[25:0]),
        .Reg_data_1_in(RegfileOut1),
        .Reg_data_2_in(RegfileOut2),
        .Ext_in(IF_ID_instr_out[15:0]),
        .rt_in(IF_ID_instr_out[20:16]),
        .rd_in(IF_ID_instr_out[15:11]),
        .rs_in(IF_ID_instr_out[25:21]),
        // FIXME
        .shamt_in(IF_ID_instr_out[10:6]),

        .MemtoReg_out(ID_EX_MemtoReg_out),
        .RegWrite_out(ID_EX_RegWrite_out),
        .Branch_out(ID_EX_Branch_out),
        .Jump_out(ID_EX_Jump_out),
        .MemWrite_out(ID_EX_MemWrite_out),
        .MemRead_out(ID_EX_MemRead_out),
        .RegDst_out(ID_EX_RegDst_out),
        .ALUSrc_out(ID_EX_ALUSrc_out),
        .ExtOp_out(ID_EX_ExtOp_out),
        .ALUOp_out(ID_EX_ALUOp_out),
        .PC_out(ID_EX_PC_out),
        .Jump_immed_out(ID_EX_Jump_immed_out),
        .Reg_data_1_out(ID_EX_Reg_data_1_out),
        .Reg_data_2_out(ID_EX_Reg_data_2_out),
        .Ext_out(ID_EX_Ext_out),
        .rt_out(ID_EX_rt_out),
        .rd_out(ID_EX_rd_out),
        .rs_out(ID_EX_rs_out),
        // c
        .shamt_out(ID_EX_shamt)
    );

    mux_by_RegDst IF_ID_MUX(
        .rt(ID_EX_rt_out),
        .rd(ID_EX_rd_out),
        .RegDst(ID_EX_RegDst_out),

        .DstReg(MuxImRFOut)
    );
    mux_by_ForwardA ForwardA_Mux(
        .ForwardA(ForwardA_Data),
        .Mux_DM(MuxDmOut),
        .Data_rs(ID_EX_Reg_data_1_out),
        .ALURes(EX_MEM_ALURes_out),

        .ForwardA_Rs_ALU(ForwardA_Rs_Mux)
    );    
    mux_by_ForwardB ForwardB_Mux(
        .ForwardB(ForwardB_Data),
        .Mux_DM(MuxDmOut),
        .Data_rt(ID_EX_Reg_data_2_out),
        .ALURes(EX_MEM_ALURes_out),

        .ForwardB_Rt_ALU(ForwardB_Rt_Mux)
    );
    ext extend_immediate(
        .InputNum(ID_EX_Ext_out),
        .ExtOp(ID_EX_ExtOp_out),

        .OutputNum(ExtOut)
    );
    mux_by_ALUSrc RF_ALU_MUX(
        .rtData(ForwardB_Rt_Mux),
        .Immediate(ExtOut),
        .ALUSrc(ID_EX_ALUSrc_out),

        .DstData(MuxRFALUOut)
    );
    alu_ctrl ALU_controller(
        .Funct(ExtOut[5:0]),
        .ALUOp(ID_EX_ALUOp_out),

        .AluCtrlOut(AluCtrlOut)
    );
    alu ALU(
        .InputData1(ForwardA_Rs_Mux),
        .InputData2(MuxRFALUOut),
        .AluCtrlOut(AluCtrlOut),
        // FIXME: add
        .shamt(ID_EX_shamt),

        .Zero(Zero),
        .AluRes(AluOut)
    );

    EX_MEM EX_MEM_pipeline(
        .clk(Clock),
        .MemtoReg_in(ID_EX_MemtoReg_out),
        .RegWrite_in(ID_EX_RegWrite_out),
        .Branch_in(ID_EX_Branch_out),
        .Jump_in(ID_EX_Jump_out),
        .MemWrite_in(ID_EX_MemWrite_out),
        .MemRead_in(ID_EX_MemRead_out),
        .PC_in(ID_EX_PC_out),
        .Jump_immed_in(ID_EX_Jump_immed_out),
        .Zero_in(Zero),
        .ALURes_in(AluOut),
        .Data_Write_in(ForwardB_Rt_Mux),
        .ExtOut_in(ExtOut),
        .Reg_Write_in(MuxImRFOut),
        .RegRt_in(ID_EX_rt_out),

        .MemtoReg_out(EX_MEM_MemtoReg_out),
        .RegWrite_out(EX_MEM_RegWrite_out),
        .Branch_out(EX_MEM_Branch_out),
        .Jump_out(EX_MEM_Jump_out),
        .MemWrite_out(EX_MEM_MemWrite_out),
        .MemRead_out(EX_MEM_MemRead_out),
        .PC_out(EX_MEM_PC_out),
        .Jump_immed_out(EX_MEM_Jump_immed_out),
        .Zero_out(EX_MEM_Zero_out),
        .ALURes_out(EX_MEM_ALURes_out),
        .Data_Write_out(EX_MEM_Data_Write_out),
        .ExtOut_out(EX_MEM_ExtOut_out),
        .Reg_Write_out(EX_MEM_Reg_Write_out),
        .RegRt_out(EX_MEM_RegRt_out)
    );

    dm data_memory(
        .AluRes(EX_MEM_ALURes_out),
        .InputData(EX_MEM_Data_Write_out),
        .MemWrite(EX_MEM_MemWrite_out),
        .MemRead(EX_MEM_MemRead_out),
        .Clock(Clock),

        .DmOutData(DmOut)
    );

    MEM_WB MEM_WB_pipeline(
        .clk(Clock),
        .MemtoReg_in(EX_MEM_MemtoReg_out),
        .RegWrite_in(EX_MEM_RegWrite_out),
        .Mem_Data_in(DmOut),
        .ALU_Data_in(EX_MEM_ALURes_out),
        .Reg_Write_in(EX_MEM_Reg_Write_out),
        //hazard
        .MemRead_in(EX_MEM_MemRead_out),
        .RegRt_in(EX_MEM_RegRt_out),

        .MemtoReg_out(MEM_WB_MemtoReg_out),
        .RegWrite_out(MEM_WB_RegWrite_out),
        .MemRead_out(MEM_WB_MemRead_out),
        .Mem_Data_out(MEM_WB_Mem_Data_out),
        .ALU_Data_out(MEM_WB_ALU_Data_out),
        .Reg_Write_out(MEM_WB_Reg_Write_out),
        .RegRt_out(MEM_WB_RegRt_out)
    );

    mux_by_MemToReg DM_OUT_MUX(
        .DmData(MEM_WB_Mem_Data_out),
        .ALUData(MEM_WB_ALU_Data_out),
        .MemtoReg(MEM_WB_MemtoReg_out),

        .DstData(MuxDmOut)
    );


    // Hazard

    // Data Forward
    Forward_DataHazard ForwardDataHazard(
        .EX_MEM_RW(EX_MEM_RegWrite_out),
        .MEM_WB_RW(MEM_WB_RegWrite_out),
        .MEM_WB_MR(MEM_WB_MemRead_out),
        // .MEM_WB_RegRt(MEM_WB_RegRt_out),
        .EX_MEM_RegRd(EX_MEM_Reg_Write_out),
        .MEM_WB_RegRd(MEM_WB_Reg_Write_out),
        .ID_EX_RegRs(ID_EX_rs_out),
        .ID_EX_RegRt(ID_EX_rt_out),

        .ForwardA(ForwardA_Data),
        .ForwardB(ForwardB_Data)
    );

    //Data Hazard
    Hazard_Data HazardData(
        .Opcode(IF_ID_instr_out[31:26]),    
        .ID_EX_MR(ID_EX_MemRead_out),
        .MEM_WB_MR(MEM_WB_MemRead_out),
        .MEM_WB_RegRt(MEM_WB_RegRt_out),
        .ID_EX_RegRs(ID_EX_rs_out),
        .ID_EX_RegRt(ID_EX_rt_out),
        .IF_ID_RegRs(IF_ID_instr_out[25:21]),
        .IF_ID_RegRt(IF_ID_instr_out[20:16]),

        .IF_ID_Write_Zero(IF_ID_Flush_Data),
        .PC_Sub_4(PC_Sub_4_Data),
        .Ctrl_0(Ctrl_0_Data)
        // .ForwardA(ForwardA_Data),
        // .ForwardB(ForwardB_Data)
    );


    // Control Forward
    Forward_ControlHazard ForwardControlHazard(
        .Opcode(IF_ID_instr_out[31:26]),
        .IF_ID_RegRs(IF_ID_instr_out[25:21]),
        .IF_ID_RegRt(IF_ID_instr_out[20:16]),
        .EX_MEM_RegRd(EX_MEM_Reg_Write_out),
        .EX_MEM_MR(EX_MEM_MemRead_out),
        .ALURes(EX_MEM_ALURes_out),

        .ForwardC(ForwardC_Data)
    );

    //Control Hazard
    Hazard_Control HazardControl(
        .Opcode(IF_ID_instr_out[31:26]),
        .ID_EX_RW(ID_EX_RegWrite_out),
        .ID_EX_MR(ID_EX_MemRead_out),
        .EX_MEM_MR(EX_MEM_MemRead_out),
        .IF_ID_RegRs(IF_ID_instr_out[25:21]),
        .IF_ID_RegRt(IF_ID_instr_out[20:16]),
        .ID_EX_RegRd(ID_EX_rd_out),
        .ID_EX_RegRt(ID_EX_rt_out),
        .EX_MEM_RegRd(EX_MEM_RegRt_out),

        .IF_ID_Write_Zero(IF_ID_Flush_Ctrl),
        .PC_Sub_4(PC_Sub_4_Ctrl),
        .Ctrl_0(Ctrl_0_Ctrl)
    );

    Branch_PC BranchPC(
        .Opcode(IF_ID_instr_out[31:26]),
        .BEQ_immed(BEQ_imme_out),
        .PC(PC),

        .BEQ_PC(BEQ_PC)
    );

endmodule //data_path
