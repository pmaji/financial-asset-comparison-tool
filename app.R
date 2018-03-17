library(shiny)
library(xts)
library(quantmod)
library(zoo)
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


# source the Functions.R file
source("Functions.R")


# Define UI for application that draws a histogram
ui <- 
  navbarPage(title = "Asset Comparison Toolbox",
             theme = shinytheme("superhero"),
             
             # FIRST TAB PAGE BEGINS
             tabPanel(title = "Portfolio",
                      sidebarLayout(
                        sidebarPanel(
                          h5("Welcome! This simple app is meant to allow you to quickly compare the historical performance of various crypto and non-crypto assets."),
                          h6("Enter your initial invesment amount ($):"),
                          numericInput(inputId = "initial_investment", 
                                       label = NA, 
                                       value = 1000, 
                                       min = 1, 
                                       max = NA, 
                                       step = 1),
                          h6("Use all lower-case to input crypto-assets, and all upper-case to input equities."),
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
                          dateRangeInput("port_dates",
                                         label = NA, 
                                         # default date shows past 6 months of data
                                         start = Sys.Date()-183, 
                                         end = Sys.Date()-3),
                          wellPanel(
                            helpText(
                              a("Read the documentation and methodology here", 
                                href="https://github.com/pmaji/crypto-asset-comparison-tool/blob/master/README.md", target="_blank")
                                )
                              )
                            ),
                            # Show a plot of the generated distribution
                        mainPanel(
                          plotlyOutput("portfolio_perf_chart")
                                
                              )
                            )
                          ),
              
              # SECOND TAB PAGE BEGINS
              tabPanel(title = "Returns",
                        sidebarLayout(
                          sidebarPanel(
                            h5("Time for returns"),
                            h6("Use all lower-case to input crypto-assets, and all upper-case to input equities."),
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
                            dateRangeInput("port_dates",
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
                                         step = 0.001),
                            wellPanel(
                              helpText(
                                a("Read the documentation and methodology here", 
                                  href="https://github.com/pmaji/crypto-asset-comparison-tool/blob/master/README.md", target="_blank")
                              )
                            )
                          ),
                          # Show a plot of the generated distribution
                          mainPanel(
                            plotlyOutput("portfolio_sharpe_chart"),
                            plotlyOutput("asset_returns_chart")
                          )
                        )
                        
                 )
)


####################################
############   SERVER   ############
####################################

server <- function(input, output, session) {
  
  # functions to observe changing inputs and constanlty update between tabs
  observe({
    primary_asseta <- input$asset_1a
    updateTextInput(session, "asset_1b", value = primary_asseta)
  })
  observe({
    primary_assetb <- input$asset_1b
    updateTextInput(session, "asset_1a", value = primary_assetb)
  })
  
  observe({
    secondary_asseta <- input$asset_2a
    updateTextInput(session, "asset_2b", value = secondary_asseta)
  })
  observe({
    secondary_assetb <- input$asset_2b
    updateTextInput(session, "asset_2a", value = secondary_assetb)
  })
  
  
  
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
            port_start_date = input$port_dates[1],
            port_end_date = input$port_dates[2],
            initial_investment = input$initial_investment
                       )
        # builds the actual viz
        build_portfolio_perf_chart(base_data)
      }
            ), millis = 1000) # sets wait time for debounce
  
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
              port_start_date = input$port_dates[1],
              port_end_date = input$port_dates[2],
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
              port_start_date = input$port_dates[1],
              port_end_date = input$port_dates[2],
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

