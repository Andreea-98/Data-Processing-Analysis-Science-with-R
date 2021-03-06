############################################################################
###                         Al.I. Cuza University of Iași                ###
###            Faculty of Economics and Business Administration          ###
###       Department of Accounting, Information Systems and Statistics   ###
############################################################################
###
############################################################################
###             Data Processing/Analysis/Science with R                  ###
############################################################################
###
############################################################################
###            09b Packages for Exploratory Data Analysis                ###
### See also the presentation:
### https://github.com/marinfotache/Data-Processing-Analysis-Science-with-R/blob/master/09%20Exploratory%20Data%20Analysis/09%20Exploratory%20Data%20Analysis.pptx
############################################################################
## last update: 08.12.2020

library(tidyverse) 
library(corrr)
library(readxl)
# giving up scientific notation (1.6e+07)
options(scipen=999, digits=4)


############################################################################
###            Download the necessary data sets for this script
############################################################################

# all the files needed o run this script are available at:
# https://github.com/marinfotache/Data-Processing-Analysis-Science-with-R/tree/master/DataSets

# Please download the files in a local directory (such as 'DataSets') and  
# set the directory where you dowloaded the data files as the 
# default/working directory, ex:
setwd('/Users/marinfotache/Google Drive/R(Mac)-1 googledrive/DataSets')

############################################################################


#######################################################################
###	                              Agenda                           ###	
#######################################################################
###	  I. EDA with the `tidyverse`                                  ###	
###	  II. EDA with `DataExplorer` package                          ###	
###	  III. EDA with `inspectdf` package                          ###	
#######################################################################




#######################################################################
###	             I. EDA with the `tidyverse`                       ###	
#######################################################################

###                      Fuel Economy dataset(s) 
fuel_economy_2018 <- read_tsv("all_alpha_18.txt") %>%
     mutate (cty_l100km = round(235.214583333333 / as.numeric(`City MPG`),2),
          hwy_l100km = round(235.214583333333 / as.numeric(`Hwy MPG`),2),
          combined_l100km = round(235.214583333333 / as.numeric(`Cmb MPG`),2)) %>%
     mutate (manufacturer = word(Model)) %>%
     mutate(manufacturer = case_when(
          manufacturer == 'ACURA' ~ 'HONDA',
          manufacturer == 'ASTON' ~ 'ASTON MARTIN',
          manufacturer == 'ALFA' ~ 'FIAT',
          manufacturer %in% c('BUICK', 'CADILLAC', 'CHEVROLET',
               'GMC') ~ 'GENERAL MOTORS',
          manufacturer %in% c( 'DODGE', 'JEEP', 'RAM') ~ 'CHRYSLER',
          manufacturer == 'GENESIS' ~ 'HYUNDAI',
          manufacturer == 'INFINITI' ~ 'NISSAN',
          manufacturer == 'JAGUAR' |  
               str_detect (manufacturer, '(^LAND|^RANGE)|ROVER') ~ 'TATA MOTORS',
          manufacturer == 'LEXUS' ~ 'TOYOTA',
          manufacturer == 'LINCOLN' ~ 'FORD',
          manufacturer == 'MINI' ~ 'BMW',
          manufacturer == 'SMART' ~ 'MERCEDES-BENZ',
          TRUE ~ manufacturer)
     ) %>%
     select (Model:Fuel, `Veh Class`, `Air Pollution Score`, 
             `Greenhouse Gas Score`, SmartWay, cty_l100km:manufacturer)

glimpse(fuel_economy_2018)



#################################################################
## Task 1: Display the number missing values for each variable ## 
#################################################################

# one must take into account than `Cyl` has some `N/A` values
# (not NA, but 'N/A'):
missing_vals <- fuel_economy_2018 %>%
     map_int(., ~ sum(is.na(.) | . == 'N/A')) %>%
     tibble(variable = names(.), n_missing = .) %>%
     mutate (percent_missing = round(n_missing * 100 / 
               nrow(fuel_economy_2018), 2))


# or
missing_vals2 <- fuel_economy_2018 %>%
     purrr::map_df( ~ sum(is.na(.)))
#... continue...


# now, the plot
ggplot(missing_vals, 
     aes (x = variable, y = n_missing, fill = variable)) +
     geom_col() +
     coord_flip() +
     geom_text(aes(label = paste0(percent_missing, '%'), size = 3.5, 
               hjust = if_else(percent_missing > 3, 1.02, -0.03), 
               vjust = 0.5))  +
     theme(legend.position="none") + # this will remove the legend
     scale_y_continuous(limits = c(0,170), breaks = seq(0, 170, 20)) 
     


