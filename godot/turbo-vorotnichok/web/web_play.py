import sys, time
from playwright.sync_api import sync_playwright
url=sys.argv[1]; pre=sys.argv[2]
with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/opt/pw-browsers/chromium',args=['--use-gl=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    pg=b.new_page(viewport={'width':1280,'height':720}); logs=[]
    pg.on('pageerror',lambda e: logs.append('ERR '+str(e)))
    pg.goto(url); time.sleep(15)
    pg.mouse.click(375,155); time.sleep(0.5)
    pg.mouse.click(375,227); time.sleep(0.5)
    pg.screenshot(path=pre+'_a.png')
    pg.mouse.click(1018,450); time.sleep(3)
    pg.keyboard.press('Space'); time.sleep(0.2)
    pg.keyboard.down('Space'); time.sleep(0.05); pg.keyboard.up('Space')
    time.sleep(2.5); pg.screenshot(path=pre+'_b.png')
    print(logs)
    b.close()
