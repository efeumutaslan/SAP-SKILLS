---
name: sap-gui-scripting
description: |
  SAP GUI Scripting automation skill. Use when: automating SAP GUI transactions with VBScript
  or Python, recording and replaying GUI scripts, building RPA bots for SAP GUI, screen scraping
  SAP transactions, automating repetitive data entry, batch processing in SAP GUI, or testing
  SAP GUI transactions. Covers SAP GUI Scripting API, VBScript/Python automation, and integration
  with RPA tools like SAP Build Process Automation Desktop Agent.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-24"
---

# SAP GUI Scripting & Automation

## Related Skills
- `sap-build-process-automation` — Desktop Agent uses GUI scripting under the hood
- `sap-testing-quality` — Automated GUI testing with eCATT/CBTA
- `sap-s4hana-extensibility` — When to use API vs. GUI scripting

## Quick Start

**Prerequisites:**
1. Enable scripting on SAP server: `RZ11` → parameter `sapgui/user_scripting` = `TRUE`
2. Enable on client: SAP GUI → Options → Accessibility & Scripting → Enable scripting
3. Disable notification popups: uncheck "Notify when script attaches" and "Notify when script opens connection"

**Record your first script:**
1. Open SAP GUI → transaction you want to automate
2. Menu: Customize Local Layout (Alt+F12) → Script Recording and Playback
3. Click Record, perform actions, click Stop
4. Save as `.vbs` file — this is your starting template

**Minimal VBScript — Run Transaction:**

```vbs
If Not IsObject(application) Then
   Set SapGuiAuto = GetObject("SAPGUI")
   Set application = SapGuiAuto.GetScriptingEngine
End If

Set connection = application.Children(0)
Set session = connection.Children(0)

session.findById("wnd[0]/tbar[0]/okcd").text = "/nMM03"
session.findById("wnd[0]").sendVKey 0
session.findById("wnd[0]/usr/ctxtRMMG1-MATNR").text = "MAT-001"
session.findById("wnd[0]").sendVKey 0
```

## Core Concepts

### Object Hierarchy
```
GuiApplication
 └── GuiConnection (SAP system connection)
      └── GuiSession (user session / window)
           └── GuiFrameWindow (wnd[0], wnd[1]...)
                ├── GuiToolbar (tbar[0] = command, tbar[1] = app)
                ├── GuiUserArea (usr/)
                │    ├── GuiTextField, GuiCTextField
                │    ├── GuiComboBox, GuiCheckBox, GuiRadioButton
                │    ├── GuiTableControl, GuiGridView (ALV)
                │    ├── GuiTab, GuiTabStrip
                │    └── GuiTree
                ├── GuiStatusbar (sbar/)
                └── GuiTitlebar (titl/)
```

### Element ID Pattern
Format: `wnd[N]/area/type[row,col]`
- `wnd[0]/tbar[0]/okcd` — Command field (OKCode)
- `wnd[0]/usr/ctxtFIELD-NAME` — Context field (F4 help available)
- `wnd[0]/usr/txtFIELD-NAME` — Text input field
- `wnd[0]/usr/chkFIELD-NAME` — Checkbox
- `wnd[0]/usr/radFIELD-NAME` — Radio button
- `wnd[0]/usr/btnBUTTON-NAME` — Push button
- `wnd[0]/usr/tblTABLE/ctxtFIELD[row,col]` — Table cell
- `wnd[0]/usr/cntlGRID/shellcont/shell` — ALV Grid control
- `wnd[0]/sbar` — Status bar (messages)

### Virtual Keys (sendVKey)
| Key | Code | Description |
|-----|------|-------------|
| Enter | `0` | Confirm/execute |
| F2 | `2` | Choose/display |
| F3 | `3` | Back |
| F5 | `5` | Refresh |
| F8 | `8` | Execute report |
| F12 | `12` | Cancel |
| Shift+F4 | `16` | Save as variant |
| Ctrl+S | `11` | Save |
| Ctrl+Shift+F3 | `43` | Delete |

