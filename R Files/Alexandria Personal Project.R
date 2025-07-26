library(rvest)
library(dplyr)
library(magrittr)
library(stringr)

options(timeout = max(100000, getOption("timeout")))

URL_1 <- "https://realestate.alexandriava.gov/index.php?action=address"
URL_2 <- "https://realestate.alexandriava.gov/index.php?StreetNumber=&text_street=&StreetName="

Data_1 <- read_html(URL_1)

A_Streets <- Data_1 %>% html_nodes("#coa-streets") %>% html_text()

A_Streets_Fix <- gsub("[\t\r\\n\n]", ' ', A_Streets)

Keep_Fixing <- gsub("  ", ",", A_Streets_Fix)

Fixed <- gsub(" ", "%5E", Keep_Fixing)

A_Streets_URL_List <- as.list(el(strsplit(Fixed, ",")))

Table_1 <- data.frame()

for (Address in A_Streets_URL_List) {
  
  Page <- 0
  
  while (TRUE) {
    
    URL_3 <- paste0(URL_2, Address, "&UnitNo=&Search=Search", "&CPage=", Page)
    
    Data_2 <- read_html(URL_3)
    
    A_Properties <- Data_2 %>% html_nodes("nobr") %>% html_text()
    
    A_Account_Num <- Data_2 %>% html_nodes("td~ td+ td .srchdt:nth-child(2)") %>% html_text()
    
    A_SQFT <- Data_2 %>% html_nodes("td+ td br~ .srchdt") %>% html_text()
    
    A_Current_Owner <- Data_2 %>% html_nodes("td:nth-child(1) .resultdthdr:nth-child(1)") %>% html_text()
    
    if (length(A_Properties) == 0) {
      
      break
      
    }
    
    Page_Data <- data.frame(A_Properties, A_Current_Owner, A_Account_Num, A_SQFT)
    
    Table_1 <- rbind(Table_1, Page_Data)
    
    Page <- Page + 1
    
    save(Table_1, file = 'AvaStreetsTable.RData')
    
  }
}

options(timeout = max(1000000, getOption("timeout")))

URL_4 <- "https://realestate.alexandriava.gov/detail.php?accountno="

if (file.exists('AvaBuildingLand.RData')) {
  
  load('AvaBuildingLand.RData')
  
} else {
  
  Table_2 <- data.frame()
}

processed_accounts <- Table_2$Num

if (file.exists("Ava_Streets_Table.csv")) {
  
  print('poop')
  
  Ava_Streets_Table <- read.csv("Ava_Streets_Table.csv", stringsAsFactors = FALSE)
  
  Account_Num <- unique(Ava_Streets_Table$A_Account_Num)
  
} 

not_processed_accounts <- setdiff(Account_Num, processed_accounts)

for (Num in not_processed_accounts) {
  
  URL_5 <- paste0(URL_4, Num)
  
  Data_3 <- read_html(URL_5)
  
  A_Levy_Year <- Data_3 %>% html_nodes(".clickme~ tr td:nth-child(1) .data , .clickme td:nth-child(1)") %>% html_text()
  
  if (length(A_Levy_Year) == 0) {
    
    next
    
  }
  
  A_Land_Value <- Data_3 %>% html_nodes(".data+ table td:nth-child(2) .data") %>% html_text()
  
  A_Building_Value <- Data_3 %>% html_nodes(".data+ table td:nth-child(3) .data") %>% html_text()
  
  A_Total_Value <- Data_3 %>% html_nodes(".data+ table td:nth-child(4) .data") %>% html_text()
  
  A_Zip_Code <- Data_3 %>% html_nodes(".notranslate+ .notranslate") %>% html_text()
  
  A_Zip_Code <- str_extract(A_Zip_Code, "\\b\\d{5}(?=\\b)")
  
  
  #valid_zip_codes <- c("22206", "22304", "22313", "22332", "22301", "22305", 
                       #"22314", "22333", "22302", "22311", "22320", "22334", 
                       #"22303", "22312", "22331")
  
  #if (!A_Zip_Code %in% valid_zip_codes) {
    
    #A_Zip_Code <- NA
    
  #}
  
  Updated_Table <- data.frame(Num, A_Levy_Year, A_Land_Value, A_Building_Value, A_Total_Value, A_Zip_Code)
  
  Table_2 <- bind_rows(Table_2, Updated_Table)
  
  save(Table_2, file = 'AvaBuildingLand.RData')
  
}

