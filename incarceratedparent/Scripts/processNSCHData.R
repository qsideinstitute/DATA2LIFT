# -----------------------------------------------------------------------------
# Comparison of Two Estimates of Children with Incarcerated Parents by State
# Author: Zofia C. Stanley
# Date: Jan 23, 2024
#
# Description:
# This script reads, processes, and analyzes data regarding children with 
# incarcerated parents. It compares state-level estimates from the Annie E.
# Casey Foundation's National Survey of Children's Health (NSCH) and QSIDE's 
# estimate. The script generates maps for NSCH estimates, QSIDE estimates, 
# and the ratio of NSCH to QSIDE estimates. 
#
# -----------------------------------------------------------------------------

# Load required packages
library(readxl)
library(dplyr)
library(ggplot2)
library(maps)
library(scales)

load("RawData/PUMSRawData.Rdata")

# -------------------------------------------------------------
# Data Preparation
# -------------------------------------------------------------

# Read NSCH data from Excel file and reformat
file_path <- "incarceratedparent/RawData/nsch_data.xlsx"
nsch_data <- read_excel(file_path) %>%
  filter(TimeFrame == "2020-2021", DataFormat == "Number", LocationType == "State") %>%
  rename(state = Location, nsch_count = Data) %>%
  mutate(
    state = state.abb[match(state, state.name)], 
    nsch_count = as.numeric(nsch_count)
  ) %>%
  select(state, nsch_count)

pumaPopData <- rawPumsData %>%
  filter(AGEP <= 18) %>%
  group_by(ST) %>%
  summarise(total_pop = sum(PWGTP)) %>%
  select(ST, total_pop) %>%
  rename(state_code = ST) %>%
  ungroup()

# Create a lookup table for state FIPS codes
fipsLookup <- fips_codes %>%
  select(state, state_code) %>%
  unique 

# Merge PUMS data with FIPS codes to integrate geographical data
pumaPopData <- merge(pumaPopData, fipsLookup) %>%
  select(-state_code) 

# Compute children with incarcerated parent per 1,000 children (aged 15-17)
nsch_data <- merge(nsch_data, pumaPopData) %>%
  mutate(nsch_per_pop = nsch_count/(total_pop/1000)) %>%
  select(-total_pop)

# Read QSIDE data from CSV file and process
csv_file_path <- "incarceratedparent/ProcessedData/incarceratedParentDataByPUMA.csv"
qside_estimate <- read.csv(csv_file_path, stringsAsFactors = FALSE) %>%
  select(state, PUMA, count) %>%
  group_by(state) %>%
  summarise(qside_count = sum(count))

pumaPopData <- rawPumsData %>%
  filter(AGEP >= 15 & AGEP <= 17) %>%
  group_by(ST) %>%
  summarise(total_pop = sum(PWGTP)) %>%
  select(ST, total_pop) %>%
  rename(state_code = ST) %>%
  ungroup()

# Merge PUMS data with FIPS codes to integrate geographical data
pumaPopData <- merge(pumaPopData, fipsLookup) %>%
  select(-state_code) 

# Compute children with incarcerated parent per 1,000 children (aged 15-17)
qside_estimate <- merge(qside_estimate, pumaPopData) %>%
  mutate(qside_per_pop = qside_count/(total_pop/1000)) %>%
  select(-total_pop)

# Merge NSCH and QSIDE data, compute ratio
merged_data <- inner_join(nsch_data, qside_estimate, by = "state") %>%
  mutate(ratio = ifelse(qside_count == 0, NA, nsch_count / qside_count)) 

# Calculate national factor
national_factor <- sum(nsch_data$nsch_count) / sum(qside_estimate$qside_count)

# Compute the Pearson correlation coefficient
correlation_coefficient <- cor(merged_data$nsch_per_pop, merged_data$qside_per_pop, use = "complete.obs")

# Print the correlation coefficient
print(correlation_coefficient)

# Prepare map data with US states
states_map <- map_data("state") %>%
  mutate(
    state = state.abb[match(region, tolower(state.name))], 
  )
states_map <- states_map %>%
  mutate( index = seq_len(nrow(states_map)) )

# Merge your data with the map data
data_to_plot <- merge(states_map, merged_data, by = "state")
data_to_plot <- data_to_plot[order(data_to_plot$index), ]

# -------------------------------------------------------------
# Plotting
# -------------------------------------------------------------

#Function to create a theme for the maps
map_theme <- function() {
  theme_minimal() +
    theme(
      legend.position = "right",
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.text.x = element_blank(),
      axis.text.y = element_blank(),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      axis.ticks = element_blank(),
      panel.background = element_blank()
    )
}

# Plot 1: NSCH Estimate
p1 <- ggplot(data = data_to_plot, aes(x = long, y = lat, group = group, fill = nsch_count)) +
  geom_polygon(color = "white") +
  coord_fixed(1.3) +
  labs(
    fill = "Count",
    title = "Estimate of Children who Have Experienced Parental Incarceration",
    subtitle = "Ages 0 - 18",
    caption = "Source: Annie E. Casey Foundation Kids Count"
  ) +
  map_theme() +
  scale_fill_continuous(labels = label_comma())

# Plot 2: QSIDE Estimate
p2 <- ggplot(data = data_to_plot, aes(x = long, y = lat, group = group, fill = qside_count)) +
  geom_polygon(color = "white") +
  coord_fixed(1.3) +
  labs(
    fill = "Count",
    title = "Estimate of Children who Have an Incarcerated Parent",
    subtitle = "Ages 15 - 17",
    caption = "Source: QSIDE"
  ) +
  map_theme() +
  scale_fill_continuous(labels = label_comma())

# Plot 3: Ratio of Annie E. Casey Estimate to QSIDE Estimate
p3 <- ggplot(data = data_to_plot, aes(x = long, y = lat, group = group, fill = ratio)) +
  geom_polygon(color = "white") +
  coord_fixed(1.3) +
  labs(
    fill = "Ratio",
    title = "Annie E. Casey Estimate Divided By QSIDE Estimate",
    caption = "Sources: Annie E. Casey Foundation and QSIDE"
  ) +
  map_theme() +
  scale_fill_continuous(labels = label_comma())

p4 <- ggplot(merged_data, aes(x = nsch_per_pop, y = qside_per_pop)) +
  geom_point() +  # Add points
  geom_smooth(method = lm, se = FALSE, color = "blue") +  # Add a regression line
  labs(
    x = "Annie E. Casey Estimate per 1,000 Youth Aged 0-17",
    y = "QSIDE Estimate per 1,000 Youth Aged 15-17",
    title = "Comparative Analysis of Children with an Incarcerated Parent",
    subtitle = "State-Level Rates per Population"
  ) +
  theme_minimal()

# -------------------------------------------------------------
# Save Plots
# -------------------------------------------------------------

ggsave(plot = p1, filename = "incarceratedparent/Plots/NSCHCountMap.pdf", width = 10, height = 6, units = "in", bg = "white")
ggsave(plot = p2, filename = "incarceratedparent/Plots/QSIDECountMap.pdf", width = 10, height = 6, units = "in", bg = "white")
ggsave(plot = p3, filename = "incarceratedparent/Plots/NSCH_QSIDE_RatioMap.pdf", width = 10, height = 6, units = "in", bg = "white")
ggsave(plot = p4, filename = "incarceratedparent/Plots/NSCH_QSIDE_Scatter.pdf", width = 10, height = 6, units = "in", bg = "white")