## Common Patterns

### Pattern 1: Python Automation with win32com

```python
import win32com.client
import time

def get_sap_session():
    """Connect to running SAP GUI session."""
    sap_gui = win32com.client.GetObject("SAPGUI")
    app = sap_gui.GetScriptingEngine
    connection = app.Children(0)
    session = connection.Children(0)
    return session

def run_transaction(session, tcode):
    """Navigate to transaction."""
    session.findById("wnd[0]/tbar[0]/okcd").text = f"/n{tcode}"
    session.findById("wnd[0]").sendVKey(0)

def get_status_message(session):
    """Read status bar message."""
    sbar = session.findById("wnd[0]/sbar")
    return {
        "type": sbar.MessageType,  # S=Success, E=Error, W=Warning, I=Info
        "text": sbar.Text
    }
```

### Pattern 2: Table Data Extraction

```python
def extract_alv_grid(session, grid_id="wnd[0]/usr/cntlGRID/shellcont/shell"):
    """Extract all data from ALV grid."""
    grid = session.findById(grid_id)
    columns = grid.ColumnCount
    rows = grid.RowCount
    col_names = [grid.GetColumnTitles(i) for i in range(columns)]

    data = []
    for row in range(rows):
        grid.SetCurrentCell(row, grid.GetColumnName(0))
        record = {}
        for col in range(columns):
            col_name = grid.GetColumnName(col)
            record[col_name] = grid.GetCellValue(row, col_name)
        data.append(record)
    return data

def extract_table_control(session, table_id):
    """Extract data from classic table control (scroll-aware)."""
    table = session.findById(table_id)
    all_rows = []
    visible = table.VisibleRowCount
    total = table.RowCount

    for offset in range(0, total, visible):
        table.VerticalScrollbar.Position = offset
        for row in range(min(visible, total - offset)):
            row_data = {}
            for col in range(table.Columns.Count):
                cell = table.GetCell(row, col)
                row_data[table.Columns(col).Name] = cell.Text
            all_rows.append(row_data)
    return all_rows
```

### Pattern 3: Batch Data Entry (e.g., Mass Material Change)

```python
def mass_material_change(session, materials):
    """Change multiple materials via MM02."""
    results = []
    for mat in materials:
        run_transaction(session, "MM02")
        session.findById("wnd[0]/usr/ctxtRMMG1-MATNR").text = mat["matnr"]
        session.findById("wnd[0]").sendVKey(0)

        # Select views
        for view in session.findById("wnd[0]/usr/tabsTABSPR1").Children:
            if hasattr(view, "Selected"):
                view.Selected = view.Text in mat.get("views", ["Basic Data 1"])

        session.findById("wnd[0]").sendVKey(0)

        # Update fields
        for field_id, value in mat.get("fields", {}).items():
            try:
                session.findById(field_id).text = value
            except Exception as e:
                results.append({"matnr": mat["matnr"], "status": "ERROR", "msg": str(e)})
                session.findById("wnd[0]").sendVKey(12)  # Cancel
                continue

        session.findById("wnd[0]").sendVKey(11)  # Ctrl+S
        msg = get_status_message(session)
        results.append({"matnr": mat["matnr"], "status": msg["type"], "msg": msg["text"]})

    return results
```

### Pattern 4: Handle Popups and Modal Dialogs

```python
def handle_popup(session, action="confirm"):
    """Handle unexpected popup windows."""
    try:
        popup = session.findById("wnd[1]")
        if action == "confirm":
            popup.findById("wnd[1]/usr/btnBUTTON_1").press()  # Yes/OK
        elif action == "cancel":
            popup.findById("wnd[1]/usr/btnBUTTON_2").press()  # No/Cancel
        elif action == "close":
            popup.Close()
        return True
    except Exception:
        return False  # No popup present

def safe_action(session, action_func, max_popups=3):
    """Execute action and handle any resulting popups."""
    action_func()
    for _ in range(max_popups):
        time.sleep(0.3)
        if not handle_popup(session, "confirm"):
            break
```