options(timeout = max(1000000, getOption("timeout")))

URL_4 <- "https://realestate.alexandriava.gov/detail.php?accountno="

if (file.exists("AvaSales.RData")) {
  load("AvaSales.RData")
} else {
  sales_table <- data.frame(
    num = character(),
    A_Sales_Year = character(),
    A_Sales_Value = character(),
    stringsAsFactors = FALSE
  )
}

# Get list of processed account numbers
processed_sales <- unique(sales_table$num)

# Get the remaining account numbers
all_accounts <- Ava_Streets_Table$A_Account_Num
remaining_accounts <- setdiff(all_accounts, processed_sales)

# Loop through only unprocessed account numbers
for (num in remaining_accounts) {
  
  URL_5 <- paste0(URL_4, num)
  Data_4 <- read_html(URL_5)
  
  A_Sales_Year <- Data_4 %>% html_nodes("h2+ table tr+ tr td:nth-child(1) .data") %>% html_text()
  A_Sales_Value <- Data_4 %>% html_nodes("h2+ table tr+ tr td:nth-child(2) .data") %>% html_text()
  
  if (length(A_Sales_Year) == 0 && length(A_Sales_Value) == 0) next
  
  max_len <- max(length(A_Sales_Year), length(A_Sales_Value))
  
  A_Sales_Year <- if (length(A_Sales_Year) < max_len) c(A_Sales_Year, rep(NA, max_len - length(A_Sales_Year))) else A_Sales_Year
  A_Sales_Value <- if (length(A_Sales_Value) < max_len) c(A_Sales_Value, rep(NA, max_len - length(A_Sales_Value))) else A_Sales_Value
  
  New_Updated_Table <- data.frame(
    num = rep(as.character(num), max_len),
    A_Sales_Year = A_Sales_Year,
    A_Sales_Value = A_Sales_Value,
    stringsAsFactors = FALSE
  )
  
  sales_table <- bind_rows(sales_table, New_Updated_Table)
  
  save(sales_table, file = 'AvaSales.RData')
}


options(timeout = max(1000000, getOption("timeout")))

if (file.exists("AvaBuildingDescriptions.RData")) {
  load("AvaBuildingDescriptions.RData")
} else {
  building_desc_table <- data.frame(
    num = integer(),
    A_Year_Built = character(),
    A_Construction_Quality = character(),
    A_Building_Condition = character(),
    A_HVAC = character(),
    A_Building_Type = character(),
    A_Gross_Building_Area = character(),
    A_Net_Leaseable_Area = character(),
    stringsAsFactors = FALSE
  )
}

# Get the list of already processed account numbers
processed_accounts <- building_desc_table$num

# Get all account numbers from the full table
all_accounts <- Ava_Streets_Table$A_Account_Num

# Filter to get only the remaining (unprocessed) account numbers
remaining_accounts <- setdiff(all_accounts, processed_accounts)

#building_desc_table <- data.frame()