#################################################################
##     Task 2: Display the frequency (and the percent) of the  ##
##           values for each character/factor variable         ##
#################################################################

# first, compute the frequencies for each categorical variables and values
eda_factors <- fuel_economy_2018 %>%
     mutate_if(is.factor, as.character) %>%
     select_if(., is.character ) %>%
     mutate (id = row_number()) %>%
     pivot_longer(-id, names_to = "variable", values_to = "value" ) %>%
     mutate (value = coalesce(value, 'N/A')) %>%
     group_by(variable, value) %>%
     summarise (n_value = n()) %>%
     ungroup() %>%
     mutate (percent = round(n_value * 100 / nrow(fuel_economy_2018),2)) %>%
     arrange(variable, value)
View(eda_factors)

glimpse(eda_factors)

test <- eda_factors %>%
     filter (is.na(value))

test <- eda_factors %>%
     filter (value == 'N/A')


# plot only the factors with less than 20 distinct values 
eda_factors %>%
     group_by(variable) %>%
     summarise(n_of_values = n()) %>%
     filter (n_of_values < 20) %>%    
     ungroup() %>%
     select (variable) %>%
     inner_join(eda_factors) %>%
ggplot(., aes(x = value, y = n_value, fill = value)) +
     geom_col() +
     geom_text (aes(label = paste0(round(percent,0), '%'), 
                  vjust = if_else(n_value > 300, 1.5, -0.5))) +
    facet_wrap(~ variable, scale = "free") +
    guides(fill=FALSE) +
    theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1)) +
    theme(strip.text.x = element_text(size = 14)) +
    xlab("") + ylab("frequency") 



#################################################################
##    Task 3: Display the distribution (as histograms,         ##
##   density plots and boxplots) of each numeric variable      ##
#################################################################
glimpse(fuel_economy_2018)

num_variables <- fuel_economy_2018 %>%
     mutate (Displ = as.numeric(Displ), Cyl = as.integer(Cyl)) %>%
     select_if(., is.numeric ) %>%
     mutate (id = row_number()) %>%
     pivot_longer(-id, names_to = "variable", values_to = "value" ) 
View(num_variables)


# separate histogram for each numeric value; free scale
num_variables %>%
ggplot(., aes(x = value, fill = variable)) +
     geom_histogram() +
     facet_wrap(~ variable, scale = "free") +
     guides(fill=FALSE) +
     theme(axis.text.x = element_text(size = 9)) +
     theme(strip.text.x = element_text(size = 12)) +
     xlab("") + ylab("frequency") 


# boxplot (common scale)
num_variables %>%
ggplot(., aes(y = value)) +
     geom_boxplot() +
     facet_wrap(~ variable, nrow = 1) +
     guides(fill=FALSE) +
     xlab("") + ylab("value") +
     theme(axis.text.x = element_blank()) +
     scale_y_continuous(breaks = seq(0, 30, 1))



#################################################################
##    Task 4: Display the distribution (as histograms,         ##
##   density plots and boxplots) of `cty_l100km`,              ##
##   `hwy_l100km`, `Air Pollution Score` and                  ##
##   `Greenhouse Gas Score`,                                   ##
##   grouped on `Veh Class`                                    ##
#################################################################
glimpse(fuel_economy_2018)

df <- fuel_economy_2018 %>%
     transmute (cty_l100km, hwy_l100km, 
          air_pollution_score = `Air Pollution Score`,
          greenhouse_gas_score = `Greenhouse Gas Score`, 
          vehicle_class = `Veh Class`) %>%
     mutate (id = row_number()) %>%
     pivot_longer(c(-id, -vehicle_class),
                  names_to = "variable", values_to = "value" ) %>%
     arrange(variable, vehicle_class)
View(df)


# separate histogram for each numeric value; free scale
df %>%
ggplot(., aes(x = value, fill = variable)) +
     geom_histogram() +
     facet_wrap(. ~ variable + vehicle_class, ncol = 10) +
     guides(fill=FALSE) +
     theme(axis.text.x = element_text(size = 8)) +
     theme(strip.text.x = element_text(size = 8)) +
     xlab("") + ylab("frequency") 



# plot superimposed density curves
df %>%
ggplot(., aes(x = value, fill = vehicle_class, color = vehicle_class)) +
     geom_density(aes(alpha = 0.5)) +
     facet_wrap(. ~ variable, scales = "free") +
     theme(axis.text.x = element_text(size = 8)) +
     theme(strip.text.x = element_text(size = 12)) +
     xlab("") + ylab("frequency") 



