library(DT)
library(plotly)
library(shiny)
library(shinyBS)

shinyUI(
  navbarPage('Winston-Salem Police Response',

    tabPanel('Quick Starts',

      fluidRow(
        column(6,
               h2('Quick Starts:'),
               offset = 1)
      ),

      fluidRow(
        column(1, NULL),
        uiOutput('quick_start_ui')
      )
    ),

    tabPanel('Analysis',
      includeCSS('www/app.css'),
      includeScript('www/app.js')
      ,

      fluidRow(
        column(3,

          selectInput(
            inputId = 'date_range_preset',
            label   = 'Date range:',
            choices = c('Previous year',
                        'Previous 6 months',
                        'Previous 30 days',
                        'Previous week',
                        'Yesterday',
                        'Custom'))
          ,
          conditionalPanel(
            condition = 'input.date_range_preset === "Custom"',
            dateRangeInput(
              inputId = 'date_range_custom',
              label   = 'Custom date range:',
              start   = Sys.Date() - 30,
              end     = max(data_all$date),
              min     = min(data_all$date),
              max     = max(data_all$date))
          )

          ,
          selectInput(
            inputId = 'type',
            label   = 'Category (type to search, select one or more):',
            choices = all_types,
            selected = 'DUI',
            multiple = TRUE,
            selectize = TRUE)

          ,
          conditionalPanel(
            condition = "input.tabset_analysis !== 'Map'",
            selectInput(
              inputId = 'aggregation_time',
              label   = 'Aggregate by time:',
              choices = list(
                #'None' = 'none',
                'Day of week' = 'day_of_week',
                'Day of year' = 'day_of_year',
                'Hour of day' = 'hour',
                'Month of year' = 'month',
                'Week of year' = 'week_of_year'
                ),
              selected = 'hour')
            ,
            checkboxInput(
              inputId = 'relative_frequency',
              label   = 'Use relative frequency instead of absolute frequency'),
            checkboxInput(
              inputId = 'cumulative',
              label   = 'Show cumulative counts over time')
          )

          #,
          # conditionalPanel(
          #   condition = "input.tabset_analysis === 'Map'",
          #   h4('Coming soon: Map by time intervals')
          # ),

          # selectInput(
          #   inputId = 'aggregation_location',
          #   label   = 'Aggregate by location:',
          #   choices = c(
          #     'None',
          #     'Census tract',
          #     'Neighborhood',
          #     'ZIP code',
          #     'Ward'))
        )

        ,
        column(9,

          tabsetPanel(
            tabPanel('Data Table',
              data_table_ui <- column(12,
                        DT::dataTableOutput('analysis_data_table'))
            ),
            tabPanel('Graph',
              column(12,
                   plotlyOutput('graph',
                                height = '100%'))
            ),
            tabPanel('Map',
              HTML(sprintf('<script src="https://maps.googleapis.com/maps/api/js?key=%s&libraries=visualization"
    async defer></script>', google_maps_api_key)),
              column(12,
                div(id = 'analysis_map')
              )
            ),
            id   = 'tabset_analysis',
            selected = 'Map',
            type = 'pills'
          )
        )
      )
    ),
    selected = 'Analysis',
    id = 'tabset_main'
  )
)


