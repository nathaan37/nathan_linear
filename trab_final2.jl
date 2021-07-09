using JuMP, Gurobi, DelimitedFiles

#Definições iniciais
num_origens = 2
num_depositos = 3
num_destinos = 5

#Lendo a instância (Origens, Depósitos e Destinos)
inst_locais = readdlm("origens_destinos.txt")

origens = Array{String}(undef, num_origens) #Nome das Origens
for i = 1:num_origens
    origens[i] = inst_locais[1, i]
end

depositos = Array{String}(undef, num_depositos) #Nome dos Depósitos
for i = 1:num_depositos
    depositos[i] = inst_locais[2, i]
end

destinos = Array{String}(undef, num_destinos) #Nome dos Destinos
for i = 1:num_destinos
    destinos[i] = inst_locais[3, i]
end

#Lendo a instância (Ofertas e demandas)
inst_oferta_demanda = readdlm("ofertas_demandas.txt")

oferta_p1 = Array{Float64}(undef, num_origens)
oferta_p2 = Array{Float64}(undef, num_origens)

for i = 1:num_origens
    oferta_p1[i] = inst_oferta_demanda[i, 1]
    oferta_p2[i] = inst_oferta_demanda[i, 2]
end

demanda_p1 = Array{Float64}(undef, num_destinos)
demanda_p2 = Array{Float64}(undef, num_destinos)

for i = 1:num_destinos
    demanda_p1[i] = inst_oferta_demanda[3, i]
    demanda_p2[i] = inst_oferta_demanda[4, i]
end

#Lendo a instância (Capacidade dos Depósitos)
capacidade_p1 = Array{Float64}(undef, num_depositos)
capacidade_p2 = Array{Float64}(undef, num_depositos)

for i = 1:num_depositos
    capacidade_p1[i] = inst_oferta_demanda[num_origens+num_origens+1, i]
    capacidade_p2[i] = inst_oferta_demanda[num_origens+num_origens+2, i]
end

#Lendo a instância (Custos)
inst_custos = readdlm("custos.txt")

c_odp = Array{Float64}(undef, num_origens, num_depositos) #Custo do trecho "oriem-depósito"

for i = 1:num_origens
    for j = 1:num_depositos
        c_odp[i, j] = inst_custos[i, j]
    end
end

c_dde = Array{Float64}(undef, num_depositos, num_destinos) #Custo do trecho "depósito-destino"

for i = 1:num_depositos
    for j = 1:num_destinos
        c_dde[i, j] = inst_custos[num_origens+i, j]
    end
end

c_man = Array{Float64}(undef, num_depositos) #Custo de manuseio no depósito

for i = 1:num_depositos
    c_man[i] = inst_custos[num_origens+num_depositos+1, i]
end

#Lendo a instância (Tempos)
inst_tempos = readdlm("tempos.txt")

t_dem = Array{Float64}(undef, num_destinos) #Tempo para atender a demanda

for i = 1:num_destinos
    t_dem[i] = inst_tempos[1, i]
end

t_odp = Array{Float64}(undef, num_origens, num_depositos) #Tempo entre "origem-depósito"

for i = 1:num_origens
    for j = 1:num_depositos
        t_odp[i, j] = inst_tempos[1+i, j]
    end
end

t_dde = Array{Float64}(undef, num_depositos, num_destinos) #Tempo entre "depósito-destino"

for i = 1:num_depositos
    for j = 1:num_destinos
        t_dde[i, j] = inst_tempos[1+num_origens+i, j]
    end
end

#Modelagem
transhipment = Model(optimizer_with_attributes(Gurobi.Optimizer))

#Variáveis
@variable(transhipment, Qodp_p1[i = 1:num_origens, j = 1:num_depositos] ≥ 0)
@variable(transhipment, Qodp_p2[i = 1:num_origens, j = 1:num_depositos] ≥ 0)
@variable(transhipment, Qdde_p1[i = 1:num_depositos, j = 1:num_destinos] ≥ 0)
@variable(transhipment, Qdde_p2[i = 1:num_depositos, j = 1:num_destinos] ≥ 0)
@variable(transhipment, Qman_p1[i = 1:num_depositos] ≥ 0)
@variable(transhipment, Qman_p2[i = 1:num_depositos] ≥ 0)

