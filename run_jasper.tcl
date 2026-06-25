# ================================================================
# run_jasper.tcl - Script de verificação formal do mem_arbiter
#
# Uso:  jg run_jasper.tcl
#       (executar a partir da raiz do projeto: projeto_final/)
# ================================================================
clear -all
check_cov -init -model {branch} -include_assign_scoring
set_engine_mode {B Hp Ht Tri}

# Leitura dos fontes RTL e do testbench (SystemVerilog 2012)
analyze -sv12 rtl/mem_arbiter.v
analyze -sv12 rtl/sync_fifo.v
analyze -sv12 verif/tb_mem_arbiter.sv

# Elaboração com o testbench como módulo de topo
elaborate -top tb_mem_arbiter -no_precondition

# Configuração de clock e reset para o motor formal
clock clk
reset !rst_n

# Exercício de grafos (Tarefa 3)
# Constrói o grafo da FSM e roda BFS para alcançabilidade
source grafo_fsm.tcl

# Executa todas as assertions, assumptions e covers
prove -all

# ================================================================
# Tarefa 4: Análise de Coverage Formal
# ================================================================

# Medir coverage com base nas assertions provadas
check_cov -measure -time_limit 30s
