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
                          h5("Welcome! This app allows you to compare the historical performance of various crypto and non-crypto assets."),
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
                                      selected = "GOOG", 
                                      multiple = FALSE,
                                      selectize = TRUE),
                          h6("Choose the date range for which you'd like data below:"),
                          dateRangeInput("port_dates1a",
                                         label = NA, 
                                         # default date shows past 6 months of data
                                         start = Sys.Date()-183, 
                                         end = Sys.Date()-3)
                        ),
                        # Show a plot of the generated distribution
                        mainPanel(
                          plotlyOutput("portfolio_perf_chart"),
                          br(),
                          tableOutput("port_summary_table")
                          
                        )
                      )
             ),
             
             # SECOND TAB PAGE BEGINS
             tabPanel(title = "Returns",
                      sidebarLayout(
                        sidebarPanel(
                          h5("Time for returns"),
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
                                      selected = "GOOG", 
                                      multiple = FALSE,
                                      selectize = TRUE),
                          h6("Choose the date range for which you'd like data below:"),
                          dateRangeInput("port_dates1b",
                                         label = NA, 
                                         # default date shows past 6 months of data
                                         start = Sys.Date()-183, 
                                         end = Sys.Date()-3),
                          h6("Choose the period over which to calculate Sharpe ratio:"),
                          selectInput("period",
                                      label = NA,
                                      choices = c("daily", "weekly", "monthly", "quaterly", "yearly"),
                                      selected = "weekly"),
                          numericInput(inputId = "Rf", 
                                       label = NA, 
                                       value = 0, 
                                       min = 1, 
                                       max = NA, 
                                       step = 0.001),
                          numericInput(inputId = "p", 
                                       label = NA, 
                                       value = 0.95, 
                                       min = 0.01, 
                                       max = 0.99, 
                                       step = 0.001)
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
  
  # functions to observe changing inputs and constanlty update between tabs
  # observe and link asset 1
  observe({
    primary_asseta <- input$asset_1a
    updateTextInput(session, "asset_1b", value = primary_asseta)
  })
  observe({
    primary_assetb <- input$asset_1b
    updateTextInput(session, "asset_1a", value = primary_assetb)
  })
  
  # observe and link asset 2
  observe({
    secondary_asseta <- input$asset_2a
    updateTextInput(session, "asset_2b", value = secondary_asseta)
  })
  observe({
    secondary_assetb <- input$asset_2b
    updateTextInput(session, "asset_2a", value = secondary_assetb)
  })
  
  # observe and link date range
  observe({
    datea <- input$port_dates1a
    updateTextInput(session, "port_dates1b", value = datea)
  })
  observe({
    dateb <- input$port_dates1b
    updateTextInput(session, "port_dates1a", value = dateb)
  })
  
  
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
              port_end_date = input$port_dates1b[2],
              initial_investment = input$initial_investment
            )
          # builds the actual viz
          build_portfolio_perf_chart(base_data)
        }
      ), millis = 1000) # sets wait time for debounce
  
  
  # now building the summary table to go below the portfolio chart
  
  output$port_summary_table <- 
    debounce(
      renderTable({
        
        # creates the dataset to feed the table
        base_data <- 
          get_pair_data(
            asset_1 = input$asset_1a,
            asset_2 = input$asset_2a, 
            port_start_date = input$port_dates1a[1],
            port_end_date = input$port_dates1b[2],
            initial_investment = input$initial_investment
          )
        
        # builds the actual data table
        port_summary_table <- build_summary_table(base_data)
        return(port_summary_table)
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
              port_start_date = input$port_dates1a[1],
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
              port_start_date = input$port_dates1a[1],
              port_end_date = input$port_dates1b[2],
              initial_investment = input$initial_investment
            )
          # builds the altered dataset
          asset_returns_list <- get_portfolio_returns(
            portfolio_data = base_data,
            period = input$period)
          # building the retrns ratio viz
          asset_returns_chart <- build_asset_returns_plot(asset_returns_list)
          # output the plot
          asset_returns_chart
          
        }
      ), millis = 1000)
  
}

# Run the application 
shinyApp(ui = ui, server = server)

