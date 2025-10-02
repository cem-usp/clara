# ---------------------------------------- #
# Adicionar informacoes de porte empresarial
# e fazer traducoes na base
# ---------------------------------------- #

# Bibliotecas necessarias
library(dplyr)
library(tidyr)
library(data.table)


# Definir caminhos dos diretorios
estabelecimentos_dir <- "1-inputs/CNPJ_2024/1-ESTABELECIMENTOS"
empresas_dir <- "1-inputs/CNPJ_2024/2-EMPRESAS"
socios_dir <- "1-inputs/CNPJ_2024/3-SOCIOS"
demais_arquivos_dir <- "1-inputs/CNPJ_2024/4-DEMAIS_ARQUIVOS"
temporario_dir <- "2-temp"


output_dir <- file.path(temporario_dir, "01.05-adicionar_informacoes_porte_traduzir_base")

# Criar diretorio de saida caso não exista
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Ler arquivo gerado na etapa 01.04
estab_emp_soc <- fread(file.path(temporario_dir, "01.04-unir_estab_empresas_socios/01.04.01-estab_emp_soc_spcap_farmacias.csv"),
                       sep = ";", encoding = "Latin-1")


# Ler arquivos de corespondência para Município, Natureza Jurídica e CNAE

# Municípios
# Baixar correspondência com códigos do IBGE pelo link abaixo, na aba 'Tabela de Órgãos e Municípios'
# https://dados.gov.br/dados/conjuntos-dados/tabela-de-rgos-e-municpios#:~:text=Info,RFB%20e%20dom%C3%ADnios%20de%20endere%C3%A7amento.

# Definir nome do arquivo de correspondências para municípios
municipios_arquivo <- "1-inputs/municipios.csv"

# Ler arquivo de correspondência para municípios
municipios_trad <- read.csv(municipios_arquivo, sep=";", fileEncoding = "latin1")

# Corrigir nomes das colunas
colnames(municipios_trad) <- gsub("\\.+", "_", colnames(municipios_trad))

# Selecionar colunas que serão utilizadas
municipios_trad <- municipios_trad[, c("CÓDIGO_DO_MUNICÍPIO_TOM", "CÓDIGO_DO_MUNICÍPIO_IBGE", "MUNICÍPIO_IBGE")]

# Renomear colunas
colnames(municipios_trad) <- c("MUNICIPIO_TOM", "MUNICIPIO_IBGE", "MUNICIPIO")

# Naturezas Jurídicas
# Definir nome do arquivo de correspondências para Natureza Jurídica
naturezas_juridicas_arquivo <- "F.K03200$Z.D50111.NATJUCSV"

# Ler arquivo de dados do Simples Nacional
naturezas_juridicas_trad <- read.csv(file.path(demais_arquivos_dir, naturezas_juridicas_arquivo), sep=";", fileEncoding = "latin1", header = FALSE)

# Atribuir nomes às colunas
colnames(naturezas_juridicas_trad) <- c("NATUREZA_JURIDICA", "DESCRICAO")

# Garantir que "NATUREZA_JURIDICA" seja do tipo inteiro
naturezas_juridicas_trad$NATUREZA_JURIDICA <- as.integer(naturezas_juridicas_trad$NATUREZA_JURIDICA)

# CNAEs
# Definir nome do arquivo de correspondências para CNAEs
cnaes_arquivo <- "F.K03200$Z.D50111.CNAECSV"

# Ler arquivo de dados do Simples Nacional
cnaes_trad <- read.csv(file.path(demais_arquivos_dir, cnaes_arquivo), sep=";", fileEncoding = "latin1", header = FALSE)

# Atribuir nomes às colunas
colnames(cnaes_trad) <- c("CNAE", "DESCRICAO")

# Garantir que "CNAE" seja do tipo caractere (string)
cnaes_trad$CNAE <- as.character(cnaes_trad$CNAE)

# ---------------------------------------- #
# Unir ou traduzir conforme correspondências
# ---------------------------------------- #
# Unir os dataframes para Municípios
estab_emp_soc <- merge(estab_emp_soc, municipios_trad, by = "MUNICIPIO_TOM", all.x = TRUE)
estab_emp_soc <- subset(estab_emp_soc, select = -MUNICIPIO_TOM)

# Criar um dicionário de mapeamento {NATUREZA_JURIDICA: DESCRICAO}
naturezas_juridicas_dict <- setNames(naturezas_juridicas_trad$DESCRICAO, naturezas_juridicas_trad$NATUREZA_JURIDICA)

