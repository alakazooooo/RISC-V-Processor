module ReservationStation (
    input wire clk,
    
    // inputs to RS
    input wire [5:0] physical_rd, physical_rs1, physical_rs2,
    input wire rs1_ready, rs2_ready,
    input wire [31:0] rs1_value, rs2_value,
    input wire [5:0] ROB_num, //not yet in

    //from decode
    input wire [3:0] ALUControl,
    input wire [31:0] imm,
    input wire LoadStore,
    input wire ALUSrc,
    input wire RegWrite,
    input wire BMS,
    
    //forward inputs TODO (or implemented in dispatch?)
    

    // Issue interface
    output reg [1:0] FU_num,
    output reg load_store_valid,
    output reg [31:0] issue_rs1_value_0, issue_rs1_value_1, issue_rs1_value_2,
    output reg [31:0] issue_rs2_value_0, issue_rs2_value_1, issue_rs2_value_2,
    output reg [2:0] issue_alu_type_0, issue_alu_type_1, issue_alu_type_2
);

    // Constants
    parameter RS_SIZE = 64;
    parameter ENTRY_WIDTH = 129; 

    // Reservation station
    reg [ENTRY_WIDTH-1:0] reservation_station [RS_SIZE-1:0]; //initialize to zero?
    reg [5:0] head, tail;
    reg [5:0] count;
    initial begin
        FU_num = 2'b0;
    end

    // clean gaps between entries if issue out of order
    reg [ENTRY_WIDTH-1:0] temp_rs [0:RS_SIZE-1];
    reg [5:0] new_head, new_tail;
    integer i, j;
    always @(*) begin
        j = 0;
        new_head = 6'd0;
        new_tail = 6'd0;
        
        // Initialize temp_rs
        for (i = 0; i < RS_SIZE; i = i + 1) begin
            temp_rs[i] = 129'd0;
        end
        
        // Compact valid entries
        for (i = 0; i < RS_SIZE; i = i + 1) begin
            if (reservation_station[(head + i) % RS_SIZE][128] == 1'b1) begin
                temp_rs[j] = reservation_station[(head + i) % RS_SIZE];
                j = j + 1;
            end
        end
        
        new_tail = j;
    end

    // Reservation station loading and management
    always @(posedge clk) begin
        // manage queue so that all valid instructions are at the top of the RS
        // Copy compacted entries back to reservation_station
        for (i = 0; i < RS_SIZE; i = i + 1) begin
            reservation_station[i] <= temp_rs[i];
        end
        
        head <= new_head;
        tail <= new_tail;
        count <= new_tail - new_head;

        // Add new instruction 
        if (count < RS_SIZE) begin
            reservation_station[tail][128] <= 1'b1; // valid
            reservation_station[tail][127:124] <= ALUControl;
            reservation_station[tail][123:118] <= physical_rd;
            reservation_station[tail][117:112] <= physical_rs1;
            reservation_station[tail][111:80] <= rs1_value;
            reservation_station[tail][79] <= rs1_ready;
            reservation_station[tail][78:73] <= physical_rs2;
            reservation_station[tail][72:41] <= rs2_value;
            reservation_station[tail][40] <= rs2_ready;
            reservation_station[tail][39:8] <= imm;
            reservation_station[tail][7:6] <= FU_num;
            reservation_station[tail][5:0] <= ROB_num;

            
            tail <= (tail + 1) % RS_SIZE;
            count <= count + 1;
            if(FU_num == 2'd2) begin
                FU_num =  2'd0;
            end else begin
                FU_num = FU_num + 2'd1;
            end
        end

        // TODO Remove issued instructions

    end

    // FU_num and load_store_valid logic (TODO)



endmodule
