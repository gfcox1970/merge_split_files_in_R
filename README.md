# Merging and Splitting Files using R

## Introduction

The purpose of this repository will show how 

- To merge mutliple MS Excel workbooks into one data frame using `R`
- Add new columns to the data frame
- Split the data frame into multiple new CSV files

## Create File Paths

```r
c_IMPORT_PATH <- "data/"
c_EXPORT_PATH <- "export/"
c_DIMENSIONS_PATH <- "dimensions/"
```

## Load Libraries

```r
library(tidyverse)
library(readxl)
```

## Load Data

The data from multiple MS Excel workbooks will be loaded into one data frame by using the `map` and `read_excel` functions. Once loaded the column names will be cleaned using the `clean_names()` function from the `janitor` package. The `order_id` column contains a string that is a concatenation of the values that represent the `division`, `supplier` and `order_id` for each row. This column will be split into three columns named `division_id`, `supplier_id` and `order_id`. 

```r
df <-

	# List files that need to be merged into data frame
	list.files (path = c_IMPORT_PATH,
							pattern = "*.xlsx",
							full.names = TRUE) %>%

	# use map_df and read_excel to import data and add to
	# data frame
	map_df(function(x)
		read_excel (x)) %>%

	# clean column names
	janitor::clean_names() %>%

	# split order_id column into three columns
	separate(
		col = order_id,
		sep = "_",
		into = c("division_id", "supplier_id", "id")
	)
```

# Load Dimension Files

The dimension files contain the full proper names for the three columns created using the `separate` function in the previous section. These will be loaded from CSV files held in the Dimensions sub-folder. these files will be used in the next section using the `inner_join` function.

```r
# Load list of actual division names
divisions_df <-
	read_csv(paste0(c_DIMENSIONS_PATH, "divisions.csv"), show_col_types = FALSE)

# Load list of actual supplier names
suppliers_df <-
	read_csv(paste0(c_DIMENSIONS_PATH, "suppliers.csv"), show_col_types = FALSE)

# Load list of actual project names
projects_df <-
	read_csv(paste0(c_DIMENSIONS_PATH, "projects.csv"), show_col_types = FALSE)
```

## Transform Data

Once data has been loaded, the following transformations will be performed.

- The three dimension tables loaded in the previous section will be joined to the main data frame using `inner_join` function. The common identifier columns will be dropped on joining
- A column named `invoice_year` added containing a year value based on the `invoice_date` column
- A column named `filename` containing a concatenation of the `c_EXPORT_PATH`, the prefix of `invoices_`, the value from the `invoice_year` column and the file extension of `.csv`
- Once the filename has been created, the `invoice_year` column will be dropped

```r
df <- df %>%

	# Join to divisions data frame
	inner_join(divisions_df) %>%

	# Join to suppliers data frame
	inner_join(suppliers_df) %>%

	# Join to projects data frame
	inner_join(projects_df) %>%

	# Select the required columns
	select(c(10, 11, 9, 4:8)) %>%

	# add new columns
	mutate(
		# Year column from invoice date
		invoice_year = year(invoice_date),

		# Filename column
		filename = paste0(c_EXPORT_PATH, "invoices_", invoice_year, ".csv")
	) %>%

	select(-invoice_year)
```

## Export Data

The data frame is now ready to be exported into separate CSV files using the `filename` column as the basis for the split of data. The data frame is grouped using the `group_by` function and then split into separate files using the `group_walk` function. Using this function will automatically drop the `filename` column from the data frame group. If this column is to be kept in the exported file, using the `.keep` parameter set to `TRUE`

```r
df %>%

	# Group data by filename
	group_by(filename) %>%

	# Export data for each group to a csv file.
	group_walk( ~ write_csv(.x, .y$filename))

```
