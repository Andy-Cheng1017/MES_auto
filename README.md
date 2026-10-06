# MES Auto: 操作與維護手冊 / Operating and Maintenance Guide

本文件適用於此資料夾中的 LibreOffice Calc 工作簿、Basic 巨集、AutoHotkey 腳本及 BOM CSV。此工具會直接操作 MES，請先閱讀「執行前檢查」並以一筆核准的測試資料確認流程，再批次執行。

This guide covers the LibreOffice Calc workbook, Basic macros, AutoHotkey scripts, and BOM CSV files in this folder. The automation operates MES directly. Read the pre-run checklist and validate the process with one approved test record before batch processing.

## 目錄 / Contents

- [繁體中文](#繁體中文)
- [English](#english)

## 繁體中文

### 1. 專案內容

| 路徑 | 用途 |
| --- | --- |
| `MES_Auot.ods` | Calc 作業簿。主要資料表為 `FA_Report`，另有代碼資料庫及 BOM 設定/暫存表。檔名目前是 `MES_Auot`，請勿自行假設為 `MES_Auto`。 |
| `VBA/AHK.xba` | 匯出 MES 作業 JSON、歸檔及清除報表的 Basic 巨集來源。 |
| `VBA/DB_Normalized.xba` | BOM 標準化巨集來源。 |
| `VBA/FA_FuntionKey.xba` | `FA_Report` 輸入輔助、資料查找及照片處理巨集來源。 |
| `VBA/script.xlb` | `VBA` 巨集函式庫清單；由工作簿內的安裝巨集連結。 |
| `AHK/Exporting_Importing.ahk` | 從 JSON 逐筆將序號送入 MES 的簡易輸入腳本。 |
| `AHK/Repairing.ahk` | 從 JSON 逐筆輸入維修資料並執行儲存/返站流程的腳本。 |
| `AHK/FindText.ahk` | `Repairing.ahk` 使用的畫面文字/影像辨識函式庫。 |
| `AHK/_JXON.ahk` | AHK v2 的 JSON 讀取函式庫。 |
| `AHK/No_sleep.ahk` | 閒置時送出 F24 的選用腳本；不是 MES 作業必要元件。 |
| `BOM_Raw/` | 原始 BOM CSV 輸入資料。 |
| `BOM_Normalized/` | 標準化 BOM CSV；欄位為位號、版面、零件描述。 |
| `History/MES_Jobs.json` | AHK 共用的作業佇列。匯出巨集會覆寫此檔。 |
| `History/History.ods` | 歸檔巨集建立/追加的歷史資料檔；尚未歸檔時可能不存在。 |

請保留整個資料夾結構。巨集和 AHK 都以相對路徑尋找相鄰資料夾；搬動單一檔案會使路徑失效。

### 2. 必要條件與首次設定

1. 使用 Windows、LibreOffice Calc，以及 AutoHotkey v2。專案包含 AutoHotkey 2.0.19 安裝壓縮檔；若公司有核准版本，使用公司核准版本。
2. 將整個專案放在本機或公司核准的位置，確認 `MES_Auot.ods`、`VBA/script.xlb`、`AHK/`、`BOM_Raw/`、`BOM_Normalized/` 和 `History/` 都在同一專案根目錄。
3. 在 LibreOffice 開啟並儲存 `MES_Auot.ods`。依公司政策允許此文件的巨集執行；不要為此降低整台電腦的巨集安全設定。
4. 從 Calc 執行工作簿內建安裝巨集：**工具 > 巨集 > 執行巨集**，選擇 `MES_Auot.ods > Standard > Install_lib > InstallMESLibrary`，然後按「執行」。此巨集會將專案中的 `VBA/script.xlb` 連結為 LibreOffice 全域 `VBA` 函式庫。
5. 安裝完成後關閉所有 LibreOffice 視窗，再重新開啟工作簿。巨集程式庫是連結到目前資料夾；移動專案後需重新連結。
6. `InstallMESLibrary` 若發現全域已有名為 `VBA` 的函式庫，會先移除該函式庫再建立專案連結。若同事已使用其他同名全域函式庫，先備份並請 LibreOffice 管理者確認，再執行安裝。
7. 確認巨集選單中可找到 `VBA` 函式庫。`FA_Report` 的內容變更事件已設定為呼叫 `VBA.FA_FuntionKey.Main`；若程式庫未載入，輸入輔助不會正常工作。

安裝巨集依賴工作簿已儲存，且 `VBA/script.xlb` 位於工作簿同一層的 `VBA` 子資料夾。不要只複製 `.xba` 到其他位置後就假設已安裝。

### 3. 建議作業順序

1. **準備 BOM（需要查 BOM 時）**：先確認正確機種 BOM 已放入 `BOM_Normalized/`；若只有原始檔，先執行標準化（第 5 節）。
2. **填寫 `FA_Report`**：從第 2 列開始逐筆輸入，確認必填欄位、代碼及描述正確。輸入輔助會在欄位內容變更時觸發。
3. **檢查報表**：人工核對序號、故障/責任/維修代碼、位號、版面、症狀、原因、處置及返站站別。自動帶入只是一項建議，不代表 MES 已接受或資料正確。
4. **匯出作業佇列**：執行 `VBA > AHK > ExportMESJobsJson`。它會覆寫 `History/MES_Jobs.json`，只匯出從第 2 列起、A 欄序號連續不空白的資料；遇到第一個空白序號就停止。
5. **確認 JSON 佇列**：確認檔案存在、筆數及內容正確，並確認它是本次核准的作業，而非前次留下的資料。不得直接執行未檢查的舊佇列。
6. **執行適用的 AHK 腳本**：只執行目前流程需要的腳本；兩支腳本都讀取同一份 JSON，不要未確認流程就連續執行兩次。
7. **在 MES 人工驗證**：逐筆確認 MES 顯示及儲存結果。腳本沒有可靠的交易成功回執；批次結束不等於所有紀錄都成功。
8. **完成並確認後歸檔**：執行 `VBA > AHK > ArchiveData`。此動作會追加到 `History/History.ods`，成功後清除 `FA_Report` 第 2 列以下的內容。歸檔前請確認資料已保存且佇列已完成。

### 4. `FA_Report` 欄位與輸入輔助

欄名在第 1 列，資料從第 2 列開始。巨集依欄位位置運作，請勿任意移動或插入欄位。

| 欄 | 欄位 | 操作/用途 |
| --- | --- | --- |
| A | 序號 | 作業序號；匯出 JSON 的 `SN`。空白會停止匯出後續列。 |
| B | 不良原因代碼 | 依 `CP_Code_DB` 查碼並填入 C 欄描述；也可能依 `FaultCode_Default_DB` 建議責任/維修資料。 |
| C | 不良原因描述 | 由代碼資料庫帶入。 |
| D | 責任代碼 | 依 `Accountability_Code_DB` 查碼並填入 E 欄描述。 |
| E | 責任原因描述 | 由代碼資料庫帶入。 |
| F | 位號 | 依 `BOM_Setting` 的機種查找 BOM，將版面和零件描述填入 G、H 欄。 |
| G | 版面 | BOM 查找結果。 |
| H | 零件描述 | BOM 查找結果。 |
| I | 維修代碼 | 依 `Repair_Code_DB` 查碼並填入 J 欄描述。 |
| J | 維修描述 | 由代碼資料庫帶入；可作為維修處置建議的查找依據。 |
| K | 不良現象 | 由操作人員填寫。 |
| L | 不良原因 | 可依故障代碼、責任代碼及模板建議；請人工確認。模板支援 `{Location}`。 |
| M | 不良維修 | 可依維修描述及模板建議；請人工確認。模板支援 `{Location}`。 |
| N | 解回站點 | 依 `Station_DB` 查碼。一般維修 AHK 流程目前只處理 `FNT2` 或 `FNT7`。 |
| O | 小板號 | 選填；有值時會附加到 MES 維修描述。 |
| P | 照片 | 觸發目前的「匯入最新照片」巨集，詳見第 7 節。照片欄不會匯出到 MES JSON。 |

其他行為：

- B 欄若輸入**恰好一個空格**，輸入輔助會把前一列 B:N 的內容複製到本列；只在確定要複製時使用，並檢查複製後的資料。
- 故障碼預設值、略過欄位及原因/處置模板取決於工作簿中的資料庫工作表。代碼查不到時，不要自行假設帶入成功。
- BOM 機種名稱讀取自 `BOM_Setting` 的 B1。使用 `NormalizeBOM` 後此值會更新；若手動切換機種，請輸入不含 `.csv` 的檔名，例如 `PS_2442`。
- 巨集查找使用資料庫中的既有文字/代碼；請勿為了讓自動化「看起來成功」而省略必要的人工檢查。

### 5. BOM 標準化

目前資料夾中的原始 BOM 有 `BM_2802.csv`、`MF_2442.csv`、`PS_2442.csv`、`SP_2552_6D.csv`；標準化檔另有 `BM_2552.csv`。目前沒有 `BM_2552` 原始 CSV，因此不能用現有資料重新產生該檔。

1. 將供應來源 CSV 放入 `BOM_Raw/`，保留檔案名稱及原始資料備份。
2. 在 Calc 執行 `VBA > DB_Normalized > NormalizeBOM`。
3. 輸入原始檔名稱（可不含 `.csv`），例如 `PS_2442`。
4. 巨集會匯入至 `BOM_Raw_Import`、整理至 `BOM_Normalized_Import`，並輸出 `BOM_Normalized/<機種>.csv`；同名輸出檔會被覆寫。它也會更新 `BOM_Setting` 的 B1。
5. 開啟輸出檔確認標題為 `位號,版面,零件描述`，檢查筆數及代表性位號/描述，再用於作業。

標準化巨集會依來源格式找 `Part No`、`Description`、`Location` 標題，或依特定欄位位置與 `PC` 標記判斷格式。來源版型若改變，可能無法正確辨識；出現欄位錯誤或輸出異常時應停止使用，先檢查原始 CSV，不要把錯誤 BOM 用於 MES。

### 6. JSON 與 MES AHK 腳本

`ExportMESJobsJson` 依欄位位置輸出下列 JSON 屬性：

`SN`, `FaultCode`, `FaultDesc`, `RespCode`, `RespDesc`, `Location`, `Layer`, `PartDesc`, `RepairCode`, `RepairDesc`, `Symptom`, `RootCause`, `RepairAction`, `ReturnStation`, `BoardNo`。

AHK 腳本依賴 `History/MES_Jobs.json`，且預期資料夾結構維持原樣。腳本不會啟動 MES，也沒有安全的預覽/模擬模式。

#### `Exporting_Importing.ahk`

- 用途：從 JSON 逐筆將 `SN` 輸入 MES 序號欄並送出 Enter；不會填寫完整維修內容。
- 執行前開啟 MES 並切至正確畫面。腳本顯示「讀取完成」後按確定，並確認 MES 視窗仍是作用中視窗。
- 只適用於序號輸入作業；若需要完整維修登錄，使用 `Repairing.ahk`。

#### `Repairing.ahk`

- 用途：逐筆輸入序號、故障/責任/維修資訊、位號及描述，再執行儲存與返站或報廢流程。
- 執行前先開啟 MES，登入並切至正確的維修畫面；確認沒有未處理的對話框。此腳本沒有先確認 MES 視窗作用中的保護檢查。
- 一般維修返站目前只辨識 `FNT2` 和 `FNT7`。其他站別會出現錯誤提示，需停止並由操作人員處理。
- `RepairCode` 為 `*CIPS-PE-004*` 時會走特殊報廢對話框流程；執行前必須確認報廢資料及原因符合核准程序。
- 特定故障碼 `CP6008`、`CP6001`、`CP6045`、`CP6078` 會略過責任代碼欄位輸入。程式產生的維修描述格式為 `Layer/Location/Symptom, RootCause, RepairAction`，有小板號時另加小板序號。
- 儲存及返站按鈕部分依賴畫面辨識。螢幕解析度、縮放比例、MES 版面或按鈕外觀變更可能導致辨識失敗。

兩支腳本目前均將 `LogEnabled` 設為 `false`，因此預設不產生日誌；錯誤提示也不能取代 MES 交易結果檢查。每筆作業都要在 MES 人工確認，不要只依賴腳本結束訊息。

### 7. 照片與閒置腳本

- **照片功能需先調整**：`FA_FuntionKey` 的照片處理使用建立者個人 OneDrive 的固定路徑，尋找相機膠卷中最新的 `.jpg`，再將該檔案**移動**到以序號命名的目的地。這不是複製，也不會將照片嵌入工作簿。其他使用者在路徑尚未改成公司共用位置前，請勿使用此功能；使用前確認來源照片、序號及目的地無誤。
- `AHK/No_sleep.ahk` 每 10 秒檢查閒置時間，超過 60 秒會送出 F24 並短暫顯示提示。它不是 MES 流程必要元件，也不能取代公司核准的電源/閒置政策；未經 IT 核准不要執行。

### 8. 執行前安全檢查

- 使用核准的 MES 帳號、正確機台/站別及核准作業資料；先用一筆可控資料驗證。
- 關閉不相關的 MES 對話框，確認作用中視窗及輸入欄位；執行期間不要操作滑鼠/鍵盤或切換視窗。
- 檢查 JSON 內容和筆數、必填值、機種 BOM、返站站別及報廢條件。
- 匯出會覆寫 `MES_Jobs.json`；歸檔成功會清除 `FA_Report` 第 2 列以下資料。重要資料先依公司流程備份。
- 不要在未確認的佇列上執行 AHK，也不要以執行另一支腳本來重試可能已提交的 MES 交易；先查 MES 狀態以避免重複登錄。

### 9. 常見問題

| 狀況 | 檢查方式 |
| --- | --- |
| 找不到 JSON | 確認已執行 `ExportMESJobsJson`，且 `History/MES_Jobs.json` 存在、為有效 JSON；不要更動資料夾相對位置。 |
| AHK 顯示找不到欄位/控制項 | 確認使用 AutoHotkey v2、MES 已登入且在預期畫面；MES 更新可能改變控制項名稱，需由維護者更新腳本。 |
| 儲存按鈕或返站站別辨識失敗 | 確認解析度/縮放比例及 MES 視窗版面；停止批次並檢查該筆交易狀態。 |
| BOM 查不到零件 | 確認 `BOM_Setting!B1` 的機種名稱與 `BOM_Normalized/<機種>.csv` 完全相符，並確認位號存在。 |
| BOM 標準化輸出錯誤 | 確認原始 CSV 格式、`Part No`/`Description`/`Location` 標題或支援的 `PC` 欄位版型；保留原始檔並停止使用錯誤輸出。 |
| 輸入輔助沒有反應 | 確認已安裝全域 `VBA` 函式庫、已重新開啟 Calc、巨集允許執行，且正在編輯 `FA_Report`。 |
| 照片功能找不到/搬錯照片 | 停止使用；目前功能依賴建立者個人 OneDrive 固定路徑，且會移動最新 JPG。 |
| 歸檔後報表被清空 | `ArchiveData` 成功儲存歷史檔後會清除資料列；檢查 `History/History.ods`。若要單獨清除，`ClearFAReport` 不會先替你歸檔。 |

### 10. 巨集速查

| 巨集 | 用途與影響 |
| --- | --- |
| `VBA > AHK > ExportMESJobsJson` | 覆寫 `History/MES_Jobs.json`。 |
| `VBA > AHK > ArchiveData` | 追加至 `History/History.ods`；成功後清除報表資料列。 |
| `VBA > AHK > ClearFAReport` | 清除 `FA_Report` 第 2 列以下內容，不會先歸檔。 |
| `VBA > DB_Normalized > NormalizeBOM` | 讀取 `BOM_Raw`，覆寫同名標準化 CSV 並更新作用中機種。 |
| `VBA > FA_FuntionKey > Main` | 輸入事件使用的輔助入口；一般由 `FA_Report` 內容變更事件觸發。 |

## English

### 1. Project Contents

| Path | Purpose |
| --- | --- |
| `MES_Auot.ods` | Calc workbook. `FA_Report` is the main entry sheet; other sheets hold code databases and BOM settings/cache. The current filename is `MES_Auot`, not `MES_Auto`. |
| `VBA/AHK.xba` | Basic macro source for exporting the MES job JSON, archiving, and clearing the report. |
| `VBA/DB_Normalized.xba` | BOM normalization macro source. |
| `VBA/FA_FuntionKey.xba` | `FA_Report` input assistance, lookups, and photo handling macro source. |
| `VBA/script.xlb` | Library manifest for the `VBA` macro library; linked by the workbook's installer macro. |
| `AHK/Exporting_Importing.ahk` | Simple script that enters serial numbers from JSON into MES one by one. |
| `AHK/Repairing.ahk` | Script that enters repair data and performs the save/return-station workflow one job at a time. |
| `AHK/FindText.ahk` | Screen text/image recognition library used by `Repairing.ahk`. |
| `AHK/_JXON.ahk` | JSON reader library for AutoHotkey v2. |
| `AHK/No_sleep.ahk` | Optional script that sends F24 when idle; not required for MES processing. |
| `BOM_Raw/` | Source BOM CSV files. |
| `BOM_Normalized/` | Normalized BOM CSV files with reference designator, board/layer, and part description columns. |
| `History/MES_Jobs.json` | Shared job queue read by the AHK scripts. The export macro overwrites it. |
| `History/History.ods` | History file created/appended by the archive macro; it may not exist before the first archive. |

Keep the complete folder structure intact. The macros and AHK scripts resolve sibling folders by relative paths; moving individual files will break those paths.

### 2. Requirements and First-Time Setup

1. Use Windows, LibreOffice Calc, and AutoHotkey v2. An AutoHotkey 2.0.19 setup archive is included; use the company-approved version if one is required.
2. Place the complete project in a local or company-approved location. Keep `MES_Auot.ods`, `VBA/script.xlb`, `AHK/`, `BOM_Raw/`, `BOM_Normalized/`, and `History/` under the same project root.
3. Open and save `MES_Auot.ods` in LibreOffice. Allow this document's macros according to company policy; do not weaken computer-wide macro security for this project.
4. Run the workbook's installer macro from Calc: **Tools > Macros > Run Macro**, select `MES_Auot.ods > Standard > Install_lib > InstallMESLibrary`, then click **Run**. It links the project's `VBA/script.xlb` as LibreOffice's global `VBA` library.
5. When installation completes, close all LibreOffice windows and reopen the workbook. The macro library links to the current folder; moving the project requires relinking it.
6. If a global library named `VBA` already exists, `InstallMESLibrary` removes it before creating the project link. If a colleague uses another global library with that name, back it up and consult the LibreOffice administrator before installing.
7. Confirm that the `VBA` library is available in the macro list. The `FA_Report` content-changed event is configured to call `VBA.FA_FuntionKey.Main`; input assistance will not work correctly if the library is unavailable.

The installer requires the workbook to be saved and `VBA/script.xlb` to remain in the workbook's sibling `VBA` folder. Copying `.xba` files elsewhere does not install the library.

### 3. Recommended Workflow

1. **Prepare the BOM if needed:** Confirm that the correct model BOM exists in `BOM_Normalized/`. If only a raw CSV is available, normalize it first (Section 5).
2. **Fill in `FA_Report`:** Enter one record per row, starting on row 2. Verify required fields, codes, and descriptions. Input assistance runs when cell contents change.
3. **Review the report:** Manually verify serial numbers, fault/accountability/repair codes, reference designators, board/layer, symptom, root cause, action, and return station. Suggestions are not confirmation that MES accepted the data or that it is correct.
4. **Export the job queue:** Run `VBA > AHK > ExportMESJobsJson`. It overwrites `History/MES_Jobs.json` and exports rows from row 2 until the first blank serial number in column A.
5. **Review the JSON queue:** Confirm that the file exists and that its record count and contents match the approved jobs for this run. Do not run a stale queue from an earlier session.
6. **Run only the applicable AHK script:** Choose the script required by the current process. Both scripts read the same JSON file; do not run both back-to-back unless the workflow explicitly requires it.
7. **Verify results in MES:** Check the displayed and saved result for every record. The scripts do not provide a reliable transaction-success receipt; reaching the end of a batch does not mean every record succeeded.
8. **Archive only after verification:** Run `VBA > AHK > ArchiveData`. It appends to `History/History.ods` and, after a successful save, clears `FA_Report` content below row 1. Confirm that the data is saved and the queue is complete before archiving.

### 4. `FA_Report` Fields and Input Assistance

Headers are on row 1; records start on row 2. Macros depend on column positions, so do not move or insert columns.

| Column | Field | Operation / Purpose |
| --- | --- | --- |
| A | Serial number | Job serial number; exported as JSON `SN`. A blank cell stops export of later rows. |
| B | Fault code | Looked up in `CP_Code_DB` and described in C; may also trigger accountability/repair defaults from `FaultCode_Default_DB`. |
| C | Fault description | Populated from the code database. |
| D | Accountability code | Looked up in `Accountability_Code_DB` and described in E. |
| E | Accountability description | Populated from the code database. |
| F | Location | Looks up the model in `BOM_Setting` and fills board/layer and part description in G/H. |
| G | Board/layer | BOM lookup result. |
| H | Part description | BOM lookup result. |
| I | Repair code | Looked up in `Repair_Code_DB` and described in J. |
| J | Repair description | Populated from the code database; may be used to suggest a repair action. |
| K | Symptom | Entered by the operator. |
| L | Root cause | May be suggested from fault code, accountability code, and a template; verify it manually. Templates support `{Location}`. |
| M | Repair action | May be suggested from repair description and a template; verify it manually. Templates support `{Location}`. |
| N | Return station | Looked up in `Station_DB`. The current normal repair AHK flow handles only `FNT2` and `FNT7`. |
| O | Board serial number | Optional; appended to the MES repair description when present. |
| P | Photo | Triggers the current “import latest photo” macro; see Section 7. This column is not exported to the MES JSON. |

Additional behavior:

- Entering **exactly one space** in column B copies columns B:N from the previous row. Use this only when intended, then review the copied values.
- Fault-code defaults, skipped columns, and root-cause/action templates depend on the workbook's database sheets. Do not assume a code was populated if no database match exists.
- The active BOM model is read from `BOM_Setting!B1`. `NormalizeBOM` updates it. To switch models manually, enter the filename without `.csv`, for example `PS_2442`.
- Database lookups use existing text/code values. Manual review is still required even when the automation appears to complete normally.

### 5. BOM Normalization

The current raw BOM files are `BM_2802.csv`, `MF_2442.csv`, `PS_2442.csv`, and `SP_2552_6D.csv`. The normalized folder also contains `BM_2552.csv`; there is currently no `BM_2552` raw CSV available to regenerate it.

1. Place the source BOM CSV in `BOM_Raw/`, preserving its filename and a backup of the original.
2. In Calc, run `VBA > DB_Normalized > NormalizeBOM`.
3. Enter the raw filename, with or without `.csv`, for example `PS_2442`.
4. The macro imports the source into `BOM_Raw_Import`, transforms it into `BOM_Normalized_Import`, and writes `BOM_Normalized/<model>.csv`. An existing output with the same name is overwritten. It also updates `BOM_Setting` cell B1.
5. Open the output and confirm the headers are `位號,版面,零件描述`; check the row count and representative references/descriptions before using it.

The normalizer looks for source headers `Part No`, `Description`, and `Location`, or uses specific column positions and a `PC` marker for supported legacy layouts. If the source layout changes, the macro may not identify the data correctly. Stop and inspect the raw CSV if fields or output look wrong; do not use an incorrect BOM in MES.

### 6. JSON and MES AHK Scripts

`ExportMESJobsJson` exports these JSON properties by column position:

`SN`, `FaultCode`, `FaultDesc`, `RespCode`, `RespDesc`, `Location`, `Layer`, `PartDesc`, `RepairCode`, `RepairDesc`, `Symptom`, `RootCause`, `RepairAction`, `ReturnStation`, `BoardNo`.

The AHK scripts require `History/MES_Jobs.json` and the original folder structure. They do not launch MES and do not provide a safe preview or simulation mode.

#### `Exporting_Importing.ahk`

- Purpose: enters each JSON `SN` in the MES serial-number field and sends Enter; it does not enter the complete repair record.
- Open MES and navigate to the correct screen before running. After the “讀取完成” dialog appears, dismiss it and make sure the MES window is still active.
- Use this for serial-number entry only. Use `Repairing.ahk` when a full repair record is required.

#### `Repairing.ahk`

- Purpose: enters each serial number, fault/accountability/repair details, location, and description, then performs the save and return-station or scrap flow.
- Before running, open MES, sign in, and navigate to the correct repair screen. Resolve any open dialogs first. This script does not check that the MES window is active before starting.
- The current normal repair flow recognizes only `FNT2` and `FNT7`. Other stations produce an error prompt and require operator intervention.
- `RepairCode` equal to `*CIPS-PE-004*` selects a special scrap dialog flow. Confirm that the scrap data and reason follow the approved procedure before running it.
- Fault codes `CP6008`, `CP6001`, `CP6045`, and `CP6078` skip accountability-code entry. The script builds the MES repair description as `Layer/Location/Symptom, RootCause, RepairAction`, and appends the board serial number when supplied.
- Save and return-station controls partly depend on screen recognition. Changes to screen resolution, scaling, MES layout, or button appearance may prevent recognition.

Both scripts currently set `LogEnabled` to `false`, so they do not create logs by default. Prompts are not a substitute for checking MES transaction results. Verify every job manually in MES; do not rely only on the script's completion message.

### 7. Photo and Idle Scripts

- **The photo feature needs adaptation before use:** `FA_FuntionKey` uses a fixed OneDrive path belonging to the original author. It finds the newest `.jpg` in the camera-roll folder and **moves** that file to a serial-number-named destination. It does not copy the image or embed it in the workbook. Other users must not use this feature until the path is changed to an approved shared location. Verify the source photo, serial number, and destination first.
- `AHK/No_sleep.ahk` checks idle time every 10 seconds and sends F24 after more than 60 seconds of inactivity, with a brief tooltip. It is not required for MES processing and does not replace company-approved power/idle policies. Do not run it without IT approval.

### 8. Pre-Run Safety Checklist

- Use an approved MES account, the correct machine/station, and approved job data. Validate with one controlled record first.
- Close unrelated MES dialogs and confirm the active window and input screen. Do not use the mouse/keyboard or switch windows while automation is running.
- Review JSON contents and count, required values, model BOM, return station, and scrap conditions.
- Export overwrites `MES_Jobs.json`; successful archiving clears `FA_Report` rows below row 1. Back up important data according to company procedures.
- Do not run an unreviewed queue or rerun another script for a transaction that may already have been submitted. Check MES first to avoid duplicate entries.

### 9. Troubleshooting

| Symptom | Checks |
| --- | --- |
| JSON not found | Run `ExportMESJobsJson`; confirm `History/MES_Jobs.json` exists and is valid JSON. Keep the relative folder structure unchanged. |
| AHK cannot find a field/control | Confirm AutoHotkey v2, MES sign-in, and the expected screen. An MES update may change control names; the maintainer may need to update the script. |
| Save button or return station not recognized | Check screen resolution/scaling and MES layout. Stop the batch and check the affected transaction status. |
| BOM lookup returns no part | Confirm `BOM_Setting!B1` exactly matches `BOM_Normalized/<model>.csv` and that the reference exists. |
| BOM normalization output is wrong | Check the raw CSV layout, the `Part No`/`Description`/`Location` headers, or the supported `PC`-marker layout. Keep the source and stop using the bad output. |
| Input assistance does not respond | Confirm the global `VBA` library is installed, Calc was restarted, macros are allowed, and the active sheet is `FA_Report`. |
| Photo feature cannot find/moves the wrong image | Stop using it. It depends on the original author's fixed OneDrive path and moves the newest JPG. |
| Report was cleared after archiving | `ArchiveData` clears report rows after successfully saving the history file. Check `History/History.ods`. `ClearFAReport` clears without archiving first. |

### 10. Macro Quick Reference

| Macro | Purpose and impact |
| --- | --- |
| `VBA > AHK > ExportMESJobsJson` | Overwrites `History/MES_Jobs.json`. |
| `VBA > AHK > ArchiveData` | Appends to `History/History.ods`; clears report rows after a successful save. |
| `VBA > AHK > ClearFAReport` | Clears `FA_Report` below row 1 without archiving first. |
| `VBA > DB_Normalized > NormalizeBOM` | Reads `BOM_Raw`, overwrites the matching normalized CSV, and updates the active model. |
| `VBA > FA_FuntionKey > Main` | Input-assistance entry point; normally triggered by the `FA_Report` content-changed event. |