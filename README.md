![Digging into the Data](/marcos-e1583171396664.png)
# TORONTO ACTIVE BUILDING PERMITS
Active Building Permits Dashboard built in R Shiny

This **[dashboard](https://permits.shafquatarefeen.com/)** allows users to dig into the City of Toronto's Open Permit Data to discover active permits in their locality. The entire blog post on how i coded this app can be found on [my Blog](https://www.shafquatarefeen.com/r-shiny-permits/).

[![The Dashboard](/dashboard.png)](http://permits.shafquatarefeen.com/)

The City of Toronto has a massive collection of [Open Data](https://open.toronto.ca/) that consists of anything from parking tickets to elections results. This is actual up to date information in multiple different formats. In other words, this data can be relevant in understanding the city and addressing key issues of the day.

## Building Permits – [Active Permits](https://open.toronto.ca/dataset/building-permits-active-permits/) (CSV) – Key Fields:
* PERMIT_NUM – Identifier for the Permit
* PERMIT_TYPE – Text categorizing the type of permit
* STRUCTURE_TYPE – Identifies that type of structure
* WORK – Overall type of work covered by the application
* ADDRESS – calculated string field by aggregating the number, name, type, direction and postal code
  * STREET_NUM
  * STREET_NAME
  * STREET_TYPE
  * STREET_DIRECTION
  * POSTAL
  * GEO_ID – unique ID that can be used to join the data to the Address Points data set to get Latitude and Longitude for mapping
* APPLICATION_DATE – The date the application was received by the City
* ISSUED_DATE – The date the permit was issued
* DESCRIPTION – Detailed description of the work
* EST_CONST_COST – Estimated cost for construction (not always a numeric field – needs to be cleaned)


## [Address Points](https://open.toronto.ca/dataset/address-points-municipal-toronto-one-address-repository/)
Key Fields:
* GEO_ID – unique ID
* LATITUDE – needed for mapping visualization
* LONGITUDE – needed for mapping visualization
The data is stored in a shape file and although R might have packages to deal with extracting data from those types files, I wanted to limit the number of packages used for this application. I used QGIS to convert the data in the shapefile to a csv. 
![QGIS](/qgis.png)
