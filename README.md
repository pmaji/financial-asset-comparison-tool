## Introduction

Welcome! The **Crypto Asset Comparison Tool** is a R Shiny App that faciliates the comparison of a myriad of assets--both traditional and crypto--across time. The idea for this tool came to me when I was trading crypto-currencies actively, and spending a decent amount of time in investor telegram chats and forums. A common argument I would see was over what asset one should have invested in a short while ago, but it was clear that most such discussions were fueled by emotion--primarily ["FOMO"](https://en.oxforddictionaries.com/definition/us/fomo), as opposed to testable metrics. This isn't just a popular type of discussion in the crypto investing space; in fact, it may be even more common in tradtional finance media. I wanted to create a tool that would be able to settle all such asset performance comparison questions, regardless of whether the question was about traditional assets such as equities, or cryptoassets like Bitcoin and Ethereum. 

The ultimate purpose of this tool is to settle every question of the form: "If I had **M amount of money to invest** over **time period T**, what would have been the better investment as judged by various metrics: **Asset A** or **Asset B**?" 

This tool is modular in nature, such that there are some parameters that affect the entire app, and others that only affect certain outputs. This allows the user, at a high level, to select assets of interest, a date-range of relevance, and an initial investment amount, and thereafter compare the chosen assets using a variety of techinques. The app faciliates this procedural evaluation by nature of its layout, such that there are sections that focus on portfolio value, returns, and risk-adjusted returns. Over the course of the rest of this document, we will walk through all of the features of the app one-by-one, explaining their purpose, functionality, along with any pertinent technical details. In all screenshots of the app below, I will be using **Bitcoin (btc)** and **Ethereum (eth)** as the two assets to be compared. Read all the way through the final section to learn how you can support this project, and I hope this tool helps you to to make more informed financial decisions moving forward! 


## Sidebar UI Elements

Starting with the top-leftmost elements of the UI *(screenshot below)*, you can see that directly to the right of the title, there is an icon with three horizonal lines. Clicking this icon will expand or collapse the entire sidebar. Below the title you will find 3 hyperlinked buttons that will direct the user to this markdown document, this GitHub's issue page, and the code hosted on GitHub, in turn. 

<img src="https://raw.githubusercontent.com/pmaji/crypto-asset-comparison-tool/master/screenshots/title_links_bar.JPG" width="300" height="150">

The next segment of the sidebar *(screenshot below)* allows the user to choose which assets to compare. As is stated in the label, the lowercase assets are cryptoassets, and the uppercase assets are equities. This is done for two main reasons: visual identification, and avoidance of conflict. Visually it makes it easier at a glance to tell when you are comparing different types of assets, and, while it is rare, there are cases when there are cryptoassets and equities with the same ticker (i.e. one can compare "ETH" (Ethan Allen) the equity with "eth" (ethereum) the cryptocurrency).

<img src="https://raw.githubusercontent.com/pmaji/crypto-asset-comparison-tool/master/screenshots/asset_input_bar.JPG" width="300" height="200">

The final segment of the sidebar *(screenshot below)* allows the user to pick what date range to consider for the comparison of their chosen assets. The default is to show the most recent six months (i.e., had you invested the specified amount of money 6 months ago, this is how the assets would have performed to date). The one noteworthy caveat (which is evident from the code) is that the most recent date is always lagged by 3 days (i.e. if you are using the app on April 7th, the default will be to show 6 months of data from April 3rd and then back 6 months). I do this because the various APIs that I use sometimes have a lag, and also there are instances where the stock market is closed for Friday or Monday; hence, this lag is the minimum lag necessary to assure there are never cases of empty data caused by API lag and/or bank holidays.

<img src="https://raw.githubusercontent.com/pmaji/crypto-asset-comparison-tool/master/screenshots/date_range_bar.JPG" width="300" height="150">


## Portfolio Performance Section

The main time series chart shown *(screenshot below)* is rather intuitive: it simply shows the worth of two single-asset portfolios over time. In layman's terms, had you invested the same amount in both assets over the time series specified, this chart shows you the value of that investment over time. The default smoothing parameters were chosen arbitrarily to balance the tradeoff of resiliency vis-a-vis outliers and maintenance of fit, but can be changed as the user sees fit.

<img src="https://raw.githubusercontent.com/pmaji/crypto-asset-comparison-tool/master/screenshots/portfolio_box_ui.JPG" width="900" height="400">

The portfolio summary table *(screenshot below)* presents multiple aggregate metrics on which the two chosen assets can be judged. Each metric is its own column. For each column, the value in green is the value deemed optimal in terms of that particular metric. For example, the first column is "Asset Portfolio Max Worth"; hence, whichever asset had the highest max worth over the range specificed will have its value displayed in green, while the other will be displayed in red. The background within each cell is also a reactive bar chart, so that the magnitude of each cell can be judged at a glance relative to the magnitude of the other cell in that column. Continuing the previous example of the "Asset Portfolio Max Worth" column, if the two assets being compared have max worths of $1000 and $2000 respectively, the bar charts in each cell will be of length 50% of cell width and 100% of cell width, respectively. 

<img src="https://raw.githubusercontent.com/pmaji/crypto-asset-comparison-tool/master/screenshots/summary_box_ui.JPG" width="900" height="200">

## Rate of Return Section

The rate of return section *(screenshot below)* is entirely intuitive: it is simply a time series chart of the returns for the chosen asset over the period specified. 

<img src="https://raw.githubusercontent.com/pmaji/crypto-asset-comparison-tool/master/screenshots/returns_box_ui.JPG" width="900" height="400">

## Variance-Adjusted Return Section

The variance-adjusted return section *(screenshot below)* is a slightly more complicated additional set of metrics meant to supplement the base rate of return section. The parameter that allows the user to select the period over which to calculate rate of return (from the section above) also affects the variance-adjusted return section, as the three varieties of Sharpe Ratio are calculated over that same time period. One must be careful when choosing the Risk Free Rate, because that rate should be chosen relative to the time period selected (i.e. if you choose the vizualize "weekly" returns, your chosen risk-free rate should be a weekly risk free rate). Generally speeking, risk-free rates are chosen relative to some ["US treasury rate"](https://www.treasury.gov/resource-center/data-chart-center/interest-rates/Pages/TextView.aspx?data=yield), but it parameterized over a relatively wide range such that the user can choose whatever rate they see fit, within reason. 

The three varieties of Sharpe Ratio shown are pretty standard, the only difference being the denominators, which are variance (VaR), standard deviation (StdDev), and expected shortfall (ES), in turn.

<img src="https://raw.githubusercontent.com/pmaji/crypto-asset-comparison-tool/master/screenshots/sharpe_box_ui.JPG" width="900" height="400">

## Analytic Conclusions

The app is laid out in such a way that as you descend vertically, you follow a logical series of questions about value: 

1. At the top, we see the simplest view: how the price fluctuations of both assets would have affected the value of an initial investment amount over a specified time range.

2. Following the portfolio time series view, we see a summary table that allows the user to see which asset performs best according to a selection of aggregate metrics. 

3. Thereafter, we depart from metrics that depend on the initial amount invested, and begin addressing questions of return on investment. The first section focuses on the most vanilla definition of return on investment, while the final section allows the user to see if those rates of return are truly worth it given the variance, standard deviation, and expected shortfall inherent to the assets in question. This is put last because it enables the user to see, following the logic of the series of views from top to bottom, that even though a particular asset may have gross returns that are higher than another, and even a slightly more elevated rate of return, upon adjusting for variance, the other investment would have been a "better" choice.

## Support Needed

Below is a summary of the ways in which anyone interested can assist with / support the project :

1. Technical assistance and ideation:

     1. If you have coding experience, check out the code and issues tab and see if you can help with anything or propose new additions.
     
     2. If you want new features integrated or have any other ideas, open a new issue and I'll address it ASAP.

2. Donations appreciated for host-fees and development work:

     1. **ETH donations address: 0xF80Ca1F82Df6e3c4d6dca09b51AC78ED3E1D8E17**
     
     2. **BTC donations address (segwit): 3KKtEfqXQUNdh8mbEBT7ZBaiqLHRBZa4Gw**
     
     3. **LTC donations address: LWaLxgaBveWATqwsYpYfoAqiG2tb2o5awM**
     
3. Overall promotion:

     1. Keep sharing with you friends / fellow traders / coders so that we can get more constructive feedback.
     
     2. Consider starring us on GitHub as a means of sharing this project with the broader community.
     
## Contribution Rules

All are welcome to contribute issues / pull-requests to the codebase. All I ask is that you include a detailed description of your contribution, that your code is thoroughly-commented, and that you test your contribution locally with the most recent version of the Master branch integrated prior to submitting the PR. If you have further questions about collaboration, feel free to message me on Telegram (my public ID is the same as my GitHub ID).

**I hope that this explanation has proven helpful to you, and that you enjoy and benefit from my tool!** 
