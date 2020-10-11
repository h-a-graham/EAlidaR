# EAlidaR
Package to download EA liDAR data


So this package is very much in development...

### key issue is:

Scraping workflow is now close to completion... Uses python slenium to interact with the Dfra portal.

plan is to upload each of the 10km OS grid tiles to the portal and retrive Arc Web Map object id.

then this will intercect 4 5km tiles which can then be selected and extracted - composing the url from the Arc ID.


Things that need adding: 
- argument for 'so far completed' tile dataframe - then seleciting all tiles not completed to continue with. (perhaps not required if everything goes siwmiingly but it won't.

- Then need to write a 'Get area' module which reads in either an sf object or sf-readable file and returns the raster (files) for the area - include option to crop to extent?

- update the url generation - will need to do spatial join between 5km (intersecting lidar extent) and 10km grid then send codes...
