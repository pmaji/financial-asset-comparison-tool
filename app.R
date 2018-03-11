library(shiny)
library(xts)
library(quantmod)
library(zoo)
library(TTR)
library(magrittr)

# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel('FAANG Stock Chart Analysis'),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(
        h6("Welcome! This simple app is meant to provide you access to some basic analytical chart-visualization tools that I often use to make trading decisions with respect to the famed \'FAANG\' stocks."),
         radioButtons("stock", label = "Select stock of interest", choices = c("FB","AAPL","AMZN","NFLX","GOOGL")),
        h6("Choose the date range for which you'd like data below:"),
        dateRangeInput("dates", label = h3("Date range"), start = "2016-01-01", end = "2016-06-01"),
         wellPanel(
           helpText(a("Click here to connect with the author", href="https://www.linkedin.com/in/paulmjeffries/", target="_blank")
           )
         )
      ),
      # Show a plot of the generated distribution
      mainPanel(
         plotOutput("stockPlot")
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
   
   output$stockPlot <- renderPlot({
     Ticker = input$stock
     stopifnot(is.character(Ticker))
     Data <- getSymbols(Ticker, from=input$dates[1], to=input$dates[2], auto.assign = FALSE)
     Adj <- adjustOHLC(Data, symbol.name = Ticker)
     chartSeries(Adj, TA="addMACD();addBBands()", name = Ticker, theme = chartTheme("white"))
   })
}

# Run the application 
shinyApp(ui = ui, server = server)

