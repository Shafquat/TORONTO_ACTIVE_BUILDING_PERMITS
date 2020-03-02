library(stringr)
library(shiny)
library(dplyr)
library(DT)
library(leaflet)

### Data Manipulation ###
  
# Load data
permit_data <- read.csv("C:\\Users\\sarefee\\Documents\\R\\20-02-25 Building Permits\\activepermits.csv")
geo_id_data <- read.csv("C:\\Users\\sarefee\\Documents\\R\\20-02-25 Building Permits\\GeoIDs.csv")

# Remove "DO NOT UPDATE OR DELETE THIS INFO FIELD" from EST_CONST_COST field
permit_data$EST_CONST_COST <- str_replace(permit_data$EST_CONST_COST,"DO NOT UPDATE OR DELETE THIS INFO FIELD","")

# Sort by Construction Cost
permit_data <- permit_data[order(permit_data$EST_CONST_COST, decreasing = TRUE),]

# Calculate the Time between Application and Issued date
permit_data$time_to_issue <- as.Date(as.character(permit_data$ISSUED_DATE), format="%m/%d/%Y")-
  as.Date(as.character(permit_data$APPLICATION_DATE), format="%m/%d/%Y")

# Create an Application Year Field
permit_data$APPLICATION_YEAR <- str_sub(permit_data$APPLICATION_DATE,-4,-1)


#remove extra whitespace from Street Direction field
permit_data$STREET_DIRECTION <- str_trim(permit_data$STREET_DIRECTION)

# Create an Address field
permit_data$ADDRESS <- ifelse(str_length(permit_data$STREET_DIRECTION)==0,
  paste0(permit_data$STREET_NUM," ",permit_data$STREET_NAME," ",permit_data$STREET_TYPE,
         ", ",permit_data$POSTAL),
  paste0(permit_data$STREET_NUM," ",permit_data$STREET_NAME," ",permit_data$STREET_TYPE,
         " ",permit_data$STREET_DIRECTION,", ",permit_data$POSTAL)
  )

# Inner join to get mapping coordinates for applicable GEO_IDs
pdwc <- merge(x=permit_data, y=geo_id_data, by="GEO_ID")

### Shiny Dashboard ###

# Data consolidation for optimized dashboard
#permit_data <- read.csv("activepermits_cleaned.csv")
#pdwc <- permit_data[complete.cases(permit_data$LATITUDE),]

# Define UI for app that creates a dashboard ----
ui <- fluidPage(
  
  # App title ----
  titlePanel("Toronto Active Building Permits"),
  HTML("<h5>Created by <a href=\'https://shafquatarefeen.com/\'>Shafquat Arefeen</a></h5><br>"),
  
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      
      # Input: Select Year ----
      sliderInput(inputId = "year", "Select a Year Range", min=1979, max=2020, value=c(1979, 2020), sep = ""),
      
      # Input: Select Work ----
      selectInput(inputId = "s_type", "Select Structure", choices=c("All", sort(unique(as.character(pdwc$STRUCTURE_TYPE))))),
      
      selectInput(inputId = "p_type", "Select a Permit Type", choices=c("All", sort(unique(as.character(pdwc$PERMIT_TYPE))))),
      
      selectInput(inputId = "w_type", "Select a Description of the Work", choices=c("All", sort(unique(as.character(pdwc$WORK))))),
      
      width = 3),
    
    # Main panel for displaying outputs ----
    mainPanel(
      
      
      # Let user know of mapping restriction ----
      h5("Map will only show top 20,000 results. Please use filters like shortening the date range"),     
      # Output: Map of Geo_IDs
      leafletOutput("mymap", height=520),
      h5("Note: Permits that did not have an active GEO_ID were excluded from the map."), 
      
      # Output: Table of Work Done ----
      dataTableOutput('table')
      
      
    )
  )
)

