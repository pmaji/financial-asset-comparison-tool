# Functions file to be sourced within app later

# Function for fetching data and constructing main portfolio table

crypto_list <- c("btc","bch","ltc","eth")

get_pair_data <- function(asset_1, asset_2, start_date, end_date, initial_investment=1000){
  
  # Getting the data for asset 1
  # If it's a crypto asset then get it from coinmetrics.io; else get it from yahoo API
  if(asset_1 %in% crypto_list == T){
    # create string to be used in URL call
    crypto_url_1 <- paste0("https://coinmetrics.io/data/",asset_1,".csv")
    # pull in data from web-hosted CSV
    asset_1_data <- fread(crypto_url_1)
    # drop all the data we don't need, keeping only date and price
    asset_1_data <- asset_1_data[,c(1,5)]
    # renaming columns for coherence
    names(asset_1_data) <- c("date",asset_1)
  } else {
    # loads data from yahoo api; auto.assign=FALSE keeps it from loading into global env
    asset_1_data <- as.data.frame(getSymbols(asset_1, src = "yahoo", auto.assign=FALSE))
    # rips out the datetime index and makes it a column named "rn"
    setDT(asset_1_data, keep.rownames = TRUE)[]
    # keeps only data index and closing price
    asset_1_data <- asset_1_data[,c(1,7)]
    # changes column names to standardize naming convention
    names(asset_1_data) <- c("date",asset_1)
    # fills in weekend NULL prices with friday price
    asset_1_data <- asset_1_data %>% fill(paste(asset_1))
  }
  
  
  # Getting the data for asset 2
  # If it's a crypto asset then get it from coinmetrics.io; else get it from yahoo API
  if(asset_2 %in% crypto_list == T){
    # create string to be used in URL call
    crypto_url_2 <- paste0("https://coinmetrics.io/data/",asset_2,".csv")
    # pull in data from web-hosted CSV
    asset_2_data <- fread(crypto_url_2)
    # drop all the data we don't need, keeping only date and price
    asset_2_data <- asset_2_data[,c(1,5)]
    # renaming columns for coherence
    names(asset_2_data) <- c("date",asset_2)
  } else {
    # loads data from yahoo api; auto.assign=FALSE keeps it from loading into global env
    asset_2_data <- as.data.frame(getSymbols(asset_2, src = "yahoo", auto.assign=FALSE))
    # rips out the datetime index and makes it a column named "rn"
    setDT(asset_2_data, keep.rownames = TRUE)[]
    # keeps only data index and closing price
    asset_2_data <- asset_2_data[,c(1,7)]
    # changes column names to standardize naming convention
    names(asset_2_data) <- c("date",asset_2)
    # fills in weekend NULL prices with friday price
    asset_2_data <- asset_2_data %>% fill(paste(asset_2))
  }
  
  # first we need to get the most recent date for which we have data from BOTH assets
  # creates vector of both first dates for which we have data for both assets
  first_dates <- as.list(c(asset_1_data$date[1],asset_2_data$date[1]))
  # finds the max start date out of both
  start_date <- do.call(pmax, first_dates)
  # does a full join of both asset dataframes
  both_assets_data <- merge(x = asset_1_data, y = asset_2_data, by = "date", all = TRUE)
  # filters this by the most recent start date so that we have only complete data
  both_assets_data <- both_assets_data %>% filter(date >= start_date)
  # does a second FILL as a final check in case merge creates more nulls for some reason
  both_assets_data <- both_assets_data %>% fill(paste(asset_1))
  both_assets_data <- both_assets_data %>% fill(paste(asset_2))
  
  # Now we get the portfolio values
  # First we need the market price for both assets at time of purchase
  asset_1_mp_at_purchase <- both_assets_data %>%
    select(noquote(asset_1)) %>%
    filter(row_number()==1)
  
  asset_2_mp_at_purchase <- both_assets_data %>%
    select(noquote(asset_2)) %>%
    filter(row_number()==1)
  
  # now we built the actual portfolio value over time columns
  portfolio_data <- both_assets_data %>%
    mutate(
      asset_1_port_val = (initial_investment*(both_assets_data[,2])/asset_1_mp_at_purchase[1,1]),
      asset_2_port_val = (initial_investment*(both_assets_data[,3])/asset_2_mp_at_purchase[1,1])
    ) 
  
  # creating the strings with which to rename portoflio value columns
  asset_1_port_val_name = paste0(asset_1,"_port_val")
  asset_2_port_val_name = paste0(asset_2,"_port_val")
  # renaming portfolio values to make them readable
  names(portfolio_data)[4:5] <- c(asset_1_port_val_name, asset_2_port_val_name)
  
  return((portfolio_data))
  
  
}

fbbtc <- get_pair_data("btc","FB")


# now time to build the Plotly

library(plotly)

plot_ly(data = fbbtc, x = ~date) %>%
  add_trace(y = ~btc_port_val, name = "BTC_PORT_VAL",  type = "scatter", mode = "lines+markers") %>%
  add_trace(y = ~FB_port_val, name = "FB_PORT_VAL",  type = "scatter", mode = "lines+markers") %>%
  layout(
    title = "Asset Prices",
    xaxis = list(
      type = 'date',
      rangeselector = list(
        buttons = list(
          list(
            count = 3,
            label = "3 mo",
            step = "month",
            stepmode = "backward"),
          list(
            count = 6,
            label = "6 mo",
            step = "month",
            stepmode = "backward"),
          list(
            count = 1,
            label = "1 yr",
            step = "year",
            stepmode = "backward"),
          list(
            count = 1,
            label = "YTD",
            step = "year",
            stepmode = "todate"),
          list(step = "all"))),
      
      rangeslider = list(type = "date")),
    
    yaxis = list(title = "Price"))






