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

# trying to fix this damn shiny apps .io problem with dates 
# orig_locale <- Sys.getlocale("LC_TIME") 
# Sys.setlocale("LC_TIME", "C")
# Sys.setlocale("LC_TIME", orig_locale)


# source the Functions.R file
source("Functions.R")


# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel('Crypto / Non-Crypto Asset Comparison Tool'),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      h6("Welcome! This simple app is meant to allow you to quickly compare the historical performance of various crypto and non-crypto assets"),
      radioButtons("crypto", label = "Select crypto of interest", choices = c("btc","bch","ltc","eth")),
      h6("Choose the date range for which you'd like data below:"),
      textInput("stock", label = "Select non-crypto of interest", value = "SPY"),
      # dateRangeInput("dates", label = h3("Date range"), start = "2016-01-01", end = "2016-06-01"),
      wellPanel(
        helpText(a("Click here to connect with the author", 
                   href="https://www.linkedin.com/in/paulmjeffries/", target="_blank"),
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
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  # get data in first step; output view in second step
  output$portfolio_perf_chart <- renderPlotly({
    base_data <- get_pair_data(input$crypto,input$stock)
    build_portfolio_perf_chart(base_data)
  })

}
# Run the application 
shinyApp(ui = ui, server = server)

