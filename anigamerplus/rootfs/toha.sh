#!/bin/bash
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
sed -i "s/ws+'\/\/'+window.location.host+\///g" Dashboard/static/js/monitor.js
sed -i "s/                    'host': '127.0.0.1',/                    'host': '0.0.0.0',/g" Config.py
                    
sed -i "s|settings\['bangumi_dir'\] = os.path.join(working_dir, 'bangumi')|settings['bangumi_dir'] = '/media/bangumi'|g" Config.py
sed -i "s|settings\['temp_dir'\] = os.path.join(working_dir, 'temp')|settings['temp_dir'] = '/media/temp'|g" Config.py

python3 <<'PY'
from pathlib import Path

path = Path("Dashboard/Server.py")
text = path.read_text()

start = text.index("def run():")
end = text.index("if __name__ == '__main__':")

new = """def run():
    settings = Config.read_settings()  # 读取配置

    if settings['dashboard']['BasicAuth']:
        # BasicAuth 配置
        app.config['BASIC_AUTH_USERNAME'] = settings['dashboard']['username']  # BasicAuth user
        app.config['BASIC_AUTH_PASSWORD'] = settings['dashboard']['password']  # BasicAuth password
        app.config['BASIC_AUTH_FORCE'] = True  # 全站验证
        basic_auth = BasicAuth(app)

    port = settings['dashboard']['port']
    host = settings['dashboard']['host']

    server = WSGIServer((host, 5000), app, handler_class=WebSocketHandler)

    server.serve_forever()


def run_ssl():
    settings = Config.read_settings()  # 读取配置

    if settings['dashboard']['BasicAuth']:
        # BasicAuth 配置
        app.config['BASIC_AUTH_USERNAME'] = settings['dashboard']['username']  # BasicAuth user
        app.config['BASIC_AUTH_PASSWORD'] = settings['dashboard']['password']  # BasicAuth password
        app.config['BASIC_AUTH_FORCE'] = True  # 全站验证
        basic_auth = BasicAuth(app)

    port = settings['dashboard']['port']
    host = settings['dashboard']['host']

    server = WSGIServer(
        (host, 5001),
        app,
        handler_class=WebSocketHandler,
        certfile='/ssl/' + os.environ.get('certfile'),
        keyfile='/ssl/' + os.environ.get('keyfile')
    )

    wrap_socket = server.wrap_socket
    wrap_socket_and_handle = server.wrap_socket_and_handle

    # 处理一些浏览器(比如Chrome)尝试 SSL v3 访问时报错
    def my_wrap_socket(sock, **_kwargs):
        try:
            return wrap_socket(sock, **_kwargs)
        except ssl.SSLError:
            pass

    # 此方法依赖上面的返回值, 因此当尝试访问 SSL v3 时, 这个也会出错
    def my_wrap_socket_and_handle(client_socket, address):
        try:
            return wrap_socket_and_handle(client_socket, address)
        except AttributeError:
            pass

    server.wrap_socket = my_wrap_socket
    server.wrap_socket_and_handle = my_wrap_socket_and_handle

    server.serve_forever()


"""

text = text[:start] + new + text[end:]

path.write_text(text)
print(f"已修改: {path}")
PY

python3 <<'PY'
from pathlib import Path

path = Path("aniGamerPlus.py")
text = path.read_text()

start = text.index("def run_dashboard():")
end = text.index("signal.signal(signal.SIGINT, user_exit)", start)

new = """def run_dashboard():
    # 检测端口是否占用
    if not port_is_available(settings['dashboard']['port']):
        err_print(0, 'Web控制面板啓動失敗', 'Port已被占用! 請到配置文件更換', status=1, no_sn=True)
        return

    if settings['dashboard']['host'] == '0.0.0.0':
        host = Config.get_local_ip()
    else:
        host = settings['dashboard']['host']

    from Dashboard.Server import run as dashboard

    server = threading.Thread(target=dashboard)
    server.daemon = True
    server.start()

    err_print(0, 'Web控制面板已啓動', no_sn=True, status=2)

    if os.environ.get('ssl') == 'true':
        from Dashboard.Server import run_ssl as dashboard_SSL

        Server_SSL = threading.Thread(target=dashboard_SSL)
        Server_SSL.daemon = True
        Server_SSL.start()

        err_print(0, 'SSL Web控制面板已啓動', no_sn=True, status=2)


"""

text = text[:start] + new + text[end:]

path.write_text(text)
print(f"已修改: {path}")
PY