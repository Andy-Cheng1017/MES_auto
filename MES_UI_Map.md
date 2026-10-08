# MES UI Map

## Scope and safety

This map records screens observed through the Windows desktop UI and UI Automation (UIA). It is a partial, visual map of the current MES session, not a complete description of the MES application or its backend.

During exploration, navigation between screens was used only. The defect query page displayed existing filter/result data immediately on opening; no query was submitted, and no repair, save, delete, scrap, or completion action was performed. Live identifiers and row values are intentionally omitted.

## Observed shell and navigation

- Application window: `Chroma Sajet MES`.
- The top navigation includes Home, `已經開啟的程式`, `目錄`, settings, and about.
- `已經開啟的程式` reports four open programs. All four cards were identified: P05B04 single-board repair, P90B03 process-card query, P90 defect-repair query, and P05B03 repair transfer. P05B03 was identified from its card title only and was not opened.
- The directory exposes a `[MFG]製造` group. The following entries were visible in its UIA tree; completeness was not verified:
  - `各製程良率彙整(CA)`
  - `各製程產出統計`
  - `各製程產出統計(CZ)`
  - `各製程產出統計(總計)`
  - `不良維修資料查詢`
  - `不良維修與交接資料查詢`
  - `不良維修與交接資料查詢V2`
  - `工單上料紀錄`
  - `工單入庫狀況查詢`
  - `工單損耗`
  - `工單過站記錄(歷程)`
  - `報廢`
  - `HI未投序號`

  ## Navigation Tree and Quick Routes

  This is a route index, not a static click script. Prefer the UIA control name and the expected destination state. Coordinates below are observations from one session and must be refreshed from a current snapshot before use.

  ```text
  Chroma Sajet MES
  ├── 已經開啟的程式
  │   ├── P05B04 單板維修
  │   ├── P90B03 流程卡
  │   ├── 不良維修資料查詢
  │   └── P05B03 維修轉出
  └── 目錄
    └── [MFG]製造
      ├── 各製程良率彙整(CA)
      ├── 各製程產出統計 / (CZ) / (總計)
      ├── 不良維修資料查詢
      ├── 不良維修與交接資料查詢 / V2
      ├── 工單上料紀錄
      ├── 工單入庫狀況查詢
      ├── 工單損耗
      ├── 工單過站記錄(歷程)
      ├── 報廢
      └── HI未投序號
  ```

  ### Route Cards

  | Destination | Route | Verify arrival | Risk / notes |
  | --- | --- | --- | --- |
  | P05B04 單板維修 | `已經開啟的程式` > card titled `P05B04 單板維修` | Confirm the `工單/大板編號/序號` input and `不良資訊` group are present | Existing record data may remain on the screen. Do not use `維修`, `加入`, `刪除`, `替換`, or `完成` during navigation. |
  | P90B03 流程卡 | `已經開啟的程式` > card titled `P90B03 流程卡` | Confirm the process-card detail grid and history tabs are present | Existing production rows may appear automatically. Do not use `Open` or `匯出` without an explicit, approved task. |
  | P90 不良維修資料查詢 | `目錄` > `[MFG]製造` > `不良維修資料查詢` | Confirm filter fields plus `資料` and `資料#2` grids | Existing filters/results appeared automatically. Do not press `查詢`, `儲存`, or `匯出細項` during discovery. |
  | P05B03 維修轉出 | `已經開啟的程式` > card titled `P05B03 維修轉出` | Not verified; card title only | Do not enter until its screen and transaction effects have been reviewed. |

  ### Coordinate Snapshot

  The following coordinates are historical references from the primary display at 1920x1080 with the MES maximized. The UI capture area was 1920x980. Directory item coordinates also depend on the menu scroll position. Never click these values without a fresh screenshot/UIA snapshot confirming the same target is currently at that location.

  | Control | Observed coordinate | Context |
  | --- | --- | --- |
  | `目錄` radio button | `(76, 97)` | MES shell top navigation |
  | `已經開啟的程式` radio button | `(309, 97)` | MES shell top navigation |
  | `不良維修資料查詢` directory item | `(983, 349)` | `[MFG]製造` list at observed vertical scroll position 38.07% |

  ### Agent Navigation Protocol

  1. Take a fresh MES-scoped snapshot and confirm the active window is `Chroma Sajet MES`.
  2. Match the requested destination to a route card by the visible UIA name or card title. Do not infer the target from an old coordinate alone.
  3. If the target is in the directory, expose the menu and confirm the `[MFG]製造` group and exact item name in the current UI tree before clicking.
  4. After each navigation click, take a new snapshot and check the route's arrival conditions. If they do not match, stop and re-evaluate rather than continuing with stale coordinates.
  5. Treat coordinate clicks as a fallback for unlabeled controls only. Reconfirm the screen and bounds immediately before the click.
  6. Classify buttons as navigation, read/query, export, or state-changing. A route card is not permission to activate controls on the destination page.

  The current MCP snapshot exposes UIA names and screen coordinates, but has not yet provided verified persistent `AutomationId` paths or ClassNN mappings for MES. This tree therefore accelerates discovery; it is not yet a deterministic, selector-only automation library.

