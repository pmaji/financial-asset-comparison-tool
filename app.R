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


# source the Functions.R file
source("Functions.R")


# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel('Crypto / Non-Crypto Asset Comparison Tool'),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      h6("Welcome! This simple app is meant to allow you to quickly compare the historical performance of various crypto and non-crypto assets."),
      numericInput(inputId = "initial_investment", 
                   label = "Enter your initial invesment amount", 
                   value = 1000, 
                   min = 1, 
                   max = NA, 
                   step = 1),
      h6("Use all lower-case to input crypto-assets, and all upper-case to input equities."),
      # first the UI options to pick the 1st asset to compare:
      textInput("asset_1", 
                label = "Select 1st asset of interest", 
                value = "eth"),
      textInput("asset_2", 
                label = "Select 2nd asset of interest", 
                value = "GOOG"),
      submitButton("Update View", icon("refresh")),
      
      # h6("Choose the date range for which you'd like data below:"),
      # dateRangeInput("dates", label = h3("Date range"), start = "2016-01-01", end = "2016-06-01"),
      wellPanel(
        helpText(a("Read the documentation and methodology here", 
                    href="https://github.com/pmaji/crypto-asset-comparison-tool/blob/master/README.md", target="_blank")
        )
      )
    ),
    # Show a plot of the generated distribution
    mainPanel(
      plotlyOutput("portfolio_perf_chart")
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  # get data in first step; output view in second step
  output$portfolio_perf_chart <- renderPlotly({
    base_data <- get_pair_data(asset_1 = input$asset_1,
                               asset_2 = input$asset_2, 
                               initial_investment = input$initial_investment)
    build_portfolio_perf_chart(base_data)
  })

}
# Run the application 
shinyApp(ui = ui, server = server)

