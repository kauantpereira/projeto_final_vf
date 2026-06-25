module tb_mem_arbiter;

    // ================================================================
    // Clock e Reset
    // ================================================================
    reg clk;
    reg rst_n;

    // ================================================================
    // Sinais
    // ================================================================
    wire        a_req_ready;
    reg         a_req_valid;
    reg  [2:0]  a_req_addr;
    reg  [7:0]  a_req_wdata;
    reg         a_req_wr;

    wire        a_resp_valid;
    reg         a_resp_ready;
    wire [7:0]  a_resp_rdata;
    wire        a_resp_err;

    wire        b_req_ready;
    reg         b_req_valid;
    reg  [2:0]  b_req_addr;
    reg  [7:0]  b_req_wdata;
    reg         b_req_wr;

    wire        b_resp_valid;
    reg         b_resp_ready;
    wire [7:0]  b_resp_rdata;
    wire        b_resp_err;

    wire        mem_req;
    wire [2:0]  mem_addr;
    wire [7:0]  mem_wdata;
    wire        mem_wr;
    reg  [7:0]  mem_rdata;
    reg         mem_ack;
    reg         mem_err;

    wire        busy;
    wire        active_port;
    wire [7:0]  err_count;

    // ================================================================
    // DUT
    // ================================================================
    mem_arbiter #(
        .FIFO_DEPTH     (4),
        .TIMEOUT_CYCLES (8)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .a_req_valid  (a_req_valid),
        .a_req_ready  (a_req_ready),
        .a_req_addr   (a_req_addr),
        .a_req_wdata  (a_req_wdata),
        .a_req_wr     (a_req_wr),
        .a_resp_valid (a_resp_valid),
        .a_resp_ready (a_resp_ready),
        .a_resp_rdata (a_resp_rdata),
        .a_resp_err   (a_resp_err),
        .b_req_valid  (b_req_valid),
        .b_req_ready  (b_req_ready),
        .b_req_addr   (b_req_addr),
        .b_req_wdata  (b_req_wdata),
        .b_req_wr     (b_req_wr),
        .b_resp_valid (b_resp_valid),
        .b_resp_ready (b_resp_ready),
        .b_resp_rdata (b_resp_rdata),
        .b_resp_err   (b_resp_err),
        .mem_req      (mem_req),
        .mem_addr     (mem_addr),
        .mem_wdata    (mem_wdata),
        .mem_wr       (mem_wr),
        .mem_rdata    (mem_rdata),
        .mem_ack      (mem_ack),
        .mem_err      (mem_err),
        .busy         (busy),
        .active_port  (active_port),
        .err_count    (err_count)
    );

    // ================================================================
    // Assumptions (restrições sobre as entradas)
    // ================================================================

    // req_valid não pode cair antes do handshake completar
    assume property (@(posedge clk)
        (a_req_valid && !a_req_ready) |=> a_req_valid);
    assume property (@(posedge clk)
        (b_req_valid && !b_req_ready) |=> b_req_valid);

    // Campos de requisição estáveis enquanto valid sem ready
    assume property (@(posedge clk) (a_req_valid && !a_req_ready) |=> $stable(a_req_addr));
    assume property (@(posedge clk) (a_req_valid && !a_req_ready) |=> $stable(a_req_wdata));
    assume property (@(posedge clk) (a_req_valid && !a_req_ready) |=> $stable(a_req_wr));
    assume property (@(posedge clk) (b_req_valid && !b_req_ready) |=> $stable(b_req_addr));
    assume property (@(posedge clk) (b_req_valid && !b_req_ready) |=> $stable(b_req_wdata));
    assume property (@(posedge clk) (b_req_valid && !b_req_ready) |=> $stable(b_req_wr));

    // mem_err só é válido junto com mem_ack
    assume property (@(posedge clk) mem_err |-> mem_ack);

    // mem_ack só ocorre quando mem_req está ou esteve ativo
    assume property (@(posedge clk) mem_ack |-> (mem_req || $past(mem_req)));

    // ================================================================
    // ASSERTIONS PRÉ-ESCRITAS (devem ser verificadas contra o design)
    //
    // Estas 3 assertions verificam propriedades da especificação.
    // Execute-as no JasperGold. Algumas vão FALHAR -- isso indica
    // a presença de BUGS no RTL.
    //
    // Sua tarefa: para cada assertion que falhar, analise o
    // contra-exemplo, identifique o bug no RTL, e corrija-o.
    // ================================================================

    // --- A1: Controle de Fluxo ---
    // "Quando a FIFO da porta A está cheia, a_req_ready deve ser 0"
    // Propriedade: relação IMEDIATA entre FIFO cheia e req_ready
    A1_controle_de_fluxo: assert property (@(posedge clk) dut.fifo_a_full |-> !a_req_ready);

    // --- A2: Arbitragem Justa ---
    // "Após completar uma transação da porta A, a prioridade deve
    //  alternar para favorecer a porta B (rr_priority = 1)"
    A2_arbitragem_justa: assert property (@(posedge clk)
        (dut.state == dut.S_RESP &&
         dut.resp_valid_mux && dut.resp_ready_mux &&
         active_port == 1'b0)
        |=> (dut.rr_priority == 1'b1)
    );

    // --- A3: Tratamento de Erro ---
    // "Quando a memória retorna erro (mem_ack && mem_err), a FSM deve
    //  ir para S_ERROR no próximo ciclo, não para S_IDLE"
    A3_tratamento_de_erro: assert property (@(posedge clk)
        (dut.state == dut.S_WAIT_ACK && mem_ack && mem_err)
        |=> (dut.state == dut.S_ERROR)
    );

    // ================================================================
    // ASSERTIONS DO ALUNO
    //
    // Escreva 4 assertions para verificar as propriedades abaixo.
    // Todas devem PASSAR (proven) tanto no design original quanto
    // no design corrigido.
    //
    // COMO PREENCHER:
    //   1. Descomente a linha da assertion (remova o "//" no início)
    //   2. Substitua os "..." pela expressão SVA correta
    //   3. Mantenha o @(posedge clk) e os parênteses externos
    //
    //   Exemplo: se a assertion fosse "x deve ser sempre 1", você
    //   mudaria de:
    //     // B1_exemplo: assert property (@(posedge clk) ... );
    //   para:
    //     B1_exemplo: assert property (@(posedge clk) x == 1'b1 );
    //
    // Use a seção 4 das instruções como referência dos operadores SVA.
    // ================================================================

    // --- B1: Sinal Busy ---
    // Verifique que o sinal 'busy' é 1 quando a FSM NÃO está em
    // S_IDLE, e 0 quando está em S_IDLE.

    // B1_sinal_busy: assert property (@(posedge clk) ... );

    // --- B2: Exclusão Mútua de Respostas ---
    // Verifique que a_resp_valid e b_resp_valid NUNCA estão ambos
    // ativos ao mesmo tempo.

    // B2_exclusao_mutua: assert property (@(posedge clk) ... );

    // --- B3: Estados Válidos ---
    // Verifique que a FSM está sempre em um estado válido
    // (S_IDLE, S_MEM_REQ, S_WAIT_ACK, S_RESP, ou S_ERROR).

    // B3_estados_validos: assert property (@(posedge clk) ... );

    // --- B4: Persistência de Resposta ---
    // Verifique que, uma vez que a_resp_valid sobe, ele permanece
    // alto até que a_resp_ready complete o handshake.
    // Em outras palavras: se a_resp_valid=1 e a_resp_ready=0,
    // então no próximo ciclo a_resp_valid ainda deve ser 1.
    // Dica: use o operador |=>
    //
    // B4_persistencia_resp: assert property (@(posedge clk) ... );

    // ================================================================
    // ASSERTIONS DE REGRESSÃO (Tarefa 4)
    //
    // As assertions acima (A1-A3, B1-B4) verificam controle e
    // protocolo, mas NÃO verificam o caminho de DADOS. O relatório
    // de coverage mostra ~70% porque 30% do RTL não é exercitado.
    //
    // Escreva 4 assertions de regressão para travar o comportamento
    // correto das partes não cobertas. Estas assertions garantem que
    // futuras mudanças no código não quebrem funcionalidades validadas.
    //
    // COMO PREENCHER: mesmo processo — descomente e substitua "...".
    // ================================================================

    // --- R1: Roteamento de Dados para Memória ---
    // Após o estado S_MEM_REQ, o endereço enviado à memória (mem_addr)
    // deve corresponder ao endereço da transação capturada (txn_addr).
    //
    // R1_data_routing: assert property (@(posedge clk) ... );

    // --- R2: Flag de Erro na Transação ---
    // Quando a FSM está no estado S_ERROR, o flag txn_error deve ser
    // ativado (1) no ciclo seguinte.
    //
    // R2_error_flag: assert property (@(posedge clk) ... );

    // --- R3: Captura de Dados de Leitura ---
    // Quando uma transação de leitura (txn_wr=0) recebe mem_ack sem
    // erro no estado S_WAIT_ACK, o dado da memória (mem_rdata) deve
    // ser armazenado em txn_rdata no ciclo seguinte.
    // Dica: use $past() para referenciar o valor do ciclo anterior.
    //
    // R3_read_capture: assert property (@(posedge clk) ... );

    // --- R4: Incremento do Contador de Erros ---
    // Quando mem_ack chega com mem_err=1 no estado S_WAIT_ACK,
    // err_count deve incrementar em 1 no ciclo seguinte.
    // Dica: use $past() para comparar com o valor anterior.
    //
    // R4_err_count: assert property (@(posedge clk) ... );

endmodule
