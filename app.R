library(shiny)
library(jsonlite)
library(RCurl)
library(XML)
library(lubridate)
library(leaflet)
library(DT)
library(magrittr)


# Define the UI
myui =  bootstrapPage(
	tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
	leafletOutput("bikemap", width = "100%", height = "100%"),
	absolutePanel(top = 50, right = 50, width = 300,
		h1(textOutput("title")),
		textOutput("lastupdate")
	)
)

# Define the server function
myserver = function(input, output, session) {

	rawData = reactive({
		invalidateLater(100000, NULL)
		source("pullData.R")
	})

	output$title = renderText({
		"Melbourne BikeShare Map"
	})

	output$lastupdate = renderText({
		rawData()	# when data refreshes
		time = Sys.time()
		attributes(time)$tzone = "Australia/Melbourne"
		paste("Last update was at", time)
	})

	output$bikemap = renderLeaflet({
		data = rawData()$value		# Pull in data
		map = leaflet(data) %>% 	# Generate, return map
			setView(lng = 144.967814 , lat = -37.827523, zoom = 13) %>% 
			addProviderTiles("CartoDB.Positron") %>%
			addCircleMarkers(
				radius = ~(nbBikes + nbEmptyDocks),
				stroke = FALSE,
				fillOpacity = 0.5
             # label = ~name,
             # labelOptions = lapply(1:nrow(data), function(x) {
             #   labelOptions(opacity=0.9, noHide = T)
             # })
             )
		map
	})

}

shinyApp(ui=myui, server=myserver)