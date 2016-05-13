library(shiny)
library(jsonlite)
library(RCurl)
library(XML)
library(lubridate)
library(leaflet)
library(DT)
library(sp)
library(magrittr)
library(htmltools)

# Define the UI
myui =  bootstrapPage(
	# This script pulls the user's geolocation
	tags$script('
	$(document).ready(function () {
	navigator.geolocation.getCurrentPosition(onSuccess, onError);

	function onError (err) {
	Shiny.onInputChange("geolocation", false);
	}

	function onSuccess (position) {
		setTimeout(function () {
	    	var coords = position.coords;
			console.log(coords.latitude + ", " + coords.longitude);
			Shiny.onInputChange("geolocation", true);
			Shiny.onInputChange("lat", coords.latitude);
			Shiny.onInputChange("long", coords.longitude);
	  }, 1100)
	}
	});
	'),
	tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
	leafletOutput("bikemap", width = "100%", height = "100%"),
	conditionalPanel(condition = "input.hide == false",
		absolutePanel(top = 50, right = 50, width = 300,
			h1(textOutput("title")),
			h3("This is a map of all the BikeShare stations in Melbourne.
				Select each option to view different information."),
			textOutput("closest"),
			textOutput("lastupdate"),
			radioButtons("choice", label = h3("Choose What To Display"), 
	        choices = list("Station Size" = 1, "Current Capacity" = 2,
	                       "Clustered Bike Locations" = 3), selected = 2)
		)),
	absolutePanel(top = 5, left = 50, width = 200,
		checkboxInput("hide", label = h4("Hide Information"), FALSE)
		)
)

# Define the server function
myserver = function(input, output, session) {

	rawData = reactive({
		invalidateLater(1000000, NULL)
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
	# Determine the 'as bird flies' closest Bike Rack 
	output$closest = renderText({
		if(!is.null(input$lat)) {
			bikedata = isolate(rawData()$value)
			user = c(input$long, input$lat)
			points = as.matrix(bikedata[,c("long","lat")])
			dists = spDistsN1(points, user, longlat = TRUE)
			stat = data[which(dists == min(dists), arr.ind = TRUE) ,"name"]
			paste("Your nearest BikeShare station is", stat)
		}
	})

	# Locate the user on the map and add a marker.
	observe({
		if(!is.null(input$lat)) {
			lat = input$lat
			long = input$long
			leafletProxy("bikemap") %>%
			addMarkers(long, lat, popup = htmlEscape("You Are Here"))
		}
	})

	# An observer is used to make the elements refresh with data
	observe({
		bikedata = rawData()$value
		bikefull = bikedata[rep(1:nrow(bikedata), times=bikedata$nbBikes),]
		pal = colorNumeric(
			  palette = "RdYlGn",
			  domain = c(0,100)
			)
		# Add all points to map on data load
		leafletProxy("bikemap", data=bikedata) %>%
			addCircleMarkers(
					radius = ~(nbBikes + nbEmptyDocks),
					stroke = FALSE,
					fillOpacity = 0.5,
					popup = ~name,
					color = "blue",
					group = "capacity"
					) %>%
			addCircleMarkers(
					radius = 15,
					stroke = FALSE,
					fillOpacity = 1.0,
					popup = ~name,
					color = ~pal(capacity),
					group = "remaining"
					) %>%
		  	addLegend("bottomright", pal = pal, values = c(0,100),
			    title = "Percentage of Bikes Remaining",
			    layerId = "legend",
			    labFormat = labelFormat(suffix = "%"),
			    opacity = 1) %>%
			addCircleMarkers(data=bikefull,
				radius = 15,
				stroke = FALSE,
				fillOpacity = 0.5,
				popup = ~name,
				color = "green",
				clusterOptions = markerClusterOptions(),
				group = "bikeloc"
				) %>% 
			hideGroup("bikeloc") %>% 
			hideGroup("capacity") 
	})

	# A second observer hides, shows the marker layers based on input
	observe({
		pal = colorNumeric(
			  palette = "RdYlGn",
			  domain = c(0,100)
			)
		if(input$choice==1) {
			leafletProxy("bikemap") %>% 
			removeControl("legend") %>%
			hideGroup("bikeloc") %>% 
			hideGroup("remaining") %>% 
			showGroup("capacity") 
		} else if(input$choice==2) {
			leafletProxy("bikemap") %>% 
			hideGroup("bikeloc") %>% 
			hideGroup("capacity") %>% 
			showGroup("remaining") %>%
			addLegend("bottomright", pal = pal, values = c(0,100),
			    title = "Percentage of Bikes Remaining",
			    layerId = "legend",
			    labFormat = labelFormat(suffix = "%"),
			    opacity = 1) 
		} else if(input$choice==3) {
			leafletProxy("bikemap") %>% 
			removeControl("legend") %>%
			hideGroup("remaining") %>% 
			hideGroup("capacity") %>% 
			showGroup("bikeloc") 
		}
	})
}

shinyApp(ui=myui, server=myserver)