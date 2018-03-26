# import all necessary packages
library(shiny)
library(xts) # for xts objects
library(quantmod) # for the Yahoo finance imports
library(zoo) # for date rangling
library(TTR)
library(magrittr)
library(htmlwidgets)
library(data.table)
library(rsconnect) # for publishing
library(plotly)
library(dplyr)
library(tidyr)
library(shinythemes)
library(PerformanceAnalytics)
library(DT)
library(formattable)


# source the Functions.R file, where all functions for data importing, cleaning, and vizualization are written
source("Functions.R")


####################################
##############   UI   ##############
####################################

ui <- 
  navbarPage(title = "Asset Comparison Toolbox",
             theme = shinytheme("superhero"),
             
             # FIRST TAB PAGE BEGINS
             tabPanel(title = "Portfolio",
                      sidebarLayout(
                        sidebarPanel(
                          h5("Welcome! This app allows you to compare the historical performance of various crypto and non-crypto assets. The first tab focuses on portfolio performance, while the second tab focuses on rate of return (both raw and risk-adjusted). If you're new or have questions, click the GitHub link below for instructions on how to use the app."),
                          h6("Code and documentation: ", a(href = "https://github.com/pmaji/crypto-asset-comparison-tool/blob/master/README.md", "here on GitHub")),
                          h6("Enter your initial invesment amount ($):"),
                          numericInput(inputId = "initial_investment", 
                                       label = NA, 
                                       value = 1000, 
                                       min = 1, 
                                       max = NA, 
                                       step = 1),
                          h6("Use lowercase for crypto, and uppercase for all other:"),
                          # first the UI options to pick the 1st asset to compare:
                          h6("Select 1st asset of interest:"),
                          selectInput(inputId = "asset_1a",
                                      label = NA,
                                      choices = symbol_list, 
                                      selected = "eth", 
                                      multiple = FALSE,
                                      selectize = TRUE),
                          h6("Select 2nd asset of interest:"),
                          selectInput(inputId = "asset_2a",
                                      label = NA,
                                      choices = symbol_list, 
                                      selected = "AMZN", 
                                      multiple = FALSE,
                                      selectize = TRUE),
                          h6("Choose the date range for which you'd like data below:"),
                          dateRangeInput("port_dates1a",
                                         label = NA, 
                                         # default date shows past 1 year
                                         start = Sys.Date()-368, 
                                         end = Sys.Date()-3),
                          h6("Choose loess smoothing span parameter for portfolio chart:"),
                          h6("(Default loess span = 0.33)"),
                          numericInput(inputId ="port_loess_param",
                                       label = NA,
                                       value = 0.33,
                                       min = 0.01,
                                       max = 10,
                                       step = 0.01)
                        ),
                        # Show a plot of the generated distribution
                        mainPanel(
                          plotlyOutput("portfolio_perf_chart"),
                          br(),
                          formattableOutput("port_summary_table")
                          
                        )
                      )
             ),
             
             # SECOND TAB PAGE BEGINS
             tabPanel(title = "Returns",
                      sidebarLayout(
                        sidebarPanel(
                          h5("This tab focuses on", a(href = "https://www.investopedia.com/terms/r/rateofreturn.asp", "rate of return,"), "and then, more specifically, the average rate of return in excess of the risk free rate, per unit of volatility, as captured by variations of the", a(href = "https://en.wikipedia.org/wiki/Sharpe_ratio", "Sharpe Ratio")),
                          h6("Use lowercase for crypto, and uppercase for all other:"),
                          # first the UI options to pick the 1st asset to compare:
                          h6("Select 1st asset of interest:"),
                          selectInput(inputId = "asset_1b",
                                      label = NA,
                                      choices = symbol_list, 
                                      selected = "eth", 
                                      multiple = FALSE,
                                      selectize = TRUE),
                          h6("Select 2nd asset of interest:"),
                          selectInput(inputId = "asset_2b",
                                      label = NA,
                                      choices = symbol_list, 
                                      selected = "AMZN", 
                                      multiple = FALSE,
                                      selectize = TRUE),
                          h6("Choose the date range for which you'd like data below:"),
                          dateRangeInput("port_dates1b",
                                         label = NA, 
                                         # default date shows past 1 year
                                         start = Sys.Date()-368, 
                                         end = Sys.Date()-3),
                          h6("Choose period over which to calculate returns:"),
                          selectInput("period",
                                      label = NA,
                                      choices = c("daily", "weekly", "monthly", "quaterly", "yearly"),
                                      selected = "monthly"),
                          h6("Choose risk free rate (in same period of time as returns):"),
                          h6("(Default 0.01 = 1% risk free rate)"),
                          # risk free rates at link below; for monthly risk-free rate use 1 month treasury
                          # https://www.treasury.gov/resource-center/data-chart-center/interest-rates/Pages/TextView.aspx?data=yield
                          numericInput(inputId = "Rf", 
                                       label = NA, 
                                       value = 0.01, 
                                       min = -100, 
                                       max = 100, 
                                       step = 0.001),
                          h6("Choose confidence level:"),
                          h6("(Default 0.95 = 95 % confidence level)"),
                          numericInput(inputId = "p", 
                                       label = NA, 
                                       value = 0.95, 
                                       min = 0.01, 
                                       max = 0.99, 
                                       step = 0.001),
                          h6("Choose loess smoothing span parameter for returns chart:"),
                          h6("(Default loess span = 0.75)"),
                          numericInput(inputId ="asset_loess_param",
                                       label = NA,
                                       value = 0.75,
                                       min = 0.01,
                                       max = 10,
                                       step = 0.01)
                        ),
                        # Show a plot of the generated distribution
                        mainPanel(
                          plotlyOutput("asset_returns_chart"),
                          br(),
                          plotlyOutput("portfolio_sharpe_chart", width = "100%", height = 200)
                        )
                      )
                      
             )
  )