### Pattern 5: Login Automation

```python
def login_sap(system, client, user, password, language="EN"):
    """Open new SAP GUI connection and login."""
    import subprocess
    sap_logon = r"C:\Program Files (x86)\SAP\FrontEnd\SAPgui\saplogon.exe"
    subprocess.Popen([sap_logon])
    time.sleep(3)

    sap_gui = win32com.client.GetObject("SAPGUI")
    app = sap_gui.GetScriptingEngine
    connection = app.OpenConnection(system, True)
    session = connection.Children(0)

    session.findById("wnd[0]/usr/txtRSYST-MANDT").text = client
    session.findById("wnd[0]/usr/txtRSYST-BNAME").text = user
    session.findById("wnd[0]/usr/pwdRSYST-BCODE").text = password
    session.findById("wnd[0]/usr/txtRSYST-LANGU").text = language
    session.findById("wnd[0]").sendVKey(0)

    # Handle multiple logon popup
    handle_popup(session, "confirm")
    return session
```

### Pattern 6: Error-Resilient Script Template

```python
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("sap_script")

def run_with_retry(session, func, max_retries=3, *args, **kwargs):
    """Run GUI action with retry on transient errors."""
    for attempt in range(max_retries):
        try:
            result = func(session, *args, **kwargs)
            msg = get_status_message(session)
            if msg["type"] == "E":
                log.warning(f"Attempt {attempt+1}: SAP error: {msg['text']}")
                if attempt < max_retries - 1:
                    session.findById("wnd[0]").sendVKey(3)  # Back
                    continue
            return result
        except Exception as e:
            log.error(f"Attempt {attempt+1}: Exception: {e}")
            if attempt == max_retries - 1:
                raise
    return None
```

## Error Catalog

| Error | Message | Root Cause | Fix |
|-------|---------|------------|-----|
| `Runtime error: -2147352567` | Object not found | Element ID wrong or screen changed | Use Script Recorder to get correct ID |
| `Scripting disabled` | Server rejected script | `sapgui/user_scripting` = FALSE | Set via `RZ11` or profile parameter |
| `No SAP GUI instance` | GetObject failed | SAP GUI not running | Start SAP GUI before script |
| `Session busy` | Cannot attach | Transaction is processing | Add `time.sleep()` before action |
| `Modal dialog open` | Cannot access main window | Popup blocking | Handle `wnd[1]` before `wnd[0]` |
| `ALV: Invalid cell` | GetCellValue error | Row index out of range | Check `RowCount` before access |
| `Multiple logon` | Popup at login | User already logged in | Handle popup or close other session |
| `Authorization` | No authorization for scripting | Missing `S_SCR` auth object | Assign auth via `SU01`/role |

## Performance Tips

1. **Disable screen updates** — Not natively supported; minimize visual impact by running in background session
2. **Batch via BDC/BAPI first** — GUI scripting is last resort; prefer RFC/BAPI/OData for bulk operations
3. **Reuse sessions** — Don't login/logout per record; reuse connection for batch processing
4. **Minimize findById calls** — Cache element references: `field = session.findById(...)` then reuse `field`
5. **Handle scrolling** — For table controls, read `VisibleRowCount` and scroll incrementally
6. **Parallel sessions** — SAP allows up to 6 sessions per user; parallelize with `connection.Children(N)`
7. **Avoid hardcoded waits** — Use status bar checks instead of fixed `time.sleep()` where possible

## Gotchas

- **Screen variants**: Same transaction can show different screens based on user settings — always verify screen number
- **Language dependency**: Element IDs can differ by logon language for some older transactions
- **ALV vs. Table Control**: `GuiGridView` (ALV) and `GuiTableControl` have completely different APIs
- **SAP GUI version**: Scripting API changes between versions; test on target version
- **Security policy**: Many organizations disable scripting in production — always check policy
- **64-bit Python + 32-bit SAP GUI**: COM interop may fail; use matching architecture
