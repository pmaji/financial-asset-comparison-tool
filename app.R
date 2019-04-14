# import all necessary packages
library(shiny)
library(xts) # for xts objects
library(quantmod) # for the Yahoo finance imports
library(zoo) # for date rangling
library(TTR) # for stock analytic functions
library(htmlwidgets) # self-explanatory
library(data.table) # speeding up some matrix manipulation
library(rsconnect) # for publishing
library(plotly) # viz
library(plyr) # best practice to load plyr first and then dplyr
library(dplyr) # for pipes
library(tidyr) # for certain data transformation
library(shinythemes) # dashboard aesthetics 
library(PerformanceAnalytics) # analytic functions
library(DT) # speeding up some matrix manipulation
library(formattable) # for fancy tables 
library(shinydashboard) # self-explanatory
library(ggplot2) # for viz
library(reshape2) # data manipulaiton
library(scales) # time / date / axes scales 
library(lubridate) # date manipulation 

# source the Functions.R file, where all main functions are stored
source("Functions.R")


####################################
##############   UI   ##############
####################################


ui <- dashboardPage(
  skin="blue",
  
  dashboardHeader(
    title="Asset Comparison Tootlbox",
    titleWidth = 300
  ),
  
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      menuItem(
        "Walkthrough of how the app works",
        href="https://github.com/pmaji/crypto-asset-comparison-tool/blob/master/README.md",
        # https://rstudio.github.io/shinydashboard/appearance.html#icons for more icons
        icon=icon("github")
      ),
      menuItem(
        "Report a bug or make a request",
        href="https://github.com/pmaji/crypto-asset-comparison-tool/issues", 
        icon=icon("comment")
      ),
      menuItem(
        "Examine the code behind the app",
        href="https://github.com/pmaji/crypto-asset-comparison-tool", 
        icon=icon("code")
      ),
      
      hr(),
      
      div(
        style="text-align:center",
        "Use lowercase to input crypto assets.",
        br(),
        "Use uppercase for all others."
      ),
      
      
      br(),
      # UI options to pick the 1st asset to compare:
      selectInput(inputId = "asset_1a",
                  label = "Select 1st asset of interest:",
                  choices = symbol_list, 
                  selected = "eth", 
                  multiple = FALSE,
                  selectize = TRUE),
      # UI options to pick the 2nd asset to compare:
      selectInput(inputId = "asset_2a",
                  label = "Select 2nd asset of interest:",
                  choices = symbol_list, 
                  selected = "AMZN", 
                  multiple = FALSE,
                  selectize = TRUE),
      
      hr(),
      div(
        style="text-align:center",
        "1st date = date of initial investment",
        br(),
        "2nd date = last date in time series examined"
      ),
      dateRangeInput("port_dates1a",
                     label = "Choose date range of interest:", 
                     # default date shows past half year
                     start = Sys.Date()-183, 
                     end = Sys.Date()-3)
    )
  ),
  
  dashboardBody(
    
    # 1st row of boxes
    fluidRow(
      box(
        title="Portfolio Performance Chart", 
        # status sets color (primary, success, info, warning, danger)
        status="primary", 
        solidHeader = TRUE,
        plotlyOutput(outputId = "portfolio_perf_chart"), 
        height=500, 
        width=8
      ),
      box(
        title = "Portfolio Performance Inputs",
        status= "primary",
        solidHeader = TRUE,
        h5("This box focuses on portfolio value, i.e., how much an initial investment of the amount specified below (in USD) would be worth over time, given price fluctuations."),
        
        textInput(
          inputId = "initial_investment",
          label = "Enter your initial investment amount ($):",
          value = "1000"),
        
        hr(),
        
        h5("The slider below modifies the", a(href = "https://stats.stackexchange.com/questions/2002/how-do-i-decide-what-span-to-use-in-loess-regression-in-r", "smoothing parameter"), "used in the", a(href = "https://en.wikipedia.org/wiki/Local_regression", "LOESS function"), "that produces the lines on the scatterplot."),
        
        sliderInput(
          inputId = "port_loess_param",
          label = "Smoothing parameter for portfolio chart:",
          min = 0.1,
          max = 2,
          value = .33,
          step = 0.01,
          animate = FALSE
        ),
        
        hr(),
        h5("The table below provides metrics by which we can compare the portfolios. For each column, the asset that performed best by that metric is colored green."),
        
        height = 500, 
        width = 4
      )
    ),
    
    
    # 2nd row of boxes  
    fluidRow(
      box(
        title="Portfolio Performance Summary Table",
        status="primary",
        solidHeader = TRUE,
        formattableOutput("port_summary_table"),
        height = 175,
        width = 12
      )
    ),
    
    # 3rd row of boxes
    fluidRow(
      box(
        title="Investment Returns Chart", 
        status="success", 
        solidHeader = TRUE,
        plotlyOutput("asset_returns_chart"), 
        height=500, 
        width=8
      ),
      box(
        title = "Investment Returns Inputs",
        status= "success",
        solidHeader = TRUE,
        h5("This box focuses on", a(href = "https://www.investopedia.com/terms/r/rateofreturn.asp", "rate of return"), "calculated at the level of detail specified below."),
        
        selectInput(
          "period",
          label = "Period over which to calculate returns:",
          choices = c("daily", "weekly", "monthly", "quaterly", "yearly"),
          selected = "weekly"
        ),
        hr(),
        
        h5("The default smoothing parameter for the returns chart is slightly higher than the default for the portfolio performance chart given that returns data are generally aggregated."),
        br(),
        
        sliderInput(
          inputId = "asset_loess_param",
          label = "Smoothing parameter for returns chart:",
          min = 0.1,
          max = 2,
          value = .75,
          step = 0.01,
          animate = FALSE),
        
        br(),
        height = 500, 
        width = 4
      )
    ),
    
    
    # 4th row of boxes
    fluidRow(
      box(
        title="Variance-Adjusted Returns Chart", 
        status="warning", 
        solidHeader = TRUE,
        plotlyOutput("portfolio_sharpe_chart"), 
        height=500, 
        width=8
      ),
      box(
        title = "Variance-Adjusted Returns Inputs",
        status= "warning",
        solidHeader = TRUE,
        h5("This box focuses more specifically on the average rate of return in excess of the", a(href = "https://www.investopedia.com/terms/r/risk-freerate.asp", "risk free rate"), "per unit of volatility, as captured by variations of the", a(href = "https://en.wikipedia.org/wiki/Sharpe_ratio", "Sharpe Ratio."), "Be sure your chosen risk free rate matches up with your selected time period. Default is 30 basis points for the weekly risk free rate."),
        br(),
        br(),
        
        # risk free rates at link below; for monthly risk-free rate use 1 month treasury
        # https://www.treasury.gov/resource-center/data-chart-center/interest-rates/Pages/TextView.aspx?data=yield
        sliderInput(
          inputId = "Rf",
          label = "Choose risk free rate (as decimal):",
          min = -0.10,
          max = 0.10,
          value = (0.01/4),
          step = 0.001,
          animate = FALSE
        ),
        
        hr(),
        h5("The confidence level chosen is used in the", a(href = "https://cran.r-project.org/web/packages/SharpeR/vignettes/SharpeRatio.pdf", "Sharpe Ratio calculations.")),
        
        sliderInput(
          inputId = "p",
          label = "Choose confidence level (as decimal):",
          min = 0.1,
          max = 0.99,
          value = 0.95,
          step = 0.01,
          animate = FALSE
        ),
        
        br(),
        height = 500, 
        width = 4
      )
      
      
    )
  )
)