for (num in remaining_accounts) {
  
  URL_6 <- paste0(URL_4, num)
  cat("Processing:", num, "\n")
  
  Data_5 <- read_html(URL_6)
  
  # Helper function to safely extract single value or return NA
  extract_or_na <- function(data, xpath) {
    result <- data %>%
      html_nodes(xpath = xpath) %>%
      html_text(trim = TRUE)
    if (length(result) == 0) NA else result
  }
  
  # Extract values from the Building Description section
  A_Year_Built <- extract_or_na(Data_5, "//span[contains(text(),'Year Built:')]/following-sibling::text()[1]")
  if (is.na(A_Year_Built)) next  # If no year built, skip this entry
  
  A_Construction_Quality <- extract_or_na(Data_5, "//span[contains(text(),'Construction Quality:')]/following-sibling::text()[1]")
  A_Building_Condition    <- extract_or_na(Data_5, "//span[contains(text(),'Building Condition:')]/following-sibling::text()[1]")
  A_HVAC                  <- extract_or_na(Data_5, "//span[contains(text(),'HVAC:')]/following-sibling::text()[1]")
  A_Building_Type         <- extract_or_na(Data_5, "//span[contains(text(),'Building Type:')]/following-sibling::text()[1]")
  A_Gross_Building_Area   <- extract_or_na(Data_5, "//span[contains(text(),'Gross Building Area')]/following-sibling::text()[1]")
  A_Net_Leaseable_Area    <- extract_or_na(Data_5, "//span[contains(text(),'Net Leaseable Area')]/following-sibling::text()[1]")
  
  # Construct the row and bind
  Building_Desc_Row <- data.frame(
    num = num,
    A_Year_Built = A_Year_Built,
    A_Construction_Quality = A_Construction_Quality,
    A_Building_Condition = A_Building_Condition,
    A_HVAC = A_HVAC,
    A_Building_Type = A_Building_Type,
    A_Gross_Building_Area = A_Gross_Building_Area,
    A_Net_Leaseable_Area = A_Net_Leaseable_Area,
    stringsAsFactors = FALSE
  )
  
  building_desc_table <- bind_rows(building_desc_table, Building_Desc_Row)
  
  save(building_desc_table, file = 'AvaBuildingDescriptions.RData')
}


write.csv(Table_2, file = 'AvaBuildingLand.csv')




### Do not run after this for now !!!

fill_na_zip_codes <- function(data) {
  
  for (i in 2:nrow(data)) {
    
    if (is.na(data$A_Zip_Code[i])) {
      
      data$A_Zip_Code[i] <- data$A_Zip_Code[i - 1]
      
    }
    
  }
  
  for (i in 1:(nrow(data) - 1)) {
    
    if (!is.na(data$A_Zip_Code[i]) && data$A_Zip_Code[i] != data$A_Zip_Code[i + 1] && is.na(data$A_Zip_Code[i + 1])) {
      
      data$A_Zip_Code[i + 1] <- data$A_Zip_Code[i]
      
    }
    
  }

  return(data)
}

Table_2 <- fill_na_zip_codes(Table_2)

URL_6 <- "https://realestate.alexandriava.gov/taxyr_detail.php?accountno="
  
options(timeout = max(100000, getOption(('timeout'))))

Table_3 <- data.frame()

uniqueNums <- unique(Table_2$Num)

for (num in uniqueNums) {
  
  URL_7 <- paste0(url6, num)
  
  Data_4 <- real_html(URL_7)
  
  years <- Data_4 %>% html_nodes(".data.clickme") %>% html_text()
  
  num_years <- length(years)
  
  year <- 2024
  
  for (i in 0:years) {
    
    URL_8 <- paste0(URL_7, num, "&taxyear=", year)
    
    year <- year - 1
    
    Data_5 <- read_html(URL_8)
    
    propTaxFirstHalf <- Data_5 %>%
                    html_nodes(".data:nth-child(4) td:nth-child(2)") %>%
                      html_text()
    
    propTaxFirstHalfNumeric <- as.numeric(gsub("[$,]", "", propTaxFirstHalf))
    
    propTaxSecondHalf <- Data_5 %>% html_nodes(".data:nth-child(9) td:nth-child(2)") %>% html_text()
    
    propTaxSecondHalfNumeric <- as.numeric(gsub("[$,]", "", propTaxSecondHalf))
    
    propTaxTotal <- propTaxFirstHalfNumeric + propTaxSecondHalfNumeric 
    
    updateTable_3 <- data.frame(num, year, propTaxTotal)
    
    Table_3 <- rbind(Table_3, updateTable_3)
    
  }
  
}


#take the column from table_2 containing all the unieque URL's for 
# account number and then string concatenate "&taxyear=2023" until
#it reaches a tax year with zero input and break to next

save(Table_1, file = 'Table.RData')

save(Table_2, file = 'New_Data.RData')

write.csv(Table_1, file = 'Ava_Streets_Table.csv')

write.csv(Table_2, file = 'ABuildingLand.csv')

write.csv(sales_table, file = 'Ava_Sales_Table.csv')

write.csv(building_desc_table, file = 'buildingdescriptions.csv')

load("C:/Users/barre/Alexandria Personal Project/AvaBuildingLand.RData")

load("C:/Users/barre/Alexandria Personal Project/.RData")
