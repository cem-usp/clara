# -------------------------------------------------------- #
# Descompactar arquivos de CNPJ e organiza-los em diretorios 
# -------------------------------------------------------- #

# ---------------------------------------------------------- #
# Para dar proceguinto ao codigo, baixar todos os arquivos da 
# Receita Federal do Brasil
# M?s de referencia: 2025-01 (janeiro de 2025)
# https://arquivos.receitafederal.gov.br/dados/cnpj/dados_abertos_cnpj/?C=N;O=D
# Armazenar arquivos em CNPJ_2024 dentro de diretorio "inputs"
# ---------------------------------------------------------- #

# Bibliotecas necessárias
library(utils)
library(tools)

# Definir diretorio com arquivos de CNPJ
cnpj_dir <- "1-inputs/CNPJ_2024"

# Definir subdiret?rios
subdiretorios <- c(
  "1-ESTABELECIMENTOS",
  "2-EMPRESAS",
  "3-SOCIOS",
  "4-DEMAIS_ARQUIVOS"
)

# Criar subdiretorios no diretorio caso nao existam
for (subdir in subdiretorios) {
  caminho <- file.path(cnpj_dir, subdir)
  
  # Verificar se o diretorio existe
  if (!file.exists(caminho)) {
    dir.create(caminho, recursive = TRUE)
    cat("Diretorio criado:", caminho, "\n")
  } else {
    cat("Diretorio ja existe:", caminho, "\n")
  }
}

# Definir diret?rios de destino para extra??o
diretorios_destino <- list(
  "Estabelecimentos" = file.path(cnpj_dir, "1-ESTABELECIMENTOS"),
  "Empresas" = file.path(cnpj_dir, "2-EMPRESAS"),
  "Socios" = file.path(cnpj_dir, "3-SOCIOS"),
  "Demais_Arquivos" = file.path(cnpj_dir, "4-DEMAIS_ARQUIVOS")
)

# Definir funcao para descompactar os arquivos
unzip_arquivos <- function() {
  arquivos_zip <- list.files(cnpj_dir, pattern = "\\.zip$", full.names = TRUE, recursive = TRUE)
  
  for (zip_file_path in arquivos_zip) {
    # Define o diretorio de destino baseado no nome do arquivo zip
    file_name <- basename(zip_file_path)
    if (grepl("^Estabelecimentos", file_name)) {
      destino <- diretorios_destino$Estabelecimentos
    } else if (grepl("^Empresas", file_name)) {
      destino <- diretorios_destino$Empresas
    } else if (grepl("^Socios", file_name)) {
      destino <- diretorios_destino$Socios
    } else {
      destino <- diretorios_destino$Demais_Arquivos
    }
    
    # Cria o diretorio de destino se nao existir
    if (!dir.exists(destino)) {
      dir.create(destino, recursive = TRUE)
    }
    
    # Extracao do conteudo do arquivo .zip
    unzip(zip_file_path, exdir = destino)
    cat("Arquivos de", file_name, "extra?dos para", destino, "\n")
  }
}

# Descompactar e organizar arquivos .zip
unzip_arquivos()