####################################
############   SERVER   ############
####################################

server <- function(input, output, session) {
  
  # utility functions to be used within the server; this enables us to use a textinput for our portfolio values
  exists_as_number <- function(item) {
    !is.null(item) && !is.na(item) && is.numeric(item)
  }
  
  # data-creation reactives (i.e. everything that doesn't directly feed an output)
  
  # first is the main data pull which will fire whenever the primary inputs (asset_1a, asset_2a, initial_investment, or port_dates1a change)
  react_base_data <- reactive({
    if (exists_as_number(as.numeric(input$initial_investment)) == TRUE) {
      # creates the dataset to feed the viz
      return(
        get_pair_data(
          asset_1 = input$asset_1a,
          asset_2 = input$asset_2a, 
          port_start_date = input$port_dates1a[1],
          port_end_date = input$port_dates1a[2],
          initial_investment = (as.numeric(input$initial_investment))
        )
      )
    } else {
      return(
        get_pair_data(
          asset_1 = input$asset_1a,
          asset_2 = input$asset_2a, 
          port_start_date = input$port_dates1a[1],
          port_end_date = input$port_dates1a[2],
          initial_investment = (0)
        )
      )
    }
  })
  
  
  react_port_summary_table <- reactive({
    # reshapes the data for a summary view
    return(
      build_summary_table(portfolio_data = react_base_data())
    )
    
  })
  
  
  react_asset_returns_list <- reactive({
    return(
      get_portfolio_returns(
        portfolio_data = react_base_data(),
        period = input$period
      )
    )
  })
  

simple_formatter <- function(){
    formatter("span",
              style = x ~ style(
                display = "inline-block",
                direction = "rtl",
                "border-radius" = "4px",
                "padding-right" = "2px",
                "background-color" = csscolor("darkslategray"),
                width = percent(proportion(x)),
                color = csscolor(gradient(x, "red", "green"))
              ))
  }
  
  react_formattable <- reactive({
    return(
      formattable(react_port_summary_table(), 
                  list(
                    "Asset Portfolio Max Worth" = simple_formatter(),
                    "Asset Portfolio Latest Worth" = simple_formatter(),
                    "Asset Portfolio Absolute Profit" = simple_formatter(),
                    "Asset Portfolio Rate of Return" = simple_formatter()
                    )
                  )
      )
    })
  
  
  
  # Now the reactives for the actual vizualizations
  output$portfolio_perf_chart <- 
    debounce(
      renderPlotly({
        data <- react_base_data()
        build_portfolio_perf_chart(data, port_loess_param = input$port_loess_param)
      }), 
      millis = 2000) # sets wait time for debounce
  
  
  output$port_summary_table <- 
    debounce(
      renderFormattable({
        # css color names taken from http://www.crockford.com/wrrrld/color.html
        react_formattable()
        
      }), millis = 2000) # sets wait time for debounce
  
  
  output$portfolio_sharpe_chart <-
    debounce(
      renderPlotly(
        {
          # building the sharpe ratio viz
          get_sharpe_ratio_plot(
            asset_returns_list = react_asset_returns_list(),
            Rf = input$Rf,
            p = input$p
          )
        }
      ), millis = 2000)
  
  output$asset_returns_chart <-
    debounce(
      renderPlotly(
        {
          # building the retrns ratio viz
          build_asset_returns_plot(
            asset_returns_list = react_asset_returns_list(), 
            asset_loess_param = input$asset_loess_param)
        }
      ), millis = 2000)
  
}

# Run the application 
shinyApp(ui = ui, server = server)

