# Set working directory
my_dir <- "~/github/telmex_speed/data/"
setwd(my_dir)

# Download rates data from Public register from Mexico
urlbase <- "https://rpc.ift.org.mx/vrpc/assets/publish/tarifas_telecom"
file <- "tarifas_fijo_25012021.xlsx"
url <- file.path(urlbase, file)

if (!file.exists(file)){
  print("Starts data download...")
  download.file(url, file)
} else {
  print("Data present in directory, skiping download")
}

print("Bye bye :)")