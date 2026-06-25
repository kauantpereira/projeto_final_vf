# Entrega do Projeto Final — Verificação Formal

## Tarefa 1: Depuração e Correção de Bugs no RTL

### Bug 1 — A1: `req_ready` não caía imediatamente ao encher a FIFO

**Comportamento errado:** `a_req_ready` e `b_req_ready` eram registrados em flip-flops, introduzindo um ciclo de atraso. Quando a FIFO ficava cheia, o sinal `req_ready` só caía no ciclo seguinte.

**Causa raiz:** uso de `always @(posedge clk)` com registradores `a_req_ready_r` / `b_req_ready_r` que atribuíam `~fifo_a_full` com latência de um ciclo.

**Correção:** substituição por assigns combinacionais:
```verilog
assign a_req_ready = rst_n ? ~fifo_a_full : 1'b1;
assign b_req_ready = rst_n ? ~fifo_b_full : 1'b1;
```
Com isso, `req_ready` reflete o estado da FIFO no mesmo ciclo.

---

### Bug 2 — A3: FSM não transitava para `S_ERROR` em `mem_ack && mem_err`

**Comportamento errado:** quando a memória retornava `mem_ack && mem_err`, a FSM transitava para `S_IDLE` em vez de `S_ERROR`, ignorando o erro.

**Causa raiz:** transição errada no estado `S_WAIT_ACK`:
```verilog
// original — errado
state_nxt = S_IDLE;
```

**Correção:**
```verilog
state_nxt = S_ERROR;
```

---

### Bug 3 — A2: `rr_priority` não alternava corretamente após transação

**Comportamento errado:** ao concluir uma transação, `rr_priority` era atribuído com `txn_port` (a própria porta que acabou de ser atendida), mantendo a prioridade na mesma porta e nunca alternando.

**Causa raiz:**
```verilog
// original — errado
rr_priority <= txn_port;
```

**Correção:**
```verilog
rr_priority <= ~txn_port;
```
Isso inverte o bit, favorecendo a outra porta na próxima arbitração.

---

### Print — Assertions A1, A2 e A3 como `prove`

> **[INSERIR AQUI PRINT DO JASPERGOLD MOSTRANDO A1, A2 E A3 COM STATUS `prove`]**

---

## Tarefa 2: Assertions do Aluno — Grupo B

### B1 — Sinal `busy`

```systemverilog
B1_sinal_busy: assert property (@(posedge clk)
    (dut.state != dut.S_IDLE) |=> (dut.busy == 1'b1) and
    (dut.state == dut.S_IDLE) |=> (dut.busy == 1'b0)
);
```
Verifica que `busy` é `1` fora de `S_IDLE` e `0` em `S_IDLE`.

---

### B2 — Exclusão mútua de respostas

```systemverilog
B2_exclusao_mutua: assert property (@(posedge clk)
    !(a_resp_valid && b_resp_valid)
);
```
Garante que `a_resp_valid` e `b_resp_valid` nunca estão ativos simultaneamente.

---

### B3 — Estados válidos da FSM

```systemverilog
B3_estados_validos: assert property (@(posedge clk)
    (dut.state == dut.S_IDLE    ||
     dut.state == dut.S_MEM_REQ ||
     dut.state == dut.S_WAIT_ACK||
     dut.state == dut.S_RESP    ||
     dut.state == dut.S_ERROR)
);
```
A FSM nunca pode assumir um estado fora dos cinco estados definidos.

---

### B4 — Persistência de resposta

```systemverilog
B4_persistencia_resp: assert property (@(posedge clk)
    (a_resp_valid && !a_resp_ready)
    |=> (a_resp_valid)
);
```
Enquanto `a_resp_ready` não for afirmado, `a_resp_valid` deve permanecer ativo.

---

### Print — Assertions B1–B4 como `prove`

> **[INSERIR AQUI PRINT DO JASPERGOLD MOSTRANDO B1, B2, B3 E B4 COM STATUS `prove`]**
