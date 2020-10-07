from selenium import webdriver
from selenium.webdriver.support.ui import Select
import pyautogui
import pandas as pd
import math

from glob import glob
import time
import os
import re
from pathlib import Path
from datetime import datetime
import warnings


def scrapestuff(gecko_exe, work_dir):
  
  startTime = datetime.now() # start timer
  
  link = 'https://environment.data.gov.uk/DefraDataDownload/?Mode=survey'
  
  # work_dir = r.wd
  search_str = os.path.join(work_dir, 'data/grid_shp_zip/Tile_*.zip')
  zip_list = glob(search_str)
  zip_list = [str(Path(x)) for x in zip_list]
  # zip_list = zip_list[:3]  # Use this line for testing/debugging
  
  # we must chunk up the list to avoid the limit of 10 uploads per session...
  zip_chunks = chunks(zip_list, 10)

  # print(browser.title)
  fail_list = []
  dump_list = []
  
  for chunk in zip_chunks:
    # Set up Firefox browser
    browser = webdriver.Firefox(executable_path = gecko_exe)
    # browser.implicitly_wait(10)
    browser.get(link)
    time.sleep(20)
    
    for file in chunk:
      # get tile id number
      tile_n = int(re.search('Tile_(.*).zip', file).group(1))
      # print(tile_n)
      try:
        time.sleep(10)
        #click on upload button
        browser.find_element_by_css_selector('#buttonid').click()
        time.sleep(1)
        
        #send file to windows pop up
        pyautogui.write(file) 
        time.sleep(3)
        pyautogui.press('enter')
        time.sleep(6)
        
        # click 'get available tiles'
        browser.find_element_by_css_selector('.grid-item-container').click()
        time.sleep(45)
        
        #select DTM
        # browser.find_element_by_css_selector('#productSelect').click()
        
        select = Select(browser.find_element_by_css_selector('#productSelect'))
        time.sleep(3)
        select.select_by_visible_text('LIDAR Composite DTM')
        time.sleep(2)
          
        # get first link for download
        down_link = browser.find_element_by_css_selector('.data-ready-container > a:nth-child(1)').get_property('href')
        
        #retrieve arc object id from url
        result = re.search('interactive/(.*)/LIDARCOMP', down_link).group(1)
        
        #reset upload window
        browser.find_element_by_css_selector('div.result-options:nth-child(7) > input:nth-child(1)').click()
        
        
        # create pandas dataframe from results and append to list
        out_vals = [[tile_n, result]]
        scrape_out = pd.DataFrame(out_vals, columns=['tile_n', 'arc_code'])
        dump_list.append(scrape_out)
      
      
    
      except Exception as e:
        # Error handling - very general at the moment as I have no idea why errors will be thrown... Store tile number and Error in tuple and append to list...
        warnings.warn("Error has occurred for Tile {0}".format(tile_n))
        error_out = [[tile_n, str(e)]]
        error_out_pd = pd.DataFrame(error_out, columns=['tile_n', 'error_message'])
        fail_list.append(error_out_pd)
        
        pass
        
    browser.quit()
  
  # join list of pf dfs to single df
  try:
    combine_dfs = pd.concat(dump_list).reset_index(drop=True)
  except Exception:
    warnings.warn('No data to join - somethings gone horribly wrong!!!')
    combine_dfs = []
  
  try:
    combine_errs = pd.concat(fail_list).reset_index(drop=True)
    warnings.warn('Errors have occurred - check Error log with py$error_df')
  except Exception:
    print('No Errors Occurred - YAY!!')
    combine_errs = []
  
  endTime = datetime.now() - startTime
  
  print('Python Script completed in {0}'.format(endTime))
  
  return combine_dfs, combine_errs

def chunks(l, n):
    n = max(1, n)
    return (l[i:i+n] for i in range(0, len(l), n))  


