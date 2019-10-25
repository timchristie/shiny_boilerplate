library(shiny)
library(shinydashboard)
source('misc/libraries.R', local = TRUE)

# Generate the UI Elements
dashboard.tabs <- dir('tabs', full.names = F)
dashboard.header <- dashboardHeader()
dashboard.sidebar <- dashboardSidebar(
  dashboardSidebar(
    sidebarMenu(
      id = 'tabs',
      sidebarMenuOutput("dashboardMenu")
    )
  )
)

dashboard.body <- dashboardBody(tags$head(
  # Uncomment this line if you want to use a custom css file. 
  # tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
), htmlOutput("dashboardTabs"))

ui <-
  dashboardPage(dashboard.header, dashboard.sidebar, dashboard.body)

server <- function(input, output, session) {
  
  dashboard.dbScriptLength <- length(dir('databases'))
  withProgress(message = "Running database requests", value = 0, {
    # run database functions. for loop is used to get dataframes into this scope.
    for (dbscript in dir("databases")) {
      tmp_dbscript <- paste("databases/", dbscript, sep = "")
      incProgress(1/dashboard.dbScriptLength, detail = tmp_dbscript)
      source(tmp_dbscript, local = TRUE)
    }
  })
  
  # run backend.R for each folder. lapply is used to avoid bringing variables into this scope.
  dashboard.tabScriptLength <- length(dir('tabs'))
  withProgress(message = "Running server side code", value = 0, {
    lapply(dashboard.tabs, function(tabName) {
      tmp_backend <- paste("tabs/", tabName, "/backend.R", sep = "")
      incProgress(1/dashboard.tabScriptLength, detail = tmp_backend)
      if(file.exists(tmp_backend)) {
        source(tmp_backend, local = TRUE)
      }
    })
  })
  
  # generate tab pages
  output$dashboardTabs <- renderUI({
    tabs <- lapply(dashboard.tabs, function(tab) {
      dashboard.temp_tabitem <- paste("tabs/", tab, "/frontend.R", sep ="")
      
      if(file.exists(dashboard.temp_tabitem)) {
        tabItem(tabName = tab, source(dashboard.temp_tabitem, local = TRUE)$value)
      } else {
        tabItem(tabName = tab, sidebarLayout(
          mainPanel = fluidRow(
            box(
              width = 4,
              title = 'Tab not found',
              HTML('The app could not find a frontEnd.R file in the tabs directory.')
            )
          ),
          sidebarPanel = fluidRow()
        ))
      }
    })
    tagAppendChild(tabItems(), tabs)
  })
  # generate menu
  output$dashboardMenu <- renderMenu({
    source('misc/menu.R', local = TRUE)
  })
  
  # set tab upon load to the 'example1' tab
  # TODO MAKE A 
  isolate({updateTabsetPanel(session, "tabs", "example1")})
  
}


shinyApp(ui, server)