####################################
############   SERVER   ############
####################################

server <- function(input, output, session) {
  
  # FURTHER INVESTIGATION NEEDED HERE AS TO WHY DOESN'T WORK
  # functions to observe changing inputs and constanlty update between tabs
  # observe and link asset 1
  # observe({
  #   primary_asseta <- input$asset_1a
  #   updateSelectInput(session, "asset_1b", selected = primary_asseta)
  # })
  # observe({
  #   primary_assetb <- input$asset_1b
  #   updateSelectInput(session, "asset_1a", selected = primary_assetb)
  # })
  # 
  # # observe and link asset 2
  # observe({
  #   secondary_asseta <- input$asset_2a
  #   updateSelectInput(session, "asset_2b", selected = secondary_asseta)
  # })
  # observe({
  #   secondary_assetb <- input$asset_2b
  #   updateSelectInput(session, "asset_2a", selected = secondary_assetb)
  # })
  # 
  # # observe and link date range
  # observe({
  #   datea <- input$port_dates1a
  #   updateDateRangeInput(session, "port_dates1b", start = datea[1], end = datea[2])
  # })
  # observe({
  #   dateb <- input$port_dates1b
  #   updateDateRangeInput(session, "port_dates1a", start = dateb[1], end = dateb[2])
  # })


  # TAB ONE CALCULATIONS AND VIZUALIZATIONS 
  # 2 step process to create portfolio_perf_chart: create dataset; make viz
  # debounce introduced to throttle time between input change and re-render
  output$portfolio_perf_chart <- 
    debounce(
      renderPlotly(
        {
          # creates the dataset to feed the viz
          base_data <- 
            get_pair_data(
              asset_1 = input$asset_1a,
              asset_2 = input$asset_2a, 
              port_start_date = input$port_dates1a[1],
              port_end_date = input$port_dates1a[2],
              initial_investment = input$initial_investment
            )
          # builds the actual viz
          build_portfolio_perf_chart(base_data, port_loess_param = input$port_loess_param)
        }
      ), millis = 1000) # sets wait time for debounce
  
  
  # now building the summary table to go below the portfolio chart
  
  output$port_summary_table <- 
    debounce(
      renderFormattable({
        
        # creates the dataset to feed the table
        base_data <- 
          get_pair_data(
            asset_1 = input$asset_1a,
            asset_2 = input$asset_2a, 
            port_start_date = input$port_dates1a[1],
            port_end_date = input$port_dates1a[2],
            initial_investment = input$initial_investment
          )
        
        # builds the actual summary table
        port_summary_table <- build_summary_table(base_data)
        
        # adds on all the formattable details
        # css color names taken from http://www.crockford.com/wrrrld/color.html
        formattable(port_summary_table, 
                    list(
                      asset_portfolio_rate_of_return = formatter("span",
                                                                 style = x ~ style(
                                                                   display = "inline-block",
                                                                   direction = "rtl",
                                                                   "border-radius" = "4px",
                                                                   "padding-right" = "2px",
                                                                   "background-color" = csscolor("darkslategray"),
                                                                   width = percent(proportion(x)),
                                                                   color = csscolor(gradient(x, "red", "green"))
                                                                 )),
                      asset_portfolio_absolute_profit = formatter("span",
                                                                  style = x ~ style(
                                                                    display = "inline-block",
                                                                    direction = "rtl",
                                                                    "border-radius" = "4px",
                                                                    "padding-right" = "2px",
                                                                    "background-color" = csscolor("darkslategray"),
                                                                    width = percent(proportion(x)),
                                                                    color = csscolor(gradient(x, "red", "green"))
                                                                  )),
                      asset_portfolio_latest_worth = formatter("span",
                                                               style = x ~ style(
                                                                 display = "inline-block",
                                                                 direction = "rtl",
                                                                 "border-radius" = "4px",
                                                                 "padding-right" = "2px",
                                                                 "background-color" = csscolor("darkslategray"),
                                                                 width = percent(proportion(x)),
                                                                 color = csscolor(gradient(x, "red", "green"))
                                                               )),
                      asset_portfolio_max_worth = formatter("span",
                                                            style = x ~ style(
                                                              display = "inline-block",
                                                              direction = "rtl",
                                                              "border-radius" = "4px",
                                                              "padding-right" = "2px",
                                                              "background-color" = csscolor("darkslategray"),
                                                              width = percent(proportion(x)),
                                                              color = csscolor(gradient(x, "red", "green"))
                                                            ))
                    )
        )
        
        
      }), millis = 1000) # sets wait time for debounce
  
  
  
  
  
  
  # 3 step process to create Sharpe ratio chart: create data; derive ratios; make viz
  output$portfolio_sharpe_chart <-
    debounce(
      renderPlotly(
        {
          # creates the main dataset
          base_data <- 
            get_pair_data(
              asset_1 = input$asset_1b,
              asset_2 = input$asset_2b, 
              port_start_date = input$port_dates1b[1],
              port_end_date = input$port_dates1b[2],
              initial_investment = input$initial_investment
            )
          # builds the altered dataset
          asset_returns_list <- get_portfolio_returns(
            portfolio_data = base_data,
            period = input$period)
          # building the sharpe ratio viz
          sharpe_ratio_plot <- get_sharpe_ratio_plot(
            asset_returns_list = asset_returns_list,
            Rf = input$Rf,
            p = input$p)
          # output the plot
          sharpe_ratio_plot
          
        }
      ), millis = 1000)
  
  # 3 step process to create main returns chart: create data, derive ratio, make viz
  output$asset_returns_chart <-
    debounce(
      renderPlotly(
        {
          # creates the main dataset
          base_data <- 
            get_pair_data(
              asset_1 = input$asset_1b,
              asset_2 = input$asset_2b, 
              port_start_date = input$port_dates1b[1],
              port_end_date = input$port_dates1b[2],
              initial_investment = input$initial_investment
            )
          # builds the altered dataset
          asset_returns_list <- get_portfolio_returns(
            portfolio_data = base_data,
            period = input$period)
          # building the retrns ratio viz
          asset_returns_chart <- build_asset_returns_plot(asset_returns_list = asset_returns_list, 
                                                          asset_loess_param = input$asset_loess_param)
          # output the plot
          asset_returns_chart
          
        }
      ), millis = 1000)
  
}

# Run the application 
shinyApp(ui = ui, server = server)

