# cross-platform function to find chrome version.
find_chrome_v <- function(){
  
  if (Sys.info()['sysname'] == "Windows") {
    v <- system('reg query "HKEY_CURRENT_USER\\Software\\Google\\Chrome\\BLBeacon" /v version', intern=TRUE)[3] %>%
      gsub("[^0-9.-]", "", .)
  } else {
    v <- system("google-chrome --version", intern=T) %>% # added 'intern=T' to capture output as char vector
      gsub("[^0-9.-]", "", .)
  }
  
  if (!v %in% binman::list_versions("chromedriver")[[1]]) { # replaced OS specific name as mine was '$linux64'
    stop("Installed Chrome version is not listed under in binman::list_versions('chromedriver')\n
         Try updating Google Chrome...")
  }
  
  return(v)
  
}
