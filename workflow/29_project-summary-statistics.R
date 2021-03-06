# General and basic summary statistics for project

library(sf)
library(tidyverse)

surveyed_area <- 
  sf::st_read("data/data_output/surveyed-area-3310.gpkg", stringsAsFactors = FALSE)

ground_trees <- read_csv(here::here("analyses", "analyses_output", "deep-ground-tree-summary-by-site.csv"))

trees <- 
  sf::st_read(here::here("data", "data_drone", "L3b", "model-classified-trees_all.gpkg"), stringsAsFactors = FALSE)

trees_split <-
  trees %>% 
  split(f = trees$site)

trees_buffered <-
  trees_split %>% 
  lapply(FUN = function(x) {
    
    site <- unique(x$site)
    site_bounds <- surveyed_area[surveyed_area$site == site, ]
    site_bounds_buffer <- sf::st_buffer(site_bounds, -35)
    
    return(x[site_bounds_buffer, ])
  })

trees_3310 <-
  do.call("rbind", trees_buffered)

summary_table_by_site_ground <-
  ground_trees %>% 
  dplyr::mutate(ground_n_total = live_count + dead_count,
                ground_tpha_total = ground_n_total / 0.202343,
                ground_tpha_abco = abco_count / 0.202343,
                ground_tpha_cade = cade_count / 0.202343,
                ground_tpha_pipo_live = pipo_count / 0.202343,
                ground_tpha_pipo_and_dead = pipo_and_dead_count / 0.202343,
                ground_prop_mortality = dead_count / ground_n_total,
                ground_prop_mortality_pipo = pipo_count_dead / ground_n_total,
                ground_prop_mortality_nonhost = nonhost_count_dead / ground_n_total,
                ground_prop_mortality_abco = abco_count_dead / ground_n_total,
                ground_prop_pipo_live = pipo_count / ground_n_total,
                ground_prop_pipo_and_dead = pipo_and_dead_count / ground_n_total,
                ground_prop_abco = abco_count / ground_n_total,
                ground_prop_cade = cade_count / ground_n_total,
                ground_prop_nonhost_live = 1 - ground_prop_pipo_live,
                ground_prop_nonhost_all = 1 - ground_prop_pipo_and_dead) %>% 
  dplyr::rename(ground_qmd_pipo = pipo_qmd,
                ground_qmd_pipo_live_and_dead = pipo_live_and_dead_qmd,
                ground_qmd_pipo_and_dead = pipo_and_dead_qmd,
                ground_qmd_overall = overall_qmd,
                ground_qmd_dead = dead_qmd,
                ground_qmd_dead_pipo = pipo_dead_qmd,
                ground_qmd_live = live_qmd) 

summary_table_by_site <-
  trees_3310 %>%
  st_drop_geometry() %>%
  group_by(site) %>%
  summarize(air_n_total = n(),
            air_n_live = length(which(live == 1)),
            air_n_dead = length(which(live == 0)),
            air_prop_mortality = 1 - mean(live),
            air_n_pipo_live = length(which(species == "pipo" & live == 1)),
            air_n_pipo_and_dead = length(which(live == 0 | (species == "pipo" & live == 1))),
            air_n_abco = length(which(species == "abco")),
            air_n_cade = length(which(species == "cade")),
            air_prop_pipo_live = air_n_pipo_live / air_n_total,
            air_prop_pipo_and_dead = air_n_pipo_and_dead / air_n_total,
            air_prop_abco = air_n_abco / air_n_total,
            air_prop_cade = air_n_cade / air_n_total,
            air_prop_nonhost_live = 1 - air_prop_pipo_live,
            air_prop_nonhost_all = 1 - air_prop_pipo_and_dead,
            air_qmd_pipo = sqrt(sum(estimated_dbh[species == "pipo" & live == 1]^2) / air_n_pipo_live),
            air_qmd_pipo_and_dead = sqrt(sum(estimated_dbh[live == 0 | (species == "pipo" & live == 1)]^2) / air_n_pipo_and_dead),
            air_qmd_overall = sqrt(sum(estimated_dbh^2) / air_n_total),
            air_qmd_live = sqrt(sum(estimated_dbh[live == 1]^2) / air_n_live),
            air_qmd_dead = sqrt(sum(estimated_dbh[live == 0]^2) / air_n_dead))

summary_print_table <-
  summary_table_by_site %>% 
  dplyr::left_join(summary_table_by_site_ground, by = "site") %>% 
  dplyr::left_join(surveyed_area %>% st_drop_geometry(), by = "site") %>% 
  dplyr::mutate(air_tpha_total = air_n_total / buffered_survey_area,
                air_tpha_abco = air_n_abco / buffered_survey_area,
                air_tpha_cade = air_n_cade / buffered_survey_area,
                air_tpha_pipo_live = air_n_pipo_live / buffered_survey_area,
                air_tpha_pipo_and_dead = air_n_pipo_and_dead / buffered_survey_area,)

write_csv(summary_print_table, path = here::here("analyses", "analyses_output", "summarized-non-spatial-site-data.csv"))
