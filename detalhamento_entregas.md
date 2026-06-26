# Documentacao do Trabalho Pratico

Este arquivo resume o que o Projeto Final pede para ser feito e entregue. Os prints do JasperGold devem ser coletados no ambiente onde o Jasper estiver instalado.

## Objetivo Geral

O trabalho usa verificacao formal com JasperGold em um arbitro de memoria dual-port (`mem_arbiter`). O objetivo e:

- analisar assertions pre-escritas que falham;
- corrigir bugs no RTL;
- escrever novas assertions SystemVerilog;
- relacionar a FSM do hardware com busca em grafos;
- usar coverage formal para criar assertions de regressao;
- documentar os resultados em um relatorio final.

## Arquivos Principais

- `rtl/mem_arbiter.v`: RTL principal, contem os bugs que precisam ser corrigidos.
- `rtl/sync_fifo.v`: FIFO sincrona auxiliar, sem bugs esperados.
- `verif/tb_mem_arbiter.sv`: testbench formal com assumptions e assertions.
- `grafo_aluno.tcl`: arquivo que deve ser completado na tarefa de grafos.
- `grafo_fsm.tcl`: script auxiliar para gerar distancias e covers.
- `run_jasper.tcl`: script principal para rodar a verificacao formal no Jasper.

## Tarefa 1: Depurar e Corrigir Bugs no RTL

O testbench possui tres assertions pre-escritas, chamadas A1, A2 e A3. Elas devem ser executadas no JasperGold contra o design original.

O trabalho pede:

- rodar as assertions A1, A2 e A3;
- observar quais falham;
- analisar o contra-exemplo de cada falha;
- identificar a causa raiz no RTL;
- corrigir os bugs em `rtl/mem_arbiter.v`;
- rodar novamente para confirmar que as assertions passam.

Assertions do Grupo A:

- A1: `req_ready` deve cair imediatamente quando a FIFO correspondente esta cheia.
- A2: apos completar uma transacao, `rr_priority` deve alternar para favorecer a outra porta.
- A3: quando a memoria retorna `mem_ack && mem_err`, a FSM deve ir para `S_ERROR`.

Entregaveis desta tarefa no relatorio:

- explicacao verbal de cada bug;
- explicacao do comportamento errado do codigo original;
- explicacao de por que a correcao resolve;
- print do Jasper mostrando as assertions corrigidas como `prove`.

## Tarefa 2: Assertions do Aluno, Grupo B

O arquivo `verif/tb_mem_arbiter.sv` possui quatro assertions incompletas, B1 a B4. Elas devem ser descomentadas e preenchidas com expressoes SVA corretas.

Assertions pedidas:

- B1: `busy` deve ser `1` quando a FSM nao esta em `S_IDLE`, e `0` quando esta em `S_IDLE`.
- B2: `a_resp_valid` e `b_resp_valid` nunca podem estar ativos ao mesmo tempo.
- B3: a FSM deve estar sempre em um estado valido: `S_IDLE`, `S_MEM_REQ`, `S_WAIT_ACK`, `S_RESP` ou `S_ERROR`.
- B4: `resp_valid` deve permanecer ativo ate o handshake com `resp_ready`.

Entregaveis desta tarefa no relatorio:

- codigo de cada assertion escrita;
- print do Jasper mostrando status `prove` para cada assertion B1-B4.

## Tarefa 3: Verificacao Formal Como Busca em Grafos

Esta tarefa relaciona model checking com BFS em grafos. A FSM do `mem_arbiter` deve ser representada como um grafo de estados.

O trabalho pede completar `grafo_aluno.tcl` em duas partes:

- G1: construir o grafo da FSM corrigida.
- G2: implementar a procedure `min_transicoes` usando BFS.

Grafo esperado da FSM corrigida:

- `S_IDLE -> S_MEM_REQ`
- `S_MEM_REQ -> S_WAIT_ACK`
- `S_WAIT_ACK -> S_RESP`
- `S_WAIT_ACK -> S_ERROR`
- `S_RESP -> S_IDLE`
- `S_ERROR -> S_RESP`

Self-loops nao contam como transicoes para esta tarefa.

Depois de completar o grafo e o BFS:

- rodar `tclsh grafo_fsm.tcl`;
- conferir a tabela de distancias minimas;
- rodar o Jasper com `run_jasper.tcl`;
- verificar os covers gerados pelo script.

Entregaveis desta tarefa no relatorio:

- desenho do grafo de transicao da FSM corrigida;
- arquivo `grafo_aluno.tcl` completo;
- saida do script com a tabela de distancias minimas;
- print da Property Table do Jasper mostrando os covers como `covered`;
- respostas das perguntas P1 a P5.

