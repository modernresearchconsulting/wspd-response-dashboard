google_maps_api_key <- ''

data_all <- readRDS('data/data_all.rds')

data_date_max <- max(data_all$date, na.rm = TRUE)

if (data_date_max == Sys.Date() - 1) {
  stop('Data is up to date! Run again tomorrow when data from today will be available.')
}

date_start <- data_date_max + 1
date_end   <- Sys.Date() - 1

##################

library(httr)
library(jsonlite)

download_data <- function(
  date_start,
  date_end,
  folder = 'downloads')
{
  base_url <- 'http://www.cityofws.org/crimestats/txt'
  
  if (date_start > date_end) {
    stop('date_start is later than date_end')
  } else if (date_start > Sys.Date()) {
    stop('date_start is in the future')
  } else if (date_end > Sys.Date()) {
    stop('date_end is in the future')
  }

  dates <- seq(date_start, date_end, by = 1)

  random_order <- sample.int(length(dates))

  dates <- dates[random_order]

  sapply(dates,
         FUN = function(date) {

            month <- strftime(date, '%m')
            day   <- strftime(date, '%d')
            year  <- strftime(date, '%Y')

            date_file <- sprintf('WSPD%s%s.TXT',
              month,
              day)

            date_url <- sprintf('%s/%s', base_url, date_file)

            destfile <- sprintf('%s/%s/%s', folder, year, date_file)

            download.file(
              url = date_url,
              destfile = destfile)

            Sys.sleep(runif(1) * 10)

            destfile
         })
}

data_files <- download_data(
  date_start = date_start,
  date_end = date_end,
  folder = 'downloads')

data_by_file <- lapply(
  data_files,
  FUN = function(data_file) {

    read.fwf(data_file,
     widths = c(13, 7, 5, 31, 6, 40),
     header = FALSE,
     col.names = c('report', 'date', 'time', 'type', 'address_number', 'address_street'),
     stringsAsFactors = FALSE)
  })

data <- do.call(rbind, data_by_file)

# drop rows where report is NA
data <- data[!is.na(data$report), ]

# Remove trailing spaces from character variables
classes <- sapply(data, class)
character_classes <- which(classes == 'character')

data[character_classes] <- lapply(
  data[character_classes],
  FUN = function(x) {
    gsub(' +$', '', x)
  })

date_text <- sprintf('%06d', data$date)
time_text <- sprintf('%04d', data$time)

data$month          <- as.numeric(substring(date_text, 1, 2))
data$day_of_month   <- as.numeric(substring(date_text, 3, 4))
data$year           <- as.numeric(substring(date_text, 5, 6)) + 2000

data$hour           <- as.numeric(substring(time_text, 1, 2))
data$minute         <- as.numeric(substring(time_text, 3, 4))

data$date       <- as.Date(date_text, '%m%d%y')
data$date_time  <- strptime(sprintf('%s %s', date_text, time_text),
                           '%m%d%y %H%M')

data$day_of_year    <- as.numeric(strftime(data$date, '%j'))
data$day_of_week    <- as.numeric(strftime(data$date, '%w'))
data$week_of_year   <- as.numeric(strftime(data$date, '%V'))

data$time_text <- strftime(strptime(data$date_time, format = '%Y-%m-%d %H:%M:%S'),
                        format = '%H:%M')

data$address <- paste(data$address_number,
                      data$address_street)

data_previous <- readRDS('data/data_all.rds')

data_all <- rbind(data_previous, data)

data_all <- unique(data_all)

saveRDS(data_all, 'data/data_all.rds')

########

addresses_geocoded <- readRDS('data/addresses_geocoded.rds')

addresses <- unique(data_all$address)

addresses_new <- data.frame(
  address = setdiff(addresses, addresses_geocoded$address),
  latitude = NA,
  longitude = NA,
  zip = NA,
  location_type = NA_character_,
  formatted = NA_character_,
  stringsAsFactors = FALSE)

for (i in seq_len(nrow(addresses_new))) {
  message('geocoding record ', i)

  address <- addresses_new$address[i]

  response <- httr::GET(
    url = sprintf('https://maps.googleapis.com/maps/api/geocode/json?address=%s,+Winston-Salem,+NC&key=%s',
                  gsub(' ', '+', address),
                  google_maps_api_key))

  results <- jsonlite::fromJSON(
    rawToChar(response$content),
    simplifyDataFrame = FALSE)

  if (results$status == 'OK') {
    result <- results$results[[1]]

    addresses_new$formatted[i] <- result$formatted_address

    for (address_component in result$address_components) {
      if ('postal_code' %in% address_component$types) {
        addresses_new$zip[i] <- address_component$long_name
      }
    }

    addresses_new$latitude[i]       <- result$geometry$location$lat
    addresses_new$longitude[i]      <- result$geometry$location$lng
    addresses_new$location_type[i]  <- result$geometry$location_type
  }

  if (i < seq_len(nrow(addresses_new))) {
    Sys.sleep(10)
  }
}

addresses_geocoded <- rbind(
  addresses_geocoded,
  addresses_new)

saveRDS(addresses_geocoded, file = 'data/addresses_geocoded.rds')
