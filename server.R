library(DT)
library(httr)
library(lubridate)
library(plotly)
library(shiny)

shinyServer(
  function(input, output, session) {

    analysis_date_range <- reactive({
      req(input$date_range_preset)

      message(' -- reactive analysis_date_range')

      date_range_preset <- input$date_range_preset

      if (date_range_preset == 'Custom') {

        input$date_range_custom

      } else {

        if (date_range_preset == 'Previous year') days <- 365
        else if (date_range_preset == 'Previous 6 months') days <- 182
        else if (date_range_preset == 'Previous 30 days') days <- 30
        else if (date_range_preset == 'Previous week') days <- 7
        else if (date_range_preset == 'Yesterday') days <- 1

        c(Sys.Date() - days, Sys.Date() - 1)
      }
    })

    data_filtered <- reactive({
      req(analysis_date_range(),
          input$type)

      message(' -- reactive data_filtered')

      filter_list <- list(
        date = data_all$date >= analysis_date_range()[1] &
               data_all$date <= analysis_date_range()[2],

        category = data_all$type %in% input$type)

      great_filter <- Reduce(`&`, filter_list)

      data_all[great_filter, ]
    })

    date_time <- reactive({
      req(input$aggregation_time != 'none')

      if (input$aggregation_time %in% c('day_of_week', 'day_of_year', 'month', 'week_of_year')) {
        'date'
      } else {
        'time'
      }
    })

    date_time_function <- reactive({
      req(date_time())

      if (date_time() == 'date') as.Date
      else if (date_time() == 'time') as.POSIXct
    })

    analysis_data <- reactive({
      req(data_filtered(),
          input$aggregation_time)

      data <- data_filtered()
      aggregation_time <- input$aggregation_time

      if (aggregation_time == 'none') {

        data

      } else {
        req(date_time(),
            date_time_function())

        # Modify time to suit plotting needs
        data$time_graph <- data$date_time

        if (aggregation_time == 'day_of_week') {

          week(data$time_graph) <- 1
          year(data$time_graph) <- year(Sys.Date())

        } else if (aggregation_time == 'day_of_year') {

          year(data$time_graph) <- year(Sys.Date())

        } else if (aggregation_time == 'hour') {

          hour_original <- hour(data$time_graph)

          hour(data$time_graph)   <- 12
          month(data$time_graph)  <- 1
          day(data$time_graph)    <- 1
          minute(data$time_graph) <- 10
          second(data$time_graph) <- 10
          year(data$time_graph)   <- 2018

          hour(data$time_graph)   <- hour_original

        } else if (aggregation_time == 'month') {

          year(data$time_graph) <- year(Sys.Date())
          day(data$time_graph)  <- 1

        } else if (aggregation_time == 'week_of_year') {

          year(data$time_graph) <- year(Sys.Date())
          wday(data$time_graph) <- 1
        }

        data$time_graph <- date_time_function()(data$time_graph)
        data$time_graph <- as.character(data$time_graph)

        data <- aggregate(
          x = setNames(data['type'], 'count'),
          by = data[c('time_graph', 'type')],
          FUN = function(x) sum(!is.na(x)))

        data$time_graph <- date_time_function()(data$time_graph)

        # Construct relative frequency
        data$relative_frequency <- ave(
          data$count,
          by = data['type'],
          FUN = function(x) x / sum(x))

        # Construct cumulative count
        time_order <- order(data$time_graph)
        data <- data[time_order, ]

        data$cumulative_count <- ave(
          data$count,
          data['type'],
          FUN = cumsum)

        # Construct cumulative relative frequency
        data$cumulative_relative_frequency <- ave(
          data$relative_frequency,
          data['type'],
          FUN = cumsum)

        round_vars <- c('relative_frequency', 'cumulative_relative_frequency')
        data[round_vars] <- lapply(
          data[round_vars],
          FUN = round,
          digits = 2)

        data
      }
  })

  table_time_format <- reactive({
    req(input$aggregation_time != 'none')

    c(day_of_week = '%A',
      day_of_year = '%m-%d',
      hour        = '%I %p',
      month       = '%m',
      week_of_year = '%V')[input$aggregation_time]
  })

  output$analysis_data_table <- DT::renderDataTable({
    req(analysis_data(),
        input$aggregation_time)

    data <- analysis_data()
    aggregation_time <- input$aggregation_time

    message(' -- renderDataTable analysis_data_table')

    if (aggregation_time == 'none') {
      column_order <- c('report', 'date', 'time_text', 'type', 'address')
      data <- data[column_order]
    } else {
      req(table_time_format())

      data[[aggregation_time]] <- strftime(data$time_graph,
                                          format = table_time_format())

      data <- data[c(aggregation_time,
                     setdiff(colnames(data), c(aggregation_time, 'time_graph')))]
    }

    datatable(
      data,
      options = list(
        paging = FALSE),
      rownames = FALSE)
  })

  graph_metric <- reactive({
    req(!is.null(input$cumulative),
        !is.null(input$relative_frequency))

    message(' -- reactive graph_metric')

    if (input$cumulative) y_prefix <- 'cumulative_'
    else y_prefix <- NULL

    if (input$relative_frequency) y_suffix <- 'relative_frequency'
    else y_suffix <- 'count'

    paste0(y_prefix, y_suffix)
  })

  graph_time_label_format <- reactive({
    req(input$aggregation_time != 'none')

    c(day_of_week = '%A',
      day_of_year = '%B',
      hour        = '%I %p',
      month       = '%B',
      week_of_year = '%B')[input$aggregation_time]
  })

  graph_time_breaks <- reactive({
    req(input$aggregation_time != 'none')

    c(day_of_week = '1 day',
      day_of_year = '2 months',
      hour        = '2 hours',
      month       = '2 months',
      week_of_year = '2 months')[input$aggregation_time]
  })

  graph_y_axis_title <- reactive({
    req(graph_metric())

    gsub('_', ' ', graph_metric())
  })

  output$graph <- renderPlotly({
    req(input$tabset_analysis == 'Graph',
        analysis_data(),
        graph_metric(),
        graph_y_axis_title(),
        graph_time_label_format(),
        graph_time_breaks(),
        date_time())

    message(' -- observe graphs')

    data <- analysis_data()

    if (date_time() == 'date') scale_x_function <- scale_x_date
    else if (date_time() == 'time') scale_x_function <- scale_x_datetime

    p <- ggplot(
      mapping = aes_string(
        x = 'time_graph',
        y = graph_metric(),
        group = 'type',
        color = 'type'),
      data = data) +
    geom_line() +
    geom_point(
      size = 2) +
    scale_x_function(
      limits = range(data$time_graph),
      date_breaks = graph_time_breaks(),
      date_labels = graph_time_label_format()) +
    scale_y_continuous(
      limits = c(0, max(data[[graph_metric()]]))) +
    theme_bw() +
    theme(
      axis.text.x = element_text(size = 14),
      legend.title = element_blank()) +
    labs(
      x = NULL,
      y = graph_y_axis_title())

    if (names(dev.cur()) != "null device") dev.off()
    pdf(NULL)

    ggplotly(p,
             tooltip = c('y', 'group'),
             height = 600) %>%
      plotly::layout(
        legend = list(
          orientation = 'v'))
  })

  ## Map

  state <- reactiveValues(
    alert_map_initialized = FALSE,
    analysis_map_initialized = FALSE,
    alert_map_center = map_center_default)

  observe({
    req(input$tabset_main == 'Analysis',
        input$tabset_analysis == 'Map',
        !state$analysis_map_initialized)

    message(' -- initializing analysis map')

    session$sendCustomMessage('initialize_map',
                              message = list(
                                div = 'analysis_map'))

    state$analysis_map_initialized <- TRUE
  })

  observe({
    req(input$tabset_main == 'Analysis',
        input$tabset_analysis == 'Map',
        state$analysis_map_initialized,
        data_filtered())

    message(' -- updating map')

    data <- data_filtered()

    if (nrow(data) == 0) {

      session$sendCustomMessage('clear_heatmap',
                                message = '')

    } else {

      data <- aggregate(
        x = setNames(data['address'], 'count'),
        by = data['address'],
        FUN = length)

      data <- merge(
        data,
        addresses_geocoded,
        all.x = TRUE)

      # Remove records that couldn't be geocoded
      geocoded <- !is.na(data$latitude) & !is.na(data$longitude)

      data <- data[geocoded, ]

      session$sendCustomMessage('clear_heatmap',
                                message = '')

      session$sendCustomMessage('draw_heatmap',
                                message = list(
                                  latitude = data$latitude,
                                  longitude = data$longitude,
                                  weight = data$count))
    }
  })

  ## Quick starts

  quick_starts_sample <- reactive({
    sample(quick_starts_all,
           size = 3,
           replace = FALSE)
  })

  output$quick_start_ui <- renderUI({
    req(quick_starts_sample())

    lapply(seq_along(quick_starts_sample()),
             FUN = function(
               quick_start_i,
               quick_starts)
             {
               qs <- quick_starts[[quick_start_i]]
               column(3,
                      div(class = 'quick-start-column',
                        tags$div(
                          class = 'quick-start-question',
                          h4(qs$question),
                          icon(qs$icon,
                               class = 'fa-2x')),
                        p(),
                        actionButton(
                          inputId = sprintf('quick_start_%d',
                                            quick_start_i),
                          label = qs$button,
                          class = 'btn-primary')
                      )
               )
             },
             quick_starts = quick_starts_sample())
  })

  observeEvent(input$quick_start_1, {
    quick_start(session = session,
                quick_starts = quick_starts_sample(),
                index = 1)
  })

  observeEvent(input$quick_start_2, {
    quick_start(session = session,
                quick_starts = quick_starts_sample(),
                index = 2)
  })

  observeEvent(input$quick_start_3, {
    quick_start(session = session,
                quick_starts = quick_starts_sample(),
                index = 3)
  })

  observeEvent(input$quick_start_4, {
    quick_start(session = session,
                quick_starts = quick_starts,
                index = 4)
  })

})
