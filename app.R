library(shiny)
library(jsonlite)
library(RCurl)
library(XML)
library(lubridate)
library(leaflet)
library(DT)


# Define the UI
myui = fluidPage(  
	titlePanel(textOutput("title")),
	sidebarLayout(
		sidebarPanel(
			textOutput("lastupdate")
		),
		mainPanel(
			leafletOutput("bikemap")
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
		map <- leaflet() %>% setView(lng = 144.972762 , lat = -37.809072, zoom = 13)
		map %>% addTiles()
		map %>% addProviderTiles("CartoDB.Positron")
	})

}

shinyApp(ui=myui, server=myserver)