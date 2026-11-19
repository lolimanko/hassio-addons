# aniGamerPlus for Home Assistant Community Add-ons

## Home Assistant Add-ons版的巴哈姆特動畫瘋自動下載工具

### 使用說明

首次使用cookie,UA,JA3指紋,Akamai指紋需添加

在設定頁中需輸入cookie，UA、JA3指紋、Akamai指紋在Web UI內輸入

cookie、UA、JA3指紋、Akamai指紋獲取方法與config.json配置文件說明在 [原作者頁面](https://github.com/miyouzi/aniGamerPlus)

cookie會自動更新 cookie過時無法使用時 請輸入新cookie並開啟覆寫cookie後執行一次後關閉覆寫cookie

如要使用SSL請在設定頁中開啟SSL，設定好憑證檔名及私鑰檔名(都放在/ssl下)及輸入SSL Port

其餘設定可使用 [filebrowser](https://github.com/alexbelgium/hassio-addons/tree/master/filebrowser) 之類工具修改config.json

config.json  aniGamer.db  cookie.txt  logs 位置在 /addon_configs/fdd0cf77_anigamerplus 

如要使用MQTT功能需安裝[Mosquitto broker](https://github.com/home-assistant/addons/tree/master/mosquitto) 並在設定內開啟MQTT

完成下載後會送出MQTT訊息 自動化範本為automation.yaml
