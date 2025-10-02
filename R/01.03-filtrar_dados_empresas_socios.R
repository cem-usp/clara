# -------------------------------------------------- #
# Filtrar bases empresas e socios 
# -------------------------------------------------- #

# Bibliotecas necessarias
library(dplyr)
library(data.table)

# Definir caminhos dos diretorios
estabelecimentos_dir <- "1-inputs/CNPJ_2024/1-ESTABELECIMENTOS"
empresas_dir <- "1-inputs/CNPJ_2024/2-EMPRESAS"
socios_dir <- "1-inputs/CNPJ_2024/3-SOCIOS"
demais_arquivos_dir <- "1-inputs/CNPJ_2024/4-DEMAIS_ARQUIVOS"
temporario_dir <- "temp_temp"


output_dir <- file.path(temporario_dir, "01.03-filtrar_dados_empresas_socios")

# Criar diretorio de saida caso não exista
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Ler arquivo '01.02.01-estabelecimentos_spcap_farmacias.csv' gerado na etapa 01.02
estab <- fread(file.path(temporario_dir, "01.02-filtrar_base/01.02.01-estabelecimentos_redepharma.csv"), sep = ";", encoding = "Latin-1")

# Criar uma lista para armazenar os data frames filtrados
dados_empresas <- list()

# Listar arquivos no diretorio de empresas
arquivos_empresas <- list.files(empresas_dir, full.names = TRUE)

# Iterar sobre os arquivos e processa-los
for (caminho_arquivo in arquivos_empresas) {
  if (file.exists(caminho_arquivo)) {
    cat("Processando:", caminho_arquivo, "\n")
    
    tryCatch({
      # Ler o arquivo CSV
      empresas <- fread(caminho_arquivo, sep = ";", encoding = "Latin-1", header = FALSE, col.names = c(
        "CNPJ_BASICO",
        "RAZAO_SOCIAL_NOME_EMPRESARIAL",
        "NATUREZA_JURIDICA",
        "QUALIFICACAO_RESPONSAVEL",
        "CAPITAL_SOCIAL_EMPRESA",
        "PORTE_EMPRESA",
        "ENTE_FEDERATIVO_RESPONSAVEL"
      ))
      
      # Converter tipos de colunas conforme necessario
      empresas <- empresas %>%
        mutate(
          CNPJ_BASICO = as.integer(CNPJ_BASICO),
          NATUREZA_JURIDICA = as.integer(NATUREZA_JURIDICA)
        )
      
      # Filtrar pelos CNPJs existentes em estab
      empresas <- empresas[CNPJ_BASICO %in% estab$CNPJ_BASICO]
      
      # Adicionar o data frame à lista
      dados_empresas <- append(dados_empresas, list(empresas))
      
    }, error = function(e) {
      cat("Erro ao processar o arquivo", caminho_arquivo, ":", e$message, "\n")
    })
  }
}

# Concatenar todos os data frames da lista em um unico data.table
empresas <- rbindlist(dados_empresas, use.names = TRUE, fill = TRUE)

# Salvar o dataframe resultante
fwrite(empresas, file.path(output_dir, "01.03.01-empresas_redepharma.csv"), sep = ";", row.names = FALSE)

# Listar arquivos no diretorio de socios
arquivos_socios <- list.files(socios_dir, full.names = TRUE)

# Criar uma lista para armazenar os data frames filtrados
dados_socios <- list()

# Iterar sobre os arquivos e processa-los
for (caminho_arquivo in arquivos_socios) {
  if (file.exists(caminho_arquivo)) {
    cat("Processando:", caminho_arquivo, "\n")
    
    tryCatch({
      # Ler o arquivo CSV
      socios <- fread(caminho_arquivo, sep = ";", encoding = "Latin-1", header = FALSE, col.names = c(
        "CNPJ_BASICO",
        "IDENTIFICADOR_SOCIO",
        "NOME_SOCIO",
        "CPF_CNPJ_SOCIO",
        "QUALIFICACAO_SOCIO",
        "DATA_ENTRADA_SOCIEDADE",
        "PAIS",
        "CPF_REPRESENTANTE",
        "NOME_REPRESENTANTE",
        "QAUALIFICACAO_REPRESENTANTE",
        "FAIXA_ETARIA"
      ))
      
      # Converter tipos de colunas conforme necessario
      socios <- socios %>%
        mutate(
          CNPJ_BASICO = as.integer(CNPJ_BASICO))
      
      # Filtrar pelos CNPJs existentes em estab
      socios <- socios[CNPJ_BASICO %in% estab$CNPJ_BASICO]
      
      # Adicionar o data frame à lista
      dados_socios <- append(dados_socios, list(socios))
      
    }, error = function(e) {
      cat("Erro ao processar o arquivo", caminho_arquivo, ":", e$message, "\n")
    })
  }
}

# Concatenar todos os data frames da lista em um unico data.table
socios <- rbindlist(dados_socios, use.names = TRUE, fill = TRUE)

# Salvar o dataframe resultante
fwrite(socios, file.path(output_dir, "01.03.02-socios_redepharma.csv"), sep = ";", row.names = FALSE)
