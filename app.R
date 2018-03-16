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


# source the Functions.R file
source("Functions.R")


# Define UI for application that draws a histogram
ui <- 
  navbarPage(title = "Asset Comparison Toolbox",
             theme = shinytheme("superhero"),
             
             # FIRST TAB PAGE BEGINS
             tabPanel("Portfolio",
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
                          textInput("asset_1", 
                                    label = NA, 
                                    # default asset selected is Ethereum
                                    value = "eth"),
                          h6("Select 2nd asset of interest:"),
                          textInput("asset_2", 
                                    label = NA, 
                                    value = "GOOG"),
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
              tabPanel("Summary"
                 )
)


####################################
############   SERVER   ############
####################################

server <- function(input, output) {
  
  # 2 step process to create portfolio_perf_chart: create dataset; make viz
  # debounce introduced to throttle time between input change and re-render
  output$portfolio_perf_chart <- 
    debounce(
      renderPlotly(
      {
        # creates the dataset to feed the viz
        base_data <- 
          get_pair_data(
            asset_1 = input$asset_1,
            asset_2 = input$asset_2, 
            port_start_date = input$port_dates[1],
            port_end_date = input$port_dates[2],
            initial_investment = input$initial_investment
                       )
        # builds the actual viz
        build_portfolio_perf_chart(base_data)
      }
            ), millis = 1000) # sets wait time for debounce

}

# Run the application 
shinyApp(ui = ui, server = server)

