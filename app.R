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
library(shinydashboard)


# source the Functions.R file, where all functions for data importing, cleaning, and vizualization are written
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
        "Source code for app",
        href="https://github.com/pmaji/crypto-asset-comparison-tool/blob/master/README.md", 
        icon=icon("github")
        ),
      
      br(),
      hr(),
      
      div(
        style="text-align:center",
        "Use lowercase to input crypto assets.",
        br(),
        "Use uppercase for all others."
        ),
      
      # first the UI options to pick the 1st asset to compare:
      br(),
      selectInput(inputId = "asset_1a",
                  label = "Select 1st asset of interest:",
                  choices = symbol_list, 
                  selected = "eth", 
                  multiple = FALSE,
                  selectize = TRUE),
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
        width=8),
      box(
        title = "Portfolio Performance Inputs",
        status= "primary",
        solidHeader = TRUE,
        br(), 
        "Choose loess smoothing span parameter for portfolio chart:",
        br(),
        "(Default loess span = 0.33)",
        br(),
        br(),
        
        sliderInput(
          inputId = "port_loess_param",
          label = NA,
          min = 0.1,
          max = 2,
          value = .33,
          step = 0.01,
          animate = FALSE
          ),
        
        hr(),

        textInput(
          inputId = "initial_investment",
          label = "Enter your initial investment amount ($):",
          value = "1000"),
        
        br(),
        # submitButton("Update View", icon("refresh")),
        
        height = 500, 
        width = 4
        )
      
      ),
    
  
    # 2nd row of boxes  
    fluidRow(
      # formattable test
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
        # status sets color (primary, success, info, warning, danger)
        status="success", 
        solidHeader = TRUE,
        plotlyOutput("asset_returns_chart"), 
        height=500, 
        width=8),
      box(
        title = "Investment Returns Inputs",
        status= "success",
        solidHeader = TRUE,
        h5("This tab focuses on", a(href = "https://www.investopedia.com/terms/r/rateofreturn.asp", "rate of return,"), "and then, more specifically, the average rate of return in excess of the risk free rate, per unit of volatility, as captured by variations of the", a(href = "https://en.wikipedia.org/wiki/Sharpe_ratio", "Sharpe Ratio")),
        hr(),
        "Choose period over which to calculate returns:",
        br(),
        
        selectInput(
          "period",
          label = NA,
          choices = c("daily", "weekly", "monthly", "quaterly", "yearly"),
          selected = "weekly"
          ),
        br(),
        "Choose loess smoothing span parameter for returns chart:",
        br(),
        "(Default loess span = 0.75)",
        
        sliderInput(
          inputId = "asset_loess_param",
          label = NA,
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
        # status sets color (primary, success, info, warning, danger)
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
        br(),
        "Choose risk free rate (in same period of time as returns):",
        br(),
        "(Default 0.01 = 1% risk free rate)",
        br(),
        br(),
  
        # risk free rates at link below; for monthly risk-free rate use 1 month treasury
        # https://www.treasury.gov/resource-center/data-chart-center/interest-rates/Pages/TextView.aspx?data=yield
        sliderInput(
          inputId = "Rf",
          label = NA,
          min = -0.10,
          max = 0.10,
          value = (0.01/4),
          step = 0.001,
          animate = FALSE
        ),
        
        hr(),
        "Choose confidence level:",
        br(),
        "(Default 0.95 = 95 % confidence level)",
        br(),
        br(),
        
        sliderInput(
          inputId = "p",
          label = NA,
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
  
  # utility functions to be used within the server
  exists_as_number <- function(item) {
    !is.null(item) && !is.na(item) && is.numeric(item)
  }
  
  # data-creation reactives (i.e. everything that doesn't directly feed an output)
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
  
  react_formattable <- reactive({
    return(
      formattable(react_port_summary_table(), 
                  list(
                    "Asset Portfolio Max Worth" = formatter("span",
                                                            style = x ~ style(
                                                              display = "inline-block",
                                                              direction = "rtl",
                                                              "border-radius" = "4px",
                                                              "padding-right" = "2px",
                                                              "background-color" = csscolor("darkslategray"),
                                                              width = percent(proportion(x)),
                                                              color = csscolor(gradient(x, "red", "green"))
                                                            )),
                    "Asset Portfolio Latest Worth" = formatter("span",
                                                               style = x ~ style(
                                                                 display = "inline-block",
                                                                 direction = "rtl",
                                                                 "border-radius" = "4px",
                                                                 "padding-right" = "2px",
                                                                 "background-color" = csscolor("darkslategray"),
                                                                 width = percent(proportion(x)),
                                                                 color = csscolor(gradient(x, "red", "green"))
                                                               )),
                    "Asset Portfolio Absolute Profit" = formatter("span",
                                                                  style = x ~ style(
                                                                    display = "inline-block",
                                                                    direction = "rtl",
                                                                    "border-radius" = "4px",
                                                                    "padding-right" = "2px",
                                                                    "background-color" = csscolor("darkslategray"),
                                                                    width = percent(proportion(x)),
                                                                    color = csscolor(gradient(x, "red", "green"))
                                                                  )),
                    "Asset Portfolio Rate of Return" = formatter("span",
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
      
    )
  })
  
  

  # Now the reactives for the actual vizualizations
  output$portfolio_perf_chart <- 
    debounce(
      renderPlotly({
        build_portfolio_perf_chart(react_base_data(), port_loess_param = input$port_loess_param)
        }), 
      millis = 2000) # sets wait time for debounce
  
  
  output$port_summary_table <- 
    debounce(
      renderFormattable({
          # adds on all the formattable details
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
  
  # 3 step process to create main returns chart: create data, derive ratio, make viz
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

