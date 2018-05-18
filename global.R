library(DT)

google_maps_api_key <- ''

data_all <- readRDS('data/data_all.rds')
addresses_geocoded <- readRDS('data/addresses_geocoded.rds')

all_types <- sort(unique(data_all$type))

map_center_default <- list(
  lat = 36.094637,
  lng = -80.244023
)

quick_starts_all <- list(
  list(
    question = 'Where did motor vehicle thefts occur in the past 6 months?',
    date_range = 'Previous 6 months',
    tab = 'Map',
    type = 'MV THEFT',
    icon = 'car',
    button = 'View map >>'),
  list(
    question = 'Where did home break-ins occur in the past month?',
    date_range = 'Previous 30 days',
    tab = 'Map',
    type = 'B&E RESIDENCE',
    icon = 'home',
    button = 'View map >>'),
  list(
    question = 'What day of the week do DUIs occur?',
    date_range = 'Previous year',
    tab = 'Graph',
    type = 'DUI',
    icon = 'car',
    aggregation_time = 'day_of_week',
    button = 'View graph >>'),
  list(
    question = 'What time of day do DUIs occur?',
    date_range = 'Previous year',
    tab = 'Graph',
    type = 'DUI',
    icon = 'car',
    aggregation_time = 'hour',
    button = 'View graph >>'),
  list(
    question = 'What time of day are officers called for barking dogs?',
    date_range = 'Previous year',
    tab = 'Graph',
    type = 'BARKING DOGS',
    icon = 'paw',
    aggregation_time = 'hour',
    button = 'View graph >>'),
  list(
    question = 'Where was vandalism reported in the past year?',
    date_range = 'Previous year',
    tab = 'Map',
    type = 'VANDALISM',
    icon = 'user-secret',
    button = 'View map >>')
)

quick_start <- function(
  session = session,
  quick_starts = quick_starts,
  index)
{
  updateNavbarPage(
    session = session,
    inputId = 'tabset_main',
    selected = 'Analysis')

  qs <- quick_starts[[index]]

  updateTabsetPanel(
    session = session,
    inputId = 'tabset_analysis',
    selected = qs$tab)

  updateSelectInput(
    session = session,
    inputId = 'date_range_preset',
    selected = qs$date_range)

  updateSelectInput(
    session = session,
    inputId = 'type',
    selected = qs$type)

  if (!is.null(qs$aggregation_time)) {
    updateSelectInput(
      session = session,
      inputId = 'aggregation_time',
      selected = qs$aggregation_time)
  }
}

