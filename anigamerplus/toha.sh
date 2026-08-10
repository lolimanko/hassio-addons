sed -i "s/db_path = os.path.join(working_dir, 'aniGamer.db')/db_path = '\/config\/aniGamer.db'/g" aniGamerPlus.py
sed -i "s/logs_dir = os.path.join(Config.get_working_dir(), 'logs')/logs_dir = '\/config\/logs'/g" ColorPrint.py
sed -i "s/config_path = os.path.join(working_dir, 'config.json')/config_path = '\/config\/config.json'/g" Config.py
sed -i "s/sn_list_path = os.path.join(working_dir, 'sn_list.txt')/sn_list_path = '\/config\/sn_list.txt'/g" Config.py
sed -i "s/cookie_path = os.path.join(working_dir, 'cookie.txt')/cookie_path = '\/config\/cookie.txt'/g" Config.py
sed -i "s/logs_dir = os.path.join(working_dir, 'logs')/logs_dir = '\/config\/logs'/g" Config.py
sed -i "s/web_log_path = os.path.join(Config.get_working_dir(), 'logs', 'web.log')/web_log_path = '\/config\/logs\/web.log'/g" Dashboard/Server.py
sed -i "s/\.\.\///g" Dashboard/templates/index.html
sed -i "s/\.\.\///g" Dashboard/templates/login.html
sed -i "s/\.\.\///g" Dashboard/templates/monitor.html
sed -i "s/\.\.\///g" Dashboard/templates/register.html
sed -i "s/url: '\/uploadConfig',/url: 'uploadConfig',/g" Dashboard/static/js/aniGamerPlus.js
sed -i "s/url: '\/manualTask',/url: 'manualTask',/g" Dashboard/static/js/aniGamerPlus.js
sed -i "s/url: '\/sn_list',/url: 'sn_list',/g" Dashboard/static/js/aniGamerPlus.js
sed -i "s/ws+'\/\/'+window.location.host+'\///g" Dashboard/static/js/monitor.js
sed -i "s/127.0.0.1/0.0.0.0/g" Config.py