# cross-platform function to find chrome version.
#'
#' This function automates the retrieval of the installed chrome driver version.
#'
#' @export
find_chrome_v <- function(){

  if (Sys.info()['sysname'] == "Windows") {
    v <- system('reg query "HKEY_CURRENT_USER\\Software\\Google\\Chrome\\BLBeacon" /v version', intern=TRUE)[3] %>%
      gsub("[^0-9.-]", "", .)
  } else if (Sys.info()['sysname'] == "Linux")  {
    v <- system("google-chrome --version", intern=T) %>% # added 'intern=T' to capture output as char vector
      gsub("[^0-9.-]", "", .)
  } else {
    stop("The `find_chrome_v()` function is not supported for this OS.
\n 1) if you have never run Rselenium before, install the chrome driver with
  `wdman::chrome()`
\n 2) Check your chrome version by opening chrome > settings > About Chrome
\n 3) Now run `binman::list_versions('chromedriver')` and pick the version
  which most closely matches your own chrome version.
\n 4) Make sure to include this version in the EAlidaR request. e.g.
  `get_area(Ashop_sf, 1, 'DTM', chrome_version='89.0.4389.23')`")
  }

  driver_check <- function(){

    tryCatch(expr = {
      n <- stringdist::amatch(v, binman::list_versions("chromedriver")[[1]], maxDist = 10)[1]
      v <- binman::list_versions("chromedriver")[[1]][n]

      message(sprintf("No exact chrome driver match was found using: %s
\nIf an error occurs run binman::list_versions('chromedriver')`
and try all options with the `chrome_verison` argument \n", v))

    },
    error=function(e){
      stop("Installed Chrome version is not listed under in binman::list_versions('chromedriver')
\n Try The following:
\n 1) Update Google Chrome... If this doesn't work then...
\n 2) Run `binman::list_versions('chromedriver')` and pick the version
  which most closely matches your own chrome version.
\n 3) Make sure to include this version in the EAlidaR request. e.g.
  `get_area(Ashop_sf, 1, 'DTM', chrome_version='89.0.4389.23')`")
    }, finally = {
      return(v)
    })
  }

  tryCatch(expr = {
    invisible(binman::list_versions("chromedriver")[[1]])
  }, error=function(e){
    message("Attempting to install chrome drivers...\n")
    wdman:::chrome_check(verbose=FALSE)
  })

  if (!v %in% binman::list_versions("chromedriver")[[1]]) {
    v <- driver_check()
  }
  return(v)

}


