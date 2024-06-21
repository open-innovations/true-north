nomis_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_141_1.data.csv?geography=1245709240...1245709350,1245715048,1245715058...1245715063,1245709351...1245709382,1245715006,1245709383...1245709577&date=latest&industry=37748736&employment_sizeband=0&legal_status=0&measures=20100&uid=",
  Sys.getenv("NOMIS_KEY")
)

nomis <- readr::read_csv(nomis_url, name_repair = tolower)

msoa11 <- sf::read_sf("~/Data/Geodata/Boundaries/msoa11_bsc.geojson")

dplyr::inner_join(
  msoa11,
  nomis,
  by = c("MSOA11CD" = "geography_code")
) |>
  ggplot2::ggplot(ggplot2::aes(fill = log(obs_value))) +
  ggplot2::geom_sf() +
  ggplot2::scale_fill_continuous(type = "viridis") +
  ggplot2::theme_void() +
  ggplot2::labs(
    title = "Number of local business units",
    fill = "Number of local business units"
  ) +
  ggplot2::theme(
    legend.position = "none",
    plot.title = ggplot2::element_text(hjust = 0.5)
  )

ggplot2::ggsave("working/cs/gm-local-business-units-msoa.png")
