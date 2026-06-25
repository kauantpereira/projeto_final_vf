# ================================================================
# TAREFA 3: Verificação Formal como Busca em Grafos
# ================================================================

# ================================================================
# G1: Grafo da FSM corrigida
# ================================================================
array set grafo {
    S_IDLE     {S_MEM_REQ}
    S_MEM_REQ  {S_WAIT_ACK}
    S_WAIT_ACK {S_RESP S_ERROR}
    S_RESP     {S_IDLE}
    S_ERROR    {S_RESP}
}

# ================================================================
# G2: Número mínimo de transições entre dois estados (BFS)
# ================================================================
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
