# Functions file to be sourced within app later

options(stringsAsFactors = FALSE)

# used to trim the available options via the in-app selectize statement
symbol_list_initial <- read.csv(file="CSVs/master.csv", colClasses=c("NULL",NA))
symbol_list <- symbol_list_initial[!(is.na(symbol_list_initial$Symbol) | symbol_list_initial$Symbol==""), ]


crypto_list <- c("btc","bch","ltc","eth","eos","ada","neo","etc",
                 "xem","dcr","zec","dash","doge","pivx","xmr","vtc","xvg",
                 "xrp","xlm","lsk","gas","dgb","btg","trx","icx","ppt","omg",
                 "bnb","snt","wtc","rep","zrx","veri","bat","knc","gnt","fun",
                 "gno","salt","ethos","icn","pay","mtl","cvc","ven","rhoc","ae",
                 "ant","btm","lrc","zil")

# Function for fetching data and constructing main portfolio table

get_pair_data <- function(asset_1 = "eth", 
                          asset_2 = "AMZN", 
                          port_start_date = Sys.Date()-183, 
                          port_end_date = Sys.Date()-3, 
                          initial_investment=1000){
  
  # Getting the data for asset 1
  # If it's a crypto asset then get it from coinmetrics.io; else get it from yahoo API
  if(asset_1 %in% crypto_list == T){
    # create string to be used in URL call
    crypto_url_1 <- paste0("https://coinmetrics.io/newdata/",asset_1,".csv")
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
    crypto_url_2 <- paste0("https://coinmetrics.io/newdata/",asset_2,".csv")
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
  
  # implement the date filter
  both_assets_data <- both_assets_data %>%
    filter(between(as.Date(date), as.Date(port_start_date), as.Date(port_end_date)))
  
  # ensure that all types are numeric for prices because odd type conversion happen sometimes when data change
  both_assets_data <- both_assets_data %>%  
    mutate(asset_one = as.numeric(.[[2]]),
           asset_two = as.numeric(.[[3]])
    ) %>%
    select(date, asset_one, asset_two) %>%
    plyr::rename(c('asset_one'=asset_1,
                   'asset_two'=asset_2))
  
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
      asset_1_port_val = (initial_investment*(as.numeric(both_assets_data[,2]))/as.numeric(asset_1_mp_at_purchase[1,1])),
      asset_2_port_val = (initial_investment*(as.numeric(both_assets_data[,3]))/as.numeric(asset_2_mp_at_purchase[1,1]))
    ) 
  
  # creating the strings with which to rename portoflio value columns
  asset_1_port_val_name = paste0(asset_1,"_port_val")
  asset_2_port_val_name = paste0(asset_2,"_port_val")
  # renaming portfolio values to make them readable
  names(portfolio_data)[4:5] <- c(asset_1_port_val_name, asset_2_port_val_name)
  
  return(portfolio_data)
  
  
}

build_summary_table <- function(portfolio_data){
  
  # creating the summary table
  # creates various vectors 
  asset_names <- c(names(portfolio_data[2]),names(portfolio_data[3]))
  asset_portfolio_max_worth <- c(max(portfolio_data[4]),max(portfolio_data[5]))
  asset_portfolio_latest_worth <- c(as.numeric(tail(portfolio_data[4],1)),as.numeric(tail(portfolio_data[5],1)))
  asset_portfolio_absolute_profit <- c(as.numeric(tail(portfolio_data[4],1))-as.numeric(head(portfolio_data[4],1)),
                                       as.numeric(tail(portfolio_data[5],1))-as.numeric(head(portfolio_data[5],1)))
  asset_portfolio_rate_of_return <- c(((as.numeric(tail(portfolio_data[4],1))-as.numeric(head(portfolio_data[4],1)))/as.numeric(head(portfolio_data[4],1)))*100,
                                      ((as.numeric(tail(portfolio_data[5],1))-as.numeric(head(portfolio_data[5],1)))/as.numeric(head(portfolio_data[5],1)))*100)
  # merges vectors into dataframe
  asset_summary_table <- data.frame(asset_names,asset_portfolio_max_worth,asset_portfolio_latest_worth, asset_portfolio_absolute_profit, asset_portfolio_rate_of_return)
  colnames(asset_summary_table) <- c("Asset Names",
                                     "Asset Portfolio Max Worth",
                                     "Asset Portfolio Latest Worth",
                                     "Asset Portfolio Absolute Profit",
                                     "Asset Portfolio Rate of Return")
  return(asset_summary_table)
  
}


