suppressWarnings(library(stringr))
suppressWarnings(suppressPackageStartupMessages(library(tidyverse)))

out_files = list.files("output_data", full.names = T)
splt_dat = out_files[grep("spltcats", out_files)]
dro2scim = read.csv(splt_dat)

dro2scim %>% 
  group_by(Publication.Year) %>% 
  summarise(mean_qrtl = mean(Quartiles, na.rm = T)) %>% 
  ggplot(aes(x = Publication.Year, y = mean_qrtl)) +
    geom_point() + 
    geom_line()

dro2scim %>% 
  gather("count_type", "citations", c(Scopus.Citation.Count, Web.of.Science.Citation.Count)) %>% 
  ggplot(aes(x = SJR, y = citations, colour = count_type)) +
  geom_point()+
  geom_smooth(se=F)

dro2scim %>% 
  gather("count_type", "citations", c(Scopus.Citation.Count, Web.of.Science.Citation.Count)) %>% 
  group_by(Publication.Year) %>% 
  summarise(mean_cites = mean(citations, na.rm = T)) %>% 
  ggplot(aes(x = Publication.Year, y = mean_cites)) +
  geom_point() + 
  geom_line()


dro2scim %>% 
  group_by(Publication.Year) %>% 
  summarise(`H index` = mean(H.index, na.rm = T)) %>% 
  ggplot(aes(x = Publication.Year, y = `H index`)) +
  geom_point() + 
  geom_line()

dro2scim %>% 
  ggplot(aes(x = Publication.Year, y = H.index, group = Publication.Year)) +
  geom_boxplot()+
  geom_point()+
  theme_bw()

dro2scim$Quartiles = factor(dro2scim$Quartiles, levels = c(4:1))
dro2scim %>% 
  filter(!is.na(Quartiles)) %>% 
  ggplot(aes(x = Publication.Year, y = Quartiles, colour = Quartiles)) +
  geom_jitter()+
  theme_bw()+
  labs(x = "Publication year", title = "Journal quartiles")