Perguntas do relatorio:

- P1: quantas transicoes minimas sao necessarias para ir de `S_IDLE` ate `S_ERROR`? E de `S_IDLE` ate `S_RESP`?
- P2: o Jasper conseguiu cobrir todos os covers gerados?
- P3: o que o operador `$changed(dut.state)[->N]` esta contando?
- P4: por que o valor `N` corresponde a distancia BFS?
- P5: se a assertion de estado valido e `prove`, o que isso significa em termos do grafo de estados? Se um estado fosse inalcançavel, o que isso significaria para uma propriedade que depende desse estado?

## Tarefa 4: Coverage Formal e Assertions de Regressao

Depois que A1-A3 e B1-B4 passam, o trabalho pede analisar coverage formal no Jasper.

O objetivo e verificar se as assertions existentes cobrem todo o comportamento relevante do RTL. O enunciado destaca que as assertions iniciais verificam principalmente controle e protocolo, mas nao cobrem todo o caminho de dados.

Passos pedidos:

- rodar `jg run_jasper.tcl -cov`;
- observar o relatorio de coverage;
- registrar o percentual de branch coverage antes das assertions de regressao;
- identificar linhas ou comportamentos `uncovered`;
- escrever assertions de regressao R1-R4;
- rodar coverage novamente;
- comparar o percentual antes e depois.

Assertions de regressao pedidas:

- R1: roteamento de dados para memoria; `mem_addr` deve corresponder a `txn_addr`.
- R2: flag de erro; em `S_ERROR`, `txn_error` deve ser ativado.
- R3: captura de dados de leitura; em leitura com `mem_ack && !mem_err`, `mem_rdata` deve ser salvo em `txn_rdata`.
- R4: contador de erros; em `mem_ack && mem_err`, `err_count` deve incrementar.

Entregaveis desta tarefa no relatorio:

- print do coverage antes das assertions R1-R4;
- percentual de coverage antes;
- explicacao das linhas ou comportamentos nao cobertos;
- codigo das assertions de regressao;
- print do coverage depois das assertions R1-R4;
- percentual de coverage depois;
- explicacao caso alguma linha continue `uncovered`;
- resposta sobre o risco de uma linha de RTL nao estar coberta por nenhuma assertion.

## Relatorio Final

O trabalho pede um relatorio documentando as tarefas. Uma estrutura recomendada e:

1. Introducao breve do design.
2. Tarefa 1: bugs encontrados, causa raiz, correcao e prints.
3. Tarefa 2: assertions B1-B4 e prints de `prove`.
4. Tarefa 3: grafo, BFS, saida do script, covers e respostas P1-P5.
5. Tarefa 4: coverage antes/depois, assertions R1-R4 e analise.
6. Conclusao breve.

Os prints do Jasper devem ser inseridos no relatorio final, nao necessariamente neste arquivo Markdown.

## Estrutura de Entrega

O enunciado pede submeter no Moodle um unico arquivo `.zip`, com nome no formato:

```text
projeto_final_<seu_RA>.zip
```

Estrutura esperada:

```text
projeto_final/
├── rtl/
│   ├── mem_arbiter.v
│   └── sync_fifo.v
├── verif/
│   └── tb_mem_arbiter.sv
├── grafo_aluno.tcl
└── relatorio.pdf
```

O arquivo `relatorio.pdf` deve conter as explicacoes, codigos relevantes, respostas e prints solicitados.

## Comandos Uteis

Executar verificacao formal:

```bash
cd projeto_final
jg run_jasper.tcl
```

Executar coverage formal:

```bash
cd projeto_final
jg run_jasper.tcl -cov
```

Executar apenas o script Tcl de grafos:

```bash
cd projeto_final
tclsh grafo_fsm.tcl
```

## Checklist Final

- [ ] A1-A3 passam no Jasper apos corrigir o RTL.
- [ ] B1-B4 foram preenchidas e passam no Jasper.
- [ ] `grafo_aluno.tcl` contem o grafo correto da FSM.
- [ ] `min_transicoes` foi implementado com BFS.
- [ ] Saida do script de grafos foi registrada.
- [ ] Covers do Jasper foram verificados.
- [ ] Coverage antes das regressions foi registrado.
- [ ] R1-R4 foram preenchidas e passam no Jasper.
- [ ] Coverage depois das regressions foi registrado.
- [ ] Relatorio final contem explicacoes, respostas e prints.
- [ ] Zip final foi montado no formato pedido.
