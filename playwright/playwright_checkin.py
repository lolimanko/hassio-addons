from playwright.sync_api import sync_playwright
import time
import datetime
import sys
import os
import requests
import psycopg2
#import shutil
from apscheduler.schedulers.background import BackgroundScheduler

def SPF():
    web = requests.get('https://www.duckdns.org/update?domains=buvi&token=cfe38572-f0e1-429c-b870-d1bf77f10dbe&txt=v=spf1 a:buvi.duckdns.org/24 include:_spf.google.com a mx ~all&verbose=true')
    print(web.text)

def main():
  #start_playwright("N1820")
  #start_playwright_supervise("D0800")
  scheduler = BackgroundScheduler(timezone="Asia/Taipei")
  scheduler.add_job(start_playwright, 'cron', hour=6, minute=20, args=["D0620"])
  scheduler.add_job(start_playwright, 'cron', hour=11, minute=20, args=["D1100"])
  scheduler.add_job(start_playwright, 'cron', hour=18, minute=40, args=["D1840"])
  scheduler.add_job(start_playwright, 'cron', hour=2, minute=40, args=["N0240"])
  scheduler.add_job(start_playwright, 'cron', hour=6, minute=40, args=["N0640"])
  scheduler.add_job(start_playwright, 'cron', hour=18, minute=20, args=["N1820"])
  scheduler.add_job(start_playwright, 'cron', hour=19, minute=0, args=["N1900"])
  scheduler.add_job(start_playwright_supervise, 'cron', hour=8, minute=0, args=["D0800"])
  scheduler.add_job(start_playwright_supervise, 'cron', hour=17, minute=30, args=["D1730"])
  scheduler.add_job(SPF, 'cron', hour=0, minute=0)
  scheduler.start()
  while True:
    time.sleep(10) # 暫停10秒鐘
    #print('程式執行中.....')
    
def start_playwright(start_time):

    conn = psycopg2.connect(database="postgres", user="postgres", password="homeassistant", host="db21ed7f-postgres-latest", port="5432")

    with conn.cursor() as cursor:
        # 查詢資料SQL語法最後一筆資料
        print(start_time)
        if start_time[0] == "D" :
            command = "SELECT * FROM staff WHERE isdayshift = True"
        elif start_time[0] == "N" :
            command = "SELECT * FROM staff WHERE isdayshift = False"
        else :
            print("請輸入參數")
            return
        # 執行指令
        cursor.execute(command)
        # 取得所有資料
        result = cursor.fetchall()
        for row in result:
            yesterday = datetime.date.today() - datetime.timedelta(days = 1)
            today = datetime.date.today()
            now = datetime.datetime.now()         
            #print(yesterday.strftime('%Y-%m-%d'))
			#                             昨天是8小                                                 昨天不是8小 跟 昨天沒有放假                                                  今天沒有放假                                            今天不是8小     跟   今天不是放假                                     今天是8小                                       今天不是放假                                    今天是8小  

            if start_time=='N0240' and yesterday  in row[3] or start_time=='N0640' and yesterday not in row[3] and yesterday not in row[2] or start_time=='N1820' and today not in row[2] or start_time=='D0620' and today not in row[3] and today not in row[2] or start_time=='D1120' and today in row[3]  or start_time=='D1840' and today not in row[2] or start_time=='N1900' and today in row[3]:

                print(str(row[0])+"開始playwright")
                with sync_playwright() as p:
                  browser = p.chromium.launch()
                  page = browser.new_page()
                  page.goto("https://docs.google.com/forms/d/e/1FAIpQLSeqOLfL6zyM1sftWAnMZd0VlA6NK4e-9d0IU0QrviZkYfEkxg/viewform")
                  page.locator("xpath=//span[text()='服勤哨點編號']/../../../following-sibling::div[1]/div/div[1]/div/div[1]/input").fill('013517')
                  page.locator( "xpath=//span[text()='自己的員工編號']/../../../following-sibling::div[1]/div/div[1]/div/div[1]/input").fill(str(row[0]))
                  if start_time=='N1820' or start_time=='D0620' or start_time=='D1120' or start_time=='N1900' :
                    #page.locator( "xpath=//span[text()='打卡類型']/../../../following-sibling::div[1]/div/div/span/div/div[1]/label/div/div/div/div[3]/div").click()
                    page.locator( "xpath=//div[@data-value='上班打卡']").click()
                  elif start_time=='N0240' or start_time=='N0640' or start_time=='D1840' :
                    #page.locator( "xpath=//span[text()='打卡類型']/../../../following-sibling::div[1]/div/div/span/div/div[2]/label/div/div/div/div[3]/div").click()
                    page.locator( "xpath=//div[@data-value='下班打卡']").click()
                  if start_time=='N1820' or start_time=='N0240' or start_time=='N0640' or start_time=='N1900' :
                    page.locator( "xpath=//div[@data-value='夜班']").click()
                  elif start_time=='D0620' or start_time=='D1120' or start_time=='D1840' :
                    page.locator( "xpath=//div[@data-value='日班']").click()
                  page.locator("xpath=//span[text()='提交']/..").click()
                  pngfilename = now.strftime("%Y-%m-%d_%H:%M:%S")+'.png'
                  page.screenshot(path="/share/htdocs/"+row[0]+"/"+pngfilename)
                  if len(os.listdir("/share/htdocs/"+row[0]))>10:
                    os.remove("/share/htdocs/"+row[0]+"/"+sorted(os.listdir("/share/htdocs/"+row[0]))[0])
                    #print(os.listdir(row[0])[0])
            else:
                print(str(row[0])+"不開始playwright")
    cursor.close()
    conn.close()
    