build_portfolio_perf_chart <- function(data, port_loess_param = 0.33){
  
  port_tbl <- data[,c(1,4:5)]
  
  # grabbing the 2 asset names
  asset_name1 <- sub('_.*', '', names(port_tbl)[2])
  asset_name2 <- sub('_.*', '', names(port_tbl)[3])
  
  # transforms dates into correct type so smoothing can be done
  port_tbl[,1] <- as.Date(port_tbl[,1])
  date_in_numeric_form <- as.numeric((port_tbl[,1]))
  # assigning loess smoothing parameter
  loess_span_parameter <- port_loess_param
  
  # now building the plotly itself
  port_perf_plot <- plot_ly(data = port_tbl, x = ~port_tbl[,1]) %>%
    # asset 1 data plotted
    add_markers(y =~port_tbl[,2],
                marker = list(color = '#FC9C01'),
                name = asset_name1,
                showlegend = FALSE) %>%
    add_lines(y = ~fitted(loess(port_tbl[,2] ~ date_in_numeric_form, span = loess_span_parameter)),
              line = list(color = '#FC9C01'),
              name = asset_name1,
              showlegend = TRUE) %>%
    # asset 2 data plotted
    add_markers(y =~port_tbl[,3],
                marker = list(color = '#3498DB'),
                name = asset_name2,
                showlegend = FALSE) %>%
    add_lines(y = ~fitted(loess(port_tbl[,3] ~ date_in_numeric_form, span = loess_span_parameter)),
              line = list(color = '#3498DB'),
              name = asset_name2,
              showlegend = TRUE) %>%
    layout(
      title = FALSE,
      xaxis = list(type = "date",
                   title = "Date"),
      yaxis = list(title = "Portfolio Value ($)"),
      legend = list(orientation = 'h',
                    x = 0,
                    y = 1.15)) %>%
    add_annotations(
      x= 1,
      y= 1.133,
      xref = "paper",
      yref = "paper",
      text = "",
      showarrow = F
    )
  
  return(port_perf_plot)
  
}


##################

get_portfolio_returns <- function(portfolio_data, period = "weekly"){
  
  # grab the string names of the assets for labelling later
  asset_1_name_str <- names(portfolio_data[2])
  asset_2_name_str <- names(portfolio_data[3])
  
  # create the xts objects necessary to run the periodReturn function
  asset_1_xts <- xts(x=portfolio_data[,2], order.by=as.Date(portfolio_data$date))
  asset_2_xts <- xts(x=portfolio_data[,3], order.by=as.Date(portfolio_data$date))
  
  # get the returns of the assets over the chosen period 
  asset_1_returns <- periodReturn(asset_1_xts, period = period)
  asset_2_returns <- periodReturn(asset_2_xts, period = period)
  
  # make the naming of the columns more intuitive
  names(asset_1_returns) <- paste0(asset_1_name_str,"_returns")
  names(asset_2_returns) <- paste0(asset_2_name_str,"_returns")
  
  # return a list of dataframes containing the returns that can be referenced later
  asset_returns_list <- list(asset_1_returns, asset_2_returns)
  
  return(asset_returns_list)
}


