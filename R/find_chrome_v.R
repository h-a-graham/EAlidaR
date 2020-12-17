
# function to find chrome version on windows.
find_chrome_v <- function(){

  if (Sys.info()['sysname'] == "Windows") {
    v <- system('reg query "HKEY_CURRENT_USER\\Software\\Google\\Chrome\\BLBeacon" /v version', intern=TRUE)[3] %>%
      gsub("[^0-9.-]", "", .)
  } else {
    v <- system("google-chrome --version") %>%
      gsub("[^0-9.-]", "", .)
  }

  if (!v %in% binman::list_versions("chromedriver")$win32){
    stop("Installed Chrome version is not listed under in binman::list_versions('chromedriver')\n
         Try updating Google Chrome...")
  }

  return(v)

}