@objective(transhipment, Min, sum(c_odp[i, j] * Qodp_p1[i, j] for i = 1:num_origens, j = 1:num_depositos) +
                              sum(c_odp[i, j] * Qodp_p2[i, j] for i = 1:num_origens, j = 1:num_depositos) +
                              sum(c_dde[i, j] * Qdde_p1[i, j] for i = 1:num_depositos, j = 1:num_destinos) +
                              sum(c_dde[i, j] * Qdde_p2[i, j] for i = 1:num_depositos, j = 1:num_destinos) +
                              sum(c_man[i] * Qman_p1[i] for i = 1:num_depositos) +
                              sum(c_man[i] * Qman_p2[i] for i = 1:num_depositos))

#Restrições de Oferta e Demanda
@constraint(transhipment, r_oferta_p1[i = 1:num_origens], sum(Qodp_p1[i, j] for j = 1:num_depositos) ≤ oferta_p1[i])
@constraint(transhipment, r_oferta_p2[i = 1:num_origens], sum(Qodp_p2[i, j] for j = 1:num_depositos) ≤ oferta_p2[i])
@constraint(transhipment, r_demanda_p1[j = 1:num_destinos], sum(Qdde_p1[i, j] for i = 1:num_depositos) == demanda_p1[j])
@constraint(transhipment, r_demanda_p2[j = 1:num_destinos], sum(Qdde_p2[i, j] for i = 1:num_depositos) == demanda_p2[j])

#Restrições de Manuseio
@constraint(transhipment, r_manuseio_p1[i = 1:num_origens], sum(Qodp_p1[i, j] for j = 1:num_depositos) == 
                                                              sum(Qman_p1[j] for j = 1:num_depositos))
@constraint(transhipment, r_manuseio_p2[i = 1:num_origens], sum(Qodp_p2[i, j] for j = 1:num_depositos) ==
                                                              sum(Qman_p2[j] for j = 1:num_depositos))

#restrições de Capacidade
@constraint(transhipment, r_capacidade_p1[i = 1:num_depositos], sum(Qdde_p1[i, j] for j = 1:num_destinos) ≤ capacidade_p1[i])
@constraint(transhipment, r_capacidade_p2[i = 1:num_depositos], sum(Qdde_p2[i, j] for j = 1:num_destinos) ≤ capacidade_p2[i])

#Restrição de tempo


#Restrições de Fluxo
@constraint(transhipment, r_fluxo_p1[j = 1:num_depositos], sum(Qodp_p1[i, j] for i = 1:num_origens) ==
                                                           sum(Qdde_p1[j, k] for k = 1:num_destinos))
@constraint(transhipment, r_fluxo_p2[j = 1:num_depositos], sum(Qodp_p2[i, j] for i = 1:num_origens) == 
                                                           sum(Qdde_p2[j, k] for k = 1:num_destinos))

#Otimizando a solução
optimize!(transhipment)

println(transhipment)

#Imprimindo a solução
println("Status: ", termination_status(transhipment))
println("Custo total minimizado: R\$ ", round(objective_value(transhipment), digits = 2))

println("\nSolução: Produto 1 (trecho ORIGEM ---> DEPÓSITOS)")
for i = 1:num_origens
    for j = 1:num_depositos
        println("A origem ", origens[i], " enviará ", round(value(Qodp_p1[i, j]), digits = 2), " para o depósito ", depositos[j])
    end
end

println("\nSolução: Produto 2 (trecho ORIGEM ---> DEPÓSITOS)")
for i = 1:num_origens
    for j = 1:num_depositos
        println("A origem ", origens[i], " enviará ", round(value(Qodp_p2[i, j]), digits = 2), " para o depósito ", depositos[j])
    end
end

println("\nSolução: Produto 1 (trecho DEPÓSITO ---> DESTINOS")
for i = 1:num_depositos
    for j = 1:num_destinos
        println("O depósito ", depositos[i], " enviará ", round(value(Qdde_p1[i, j]), digits = 2), " para o destino ", destinos[j])
    end
end

println("\nSolução: Produto 2 (trecho DEPÓSITO ---> DESTINOS")
for i = 1:num_depositos
    for j = 1:num_destinos
        println("O depósito ", depositos[i], " enviará ", round(value(Qdde_p2[i, j]), digits = 2), " para o destino ", destinos[j])
    end
end