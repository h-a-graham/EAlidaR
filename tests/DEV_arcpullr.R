devtools::load_all()

Ashop_sf


install.packages('arcpullr')

AshopDTM <- arcpullr::get_image_layer(url='https://environment.data.gov.uk/image/rest/services/SURVEY/LIDAR_Composite_2m_DTM_2020_Elevation/ImageServer',
                            sf_object=Ashop_sf, format='png')
