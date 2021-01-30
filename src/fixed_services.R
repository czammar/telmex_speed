list.of.packages <- c("tidyverse", "readr", "readxl", "dplyr","")
new.packages <- list.of.packages[!(list.of.packages %in% 
                                     installed.packages()[,"Package"])]

if(length(new.packages)) install.packages(new.packages)

library(tidyverse)
library(readr)
library("readxl")

my_dir <- "~/github/telmex_speed/data"
file <- "tarifas_fijo_25012021.xlsx"
data_location <- file.path(my_dir, file)

# Reading data
df<- read_excel(data_location)

# df <- read_csv(data_location, 
#     locale = locale(encoding = "ISO-8859-1"),
#     col_types = cols(.default = "c"))

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
df$CONCESIONARIO <- tolower(df$CONCESIONARIO)
df$NOMBRE_TARIFA <- tolower(df$NOMBRE_TARIFA)

## ID_OPERADOR CONCESIONARIO
## 100539      TELEFONOS DEL NOROESTE, S.A. DE C.V. (Telnor)
## 102992      TELEFONOS DE MEXICO, S.A.B. DE C.V. (Telmex)

# Filtering Telmex and Telnor data
df_AEP <- df %>% select(ID_TARIFA, ID_OPERADOR, CONCESIONARIO, 
              TARIFA, NOMBRE_TARIFA, INICIO_VIGENCIA_C, 
              FIN_VIGENCIA_C, FECHA_CANCELACION_C, DESCRIPCION, 
              SUSTITUYE_TARIFA, ID_TARIFA_QUE_SUSTITUYE, 
              VELOCIDAD_MBPS, VELOCIDAD_SUBIDA, VELOCIDAD_BAJADA,
              VELOCIDAD_MIN_SUBIDA, VELOCIDAD_MIN_BAJADA) %>% 
  filter(ID_OPERADOR==100539|ID_OPERADOR==102992)

# Unfortunately, no all speed of package is in column VELOCIDAD_MBPS,
# so, we examine description columns to find it.
# Note: For mysterious reason, I found IFT database include packages with 
# reported speed of 1 Mbps but that description says other stuff

## Extracting Mbps information from description of package
df_AEP$VELOCIDAD_MBPS_EXT <- str_match(df_AEP$DESCRIPCION, 
                               "infinitum de hasta\\s*(.*?)\\s*mbps")[,2]

df_AEP$VELOCIDAD_MBPS_EXT1 <- str_match(df_AEP$DESCRIPCION, 
                                        "infinitum hasta\\s*(.*?)\\s*mbps")[,2]

df_AEP$VELOCIDAD_MBPS_EXT2 <- str_match(df_AEP$DESCRIPCION, 
          "hasta\\s*(.*?)\\s*megabits")[,2]

df_AEP$VELOCIDAD_MBPS_EXT3 <- str_match(df_AEP$DESCRIPCION, 
                                  "velocidad de hasta\\s*(.*?)\\s*mbps que")[,2]


df_AEP$VELOCIDAD_MBPS_EXT <- as.numeric(df_AEP$VELOCIDAD_MBPS_EXT)
df_AEP$VELOCIDAD_MBPS_EXT1 <- as.numeric(df_AEP$VELOCIDAD_MBPS_EXT1)
df_AEP$VELOCIDAD_MBPS_EXT2<- as.numeric(df_AEP$VELOCIDAD_MBPS_EXT2)
df_AEP$VELOCIDAD_MBPS_EXT3 <- as.numeric(df_AEP$VELOCIDAD_MBPS_EXT3)

# We assign registered speed, and extract this info was absent
# In case of registers with 1 Mbps reported, extracted info from description
# was preferred instead

df_AEP <- df_AEP %>% mutate(SPEED1 = pmax(VELOCIDAD_MBPS, 
                                          VELOCIDAD_MBPS_EXT,
                                          VELOCIDAD_MBPS_EXT1,
                                          VELOCIDAD_MBPS_EXT2,
                                          VELOCIDAD_MBPS_EXT3,
                                          na.rm = TRUE))

df_AEP$SPEED<-ifelse(df_AEP$SPEED1==1, NA, df_AEP$SPEED1)

df_AEP <- df_AEP %>% select(NOMBRE_TARIFA, 
                            INICIO_VIGENCIA_C, 
                            FIN_VIGENCIA_C, 
                            FECHA_CANCELACION_C,
                            SPEED)

# Calculates availabity of packages according to date info
# Dates of begin and and
min_date <- as.Date(min(df_AEP$INICIO_VIGENCIA_C))
max_date <- as.Date(max(df_AEP$INICIO_VIGENCIA_C))

# 
# Create columns of date of introduction of a package
df_AEP$DATE_BEGIN <- df_AEP$INICIO_VIGENCIA_C

df_AEP$DATE_END <- ifelse(!is.na(df_AEP$FECHA_CANCELACION_C), 
                          df_AEP$FECHA_CANCELACION_C, 
                          ifelse(!is.na(df_AEP$FIN_VIGENCIA_C),
                                 df_AEP$FIN_VIGENCIA_C,
                                 max_date) )

df_AEP$DATE_END <- lubridate::as_date(df_AEP$DATE_END)

df_AEP <- df_AEP %>% select(NOMBRE_TARIFA,DATE_BEGIN,DATE_END, SPEED ) %>%
  drop_na()

# Adds an indentifier of packages acording to registration events
df_AEP<- df_AEP %>% mutate(package= paste0(rep("package",nrow(df_AEP)), 
                                             1:nrow(df_AEP)))

# Construct a long table of previous table
df_AEP_transform <- df_AEP %>% 
  mutate(days = map2(DATE_BEGIN,DATE_END, `:`)) %>% 
  select(-c(DATE_BEGIN,DATE_END, NOMBRE_TARIFA)) %>% unnest()

df_AEP_transform$days<- lubridate::as_date(df_AEP_transform$days)

#
df_dynamics <-df_AEP_transform %>% group_by(days) %>% 
  summarize(min_speed = min(SPEED), max_speed = max (SPEED)) %>% ungroup()


#df_to_plot %>% left_join(df_telmex_speed, by='INICIO_VIGENCIA_C')
# df_telmex %>% select(INICIO_VIGENCIA_C, SPEED) %>% arrange(INICIO_VIGENCIA_C) %>% drop_na() %>% group_by(INICIO_VIGENCIA_C) %>% summarize(min_speed = min(SPEED), max_speed = max (SPEED)) %>% ungroup()
