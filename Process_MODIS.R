##############################
### Process Raw MODIS Data ###
##############################

### Hannah White 
### Adapting previous code from Jon Yearsley
### This code processes MODIS data for the whole of Ireland (without taking into account land cover class)

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



# Load MODIS data

regexp = paste(yearStr,'[[:graph:]]+.hdf$',sep='')
hdf.files = list.files(path=inputDir,pattern=regexp,recursive=TRUE)

nFiles = length(hdf.files) # Calculate number of files to import

# Extract dates fromt he filenames
tmp=strsplit(hdf.files,'/')
ind = grep('[[:digit:]]{4}[.][[:digit:]]{2}[.][[:digit:]]{2}',tmp[[1]])
dates = sapply(tmp, FUN=function(x){x[ind]}, simplify=TRUE)
#dates = list.files(path=inputDir)
r.date = strptime(dates, format = "%Y.%m.%d", tz = "UTC")

# Reorder files into date order (earliest first)
ordInd = order(r.date)
hdf.files = hdf.files[ordInd]
r.date = r.date[ordInd]


satellite<-array(sapply(tmp,'[',1),dim=length(hdf.files)) 

# Define extent of Ireland (roughly) in MODIS CRS
ir = extent(-7.5E5, -3.3E5,5.7E6, 6.17E6)


# Read in Ireland coastline

ie = readOGR(dsn='HannahData', layer='country')
ie.grid = spTransform(ie, CRS=CRS("+init=epsg:29903"))   # Transform to Irish Grid TM75

# Define bounding box of irish coastline (rounded to the nearest hectad)
ie.coords = bbox(ie.grid)/10^4
padding = 1
bb = c(1,1,1,1)
bb[c(1,3)] = (floor(ie.coords[,1])-padding)*10^4
bb[c(2,4)] = (ceiling(ie.coords[,2])+padding)*10^4

# Create a raster in Irish grid with cells that are exactly 250mx250m
ie.raster = raster(ncol=(bb[2]-bb[1])/250, nrow=(bb[4]-bb[3])/250, extent(bb), crs=CRS("+init=epsg:29903"))


for (f in 1:length(hdf.files)) {
  # Read in the MODIS data and crop to Ireland 
  sds <- get_subdatasets(paste(inputDir,hdf.files[f],sep='/'))
  
  # code to read in hdf files in windows 
  
  filename <- rasterTmpFile()
  extension(filename) <- 'tif'
  gdal_translate(sds[grep("250m 16 days NDVI", sds)], dst_dataset = filename)
  # Load and crop the Geotiff created into R
  ndvi <- crop(raster(filename, as.is = TRUE), ir)*scalingFactor^2
  
  filename2 <- rasterTmpFile()
  extension(filename2) <- 'tif'
  gdal_translate(sds[grep("250m 16 days EVI", sds)], dst_dataset = filename2)
  evi <- crop(raster(filename2, as.is = TRUE), ir)*scalingFactor^2
  
  filename3 <- rasterTmpFile()
  extension(filename3) <- 'tif'
  gdal_translate(sds[grep("16 days pixel reliability", sds)], dst_dataset = filename3)
  QC <- crop(raster(filename3), ir) # quality control raster
  
  
 
  
  # Keep only good quality data (reliability=0 or 1) and reproject onto Irish grid
  ndvi[QC<0 | QC>1] <- NA 
  evi[QC<0 | QC>1] <- NA
  
  
    # Project to ie raster and resample
  evi_tmp = projectRaster(evi, crs=CRS("+init=epsg:29903"))   # Transform to Irish Grid TM75
  # Sync evi.grid with the ie.raster (i.e. rounded to nearest hectad)
  evi_grid = raster::resample(evi_tmp, ie.raster, method='bilinear')
  
  ndvi_tmp = projectRaster(ndvi, crs=CRS("+init=epsg:29903"))
  ndvi_grid = raster::resample(ndvi_tmp, ie.raster, method='bilinear')
  
  QC_tmp = projectRaster(QC, crs=CRS("+init=epsg:29903"))
  QC_grid = raster::resample(QC_tmp, ie.raster, method='bilinear')
  
  
  
  fname.ndvi = paste(outputDir,'/NDVI_',format(r.date[f],"%Y_%m_%d"),sep='') 
  fname.evi = paste(outputDir,'/EVI_',format(r.date[f],"%Y_%m_%d"),sep='') 
  fname.qc = paste(outputDir,'/QC_',format(r.date[f],"%Y_%m_%d"),sep='')
  writeRaster(ndvi_grid, file=fname.ndvi, format='raster', overwrite = TRUE)
  writeRaster(evi_grid, file=fname.evi, format='raster', overwrite = TRUE)
  writeRaster(QC_grid, file=fname.qc, format='raster', overwrite = TRUE)
}



