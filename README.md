# wspd-response-dashboard
Shiny app and data download script for Winston-Salem Police Department daily response data

-----

## Prerequisites:

1. R: https://cran.r-project.org/
2. R packages: shiny, DT, httr, lubridate, plotly
3. Download this repository to your computer

## Recommended:

1. RStudio: https://www.rstudio.com/products/rstudio/download/
2. Google Maps API key (required for viewing the map, free for almost all moderate use cases): https://cloud.google.com/maps-platform/

-----

## To launch the app:

First, open ```global.R``` and insert your Google Maps API key between the quotes in line 3. Without an API key, the map feature will not work.

### To launch locally:

In R: ```shiny::runApp('path/to/wspd-respond-dashboard')```

In RStudio:

1. Open at least one of the app files (```server.R```, ```ui.R```, ```global.R```).
2. A button should appear in the top right of the editor pane with a green arrow and the label "Run App" - click this button.

### To launch the app so that others can view it:

http://www.shinyapps.io/

OR 

Host on AWS with Shiny Server: https://www.rstudio.com/products/shiny/download-server/

-----

## To update the data:

Data included in this repository spans January 1, 2017 through May 17, 2018, as of the last update.

To update the data:

1. Open the file ```scripts/download-data.R```.
2. Insert your Google Maps API key between the quotes in line 1.
3. Save the file.

In R: ```source('path/to/wspd-respond-dashboard/scripts/download-data.R')```

In RStudio: There will be a button in the top left of the editor pane that says "Source" - click this button.

-----

Questions, comments, interest in building a similar tool? Contact us anytime: https://modernresearchconsulting.com/contact/