get_sharpe_ratio_plot <- function(asset_returns_list, Rf = 0, p=0.95){
  
  # calculating the shapre ratios for each asset (rounded to 4th decimal)
  asset_1_sharp_ratios <- round(SharpeRatio(asset_returns_list[[1]], Rf = Rf, p=p), 4)
  asset_2_sharp_ratios <- round(SharpeRatio(asset_returns_list[[2]], Rf = Rf, p=p), 4)
  
  # adding intuitve names to tables
  # extra spaces injected into column names to facilitate ploly labelling later
  asset_1_sharp_ratio_df <- data.frame(metric = c("StdDev Sharpe   ","VaR Sharpe   ","ES Sharpe   "),
                                       coredata(asset_1_sharp_ratios))
  asset_2_sharp_ratio_df <- data.frame(metric = c("StdDev Sharpe   ","VaR Sharpe   ","ES Sharpe   "),
                                       coredata(asset_2_sharp_ratios))
  
  # explictly clears pesky rownames
  rownames(asset_1_sharp_ratio_df) <- c()
  rownames(asset_2_sharp_ratio_df) <- c()
  
  # creating final sharpe ratio table
  
  final_sharpe_ratio_table <- merge(asset_1_sharp_ratio_df, asset_2_sharp_ratio_df, by="metric")
  # drops now-unrelated label from names (drops everything after underscore)
  names(final_sharpe_ratio_table) <- sub("_.*", "", names(final_sharpe_ratio_table))
  
  # making the main sharpe ratio viz
  
  sharpe_ratio_plot <- plot_ly(data = final_sharpe_ratio_table, 
                               x = ~final_sharpe_ratio_table[,2], 
                               y = ~metric, 
                               type = 'bar', 
                               orientation = 'h', 
                               name = names(final_sharpe_ratio_table[2]),
                               marker = list(color = '#FC9C01')) %>%
    add_trace(x = ~final_sharpe_ratio_table[,3], 
              name = names(final_sharpe_ratio_table[3]),
              marker = list(color = '#3498DB')) %>%
    layout(
      title = FALSE,
      xaxis = list(title = "Sharpe Ratio"),
      yaxis = list(title = NA),
      margin = list(l = 125),
      legend = list(orientation = 'h',
                    x = 0,
                    y = 1.2)) %>%
    add_annotations(
      x= 1,
      y= 1.16,
      xref = "paper",
      yref = "paper",
      text = "",
      showarrow = F
    )
  
  return(sharpe_ratio_plot)
}



build_asset_returns_plot <- function(asset_returns_list, asset_loess_param = 0.75){
  
  asset_1_name_str <- sub("_.*", "", names(asset_returns_list[[1]]))
  asset_2_name_str <- sub("_.*", "", names(asset_returns_list[[2]]))
  
  asset_1_returns_df <-  data.frame(date=index(asset_returns_list[[1]]), coredata(asset_returns_list[[1]]))
  asset_2_returns_df <-  data.frame(date=index(asset_returns_list[[2]]), coredata(asset_returns_list[[2]]))
  
  total <- merge(asset_1_returns_df, asset_2_returns_df, by="date")
  
  # building the viz
  
  # preparing the data for smoothing
  total[,1] <- as.Date(total[,1])
  date_in_numeric_form <- as.numeric((total[,1]))
  # picking smoothing parameter
  loess_span_parameter <- asset_loess_param
  
  
  asset_return_plot <- plot_ly(data = total, x = ~date) %>%
    # asset 1 data plotted
    add_markers(y =~total[,2],
                marker = list(color = '#FC9C01'),
                name = asset_1_name_str,
                showlegend = FALSE) %>%  
    add_lines(y = ~fitted(loess(total[,2] ~ date_in_numeric_form, span = loess_span_parameter)),
              line = list(color = '#FC9C01'),
              name = asset_1_name_str,
              showlegend = TRUE) %>%
    # asset 2 data plotted
    add_markers(y =~total[,3],
                marker = list(color = '#3498DB'),
                name = asset_2_name_str,
                showlegend = FALSE) %>%  
    add_lines(y = ~fitted(loess(total[,3] ~ date_in_numeric_form, span = loess_span_parameter)),
              line = list(color = '#3498DB'),
              name = asset_2_name_str,
              showlegend = TRUE) %>%
    layout(
      title = FALSE,
      xaxis = list(type = "date",
                   title = "Date"),
      yaxis = list(title = "Return on Investment (%)",
                   tickformat = "%"),
      legend = list(orientation = 'h',
                    x = 0,
                    y = 1.15)) %>%
    add_annotations(
      x= 1,
      y= 1.133,
      xref = "paper",
      yref = "paper",
      text = "",
      showarrow = F
    )
  
  return(asset_return_plot)
  
}