# Define server logic required to have an interactive dashboard ----
server <- function(input, output, session) {
  
  filtered <- reactive({
    rows <- (permit_data$APPLICATION_YEAR<=input$year[2] & permit_data$APPLICATION_YEAR>=input$year[1]) &
      (input$p_type == "All" | permit_data$PERMIT_TYPE==input$p_type) &
      (input$w_type == "All" | permit_data$WORK==input$w_type) &
      (input$s_type == "All" | permit_data$STRUCTURE_TYPE==input$s_type)
    permit_data[rows,,drop = FALSE] 
    
  })
  
  observeEvent(
    input$year,{
      updateSelectInput(session,"s_type",choices=c("All", sort(unique(as.character(filtered()$STRUCTURE_TYPE)))))
      updateSelectInput(session,"p_type",choices=c("All", sort(unique(as.character(filtered()$PERMIT_TYPE)))))
      updateSelectInput(session,"w_type",choices=c("All", sort(unique(as.character(filtered()$WORK)))))
    })
  
  observeEvent(
    input$p_type,{
      updateSelectInput(session,"w_type",choices=c("All", sort(unique(as.character(filtered()$WORK)))),
                        selected = input$w_type)
      updateSelectInput(session,"s_type",choices=c("All", sort(unique(as.character(filtered()$STRUCTURE_TYPE)))),
                        selected = input$s_type)
    })
  
  observeEvent(
    input$w_type,{
      updateSelectInput(session,"p_type",choices=c("All", sort(unique(as.character(filtered()$PERMIT_TYPE)))),
                        selected = input$p_type)
      updateSelectInput(session,"s_type",choices=c("All", sort(unique(as.character(filtered()$STRUCTURE_TYPE)))),
                        selected = input$s_type)
    })
  
  observeEvent(
    input$s_type,{
      updateSelectInput(session,"w_type",choices=c("All", sort(unique(as.character(filtered()$WORK)))),
                        selected = input$w_type)
      updateSelectInput(session,"p_type",choices=c("All", sort(unique(as.character(filtered()$PERMIT_TYPE)))),
                        selected = input$p_type)
    })
  
  observe({
    output$table <- renderDataTable(select(filtered(),PERMIT_NUM,ADDRESS,STRUCTURE_TYPE,PERMIT_TYPE,WORK,APPLICATION_DATE,ISSUED_DATE,time_to_issue,EST_CONST_COST,DESCRIPTION), 
                                    colnames=c("Permit #","Address","Structure","Permit Type","Work","Applied On","Issued On","Time to Issue (days)","Est. Cost ($)","Details"),
                                    options = list(pageLength = 6,columnDefs = list(list(
                                      targets = 9,
                                      render = JS(
                                        "function(data, type, row, meta) {",
                                        "return type === 'display' && data.length > 6 ?",
                                        "'<span title=\"' + data + '\">' + data.substr(0, 6) + '...</span>' : data;",
                                        "}")
                                    ))), callback = JS('table.page(3).draw(false);')
                                    #options = list(pageLength = 5, width="100%", scrollX = TRUE)
                                    , rownames= FALSE
    )
  })
  
  filtered_map <- reactive({
    rows <- (pdwc$APPLICATION_YEAR<=input$year[2] & pdwc$APPLICATION_YEAR>=input$year[1]) &
      (input$p_type == "All" | pdwc$PERMIT_TYPE==input$p_type) &
      (input$w_type == "All" | pdwc$WORK==input$w_type) &
      (input$s_type == "All" | pdwc$STRUCTURE_TYPE==input$s_type)
    #pdwc[rows,,drop = FALSE]
    head(pdwc[rows,,drop = FALSE],20000)
    
  })
  
  output$mymap <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$Stamen.TonerLite,
                       options = providerTileOptions(noWrap = TRUE)
      ) %>%
      addMarkers(lng=filtered_map()$LONGITUDE, lat=filtered_map()$LATITUDE, 
                 popup=paste("Address:", filtered_map()$ADDRESS, "<br>",
                             "Structure Type:", filtered_map()$STRUCTURE_TYPE, "<br>",
                             "Permit Type:", filtered_map()$PERMIT_TYPE, "<br>",
                             "Work:", filtered_map()$WORK, "<br>",
                             "Estimated Cost:",paste('$',as.integer(filtered_map()$EST_CONST_COST)), "<br>",
                             "Application Date:", filtered_map()$APPLICATION_DATE, "<br>",
                             "Issued Date:", filtered_map()$ISSUED_DATE, "<br>",
                             "Issued in:", filtered_map()$time_to_issue,"days"),
                 clusterOptions = markerClusterOptions()
      )
  })
}

# Create Shiny object
shinyApp(ui = ui, server = server)