## P05: 線上維修 - P05B04 單板維修

Observed screen regions and labels:

- Identification input: `工單/大板編號/序號`.
- Order information: `工單號`, `料號`, `Defect Line`, `Defect Process`, `Defect Terminal`, `Current Line`, and `Current Terminal`.
- `不良資訊` grid, with visible columns for defect phenomenon/code, descriptions, location, and repair qualification. Visible actions include `維修`, `加入`, `刪除`, `Fail测试值`, and `ICT不良数据`.
- `不良原因资讯` grid, with visible columns for defect-cause code, descriptions, location, defective part, primary-cause flag, and repair code. The grid has horizontal scrolling.
- `料件` area with `替换`, `刪除`, and `移除(依据制程)` actions.
- History tabs: `序号维修历史`, `料件替换历史`, `物料替换历史`, and `RMA退貨資訊`.
- A `完成` action is visible at the bottom of the screen.

The UIA tree exposes these labels and actions, but the business semantics, validation rules, required fields, and transaction effects have not been exercised. Treat the visible repair, parts, delete, and completion actions as state-changing.

## P90: 不良維修資料查詢

Observed filters include `工單`, `內部條碼`, `料號`, `線體`, `Defect Type`, `不良時間`, and `維修時間`. The filter toolbar includes `查詢`, `清除`, `Setup`, `儲存`, `預覽`, and `匯出細項`.

The page contains a primary `資料` grid and a secondary `資料#2` grid. UIA exposed result columns including defect type/status, defect descriptions/location, defect/receive/repair timestamps, reason description, duty description, repair location, work flag, repair employee, and repair remark. Existing data appeared automatically when this module opened. Query behavior, persistence behind `儲存`, and export behavior were not tested.

## P90B03: 流程卡

Observed screen regions and labels:

- Lookup area with a selector, an identifier input, an `Open` control, and an `匯出` action.
- Summary fields for serial number, work order, work-order type, part number, model, version, customer serial number, route, production class, specification, status, and next station.
- `包裝信息` area and a set of optional record-category checkboxes.
- A detail grid with columns for work order, panel number, panel-split flag, serial number, part number, customer part number, production line, process, status, station name, output time, operator, and customer name.
- Tabs for `过站纪录`, `維修`, `質檢`, `主鍵`, `重工`, `辅件管控`, `MAC`, `ASSY材料記錄`, `載具`, `工单料号`, `PTH物料`, `BB物料`, `SN MAPPING`, `PCB & DIP Material MAPPING`, `测试项目`, `SMT物料`, and `Sample Record`.

The page displayed existing production records on opening. No lookup, checkbox, tab, or export action was used. The purpose and side effects of `Open` and `匯出` remain unverified; treat export as a data operation.

## Not yet verified

- Other directory groups or off-screen entries, and the P05B03 repair-transfer screen (identified from its open-program card title only).
- The remaining P90 query modules.
- Window Spy `ClassNN` values. This map uses UIA names and visible screen labels only; it is not yet sufficient to validate AHK selectors.
- Whether any query toolbar action implicitly persists or exports data.
- AHK runtime behavior against MES. No live repair transaction was attempted.

## Exploration end state

The MES was left on the P05B04 single-board repair screen. No business action was performed during this exploration. Window Spy was not available from the visible notification-area controls, so ClassNN/control-class data still needs to be captured separately before treating any AHK control selector as verified.

## Industry Approach

There is no single industry-standard "AI UI skill tree" format. The mature building blocks are:

- **Native Windows applications:** Microsoft UI Automation (UIA) exposes a desktop element tree, control types, properties, control patterns, and events. Automation frameworks such as FlaUI build on UIA for application testing.
- **Web applications:** Playwright recommends role/name, label, and text locators, with auto-waiting and actionability checks. These are generally more resilient than screen coordinates.
- **Visual computer-use agents:** Coordinates and screenshots remain useful when the application does not expose accessible controls, but they are more sensitive to layout, scale, and scrolling changes.

For this MES, the practical hybrid is: skill-like route cards for operator intent, live UIA-tree discovery for locating a control, explicit wait/postcondition checks, and coordinates only as a verified fallback. If the MES UIA provider exposes stable `AutomationId` values, those should be added to the route cards after inspection; do not invent them from labels or coordinates.

References: [Microsoft UI Automation overview](https://learn.microsoft.com/en-us/dotnet/framework/ui-automation/ui-automation-overview), [FlaUI](https://github.com/FlaUI/FlaUI), [Playwright locators](https://playwright.dev/docs/locators), and [Playwright actionability](https://playwright.dev/docs/actionability). Microsoft WinAppDriver is an older Selenium-style option; its latest GitHub release shown is v1.2.1 from 2019, so it is not the first choice for a new setup.