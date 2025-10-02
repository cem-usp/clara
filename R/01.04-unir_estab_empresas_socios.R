# -------------------------------------------------- #
# Unir bases de estabelecimentos - empresas e socios 
# -------------------------------------------------- #

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


output_dir <- file.path(temporario_dir, "01.04-unir_estab_empresas_socios")

# Criar diretorio de saida caso não exista
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Ler arquivos gerados nas etapas 01.02 e 01.03
estab <- fread(file.path(temporario_dir, "01.02-filtrar_base/01.02.01-estabelecimentos_spcap_farmacias.csv"), sep = ";", encoding = "Latin-1")
empresas <- fread(file.path(temporario_dir, "01.03-filtrar_dados_empresas_socios/01.03.01-empresas_spcap_farmacias.csv"), sep = ";", encoding = "Latin-1")
socios <- fread(file.path(temporario_dir, "01.03-filtrar_dados_empresas_socios/01.03.02-socios_spcap_farmacias.csv"), sep = ";", encoding = "Latin-1")

# Editar dataframe socios
socios <- socios %>%
  filter(!is.na(NOME_SOCIO) & !is.na(CPF_CNPJ_SOCIO)) %>%  
  mutate(across(where(is.character), ~ gsub("\\*", "", .))) %>%  # Remover "*"
  mutate(SOCIO_INFO = paste0(NOME_SOCIO, " - ", CPF_CNPJ_SOCIO)) %>%
  group_by(CNPJ_BASICO) %>%
  mutate(SOCIO_NUM = row_number()) %>%
  ungroup() %>%
  select(CNPJ_BASICO, SOCIO_NUM, SOCIO_INFO) %>%
  pivot_wider(names_from = SOCIO_NUM, values_from = SOCIO_INFO, names_prefix = "SOCIO_", values_fill = list(SOCIO_INFO = "NA"))

# Unir estab, empresas e socios
estab_emp_soc <- estab %>%
  left_join(empresas, by = "CNPJ_BASICO") %>%
  left_join(socios_edit, by = "CNPJ_BASICO")

# Salvar o dataframe resultante
fwrite(estab_emp_soc, file.path(output_dir, "01.04.01-estab_emp_soc_spcap_farmacias.csv"), sep = ";", row.names = FALSE)
