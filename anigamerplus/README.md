# aniGamerPlus for Home Assistant Community Add-ons

## Home Assistant Add-ons版的巴哈姆特動畫瘋自動下載工具

### 使用說明

cookie.txt與UA需添加

cookie.txt 位置在 /addon_configs/fdd0cf77_anigamerplus 需手動添加 

可使用 [filebrowser](https://github.com/alexbelgium/hassio-addons/tree/master/filebrowser) 之類工具添加 cookie.txt 

cookie 獲取方法在 [原作者頁面](https://github.com/miyouzi/aniGamerPlus)

UA使用取Web控制臺獲取即可

如果要使用SSL，SSL憑證與私鑰請放在Let's Encrypt預設位置

（/ssl/fullchain.pem,/ssl/privkey.pem）以及

/addon_configs/fdd0cf77_anigamerplus/config.json 中  "SSL": false, 改為  "SSL": true,