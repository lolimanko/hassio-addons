# Tribler add-on（bridge 版）

啟動後，側邊欄會出現 **Tribler**（Ingress），點進去就是 Web UI，不需要輸入 API 金鑰。

## 設定
| 選項 | 說明 |
|---|---|
| `api_key` | REST API 金鑰。留空會自動產生並寫在 add-on 日誌 |
| `download_dir` | 預設下載位置（預設 `/media/tribler`） |
| `log_level` | Tribler 日誌等級：`DEBUG` / `INFO` / `WARNING`（預設）/ `ERROR` / `CRITICAL`。`INFO` 會有大量內容探索與隧道訊息，除錯時才需要 |

`api_key` 只能包含英數字與 `. _ ~ -`。

## 網路（add-on 的「網路」頁面）
本版不使用 host network，只有下列埠會對應到主機：

| 容器埠 | 預設主機埠 | 用途 |
|---|---|---|
| 55574 TCP / UDP | 55574 | BitTorrent 與 DHT |
| 8090 UDP | 8090 | Tribler IPv8 / 匿名網路 |
| 8085 TCP | 關閉 | 直連 Web UI（選用） |

- **BT 的主機埠請維持 55574**：Tribler 對外宣告的是容器內的埠號，主機埠不同會讓別人連錯埠。
- 想用 `http://<HA-IP>:<埠>/ui/#/downloads/all?key=<API_KEY>` 直連，在「網路」頁面為 8085 填一個主機埠即可；不需要就留空。

## 路由器轉 port（想要有連入連線時）
把 **TCP + UDP 55574** 與 **UDP 8090** 轉到 HA 主機的區網 IP。
bridge 網路下 UPnP / NAT-PMP / 區網探索通常用不了，所以需要手動轉發。
**不要**轉 8085 與 8099。

## 注意
- 映像從原始碼自行建置（官方 Docker 映像只有 amd64）。預設 `TRIBLER_REF=main`，建議在 Dockerfile 改成穩定的 release tag。
- 設定存在 `/data`，下載存在 `/media`。
- Tribler 本身只聽 127.0.0.1:18085，對外一律經過內建 nginx：Ingress（8099，自動帶入 API 金鑰、只接受 Supervisor 172.30.32.2）與直連埠（8085）。
- 預設下載目錄與 BitTorrent 連入埠是在 Tribler 啟動後，透過它的 REST API 設定的；連入埠只有在值改變時才會重啟 Tribler 一次。
- 本 add-on 不修改 Tribler 的設定檔（Tribler 不會替不完整的設定檔補預設值）。
