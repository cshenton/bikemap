# Live Melbourne BikeShare Availability in R Shiny

This is the `R Shiny` code for a simple web app which displays the availability of BikeShare bikes in the City of Melbourne. A live version of this map can be found on [shinyapps.io](https://cshenton.shinyapps.io/BikeMap/).

## Data

Data is streamed from [Melbourne BikeShare](http://www.melbournebikeshare.com.au/stationmap/data), which maintains a live data stream of bike availability in JSON format. 

## Scripts

`pullData.R` downloads data from source and returns it in a format useable by `R Shiny`.

`app.R` defines the UI and server functions for the application/

## Goal

To build a simple desktop application that visualises a live data stream on a map

## Process

On initial load:

* A `leaflet` map is initialized, centered on Melbourne.
* Data are loaded and formatted, and a map circle is made for each bike station.
* The sidebar is loaded, providing different display options to the user.

There are three display options
1. Station Size: Scales map circles relative to the total capacity of the station
2. Current Capacity: Circle colour shows what proportion of bikes remain at the station (legend in bottom right)
3. Clustered Bike Locations: Uses `leaflet`'s built in clustering to allow users to explore bike locations

Also displayed is a marker showing the user's location. The sidebar informs the user how far away the nearest station is. 

## Notes

This is a simple implementation, and currently does not function properly on mobile devices, though it will display properly on tablets, such as iPads.