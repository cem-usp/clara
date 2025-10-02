# -------------------- #
# Geocodificar endereços 
# -------------------- #

# Carregar pacotes necessarios
library(geocodebr)
library(readr)
library(dplyr)
library(sf)
library(purrr)


# Definir caminhos dos diretorios
estabelecimentos_dir <- "1-inputs/CNPJ_2024/1-ESTABELECIMENTOS"
empresas_dir <- "1-inputs/CNPJ_2024/2-EMPRESAS"
socios_dir <- "1-inputs/CNPJ_2024/3-SOCIOS"
demais_arquivos_dir <- "1-inputs/CNPJ_2024/4-DEMAIS_ARQUIVOS"
temporario_dir <- "2-temp"


output_dir <- file.path(temporario_dir, "01.06-geocodificar_enderecos")

# Criar diretorio de saida caso não exista
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Ler 01.05.03 arquivo gerado na etapa 01.05
estab_emp_soc <- read.csv(file.path(temporario_dir, "01.05-adicionar_informacoes_porte_traduzir_base/01.05.03-estab_emp_soc_trad_spcap_farmacias.csv"), 
                       sep = ",", encoding = "Latin-1")

# ---------------------------- #
# Tratar dados para geocodificar
# ---------------------------- #
# Adicionar 0s nos CEPs com menos de 8 d?gitos
estab_emp_soc$CEP <- sprintf("%08d", as.numeric(trimws(estab_emp_soc$CEP)))

# Criar uma nova coluna 'ENDERECO' unindo 'TIPO_LOGRADOURO' e 'LOGRADOURO'
estab_emp_soc$ENDERECO <- paste(estab_emp_soc$TIPO_LOGRADOURO, 
                                estab_emp_soc$LOGRADOURO)

# Transformar em inteiro a coluna de N?mero do endere?o
estab_emp_soc$NUMERO <- suppressWarnings(as.integer(estab_emp_soc$NUMERO))

# -------------------- #
# Geocodificar endereços
# -------------------- #
# Definir os campos para geocodifica?ao
campos <- geocodebr::definir_campos(
  estado = "UF",
  municipio = "MUNICIPIO",
  logradouro = "ENDERECO",
  numero = "NUMERO",
  cep = "CEP",
  localidade = "BAIRRO"
)

# Geocodificar com pacote 'geocodebr'
estab_emp_soc_geoloc <- geocodebr::geocode(
  enderecos = estab_emp_soc,
  campos_endereco = campos,
  resultado_completo = TRUE,
  resultado_sf = FALSE,
  verboso = TRUE,
  cache = TRUE,
  n_cores = 1
)

# Transformar o data frame de empresas em um objeto 'sf' com coordenadas
estab_emp_soc_geom <- st_as_sf(estab_emp_soc_geoloc, 
                        coords = c("lon", "lat"), 
                        crs = 4326)

# Baixar arquivos shapefile ddos distritos de Sao Paulo na aba "Layers" 
# http://dados.prefeitura.sp.gov.br/dataset/distritos

# Defnir caminho do arquivo de distritos
distritos_sp_arquivo <- '1-INPUTS/LAYER_DISTRITO/DEINFO_DISTRITO.shp'

# Abrir o arquivo .shp de distritos em Sao Paulo
distritos_sp <- st_read(distritos_sp_arquivo) %>%
  st_transform(crs = st_crs(estab_emp_soc_geom)) # Transformar o shapefile de distritos para o CRS adequado

# Transformar COD_DIST em num?rica
distritos_sp$COD_DIST <- as.numeric(distritos_sp$COD_DIST)

# Realizar a interse?ao
intersecao <- st_intersects(estab_emp_soc_geom, distritos_sp)

# Adicionar os dados de distrito
estab_emp_soc_geom <- estab_emp_soc_geom %>%
  mutate(
    # Adicionar o nome do distrito ou "NSA" caso nao haja interse?ao
    DISTRITO_SP = map_chr(1:nrow(estab_emp_soc_geom), ~{
      # Obter o munic?pio para a linha atual
      municipio <- estab_emp_soc_geom$MUNICIPIO[.x] # Substitua pelo nome correto da coluna do munic?pio
      
      if (municipio == "Sao Paulo") {
        # Se for Sao Paulo, for?ar a interse?ao com algum distrito
        distrito <- ifelse(length(intersecao[[.x]]) > 0, distritos_sp$NOME_DIST[intersecao[[.x]][1]], "NSA")
        distrito
      } else {
        # Caso contr?rio, usar a l?gica normal de interse?ao
        if (length(intersecao[[.x]]) > 0) {
          distritos_sp$NOME_DIST[intersecao[[.x]][1]]
        } else {
          "NSA"
        }
      }
    }),
    
    # Adicionar o c?digo do distrito ou "NSA"
    DISTRITO_SP_IBGE = map_chr(1:nrow(estab_emp_soc_geom), ~{
      municipio <- estab_emp_soc_geom$MUNICIPIO[.x] # Substitua pelo nome correto da coluna do munic?pio
      
      if (municipio == "Sao Paulo") {
        # Se for Sao Paulo, for?ar a interse?ao com algum distrito
        distrito_ibge <- ifelse(length(intersecao[[.x]]) > 0, as.character(distritos_sp$COD_DIST[intersecao[[.x]][1]]), "NSA")
        distrito_ibge
      } else {
        # Caso contr?rio, usar a l?gica normal de interse?ao
        if (length(intersecao[[.x]]) > 0) {
          as.character(distritos_sp$COD_DIST[intersecao[[.x]][1]])
        } else {
          "NSA"
        }
      }
    })
  )

# Transformar a geometry em latitude e longitude
estab_emp_soc_geom <- estab_emp_soc_geom %>%
  mutate(lat = st_coordinates(.)[,2],
         lon = st_coordinates(.)[,1])

# Escrever o arquivo a partir do dataframe gerado
write_csv(estab_emp_soc_geom, file.path(temporario_dir, "01.06-geocodificar_enderecos/01.06.01-estab_emp_soc_spcap_farmacias_loc.csv"))

