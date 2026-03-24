' SAP GUI Scripting — VBScript Template
' Replace: {{TRANSACTION}}, {{FIELD_VALUES}}, {{OUTPUT_PATH}}
' Prerequisites: SAP GUI Scripting enabled on client and server

' ============================================================
' Connection Setup
' ============================================================
If Not IsObject(application) Then
  Set SapGuiAuto = GetObject("SAPGUI")
  Set application = SapGuiAuto.GetScriptingEngine
End If
Set connection = application.Children(0)
Set session = connection.Children(0)

' ============================================================
' Navigate to Transaction
' ============================================================
session.findById("wnd[0]/tbar[0]/okcd").text = "/n{{TRANSACTION}}"
session.findById("wnd[0]").sendVKey 0  ' Enter

' ============================================================
' Fill Screen Fields
' ============================================================
' Text field
session.findById("wnd[0]/usr/ctxtS_BUKRS-LOW").text = "{{COMPANY_CODE}}"

' Date range
session.findById("wnd[0]/usr/ctxtS_BUDAT-LOW").text = "{{DATE_FROM}}"
session.findById("wnd[0]/usr/ctxtS_BUDAT-HIGH").text = "{{DATE_TO}}"

' Checkbox
session.findById("wnd[0]/usr/chkP_TEST").selected = True

' Radio button
session.findById("wnd[0]/usr/radRB_LIST").select

' Dropdown / combo box
session.findById("wnd[0]/usr/cmbP_LAYOUT").key = "{{LAYOUT_VARIANT}}"

' ============================================================
' Execute
' ============================================================
session.findById("wnd[0]/tbar[1]/btn[8]").press  ' F8 = Execute

' ============================================================
' Handle Popups
' ============================================================
On Error Resume Next
Set popup = session.findById("wnd[1]")
If Not popup Is Nothing Then
  ' Check if it's an info popup
  If InStr(popup.text, "Information") > 0 Then
    popup.sendVKey 0  ' Enter to dismiss
  End If
End If
On Error GoTo 0

' ============================================================
' Export ALV Grid to Excel
' ============================================================
' Method 1: Spreadsheet export
session.findById("wnd[0]/mbar/menu[0]/menu[1]/menu[2]").select  ' List > Export > Spreadsheet
session.findById("wnd[1]/usr/ctxtDY_PATH").text = "{{OUTPUT_PATH}}"
session.findById("wnd[1]/usr/ctxtDY_FILENAME").text = "export.xlsx"
session.findById("wnd[1]/tbar[0]/btn[11]").press  ' Replace if exists

' Method 2: Read ALV grid cells programmatically
Set grid = session.findById("wnd[0]/usr/cntlGRID1/shellcont/shell")
Dim rowCount : rowCount = grid.RowCount
Dim colCount : colCount = grid.ColumnCount

For row = 0 To rowCount - 1
  For col = 0 To colCount - 1
    cellValue = grid.GetCellValue(row, grid.ColumnOrder(col))
    ' Process cellValue...
  Next
Next

' ============================================================
' Cleanup
' ============================================================
session.findById("wnd[0]/tbar[0]/okcd").text = "/n"
session.findById("wnd[0]").sendVKey 0

MsgBox "Script completed.", vbInformation, "SAP GUI Script"
