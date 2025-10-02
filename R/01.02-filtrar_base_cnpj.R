# ------------------------------------------------- #
# Filtrar arquivo de estabelecimentos da base de CNPJ 
# ------------------------------------------------- #

# Bibliotecas necessarias
library(dplyr)
library(data.table)

# Definir caminhos dos diretorios
estabelecimentos_dir <- "1-inputs/CNPJ_2024/1-ESTABELECIMENTOS"
empresas_dir <- "1-inputs/CNPJ_2024/2-EMPRESAS"
socios_dir <- "1-inputs/CNPJ_2024/3-SOCIOS"
demais_arquivos_dir <- "1-inputs/CNPJ_2024/4-DEMAIS_ARQUIVOS"
temporario_dir <- "2-temp"


output_dir <- file.path(temporario_dir, "01.02-filtrar_base")

# Criar diretorio de saída caso nao exista
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# ------------------------------------------- #
# Selecionar estabelecimentos da UF Sao Paulo e 
# com CNAEs específicos 
# ------------------------------------------- #

# Definir CNAEs para a filtragem
cnaes_lista <- c("4771701",
                 "4771702")

# Definir município de interesse (Sao Paulo)
sp_mun <- 7107

# Criar uma lista para armazenar os data frames
dados <- list()

# Listar arquivos no diretorio de estabelecimentos
arquivos_estab <- list.files(estabelecimentos_dir, full.names = TRUE)

# Iterar sobre os arquivos e processa-los
for (caminho_arquivo in arquivos_estab) {
  cat("Processando:", caminho_arquivo, "\n")
  
  tryCatch({
    # Ler o arquivo CSV
    estab <- fread(caminho_arquivo, sep = ";", encoding = "Latin-1", header = FALSE, col.names = c(
      "CNPJ_BASICO", 
      "CNPJ_ORDEM", 
      "CNPJ_DV", 
      "IDENTIFICADOR_MATRIZ_FILIAL",
      "NOME_FANTASIA", 
      "SITUACAO_CADASTRAL", 
      "DATA_SITUACAO_CADASTRAL",
      "MOTIVO_SITUACAO_CADASTRAL",
      "NOME_CIDADE_EXTERIOR", 
      "PAIS",
      "DATA_INICIO_ATIVIDADE", 
      "CNAE_FISCAL_PRINCIPAL", 
      "CNAE_FISCAL_SECUNDARIO",
      "TIPO_LOGRADOURO", 
      "LOGRADOURO",
      "NUMERO", 
      "COMPLEMENTO", 
      "BAIRRO",
      "CEP", 
      "UF", 
      "MUNICIPIO_TOM", 
      "DDD_1", 
      "TELEFONE_1", 
      "DDD_2", 
      "TELEFONE_2",
      "DDD_FAX", 
      "FAX", 
      "CORREIO_ELETRONICO", 
      "SITUACAO_ESPECIAL", 
      "DATA_SITUACAO_ESPECIAL"
    ))
    
    # Converter colunas para os tipos adequados
    estab <- estab %>%
      mutate(
        CNAE_FISCAL_PRINCIPAL = as.character(CNAE_FISCAL_PRINCIPAL),
        CEP = as.character(CEP),
        UF = as.character(UF),
        MUNICIPIO_TOM = as.integer(MUNICIPIO_TOM),
        DDD_1 = as.character(DDD_1),
        TELEFONE_1 = as.character(TELEFONE_1),
        DDD_2 = as.character(DDD_2),
        TELEFONE_2 = as.character(TELEFONE_2)
      )
    
    # Filtrar pelos CNAEs desejados
    estab <- estab[CNAE_FISCAL_PRINCIPAL %in% cnaes_lista]
    
    # Filtrar pela UF (Sao Paulo)
    estab <- estab[MUNICIPIO_TOM == sp_mun]
    
    cat("Processado:", caminho_arquivo, "\n")
    
    # Adicionar o data frame a lista
    dados <- append(dados, list(estab))
  }, error = function(e) {
    cat("Erro ao processar o arquivo", caminho_arquivo, ":", e$message, "\n")
  })
}

# Concatenar todos os data frames da lista
estab <- rbindlist(dados, use.names = TRUE, fill = TRUE)

# Salvar o DataFrame processado
fwrite(estab, file.path(output_dir, "01.02.01-estabelecimentos_spcap_farmacias.csv"), sep = ";", row.names = FALSE)