#################################################################
##    Task 5: Display correlation  among numeric variables     ##
## with package `corrr` (part of tidymodels)
#################################################################


# display correlations
temp <- fuel_economy_2018 %>%
     select_if(is.numeric) %>%
     corrr::correlate()  # Create correlation data frame 
View(temp)


# ... a better look...
temp <- fuel_economy_2018 %>%
     select_if(is.numeric) %>%
     corrr::correlate() %>%
     # Focus on cor_df without 'cty_l100km' and 'hwy_l100km'            
     corrr::focus(-cty_l100km, -hwy_l100km, mirror = TRUE) %>%  
     corrr::rearrange() %>%  # rearrange by correlations
     corrr::shave() # Shave off the upper triangle for a clean result
View(temp)
     

# display even better... 
fashion(temp)


# the correlation plot
fuel_economy_2018 %>%
     select_if(is.numeric) %>%
     corrr::correlate() %>%
     corrr::rplot()


# the network plot
fuel_economy_2018 %>%
     select_if(is.numeric) %>%
     corrr::correlate() %>%
     network_plot(min_cor = .2)




#######################################################################
###	               II. EDA with `DataExplorer` package              ###	
#######################################################################

# currently (December 2020), `DataExplorer` package is not available 
# on CRAN, so it is not possible to install it with 
install.packages('DataExplorer') 

# Instead, try:
if (!require(devtools)) 
    install.packages("devtools")
devtools::install_github("boxuancui/DataExplorer")

library(DataExplorer)


#######################################################################
###	                       Fuel Economy DataSet                    ###	

## Basic information about data types and missing values

# ...as text...
temp <- DataExplorer::introduce(fuel_economy_2018)
View(temp)

# ... and as plot
plot_intro(temp)


## Missing values 
plot_missing(fuel_economy_2018)


#  Plot information about categorial/factor variables
DataExplorer::plot_bar(fuel_economy_2018)



# Plot histogram for all numeric variables
DataExplorer::plot_histogram(fuel_economy_2018)


# Plot density curves for all numeric variables
DataExplorer::plot_density(fuel_economy_2018)


## Plot the boxplots of variables `cty_l100km`, 
#  `hwy_l100km`, `Air Pollution Score` and  `Greenhouse Gas Score`,
#  #   grouped on `Veh Class` 

fuel_economy_2018 %>%
     transmute (cty_l100km, hwy_l100km, 
          air_pollution_score = `Air Pollution Score`,
          greenhouse_gas_score = `Greenhouse Gas Score`, 
          vehicle_class = `Veh Class`) %>%
     DataExplorer::plot_boxplot(., by = "vehicle_class")



## Plot correlations among numeric variables
glimpse(fuel_economy_2018)
fuel_economy_2018

fuel_economy_2018 %>%
     mutate (Displ = as.numeric(Displ), Cyl = as.integer(Cyl)) %>%
     select_if(., is.numeric ) %>%
     na.omit(.) %>%
     DataExplorer::plot_correlation()





# Create a report (on the default directory) as an HTML file (report.html)
config <- configure_report(
  add_plot_str = TRUE,
  add_plot_qq = FALSE,
  add_plot_prcomp = FALSE
)

getwd()
create_report(fuel_economy_2018 %>% na.omit(.), 
              config = config)



#######################################################################
###	               III. EDA with `inspectdf` package               ###	
#######################################################################
library(inspectdf)


##  Display the data types as text...
temp <- inspectdf::inspect_types(fuel_economy_2018)

#... and as chart
inspect_types(fuel_economy_2018) %>%
     show_plot ()


## Display the size of each column
inspect_mem(fuel_economy_2018) %>%
     show_plot ()


## Missing values 
inspect_na(fuel_economy_2018) %>%
     show_plot ()


#  Plot information about categorial/factor variables, 
#  showing only the prevalent value
inspect_imb(fuel_economy_2018) %>%
     show_plot ()


#  Plot information about categorial/factor variables, 
#  showing detailed information
inspect_cat(fuel_economy_2018) %>%
     show_plot ()



# Plot histogram for all numeric variables
inspect_num(fuel_economy_2018) %>%
     show_plot ()


# Plot correlations among numeric variables
fuel_economy_2018 %>%
     mutate (Displ = as.numeric(Displ), Cyl = as.integer(Cyl)) %>%
     select_if(., is.numeric ) %>%
     na.omit(.) %>%
     inspect_cor(.) %>%
     show_plot ()








