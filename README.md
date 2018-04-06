## Introduction

Welcome! The **Crypto Asset Comparison Tool** is a R Shiny App that faciliates the comparison of a myriad of assets--both traditional and crypto--across time. The idea for this tool came to me when I was trading crypto-currencies actively, and spending a decent amount of time in investor telegram chats and forums. A common argument I would see was over what asset one should have invested in a short while ago, but it was clear that most such discussions were fueled by emotion--primarily ["FOMO"](https://en.oxforddictionaries.com/definition/us/fomo), as opposed to testable metrics. This isn't just a popular type of discussion in the crypto investing space; in fact, it may be even more common in tradtional finance media. I wanted to create a tool that would be able to settle all such asset performance comparison questions, regardless of whether the question was about traditional assets such as equities, or cryptoassets like Bitcoin and Ethereum. 

The ultimate purpose of this tool is to settle every question of the form: "If I had *M* amount of money to invest over time period *T*, what would have been the better investment as judged by various metrics: *Asset A* or *Asset B*?" 

This tool is modular in nature, such that there are some parameters that affect the entire app, and others that only affect certain outputs. This allows the user, at a high level, to select assets of interest, a date-range of relevance, and an initial investment amount, and thereafter compare the chosen assets using a variety of techinques. The app faciliates this procedural evaluation by nature of its layout, such that there are sections that focus on portfolio value, returns, and risk-adjusted returns. Over the course of the rest of this document, we will walk through all of the features of the app one-by-one, explaining their purpose, functionality, along with any pertinent technical details. Read all the way through the final section to learn how you can support this project, and I hope this tool helps you to to make more informed financial decisions moving forward! 

FULL README IN PROGRESS; SCREENSHOTS BELOW FOR REFERENCE--explanation coming soon.

## Side-Bar UI Elements



<img src="https://raw.githubusercontent.com/pmaji/crypto-asset-comparison-tool/master/screenshots/ui_tab1.JPG" width="900" height="400">

<img src="https://raw.githubusercontent.com/pmaji/crypto-asset-comparison-tool/master/screenshots/ui_tab2.JPG" width="900" height="400">

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
