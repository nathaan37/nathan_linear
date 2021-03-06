using LinearAlgebra: length
using LinearAlgebra
using PrettyTables

#Definindo o problema
tipo = "max"
sinais = ["≤", "=", "≥"]
fobj = [3, 5]
rest = [1 0; 0 2; 3 2]
B = [4, 12, 18]
sinais_negatividade = ["≥", "≥"]

#Ajustando os índices da Função Objetivo de acordo com o tipo do problema (max ou min)
if tipo == "max"
    fobj = fobj * (-1)
end

#Declarando algumas variáveis que irão ser utilizadas na manipulação do tableau
M = 100

num_linhas = length(rest[: , 1])
num_colunas = length(rest[1, :])
num_rest = num_linhas
nvar = length(fobj)

#Montando a Função Objetivo
for i = 1:num_linhas
    if sinais[i] == "≤"
        push!(fobj, 0)
    elseif sinais[i] == "="
        push!(fobj, M)
    else
        push!(fobj, 0)
        push!(fobj, M )
    end
end

append!(fobj, 0)

#Criando o tableau e preenchendo a primeira linha com a Função Objetivo
tableau = Array{Float64}(undef, num_rest+1, length(fobj))

tableau[1, :] = fobj

#Contando o número de colunas que a "identidade" terá

n = 0
for i = 1:num_rest
    global n
    if sinais[i] == "≥"
        n = n + 2
    else
        n = n + 1
    end
end

#Montando a "identidade"
identidade = zeros(num_rest, n)

j = 0
for i = 1:num_rest
    global j
    if sinais[i] == "≥"
        j = j + 1
        identidade[i,j] = -1
        j = j + 1
        identidade[i,j] = 1
    else
         j = j + 1
         identidade[i,j] = 1
    end
end

A = [rest identidade B]

#Preenchendo o restante do tableau
for i = 1:num_rest
        tableau[i+1, :] = A[i, :]
end

#Impressão do TABLEAU
header = String[]
colunas_tableau = length(tableau[1, :])

for j = 1:colunas_tableau
    push!(header, "x$j")
end

header[colunas_tableau, 1] = "B"

println("TABLEAU INICIAL:")
pretty_table(tableau, header = header, border_crayon = crayon"green",formatters = ft_round(2))



############### SIMPLEX #################

#Manipulando o tableau de forma que as variáveis artificiais entrem na base
for i = 1:length(sinais)
    if sinais[i] ≠ "≤"
        tableau[1, :] = tableau[1, :] - (M * tableau[i+1, :])
    end
end

#A partir daqui continua o SIMPLEX já desenvolvido
num_linhas = length(tableau[:, 1])
num_colunas = length(tableau[1, :])
num_rest = num_linhas-1
num_var = num_colunas-1-num_rest

#Coletando os índices das VARIÁVEIS DE FOLGA
base = Array{Int64}(undef, num_rest)

for i = 1:num_rest
    base[i] = num_var+i
end

#Função Principal
function simplex()
    
    while minimum(tableau[1, 1:num_colunas-1]) < 0

        #Definindo a COLUNA PIVÔ (variável que ENTRA na base)
        
        entra_base = Float64
        for i = 1:num_colunas-1
            if minimum(tableau[1, 1:num_colunas-1]) == tableau[1, i]
                entra_base = i
            end
        end
    
        println("Variável que entra na base: x", entra_base)
    
        #Definindo a LINHA PIVÔ (variável que SAI na base; teste da razão mínima)
        teste_raz_min = Array{Float64}(undef, num_rest)
        a = Float64
    
        for i = 1:num_rest
            a = tableau[i+1, num_colunas] / tableau[i+1, entra_base]
            if a > 0
                teste_raz_min[i] = a
            else
                teste_raz_min[i] = 1000000000
            end
        end
        
        sai_base = Float64
        for i = 1:num_rest
            if minimum(teste_raz_min) == teste_raz_min[i]
                sai_base = i+num_var
            end
        end 
    
        println("Variável que sai da base: x", sai_base) #No tableau, a linha que sai da base é a sai_base-num_var+1
    
        base[sai_base-num_var] = entra_base #Atualiza as variáveis que compõem a base

        #Definindo o ELEMENTO PIVÔ
        elemento_pivo = tableau[sai_base-num_var+1, entra_base]
    
        println("O elemento pivô é: ", elemento_pivo)
    
        #Calculando a NOVA LINHA PIVÔ
        nova_linha_pivo = tableau[sai_base-num_var+1, :] / elemento_pivo
    
        println("A nova linha pivô é: ", nova_linha_pivo)
    
        #Atualizando o tableau
        for i = 1:num_linhas
        
            tableau[i, :] = (nova_linha_pivo * (-1 * tableau[i, entra_base]) + tableau[i, :])
        
        end
        
        tableau[sai_base-num_var+1, :] = nova_linha_pivo
        
        println("Tableau atualizado:\n", tableau)
        println("")
    
    end
