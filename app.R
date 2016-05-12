library(shiny)
library(jsonlite)
library(RCurl)
library(XML)
library(lubridate)
library(DT)

datevars = c("lastCommWithServer", "installDate", "latestUpdateTime")
source = "http://www.melbournebikeshare.com.au/stationmap/data"

# Define the UI
myui = fluidPage(  
	titlePanel(textOutput("title")),
	sidebarLayout(
		sidebarPanel(
			textOutput("lastupdate")
		),
		mainPanel(
			plotOutput("bikemap")
		) 
	)
)

# Define the server function
myserver = function(input, output, session) {

	rawData = reactive({
		invalidateLater(100000, NULL)
		source("pullData.R")
	})

	output$title = renderText({

	})

	output$lastupdate = renderText({
		rawData()	# when data refreshes
		time = Sys.time()
		attributes(time)$tzone = "Australia/Melbourne"
		paste("Last update was at", time)
	})

	output$bikemap = renderLeaflet({
		# pull in data
		# make map	
		map	
	})

}