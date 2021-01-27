library(tidyverse)
library(readr)

# Reading data
df <- read_csv("C:/Users/mxkc1z03/Downloads/tarifas_fijo_11012021.csv", 
    locale = locale(encoding = "ISO-8859-1"),
    col_types = cols(.default = "c"))

# Renaming columns
names(df) <- c("ID_TARIFA",   
  "ID_OPERADOR",
  "CONCESIONARIO",
  "TARIFA",
  "PROMOCION",
  "PAQUETE",
  "NOMBRE_TARIFA",
  "SUSTITUYE_TARIFA",
  "ID_TARIFA_QUE_SUSTITUYE",
  "DENOMINACION",
  "INICIO_VIGENCIA",
  "FIN_VIGENCIA", 
  "FECHA_CANCELACION", 
  "ESTATUS", 
  "PREPAGO", 
  "POSPAGO", 
  "PAQUETE", 
  "DIVERSOS", 
  "PARTICULAR",  
  "EMPRESARIAL",    
  "DESCRIPCION",
  "SERVICIOS", 
  "RECARGA_CON_IMPUESTOS",
  "VIGENCIA_SALDO", 
  "RENTA_MENSUAL_SIN_IMPUESTOS",  
  "RENTA_MENSUAL_CON_IMPUESTO", 
  "COSTO_EQUIPO_TERMINAL",
  "COSTO_PROV_EQUIPO_TERMINAL",
  "DEPOSITO_COSTO",
  "EQUIPO_PERDIDO_COSTO",  
  "INSTALACION_COSTO",
  "CABLEADO_COSTO",
  "CABLEADO_UNIDAD",
  "CAMBIO_DOMICILIO_COSTO",
  "PLAZO_MINIMO_PERMANENCIA",     
  "LINEAS_INCLUIDAS",
  "EQUIPOS_TERMINALES",
  "LINEA_ADICIONAL_COSTO",
  "EQUIPO_TERMINAL_ADIC_COSTO",
  "CONSIDERACIONES", 
  "EQUIPOS_TERMINALES_TV",
  "CANALES_SD",
  "CANALES_HD",
  "CANALES_AUDIO",
  "CANALES_OTROS",      
  "CANALES_TOTAL",
  "VELOCIDAD_MBPS",
  "VELOCIDAD_SUBIDA",
  "VELOCIDAD_BAJADA",
  "VELOCIDAD_MIN_SUBIDA",       
  "VELOCIDAD_MIN_BAJADA",
  "EQUIPO_TERMINAL_CANTIDAD")


# Converting date
df$INICIO_VIGENCIA_C <- lubridate::dmy(df$INICIO_VIGENCIA)
df$FIN_VIGENCIA_C <- lubridate::dmy(df$FIN_VIGENCIA)
df$FECHA_CANCELACION_C <- lubridate::dmy(df$FECHA_CANCELACION)

# Converting some variables and getting a lower version of packages description
df$VELOCIDAD_MBPS <- as.numeric(df$VELOCIDAD_MBPS)
df$DESCRIPCION <- tolower(df$DESCRIPCION)

## ID_OPERADOR CONCESIONARIO
## 100539      TELÉFONOS DEL NOROESTE, S.A. DE C.V.
## 102992      TELÉFONOS DE MÉXICO, S.A.B. DE C.V.


# Filtering Telmex data
df_telmex <- df %>% select(ID_TARIFA, ID_OPERADOR, CONCESIONARIO, 
              TARIFA, NOMBRE_TARIFA, INICIO_VIGENCIA_C, 
              FIN_VIGENCIA_C, FECHA_CANCELACION_C, DESCRIPCION, 
              SUSTITUYE_TARIFA, ID_TARIFA_QUE_SUSTITUYE, 
              VELOCIDAD_MBPS, VELOCIDAD_SUBIDA, VELOCIDAD_BAJADA,
              VELOCIDAD_MIN_SUBIDA, VELOCIDAD_MIN_BAJADA) %>% 
  filter(ID_OPERADOR==102992)


# Extracting Mbps information from description of package
df_telmex$VELOCIDAD_MBPS_EXT <- str_match(df_telmex$DESCRIPCION, 
                                "infinitum de hasta\\s*(.*?)\\s*mbps")[,2]

# 
df_telmex$SPEED <- ifelse(is.na(df_telmex$VELOCIDAD_MBPS), 
                          df_telmex$VELOCIDAD_MBPS_EXT, 
                          df_telmex$VELOCIDAD_MBPS)

df_telmex$SPEED <- as.numeric(df_telmex$SPEED)

df_telmex_speed <- df_telmex %>% select(INICIO_VIGENCIA_C, SPEED) %>%
                  arrange(INICIO_VIGENCIA_C) %>% drop_na() %>% distinct()


df1 <- df_telmex_speed %>% group_by(INICIO_VIGENCIA_C) %>% 
  summarise(min_speed = min(SPEED), max_speed = max(SPEED)) %>% ungroup()

# Dates of begin and and
min_date <- min(df_telmex_speed$INICIO_VIGENCIA_C)
max_date <- max(df_telmex_speed$INICIO_VIGENCIA_C)

df_to_plot <- data.frame(INICIO_VIGENCIA_C = seq(as.Date(min_date), 
                                                 as.Date(max_date), by="days"))

#df_to_plot %>% left_join(df_telmex_speed, by='INICIO_VIGENCIA_C')
# df_telmex %>% select(INICIO_VIGENCIA_C, SPEED) %>% arrange(INICIO_VIGENCIA_C) %>% drop_na() %>% group_by(INICIO_VIGENCIA_C) %>% summarize(min_speed = min(SPEED), max_speed = max (SPEED)) %>% ungroup()
