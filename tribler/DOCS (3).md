# Tribler add-on

啟動後，側邊欄會出現 **Tribler**（Ingress），點進去就是 Web UI，不需要輸入 API 金鑰。

## 設定
| 選項 | 說明 |
|---|---|
| `api_key` | REST API 金鑰。留空會自動產生並寫在 add-on 日誌 |
| `api_port` | 直連 Web UI 的連接埠（預設 8085，僅 `expose_api` 為 `true` 時開放） |
| `expose_api` | `true`：區網可用 `http://<HA-IP>:8085/ui/#/downloads/all?key=<API_KEY>` 直連（由 nginx 對外提供）；`false`：不開直連埠，僅能從側邊欄存取（較安全） |
| `bt_port` | BitTorrent 連入埠（預設 55574，TCP 與 UDP 共用同一個號碼；`0` = 每次啟動隨機）。改變後 Tribler 會自動重啟一次讓新埠生效 |
| `download_dir` | 下載位置（預設 `/media/tribler`） |

`api_key` 只能包含英數字與 `. _ ~ -`。

## 路由器轉 port（選用）
本 add-on 使用 host network，不需要在 HA 設定 port 對應。想改善連入連線，請在路由器把 **TCP 與 UDP 55574**（或你設定的 `bt_port`）轉到 HA 主機的區網 IP。
不要轉 8085 / 8099（Web UI），那兩個只該在區網或透過 HA 存取。

## 建議
側邊欄確定能用後，把 `expose_api` 改成 `false`，避免 API 埠暴露在區網。

## 注意
- 映像從原始碼自行建置（官方 Docker 映像只有 amd64）。預設 `TRIBLER_REF=main`，建議在 Dockerfile 改成穩定的 release tag。
- 設定存在 `/data`，下載存在 `/media`。
- Tribler 本身只聽 127.0.0.1:18085，對外一律經過內建 nginx：Ingress（8099，自動帶入 API 金鑰、改寫頁面路徑，只接受 Supervisor 172.30.32.2）與選用的直連埠。
- 預設下載目錄與連入埠是在 Tribler 啟動後，透過它的 REST API 設定的；連入埠只有在值改變時才會重啟 Tribler 一次。
- 本 add-on 不修改 Tribler 的設定檔（Tribler 不會替不完整的設定檔補預設值）。
