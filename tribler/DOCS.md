# Tribler add-on

啟動後，側邊欄會出現 **Tribler**（Ingress），點進去就是 Web UI，不需要輸入 API 金鑰。

## 設定
| 選項 | 說明 |
|---|---|
| `api_key` | REST API 金鑰。留空會自動產生並寫在 add-on 日誌 |
| `api_port` | Tribler REST API / Web UI 連接埠（預設 8085） |
| `expose_api` | `true`：區網可用 `http://<HA-IP>:8085/ui/#/downloads/all?key=<API_KEY>` 直連；`false`：只聽 127.0.0.1，僅能從側邊欄存取（較安全） |
| `download_dir` | 下載位置（預設 `/media/tribler`） |

`api_key` 只能包含英數字與 `. _ ~ -`。

## 建議
側邊欄確定能用後，把 `expose_api` 改成 `false`，避免 API 埠暴露在區網。

## 注意
- 映像從原始碼自行建置（官方 Docker 映像只有 amd64）。預設 `TRIBLER_REF=main`，建議在 Dockerfile 改成穩定的 release tag。
- 設定存在 `/data`，下載存在 `/media`。
- Ingress 由內建 nginx 處理：自動帶入 API 金鑰、改寫頁面路徑，並只接受 Supervisor（172.30.32.2）連線。
