
# Downloads data from Bikeshare site,
# Converts dates to POSIXct format
datevars = c("lastCommWithServer", "installDate", "latestUpdateTime")
source = "http://www.melbournebikeshare.com.au/stationmap/data"
file = getURL(source)
file = gsub("\\", "", file, fixed=TRUE)
data = fromJSON(file)
for(var in datevars){
	data[,var] = as.POSIXct(as.numeric(data[,var])/1e3, 
							tz="Australia/Melbourne", 
							origin="1970-01-01")
}
return(data)