end

simplex()

#Imprimindo a Solução Ótima

if tipo == "max"
    sol_otima = tableau[1, num_colunas]
else
    sol_otima = tableau[1, num_colunas] * -1
end

println("Solução Ótima:\n", "z = ", sol_otima)

println("\nVariáveis Básicas (Base):")

for i = 1:num_linhas-1
    println("x", base[i], " = ", tableau[i+1, num_colunas])
end

# DUALIDADE #

#Definindo o tipo do problema
if tipo == "max"
    tipo_dual = "min"
else
    tipo_dual = "max"
end

#Montando DUAL na forma tabular
p = fobj[1:nvar] * -1
dual_transp = [rest' p]

tableau_dual = Array{Float64}(undef, nvar+1, num_rest+1)

fobj_dual = append!(B, 0)

tableau_dual[1, :] = fobj_dual

for i = 1:nvar
    tableau_dual[i+1, :] = dual_transp[i, :]
end

#Definindo os sinais do DUAL
sinais_var_dual = String[]

if tipo == "max"
    for i = 1:num_rest
        if sinais[i] == "≤"
            push!(sinais_var_dual, "≥")
        elseif sinais[i] == "="
            push!(sinais_var_dual, "=")
        else
            push!(sinais_var_dual, "≤")
        end
    end
else
    for i = 1:num_rest
        if sinais[i] == "≥"
            push!(sinais_var_dual, "≥")
        elseif sinais[i] == "="
            push!(sinais_var_dual, "=")
        else
            push!(sinais_var_dual, "≤")
        end
    end
end

sinais_rest_dual = String[]

if tipo == "max"
    for i = 1:nvar
        if sinais_negatividade[i] == "≥"
            push!(sinais_rest_dual, "≥")
        elseif sinais_negatividade[i] == "="
            push!(sinais_rest_dual, "=")
        else
            push!(sinais_rest_dual, "≤")
        end
    end
else
    for i = 1:nvar
        if sinais_negatividade[i] == "≥"
            push!(sinais_rest_dual, "≤")
        elseif sinais_negatividade[i] == "="
            push!(sinais_rest_dual, "=")
        else
            push!(sinais_rest_dual, "≥")
        end
    end
end

#Informações do DUAL
println("\n\nDUALIDADE")
println("Tipo de problema (Dual): ", tipo_dual)
println("Coeficientes Função Objetivo do Dual: ", tableau_dual[1, 1:nvar+1])
println("Coeficientes das Restrições do Dual: ", tableau_dual[2:nvar+1, 1:nvar+1])
println("Sinais das Variáveis do Dual: ", sinais_var_dual)
println("Sinais das Restrições do Dual: ", sinais_rest_dual)

#Impressão do TABLEAU DUAL
header_dual = String[]
colunas_tableau_dual = length(tableau_dual[1, :])

for j = 1:colunas_tableau_dual
    push!(header_dual, "y$j")
end

header_dual[colunas_tableau_dual, 1] = "C"

println("\nPROBLEMA DUAL NA FORMA TABULAR:")
pretty_table(tableau_dual, header = header_dual, border_crayon = crayon"green",formatters = ft_round(2))

#Solução Dual
println("\nSolução Dual")

for i = 1:num_linhas-1
    println("y", i, " = ", tableau[1, i+nvar])
end
