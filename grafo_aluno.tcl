# ================================================================
# TAREFA 3: Verificação Formal como Busca em Grafos
#
# Execute standalone:  tclsh grafo_fsm.tcl
# Ou via Jasper:       source grafo_fsm.tcl  (após prove -all)
# ================================================================

puts "============================================================"
puts " Tarefa 3: Grafo de Transição de Estados do mem_arbiter"
puts "============================================================\n"

# ================================================================
# G1: Construir o grafo da FSM CORRIGIDA
# ================================================================
#
# Após corrigir os 3 bugs na Tarefa 1, leia o bloco "Next State
# Logic" do mem_arbiter.v CORRIGIDO e construa o grafo de
# transição de estados.
#
# Para cada estado, liste os estados DIFERENTES para os quais
# ele pode transicionar (ignore self-loops: a FSM pode ficar
# parada no mesmo estado por vários ciclos, mas isso não conta
# como transição no grafo).
#
# Formato: cada chave é um estado, e o valor é a lista de
# estados alcançáveis em UMA transição (mudança de estado).
#
# >>> COMPLETE AQUI <<<
array set grafo {
    S_IDLE     {S_MEM_REQ}
    S_MEM_REQ  {S_WAIT_ACK}
    S_WAIT_ACK {S_RESP S_ERROR}
    S_RESP     {S_IDLE}
    S_ERROR    {S_RESP}
}


# ================================================================
# G2: Calcular o número mínimo de transições entre dois estados
# ================================================================
#
# Implemente a procedure "min_transicoes" que recebe o grafo, um
# estado de origem e um de destino, e retorna o número MÍNIMO de
# transições entre estados DIFERENTES (arestas no grafo) para ir
# de origem até destino. Self-loops não contam.
#
# Se não houver caminho, retorne -1.
#
# Parâmetros:
#   nome_grafo - nome do array Tcl que contém o grafo
#   origem     - estado de partida
#   destino    - estado que queremos alcançar
#
# Retorno: número inteiro (quantidade mínima de arestas)
#
# Dica: use BFS. A distância de um nó é o nível em que ele é
#       visitado pela primeira vez.
#       Use "upvar 1 $nome_grafo grafo" para acessar o array.
#       Use "lindex" para pegar o primeiro da fila,
#       "lrange $fila 1 end" para remover o primeiro,
#       "$elem in $lista" para verificar pertinência.

proc min_transicoes {nome_grafo origem destino} {
    upvar 1 $nome_grafo grafo

    if {$origem eq $destino} { return 0 }

    set fila [list [list $origem 0]]
    set visitados [list $origem]

    while {[llength $fila] > 0} {
        set par   [lindex $fila 0]
        set fila  [lrange $fila 1 end]
        set atual [lindex $par 0]
        set dist  [lindex $par 1]

        foreach vizinho $grafo($atual) {
            if {$vizinho eq $destino} { return [expr {$dist + 1}] }
            if {$vizinho ni $visitados} {
                lappend visitados $vizinho
                lappend fila [list $vizinho [expr {$dist + 1}]]
            }
        }
    }

    return -1
}
