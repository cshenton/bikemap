# Author: Charles Shenton
# Created: 2016 May 6
#
# Last Edited by: Charles Shenton
# Last Edited: 2016 May 13
#
# Downloads and formats data from Melbourne Bikeshare site

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
data$nbBikes = as.numeric(data$nbBikes)
data$nbEmptyDocks = as.numeric(data$nbEmptyDocks)
data$terminalName = as.numeric(data$terminalName)
data$long = as.numeric(data$long)
data$lat = as.numeric(data$lat)
data$capacity = data$nbBikes/(data$nbBikes+data$nbEmptyDocks)*100
return(data)
