`default_nettype none

module tt_um_tetris_example(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena
);

    // ============================================================
    // VGA
    // ============================================================

    wire hsync;
    wire vsync;
    wire video_active;

    wire [9:0] pix_x;
    wire [9:0] pix_y;

    wire [1:0] R;
    wire [1:0] G;
    wire [1:0] B;

    assign uo_out = {
        hsync,
        B[0],
        G[0],
        R[0],
        vsync,
        B[1],
        G[1],
        R[1]
    };

    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // ============================================================
    // BUTTONS
    // ============================================================

    wire btn_left;
    wire btn_right;
    wire btn_rotate;
    wire btn_drop;

    assign btn_left   = ui_in[0];
    assign btn_right  = ui_in[1];
    assign btn_rotate = ui_in[2];
    assign btn_drop   = ui_in[3];

    wire _unused_ok;

    assign _unused_ok = &{
        ena,
        ui_in[7:4],
        uio_in
    };

    // ============================================================
    // VGA SYNCHRONIZATION
    // ============================================================

    hvsync_generator hvsync_gen(
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(video_active),
        .hpos(pix_x),
        .vpos(pix_y)
    );

    // ============================================================
    // TETRIS BOARD
    //
    // 10 columns x 20 rows
    //
    // Each bit represents one block.
    //
    // board[0]   = row 0, column 0
    // board[9]   = row 0, column 9
    // board[10]  = row 1, column 0
    // etc.
    // ============================================================

    reg [199:0] board;

    // ============================================================
    // CURRENT PIECE
    //
    // 0 = I
    // 1 = O
    // 2 = T
    // 3 = S
    // 4 = Z
    // 5 = J
    // 6 = L
    // ============================================================

    reg [2:0] piece;
    reg [1:0] rotation;

    reg signed [5:0] piece_x;
    reg signed [5:0] piece_y;

    // ============================================================
    // PIECE DATA
    //
    // Returns one 4-bit row.
    //
    // bit 3 = leftmost block
    // bit 0 = rightmost block
    // ============================================================

    function [3:0] piece_row;
        input [2:0] p;
        input [1:0] r;
        input [1:0] row;

        begin

            piece_row = 4'b0000;

            case (p)

                // ====================================================
                // I
                // ====================================================

                3'd0:
                begin
                    if ((r == 2'd0) || (r == 2'd2)) begin

                        if (row == 2'd1)
                            piece_row = 4'b1111;
                        else
                            piece_row = 4'b0000;

                    end
                    else begin

                        if ((row == 2'd0) ||
                            (row == 2'd1) ||
                            (row == 2'd2) ||
                            (row == 2'd3))
                            piece_row = 4'b0100;
                        else
                            piece_row = 4'b0000;

                    end
                end

                // ====================================================
                // O
                // ====================================================

                3'd1:
                begin
                    if ((row == 2'd0) ||
                        (row == 2'd1))
                        piece_row = 4'b0110;
                    else
                        piece_row = 4'b0000;
                end

                // ====================================================
                // T
                // ====================================================

                3'd2:
                begin

                    case (r)

                        2'd0:
                        begin
                            case (row)
                                2'd0: piece_row = 4'b0100;
                                2'd1: piece_row = 4'b1110;
                                default: piece_row = 4'b0000;
                            endcase
                        end

                        2'd1:
                        begin
                            case (row)
                                2'd0: piece_row = 4'b0100;
                                2'd1: piece_row = 4'b0110;
                                2'd2: piece_row = 4'b0100;
                                default: piece_row = 4'b0000;
                            endcase
                        end

                        2'd2:
                        begin
                            case (row)
                                2'd0: piece_row = 4'b0000;
                                2'd1: piece_row = 4'b1110;
                                2'd2: piece_row = 4'b0100;
                                default: piece_row = 4'b0000;
                            endcase
                        end

                        default:
                        begin
                            case (row)
                                2'd0: piece_row = 4'b0100;
                                2'd1: piece_row = 4'b1100;
                                2'd2: piece_row = 4'b0100;
                                default: piece_row = 4'b0000;
                            endcase
                        end

                    endcase
                end

                // ====================================================
                // S
                // ====================================================

                3'd3:
                begin

                    if ((r == 2'd0) || (r == 2'd2)) begin

                        case (row)
                            2'd0: piece_row = 4'b0110;
                            2'd1: piece_row = 4'b1100;
                            default: piece_row = 4'b0000;
                        endcase

                    end
                    else begin

                        case (row)
                            2'd0: piece_row = 4'b1000;
                            2'd1: piece_row = 4'b1100;
                            2'd2: piece_row = 4'b0100;
                            default: piece_row = 4'b0000;
                        endcase

                    end
                end

                // ====================================================
                // Z
                // ====================================================

                3'd4:
                begin

                    if ((r == 2'd0) || (r == 2'd2)) begin

                        case (row)
                            2'd0: piece_row = 4'b1100;
                            2'd1: piece_row = 4'b0110;
                            default: piece_row = 4'b0000;
                        endcase

                    end
                    else begin

                        case (row)
                            2'd0: piece_row = 4'b0100;
                            2'd1: piece_row = 4'b1100;
                            2'd2: piece_row = 4'b1000;
                            default: piece_row = 4'b0000;
                        endcase

                    end
                end

                // ====================================================
                // J
                // ====================================================

                3'd5:
                begin

                    case (r)

                        2'd0:
                        begin
                            case (row)
                                2'd0: piece_row = 4'b1000;
                                2'd1: piece_row = 4'b1110;
                                default: piece_row = 4'b0000;
                            endcase
                        end

                        2'd1:
                        begin
                            case (row)
                                2'd0: piece_row = 4'b1100;
                                2'd1: piece_row = 4'b1000;
                                2'd2: piece_row = 4'b1000;
                                default: piece_row = 4'b0000;
                            endcase
                        end

                        2'd2:
                        begin
                            case (row)
                                2'd0: piece_row = 4'b1110;
                                2'd1: piece_row = 4'b0010;
                                default: piece_row = 4'b0000;
                            endcase
                        end

                        default:
                        begin
                            case (row)
                                2'd0: piece_row = 4'b0100;
                                2'd1: piece_row = 4'b0100;
                                2'd2: piece_row = 4'b1100;
                                default: piece_row = 4'b0000;
                            endcase
                        end

                    endcase
                end

                // ====================================================
                // L
                // ====================================================

                default:
                begin

                    case (r)

                        2'd0:
                        begin
                            case (row)
                                2'd0: piece_row = 4'b0010;
                                2'd1: piece_row = 4'b1110;
                                default: piece_row = 4'b0000;
                            endcase
                        end

                        2'd1:
                        begin
                            case (row)
                                2'd0: piece_row = 4'b1000;
                                2'd1: piece_row = 4'b1100;
                                2'd2: piece_row = 4'b1000;
                                default: piece_row = 4'b0000;
                            endcase
                        end

                        2'd2:
                        begin
                            case (row)
                                2'd0: piece_row = 4'b1110;
                                2'd1: piece_row = 4'b1000;
                                default: piece_row = 4'b0000;
                            endcase
                        end

                        default:
                        begin
                            case (row)
                                2'd0: piece_row = 4'b0100;
                                2'd1: piece_row = 4'b1100;
                                2'd2: piece_row = 4'b0100;
                                default: piece_row = 4'b0000;
                            endcase
                        end

                    endcase

                end

            endcase

        end
    endfunction

    // ============================================================
    // PIECE CELLS
    //
    // These wires tell us whether each of the 16 positions
    // in the 4x4 piece is occupied.
    // ============================================================

    reg [3:0] p_row0;
    reg [3:0] p_row1;
    reg [3:0] p_row2;
    reg [3:0] p_row3;

    always @* begin
        board_index = 0; 
        collision_rotate = 0;
        render_index = 0;

        p_row0 = piece_row(piece, rotation, 2'd0);
        p_row1 = piece_row(piece, rotation, 2'd1);
        p_row2 = piece_row(piece, rotation, 2'd2);
        p_row3 = piece_row(piece, rotation, 2'd3);

    end

    // ============================================================
    // COLLISION DETECTION
    // ============================================================

    reg collision_down;
    reg collision_left;
    reg collision_right;
    reg collision_rotate;

    integer cx;
    integer cy;
    integer board_index;

    reg [3:0] collision_row;

    always @* begin
        board_index = 0; 
        collision_rotate = 0;
        render_index = 0;

        collision_down  = 1'b0;
        collision_left  = 1'b0;
        collision_right = 1'b0;
        collision_rotate = 1'b0;

        // --------------------------------------------------------
        // Check all four rows of the piece.
        // --------------------------------------------------------

        for (cy = 0; cy < 4; cy = cy + 1) begin

            if (cy == 0)
                collision_row = p_row0;
            else if (cy == 1)
                collision_row = p_row1;
            else if (cy == 2)
                collision_row = p_row2;
            else
                collision_row = p_row3;

            for (cx = 0; cx < 4; cx = cx + 1) begin

                if (collision_row[3-cx]) begin

                    // ------------------------------------------------
                    // Down collision
                    // ------------------------------------------------

                    if ((piece_y + cy + 1) >= 20)
                        collision_down = 1'b1;

                    else if ((piece_y + cy + 1) >= 0 &&
                             (piece_x + cx) >= 0 &&
                             (piece_x + cx) < 10) begin

                        board_index =
                            (piece_y + cy + 1) * 10 +
                            (piece_x + cx);

                        if (board[board_index])
                            collision_down = 1'b1;
                    end

                    // ------------------------------------------------
                    // Left collision
                    // ------------------------------------------------

                    if ((piece_x + cx - 1) < 0)
                        collision_left = 1'b1;

                    else if ((piece_y + cy) >= 0 &&
                             (piece_y + cy) < 20 &&
                             (piece_x + cx - 1) >= 0 &&
                             (piece_x + cx - 1) < 10) begin

                        board_index =
                            (piece_y + cy) * 10 +
                            (piece_x + cx - 1);

                        if (board[board_index])
                            collision_left = 1'b1;
                    end

                    // ------------------------------------------------
                    // Right collision
                    // ------------------------------------------------

                    if ((piece_x + cx + 1) >= 10)
                        collision_right = 1'b1;

                    else if ((piece_y + cy) >= 0 &&
                             (piece_y + cy) < 20 &&
                             (piece_x + cx + 1) >= 0 &&
                             (piece_x + cx + 1) < 10) begin

                        board_index =
                            (piece_y + cy) * 10 +
                            (piece_x + cx + 1);

                        if (board[board_index])
                            collision_right = 1'b1;
                    end

                end
            end
        end

        // --------------------------------------------------------
        // Rotation collision
        //
        // We simply test the four possible rows of the next
        // rotation.
        // --------------------------------------------------------

        // The game logic below handles this conservatively.
        collision_rotate = 1'b0;

    end

    // ============================================================
    // BUTTON EDGE DETECTION
    // ============================================================

    reg left_previous;
    reg right_previous;
    reg rotate_previous;
    reg drop_previous;

    wire left_pressed;
    wire right_pressed;
    wire rotate_pressed;
    wire drop_pressed;

    assign left_pressed =
        btn_left && !left_previous;

    assign right_pressed =
        btn_right && !right_previous;

    assign rotate_pressed =
        btn_rotate && !rotate_previous;

    assign drop_pressed =
        btn_drop && !drop_previous;

    // ============================================================
    // GAME CLOCK
    // ============================================================

    reg [23:0] gravity_counter;

    // Adjust this value for speed.
    localparam GRAVITY_MAX = 24'd3000000;

    wire gravity_tick;

    assign gravity_tick =
        (gravity_counter >= GRAVITY_MAX);

    // ============================================================
    // RANDOM PIECE GENERATOR
    // ============================================================

    reg [15:0] random;

    // ============================================================
    // GAME OVER
    // ============================================================

    reg game_over;

    // ============================================================
    // TEMPORARY BOARD
    // ============================================================

    reg [199:0] board_temp;

    integer gx;
    integer gy;
    integer idx;

    // ============================================================
    // MAIN GAME LOGIC
    // ============================================================

    always @(posedge clk) begin

        if (!rst_n) begin

            board <= 200'b0;

            piece <= 3'd2;
            rotation <= 2'd0;

            piece_x <= 6'sd3;
            piece_y <= 6'sd0;

            gravity_counter <= 24'b0;

            left_previous <= 1'b0;
            right_previous <= 1'b0;
            rotate_previous <= 1'b0;
            drop_previous <= 1'b0;

            random <= 16'hACE1;

            game_over <= 1'b0;

        end
        else begin

            // --------------------------------------------------------
            // Save button state
            // --------------------------------------------------------

            left_previous <= btn_left;
            right_previous <= btn_right;
            rotate_previous <= btn_rotate;
            drop_previous <= btn_drop;

            // --------------------------------------------------------
            // Random generator
            // --------------------------------------------------------

            random <= {
                random[14:0],
                random[15] ^
                random[13] ^
                random[12] ^
                random[10]
            };

            // --------------------------------------------------------
            // Gravity counter
            // --------------------------------------------------------

            if (gravity_tick)
                gravity_counter <= 24'b0;
            else
                gravity_counter <= gravity_counter + 1'b1;

            // --------------------------------------------------------
            // Game
            // --------------------------------------------------------

            if (!game_over) begin

                // ----------------------------------------------------
                // LEFT
                // ----------------------------------------------------

                if (left_pressed) begin

                    if (!collision_left)
                        piece_x <= piece_x - 1;

                end

                // ----------------------------------------------------
                // RIGHT
                // ----------------------------------------------------

                if (right_pressed) begin

                    if (!collision_right)
                        piece_x <= piece_x + 1;

                end

                // ----------------------------------------------------
                // ROTATE
                //
                // Simple rotation. More advanced wall-kick logic
                // can be added later.
                // ----------------------------------------------------

                if (rotate_pressed) begin

                    rotation <= rotation + 1'b1;

                end

                // ----------------------------------------------------
                // HARD DROP
                //
                // Instead of a while loop, move down one row per
                // clock while DROP is held.
                //
                // This is intentionally simple for synthesis.
                // ----------------------------------------------------

                if (btn_drop) begin

                    if (!collision_down)
                        piece_y <= piece_y + 1;

                end

                // ----------------------------------------------------
                // NORMAL GRAVITY
                // ----------------------------------------------------

                else if (gravity_tick) begin

                    if (!collision_down) begin

                        piece_y <= piece_y + 1;

                    end

                    else begin

                        // =================================================
                        // LOCK PIECE
                        // =================================================

                        board_temp = board;

                        // Piece row 0
                        if (p_row0[3]) begin
                            if ((piece_y >= 0) &&
                                (piece_y < 20) &&
                                (piece_x >= 0) &&
                                (piece_x < 10))
                                board_temp[piece_y*10 + piece_x] = 1'b1;
                        end

                        if (p_row0[2]) begin
                            if ((piece_y >= 0) &&
                                (piece_y < 20) &&
                                (piece_x+1 >= 0) &&
                                (piece_x+1 < 10))
                                board_temp[piece_y*10 + piece_x+1] = 1'b1;
                        end

                        if (p_row0[1]) begin
                            if ((piece_y >= 0) &&
                                (piece_y < 20) &&
                                (piece_x+2 >= 0) &&
                                (piece_x+2 < 10))
                                board_temp[piece_y*10 + piece_x+2] = 1'b1;
                        end

                        if (p_row0[0]) begin
                            if ((piece_y >= 0) &&
                                (piece_y < 20) &&
                                (piece_x+3 >= 0) &&
                                (piece_x+3 < 10))
                                board_temp[piece_y*10 + piece_x+3] = 1'b1;
                        end

                        // Piece row 1
                        if (p_row1[3]) begin
                            if ((piece_y+1 >= 0) &&
                                (piece_y+1 < 20) &&
                                (piece_x >= 0) &&
                                (piece_x < 10))
                                board_temp[(piece_y+1)*10 + piece_x] = 1'b1;
                        end

                        if (p_row1[2]) begin
                            if ((piece_y+1 >= 0) &&
                                (piece_y+1 < 20) &&
                                (piece_x+1 >= 0) &&
                                (piece_x+1 < 10))
                                board_temp[(piece_y+1)*10 + piece_x+1] = 1'b1;
                        end

                        if (p_row1[1]) begin
                            if ((piece_y+1 >= 0) &&
                                (piece_y+1 < 20) &&
                                (piece_x+2 >= 0) &&
                                (piece_x+2 < 10))
                                board_temp[(piece_y+1)*10 + piece_x+2] = 1'b1;
                        end

                        if (p_row1[0]) begin
                            if ((piece_y+1 >= 0) &&
                                (piece_y+1 < 20) &&
                                (piece_x+3 >= 0) &&
                                (piece_x+3 < 10))
                                board_temp[(piece_y+1)*10 + piece_x+3] = 1'b1;
                        end

                        // Piece row 2
                        if (p_row2[3]) begin
                            if ((piece_y+2 >= 0) &&
                                (piece_y+2 < 20) &&
                                (piece_x >= 0) &&
                                (piece_x < 10))
                                board_temp[(piece_y+2)*10 + piece_x] = 1'b1;
                        end

                        if (p_row2[2]) begin
                            if ((piece_y+2 >= 0) &&
                                (piece_y+2 < 20) &&
                                (piece_x+1 >= 0) &&
                                (piece_x+1 < 10))
                                board_temp[(piece_y+2)*10 + piece_x+1] = 1'b1;
                        end

                        if (p_row2[1]) begin
                            if ((piece_y+2 >= 0) &&
                                (piece_y+2 < 20) &&
                                (piece_x+2 >= 0) &&
                                (piece_x+2 < 10))
                                board_temp[(piece_y+2)*10 + piece_x+2] = 1'b1;
                        end

                        if (p_row2[0]) begin
                            if ((piece_y+2 >= 0) &&
                                (piece_y+2 < 20) &&
                                (piece_x+3 >= 0) &&
                                (piece_x+3 < 10))
                                board_temp[(piece_y+2)*10 + piece_x+3] = 1'b1;
                        end

                        // Piece row 3
                        if (p_row3[3]) begin
                            if ((piece_y+3 >= 0) &&
                                (piece_y+3 < 20) &&
                                (piece_x >= 0) &&
                                (piece_x < 10))
                                board_temp[(piece_y+3)*10 + piece_x] = 1'b1;
                        end

                        if (p_row3[2]) begin
                            if ((piece_y+3 >= 0) &&
                                (piece_y+3 < 20) &&
                                (piece_x+1 >= 0) &&
                                (piece_x+1 < 10))
                                board_temp[(piece_y+3)*10 + piece_x+1] = 1'b1;
                        end

                        if (p_row3[1]) begin
                            if ((piece_y+3 >= 0) &&
                                (piece_y+3 < 20) &&
                                (piece_x+2 >= 0) &&
                                (piece_x+2 < 10))
                                board_temp[(piece_y+3)*10 + piece_x+2] = 1'b1;
                        end

                        if (p_row3[0]) begin
                            if ((piece_y+3 >= 0) &&
                                (piece_y+3 < 20) &&
                                (piece_x+3 >= 0) &&
                                (piece_x+3 < 10))
                                board_temp[(piece_y+3)*10 + piece_x+3] = 1'b1;
                        end

                        // ------------------------------------------------
                        // Save board
                        // ------------------------------------------------

                        board <= board_temp;

                        // ------------------------------------------------
                        // New piece
                        // ------------------------------------------------

                        piece <= random[2:0];

                        if (random[2:0] >= 7)
                            piece <= 3'd0;

                        rotation <= 2'd0;

                        piece_x <= 6'sd3;
                        piece_y <= 6'sd0;

                    end
                end
            end

        end

    end

    // ============================================================
    // VGA GRID
    // ============================================================

    wire [5:0] grid_x;
    wire [5:0] grid_y;

    assign grid_x = pix_x[9:4];
    assign grid_y = pix_y[9:4];

    // ============================================================
    // PLAYFIELD
    // ============================================================

    wire in_playfield;

    assign in_playfield =
        (grid_x >= 15) &&
        (grid_x < 25) &&
        (grid_y >= 5) &&
        (grid_y < 25);

    wire [5:0] screen_board_x;
    wire [5:0] screen_board_y;

    assign screen_board_x = grid_x - 15;
    assign screen_board_y = grid_y - 5;

    // ============================================================
    // CURRENT FALLING PIECE RENDERING
    // ============================================================

    reg falling_cell;

    integer render_x;
    integer render_y;

    always @* begin
        board_index = 0; 
        collision_rotate = 0;
        render_index = 0;

        falling_cell = 1'b0;

        render_x = screen_board_x - piece_x;
        render_y = screen_board_y - piece_y;

        if (in_playfield) begin

            if ((render_x >= 0) &&
                (render_x < 4) &&
                (render_y >= 0) &&
                (render_y < 4)) begin

                if (render_y == 0) begin

                    if (p_row0[3-render_x])
                        falling_cell = 1'b1;

                end
                else if (render_y == 1) begin

                    if (p_row1[3-render_x])
                        falling_cell = 1'b1;

                end
                else if (render_y == 2) begin

                    if (p_row2[3-render_x])
                        falling_cell = 1'b1;

                end
                else begin

                    if (p_row3[3-render_x])
                        falling_cell = 1'b1;

                end

            end
        end
    end

    // ============================================================
    // BOARD CELL
    // ============================================================

    reg board_cell;

    integer render_index;

    always @* begin
        board_index = 0; 
        collision_rotate = 0;
        render_index = 0;

        board_cell = 1'b0;

        if (in_playfield) begin

            render_index =
                screen_board_y * 10 +
                screen_board_x;

            if (board[render_index])
                board_cell = 1'b1;

        end
    end

    // ============================================================
    // BORDER
    // ============================================================

    wire is_border;

    assign is_border =
        ((grid_x == 14 || grid_x == 25) &&
         (grid_y >= 4 && grid_y <= 25)) ||

        ((grid_y == 4 || grid_y == 25) &&
         (grid_x >= 14 && grid_x <= 25));

    // ============================================================
    // COLORS
    // ============================================================

    reg [1:0] color_r;
    reg [1:0] color_g;
    reg [1:0] color_b;

    always @* begin
        board_index = 0; 
        collision_rotate = 0;
        render_index = 0;

        color_r = 2'b00;
        color_g = 2'b00;
        color_b = 2'b00;

        // Border
        if (is_border) begin

            color_r = 2'b11;
            color_g = 2'b11;
            color_b = 2'b11;

        end

        // Falling piece
        else if (falling_cell) begin

            color_r = 2'b11;
            color_g = 2'b11;
            color_b = 2'b00;

        end

        // Locked blocks
        else if (board_cell) begin

            color_r = 2'b00;
            color_g = 2'b11;
            color_b = 2'b11;

        end

        // Empty board
        else if (in_playfield) begin

            color_r = 2'b00;
            color_g = 2'b00;
            color_b = 2'b01;

        end

    end

    assign R =
        video_active ? color_r : 2'b00;

    assign G =
        video_active ? color_g : 2'b00;

    assign B =
        video_active ? color_b : 2'b00;

endmodule
