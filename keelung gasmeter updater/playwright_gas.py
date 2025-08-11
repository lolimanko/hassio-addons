from playwright.sync_api import sync_playwright
import sys
import os
import time
import requests
#import shutil
from apscheduler.schedulers.background import BackgroundScheduler

def Gas():
    #print(sys.argv[1])
    j = requests.get('http://'+sys.argv[4]+'/json').json()
    print("查詢結果為"+j['main']['pre']+"，開始執行")
    if j['main']['pre'] != '':
        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page()
            page.goto("https://www.slgas.com.tw/Report_SQL.asp")
            page.locator("xpath=//input[@name='CusNo']").fill(sys.argv[1])
            page.locator( "xpath=//input[@name='CusName']").fill(sys.argv[2])
            page.locator( "xpath=//input[@name='Cuscallno']").fill(sys.argv[3])
            page.locator("xpath=//input[@name='Send']").click()
            page.locator( "xpath=//input[@name='CusDegree']").fill(j['main']['pre'])
            page.locator("xpath=//input[@name='send']").click()
            print("開始拍照")
            if os.path.isfile("/share/gas.png"):
                os.remove("/share/gas.png")
            page.screenshot(path="/share/gas.png")
    
    print("執行結束")
def main():
  #Gas()
  scheduler = BackgroundScheduler(timezone="Asia/Taipei")
  scheduler.add_job(Gas, 'cron', day=1)
  scheduler.start()
  while True:
    time.sleep(10) # 暫停10秒鐘
    #print('程式執行中.....')
    

if __name__ == '__main__':
    main()
