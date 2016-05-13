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
		textOutput("lastupdate"),
		selectInput("choice", label = h3("Choose What To Display"), 
        choices = list("Station Size" = 1, "Current Capacity" = 2,
                       "Clustered Bike Locations" = 3), selected = 1)
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
	
	# The base map is not reactive 
	output$bikemap = renderLeaflet({
		leaflet() %>% 	# Generate, return map
			setView(lng = 145.017814 , lat = -37.827523, zoom = 13) %>% 
			addProviderTiles("CartoDB.Positron")
	})

	# An observer is used to make the elements responsive
	observe({
		bikedata = rawData()$value
		if (input$choice==1){
			leafletProxy("bikemap", data=bikedata) %>%
				removeControl("legend") %>%
				clearMarkers() %>%
				addCircleMarkers(
					radius = ~(nbBikes + nbEmptyDocks),
					stroke = FALSE,
					fillOpacity = 0.5,
					popup = ~name,
					color = "blue"
					)
		} else if (input$choice==2){
			pal = colorNumeric(
			  palette = "RdYlGn",
			  domain = c(0,100)
			)
			leafletProxy("bikemap", data=bikedata) %>%
				clearMarkers() %>%
				addCircleMarkers(
					radius = 15,
					stroke = FALSE,
					fillOpacity = 1.0,
					popup = ~name,
					color = ~pal(capacity)
					) %>%
			  	addLegend("bottomright", pal = pal, values = c(0,100),
				    title = "Current Station Capacity",
				    layerId = "legend",
				    labFormat = labelFormat(suffix = "%"),
				    opacity = 1)
		} else {
			bikedata = bikedata[rep(1:nrow(bikedata), times=bikedata$nbBikes),]
			leafletProxy("bikemap", data=bikedata) %>%
				clearMarkers() %>%
				removeControl("legend") %>%
				addCircleMarkers(
					radius = 15,
					stroke = FALSE,
					fillOpacity = 0.5,
					popup = ~name,
					color = "green",
					clusterOptions = markerClusterOptions()
					)
		}
	})

}

shinyApp(ui=myui, server=myserver)