def start_playwright_supervise(start_time):

    today = datetime.date.today().strftime("%Y/%m/%d")
    web = requests.get('https://api.pin-yi.me/taiwan-calendar/'+today)
    #print(web.json()[0]["isHoliday"])
    if web.json()[0]["isHoliday"] :
        print("isHoliday")
        return
    conn = psycopg2.connect(database="postgres", user="postgres", password="homeassistant", host="db21ed7f-postgres-latest", port="5432")

    with conn.cursor() as cursor:
        # 查詢資料SQL語法最後一筆資料
        print(start_time)
        command = "SELECT * FROM supervise"
        # 執行指令
        cursor.execute(command)
        # 取得所有資料
        result = cursor.fetchall()
        for row in result:

            now = datetime.datetime.now()         

            print(str(row[0])+"開始playwright")
            with sync_playwright() as p:
                browser = p.chromium.launch()
                page = browser.new_page()
                page.goto("https://docs.google.com/forms/d/e/1FAIpQLSdq3F8QTXQ69fTXLACBRRILk54X4GTMCWCfNT58CaUcp2dXKQ/viewform?pli=1")
                page.locator("//div[@role='listbox']").click()
                page.wait_for_timeout(1000)
                page.locator("//div[@role='option']//span[text()='台北營運處'][1]").click()
                page.wait_for_timeout(1000)

                page.locator( "xpath=//span[text()='員工編號']/../../../following-sibling::div[1]/div/div[1]/div/div[1]/input").fill(str(row[0]))
                #page.locator( "xpath=//div[text()='您的回答'][1]/../input[1]").fill(str(row[0]))
                
                if start_time=='D0800' :
                    page.locator( "xpath=//div[@data-value='上班']").click()
                elif start_time=='D1730' :
                    page.locator( "xpath=//div[@data-value='下班']").click()
                #page.locator("xpath=//span[text()='提交']/..").click()
                pngfilename = now.strftime("%Y-%m-%d_%H:%M:%S")+'.png'
                page.screenshot(path="/share/htdocs/supervise/"+pngfilename)
                if len(os.listdir("/share/htdocs/"+row[0]))>30:
                  os.remove("/share/htdocs/supervise/"+sorted(os.listdir("/share/htdocs/supervise"))[0])
                    #print(os.listdir(row[0])[0])

    cursor.close()
    conn.close()
if __name__ == '__main__':
    main()
