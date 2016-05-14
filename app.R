# Author: Charles Shenton
# Created: 2016 May 12
#
# Last Edited by: Charles Shenton
# Last Edited: 2016 May 14
#
# Shiny app that visualises live Melbourne BikeShare information

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
myui =  bootstrapPage(theme="styles.css",
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
  	# Add Map
	leafletOutput("bikemap", width = "100%", height = "100%"),
	# Add Floating sidebar
	conditionalPanel(condition = "input.hide == false",
		absolutePanel( id = "info",
			top = 50, right = 50, width = 350, 
			h1("Melbourne BikeShare Map"),
			textOutput("lastupdate"),
			h3(textOutput("infotext")),
			textOutput("closest"),
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

	# Pull data from server
	rawData = reactive({
		invalidateLater(1000000, NULL)
		source("pullData.R")
	})
	# Text describing data
	output$infotext = renderText({
		if(input$choice==1) {
			"Each circle represents the relative 
				size (# of docks) of each station. Click 
				on a station to see its name."
		} else if(input$choice==2) {
			"The colour of each circle shows what proportion of
				bikes are still available at that station right now.
				Click on a station to see its name."
		} else if(input$choice==3) {
			"The number on each cluster shows the total number of bikes 
				currently available in that region. Click one to
				see more detail."
	}
	})
	# Determines most recent read attempt
	output$lastupdate = renderText({
		rawData()	# when data refreshes
		time = Sys.time()
		attributes(time)$tzone = "Australia/Melbourne"
		paste("Last update was at", time)
	})
	# Determine the 'as bird flies' closest Bike Rack 
	output$closest = renderText({
		if(!is.null(input$lat)) {
			bikedata = isolate(rawData()$value)
			user = c(input$long, input$lat)
			points = as.matrix(bikedata[,c("long","lat")])
			dists = spDistsN1(points, user, longlat = TRUE)
			d = round(min(dists))
			stat = data[which(dists == min(dists), arr.ind = TRUE) ,"name"]
			joke = ""
			if(d > 100){
				joke = " You don't seem to be within walking distance of a
					BikeShare station. Perhaps you should consider 
					alternative transport."
			}
			paste(sep="","Your nearest BikeShare station is ",
				stat, ". It is ", d, "km away.",joke)
		}
	})
	# Initialise base map
	output$bikemap = renderLeaflet({
		leaflet() %>% 	# Generate, return map
			fitBounds(144.904247, -37.770056,
						145.039690, -37.885019) %>%
			addProviderTiles("CartoDB.Positron")
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
	# Load all data onto map, hide unselected data
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
				popup = ~paste(name,"<br/> <b>Last Update:</b>",
					lastCommWithServer),
				color = "blue",
				group = "capacity"
				) %>%
			addCircleMarkers(
				radius = 15,
				stroke = FALSE,
				fillOpacity = 1.0,
				popup = ~paste(name,"<br/> <b>Last Update:</b>",
					lastCommWithServer),
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
				popup = ~paste(name,"<br/> <b>Last Update:</b>",
					lastCommWithServer),
				color = "green",
				clusterOptions = markerClusterOptions(),
				group = "bikeloc"
				) %>% 
			hideGroup("bikeloc") %>% 
			hideGroup("capacity") 
	})
	# Hide/Show layers based on user input
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
# Return app object
shinyApp(ui=myui, server=myserver)