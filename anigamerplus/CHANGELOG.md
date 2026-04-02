# Changelog

## 0.0.1

Server_SSL.py
```bash
server = WSGIServer((host, port), app, handler_class=WebSocketHandler, certfile='/ssl/fullchain.pem', keyfile='/ssl/privkey.pem')
```
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

index.html login.html monitor.html register.html aniGamerPlus.js monitor.js 內絕對路徑改相對路徑

SSL功能改為另一個Port 因為ingress不能用SSL

Server.py
```bash
web_log_path = os.path.join(Config.get_working_dir(), 'configs', 'logs', 'web.log')
server = WSGIServer((host, port), app, handler_class=WebSocketHandler, certfile='/ssl/fullchain.pem', keyfile='/ssl/privkey.pem')
```