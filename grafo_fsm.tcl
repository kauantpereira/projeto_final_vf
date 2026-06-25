#!/usr/bin/env tclsh

include grafo_aluno.tcl

# ================================================================
# CÓDIGO AUXILIAR: Gerar covers para validar transições no Jasper
# (já implementado - não precisa modificar)
# ================================================================
#
# Esta procedure gera comandos "cover" do Jasper para TODOS os
# pares de estados (origem, destino).
#
# Quando o par é ALCANÇÁVEL (dist >= 1), o cover gerado é:
#
#   cover -name from_<ORIG>_to_<DEST> \
#     {<expr_orig> ##1 $changed(dut.state)[->1:N] ##0 <expr_dest>}
#
#   Leitura da expressão, parte por parte:
#     <expr_orig>                  → começa no estado de origem
#     ##1                          → espera 1 ciclo de clock
#     $changed(dut.state)          → detecta quando dut.state MUDA de valor
#     [->1:N]                      → "goto repetition": espera de 1 a N
#                                    ocorrências de mudança de estado
#                                    (pode haver ciclos intermediários
#                                    em que o estado não muda — self-loops)
#     ##0                          → no mesmo ciclo da última mudança
#     <expr_dest>                  → verifica que estamos no estado destino
#
#   Ou seja: "partindo do estado origem, o design consegue chegar
#   ao estado destino em no máximo N mudanças de estado?"
#   O N vem da distância mínima calculada pelo seu BFS.
#
# Quando o par é INALCANÇÁVEL (dist == -1), o cover gerado é:
#
#   cover -name from_<ORIG>_to_<DEST> {<expr_orig> ##[1:$] <expr_dest>}
#
#   ##[1:$] significa "após qualquer número de ciclos (1 a infinito)".
#   O Jasper tenta encontrar qualquer caminho. Se não existe nenhum,
#   reporta "unreachable" — confirmando o resultado do BFS.
#
# Isso conecta o resultado do seu algoritmo de grafos com a
# verificação formal: o Jasper confirma que os caminhos existem
# (ou não) no design real.

proc gerar_covers {nome_grafo} {
    upvar 1 $nome_grafo grafo

    set estados_jasper {
        S_IDLE     "dut.state == dut.S_IDLE"
        S_MEM_REQ  "dut.state == dut.S_MEM_REQ"
        S_WAIT_ACK "dut.state == dut.S_WAIT_ACK"
        S_RESP     "dut.state == dut.S_RESP"
        S_ERROR    "dut.state == dut.S_ERROR"
    }

    puts "--- Covers de transições de estados para validar no Jasper ---"
    foreach {orig src_expr} $estados_jasper {
        foreach {dest dest_expr} $estados_jasper {
            if {$orig eq $dest} continue
            set dist [min_transicoes grafo $orig $dest]
            set nome "from_${orig}_to_${dest}"
            if {$dist == -1} {
                # Não alcançável
                #cover -name $nome "$src_expr ##\[1:\$] $dest_expr"
            } else {
                cover -name $nome "$src_expr ##1 \$changed(dut.state)\[->$dist\] ##0 $dest_expr"
            }
        }
    }
    puts ""
}


# ================================================================
# EXECUÇÃO E TESTES
# ================================================================

puts "=== G2: Transições mínimas a partir de S_IDLE ===\n"

set destinos {S_MEM_REQ S_WAIT_ACK S_RESP S_ERROR}
foreach dest $destinos {
    set dist [min_transicoes grafo S_IDLE $dest]
    puts "  S_IDLE -> $dest: $dist transições"
}
puts ""

puts "=== G2: Transições mínimas entre todos os pares ===\n"

set todos {S_IDLE S_MEM_REQ S_WAIT_ACK S_RESP S_ERROR}
foreach orig $todos {
    foreach dest $todos {
        if {$orig eq $dest} continue
        set dist [min_transicoes grafo $orig $dest]
        puts "  $orig -> $dest: $dist transições"
    }
}
puts ""

puts "=== Covers para Jasper ===\n"

gerar_covers grafo