# Aplicar o mapeamento (tradução)
estab_emp_soc$NATUREZA_JURIDICA <- naturezas_juridicas_dict[as.character(estab_emp_soc$NATUREZA_JURIDICA)]

# Traduzir códigos de matriz e filial
estab_emp_soc$MATRIZ_FILIAL <- recode(estab_emp_soc$IDENTIFICADOR_MATRIZ_FILIAL, `1` = "Matriz", `2` = "Filial")
estab_emp_soc <- subset(estab_emp_soc, select = -IDENTIFICADOR_MATRIZ_FILIAL)

# Definir dicionário de mapeamento de situação cadastral
situacao_map <- setNames(c("Nula", "Ativa", "Suspensa", "Inapta", "Baixada"), c(1, 2, 3, 4, 8))
# Aplicar o mapeamento
estab_emp_soc$SITUACAO_CADASTRAL <- recode(estab_emp_soc$SITUACAO_CADASTRAL, !!!situacao_map)

# ------------------------ #
# Listar CNPJs MEI e Simples
# ------------------------ #
# Definir nome do arquivo para o Simples Nacional
simples_arquivo <- "F.K03200$W.SIMPLES.CSV.D50111"

# Ler arquivo de dados do Simples Nacional
simples <- read.csv(file.path(demais_arquivos_dir, simples_arquivo), sep = ";", encoding = "latin1", header = FALSE,
                    col.names = c("CNPJ_BASICO", "SIMPLES", "DATA_OPCAO_SIMPLES", "DATA_EXCLUSAO_SIMPLES",
                                  "MEI", "DATA_OPCAO_MEI", "DATA_EXCLUSAO_MEI"))
# Filtrar dados do Simples
simples <- simples[simples$CNPJ_BASICO %in% estab_emp_soc$CNPJ_BASICO, ]

# Listar CNPJ básicos do Simples Nacional
cnpj_simples <- simples[simples$SIMPLES == "S", c("CNPJ_BASICO", "SIMPLES")]
# Salvar o dataframe como CSV
write.csv(cnpj_simples, file.path(temporario_dir,
                                  '01.05-adicionar_informacoes_porte_traduzir_base/01.05.01-simples_spcap_farmacias.csv'), row.names = FALSE)

# Listar CNPJ básicos Microempreendedores Individuais
cnpj_mei <- simples[simples$MEI == "S", c("CNPJ_BASICO", "MEI")]
# Salvar o dataframe como CSV
write.csv(cnpj_simples, file.path(temporario_dir,
                                  '01.05-adicionar_informacoes_porte_traduzir_base/01.05.02-mei_spcap_farmacias.csv'), row.names = FALSE)

# Unir 'cnpj_completo' resultante com 'cnpj_simples'
estab_emp_soc <- merge(estab_emp_soc, cnpj_simples, by = "CNPJ_BASICO", all.x = TRUE)

# Unir 'cnpj_completo' resultante com 'cnpj_mei'
estab_emp_soc <- merge(estab_emp_soc, cnpj_mei, by = "CNPJ_BASICO", all.x = TRUE)

# ---------------------------------------- #
# Corrigir valores de Capital Social e Porte
# ---------------------------------------- #

# Tratar a coluna CAPITAL_SOCIAL_EMPRESA
estab_emp_soc$CAPITAL_SOCIAL_EMPRESA <- estab_emp_soc$CAPITAL_SOCIAL_EMPRESA %>%
  gsub("\\.", "", .) %>%  # Remover separadores de milhar
  gsub(",", ".", .) %>%   # Trocar vírgula decimal por ponto
  as.numeric()            # Converter para número

# Criar dicionário de mapeamento
porte_map <- setNames(c("Não informado", "Microempresa", "Empresa de pequeno porte", "Demais portes"),
                      c(0, 1, 3, 5))

# Substituir os valores da coluna 'PORTE_EMPRESA'
estab_emp_soc$PORTE_EMPRESA <- recode(estab_emp_soc$PORTE_EMPRESA, !!!porte_map)

# Substituir 'PORTE_EMPRESA' por 'MEI' onde 'MEI' é igual a 'S'
estab_emp_soc$PORTE_EMPRESA[estab_emp_soc$MEI == "S"] <- "MEI"
estab_emp_soc <- subset(estab_emp_soc, select = -MEI)

# Salvar arquivo gerado
write.csv(estab_emp_soc, file.path(temporario_dir,
                                  '01.05-adicionar_informacoes_porte_traduzir_base/01.05.03-estab_emp_soc_trad_spcap_farmacias.csv'), row.names = FALSE)
