# EAlidaR
Package to download EA liDAR data


So this package is very much in development...

### key issue is:

In order to extract the relevant arc webmap object ID codes, I had hoped to use selenium (via docker) to drive the EA portal and iteratively upload the zipped shp files to the site and then scrape the codes.

Thse codes could then be saved in a database which would then allow for them to be called when a requested region intersects that shape.

However, I am struggling to get the upload to work - thisrequires either a drag and drop into the drop-area frame or input into the windows popup that appears when the upload button is clicked. However, I can't work out how to do this in selenium. Perhpas there is a Javascript insert that could be injected (such as the one in the javasrcipt folder)

Will return to this when I get time...
