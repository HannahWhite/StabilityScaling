##############################
### Process Raw MODIS Data ###
##############################

### Hannah White 
### Adapting previous code from Jon Yearsley

library(rgdal)
library(raster)
library(gdalUtils)

rm(list=ls())

setwd("J:/Postdoc Grassland Resilience")

### Read in CORINE data which has been cropped to Ireland

corine = raster('./HannahData/CORINE_IE.grd')
corine.crs = crs(corine)



inputDir = 'D:/MODIS6/Modis_ver6_18.2.19' ## data downloaded 18.2.19
outputDir = 'D:/MODIS6/MODIS_process_18.2.19'

yearStr = 'A20[0-9][0-9]'  # Some text (or reg experession) that specifies the year of the data (e.g. 'A201[0-5]' specifies years 2010-2015)
#corineInclude = c(18)  # Specify corine codes to include (pasture = 18, natural grasslands=26, moors and heathland=27)
minQuality = 1 # Minimum quality to use: 0 = use only best quality pixels, 1=use reasonable pixels
scalingFactor = 0.0001 # Scale factor to apply to NDVI and EVI data from MODIS










