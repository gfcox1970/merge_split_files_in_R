# Purpose:			Merges and Split files
# Created by:   Cox, Graham
# Created on:   2024-02-05

library(tidyverse)
library(readxl)

# Create constants ----

c_IMPORT_PATH <- "data/"
c_EXPORT_PATH <- "export/"
c_DIMENSIONS_PATH <- "dimensions/"
# Load data ----

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


# Load Dimension files ----

# Load list of actual division names
divisions_df <-
	read_csv(paste0(c_DIMENSIONS_PATH, "divisions.csv"), show_col_types = FALSE)

# Load list of actual supplier names
suppliers_df <-
	read_csv(paste0(c_DIMENSIONS_PATH, "suppliers.csv"), show_col_types = FALSE)

# Load list of actual project names
projects_df <-
	read_csv(paste0(c_DIMENSIONS_PATH, "projects.csv"), show_col_types = FALSE)

# Transform data ----

# Join three dimension tables into main data frame using inner_join
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

# Export data ----

df %>%

	# Group data by filename
	group_by(filename) %>%

	# Export data for each group to a csv file. Grouped column will be
	# dropped from the exported files.
	# use the .keep parameter set to TRUE to keep the grouped column
	group_walk( ~ write_csv(.x, .y$filename))
