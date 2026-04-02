# aniGamerPlus for Home Assistant Community Add-ons
## Home Assistant Add-ons版的巴哈姆特動畫瘋自動下載工具

cookie.txt 位置在 /addon_configs/fdd0cf77_anigamerplus 需手動添加 

可使用 [filebrowser](https://github.com/alexbelgium/hassio-addons/tree/master/filebrowser) 之類工具添加 cookie.txt 

cookie 獲取方法在 [https://github.com/miyouzi/aniGamerPlus](https://github.com/miyouzi/aniGamerPlus)

## 我改了以下檔案以符合ingress要求
Dockerfile
```bash
FROM python:3.9-slim
```
requirements.txt
```bash
gevent==22.10.1
```
aniGamerPlus.py
```bash
db_path = os.path.join(working_dir, 'configs','aniGamer.db')
```
ColorPrint.py
```bash
logs_dir = os.path.join(Config.get_working_dir(), 'configs', 'logs')
```
Config.py
```bash
config_path = os.path.join(working_dir, 'configs', 'config.json')
sn_list_path = os.path.join(working_dir, 'configs', 'sn_list.txt')
cookie_path = os.path.join(working_dir, 'configs', 'cookie.txt')
logs_dir = os.path.join(working_dir, 'configs', 'logs')
```
Server.py
```bash
web_log_path = os.path.join(Config.get_working_dir(), 'configs', 'logs', 'web.log')
server = WSGIServer((host, port), app, handler_class=WebSocketHandler, certfile='/ssl/fullchain.pem', keyfile='/ssl/privkey.pem')
```
index.html login.html monitor.html register.html aniGamerPlus.js monitor.js 內絕對路徑改相對路徑

## SSL功能開啟後ingress會失效
Server.py
```bash
server = WSGIServer((host, port), app, handler_class=WebSocketHandler, certfile='/ssl/fullchain.pem', keyfile='/ssl/privkey.pem')
```