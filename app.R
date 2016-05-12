library(shiny)
library(DT)

# Define the UI
myui = fluidPage(  
	titlePanel(textOutput("title")),
	sidebarLayout(
		sidebarPanel(
			textOutput("lastupdate")
		),
		mainPanel(
			plotOutput("map")
		) 
	)
)

myserver <- function(input, output, session) {

	dataRaw = reactive({
		invalidateLater(100000, NULL)
		source("pullData.R")
	})

	output$title = renderText({

	})

	output$lastupdate = renderText({
		
	})

	output$map = renderPlot({
		
	})

}