# ============================================================
#  SC Offline Launcher  -  themed front end for the offline mod
#  Put this file + "SC Offline Launcher.bat" next to dinput8.dll
#  and the data folder (the same folder launch_offline.bat is in).
# ============================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

trap {
    [void][System.Windows.Forms.MessageBox]::Show(($_.Exception.Message + "`n" + $_.InvocationInfo.PositionMessage), 'SC Offline Launcher - error')
    break
}

$script:Root        = $PSScriptRoot
$script:Data        = Join-Path $script:Root 'data'
$script:Dll         = Join-Path $script:Root 'dinput8.dll'
$script:CfgPath     = Join-Path $script:Root 'launcher.json'
$script:ProfilePath = Join-Path $script:Data 'OfflineDB\default_1.xml'
$script:ShipsPath   = Join-Path $script:Data 'ships.txt'
$script:NpcRx       = '_AI|_PU_|_PU$|Unmanned|Template|Teach|TEST|TEMP|Derelict|Wreck|Boarded|Hijacked|Showdown|Orbital_Sentry|^probe_|^EAObjective|^Spaceship_|Tutorial|Indestructible'

# ---------- settings ----------
$script:Cfg = @{
    GameBin     = 'F:\StarCitizen\StarCitizen\LIVE\Bin64'
    BootMap     = 'PU_All'
    StartShip   = 'DRAK_Cutlass_Black'
    StartLoc    = 'saved'
}
if (Test-Path $script:CfgPath) {
    try {
        $j = Get-Content $script:CfgPath -Raw | ConvertFrom-Json
        foreach ($k in @($script:Cfg.Keys)) {
            if ($null -ne $j.$k) { $script:Cfg[$k] = $j.$k }
        }
    } catch { }
}
function Save-Cfg {
    try { $script:Cfg | ConvertTo-Json | Set-Content -Path $script:CfgPath -Encoding UTF8 } catch { }
}

# ---------- theme ----------
function C([string]$hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }
$script:cBg     = C '#0E1014'
$script:cPanel  = C '#161A20'
$script:cPanel2 = C '#1E232B'
$script:cLine   = C '#2B313B'
$script:cAccent = C '#E8A93A'
$script:cAccentH= C '#F6C163'
$script:cText   = C '#E8E8E8'
$script:cMuted  = C '#8B93A0'
$script:cGood   = C '#6FCF97'
$script:cBad    = C '#EB5757'
$script:cWarn   = C '#F2C94C'

function New-Label([string]$text, [int]$x, [int]$y, [int]$w, [int]$h, [double]$size = 10, [bool]$bold = $false, $color = $null) {
    $l = New-Object System.Windows.Forms.Label
    $l.AutoSize = $false
    $l.Text = $text
    $l.Location = New-Object System.Drawing.Point($x, $y)
    $l.Size = New-Object System.Drawing.Size($w, $h)
    if ($bold) { $style = [System.Drawing.FontStyle]::Bold } else { $style = [System.Drawing.FontStyle]::Regular }
    $l.Font = New-Object System.Drawing.Font('Segoe UI', [single]$size, $style)
    if ($color) { $l.ForeColor = $color } else { $l.ForeColor = $script:cText }
    $l.BackColor = [System.Drawing.Color]::Transparent
    return $l
}

function New-Button([string]$text, [int]$x, [int]$y, [int]$w, [int]$h, [bool]$primary = $false) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object System.Drawing.Point($x, $y)
    $b.Size = New-Object System.Drawing.Size($w, $h)
    $b.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $b.FlatAppearance.BorderSize = 1
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.UseVisualStyleBackColor = $false
    if ($primary) {
        $b.Font = New-Object System.Drawing.Font('Segoe UI Semibold', [single]11)
        $b.BackColor = $script:cAccent
        $b.ForeColor = C '#17120A'
        $b.FlatAppearance.BorderColor = $script:cAccent
        $b.FlatAppearance.MouseOverBackColor = $script:cAccentH
    } else {
        $b.Font = New-Object System.Drawing.Font('Segoe UI', [single]9.5)
        $b.BackColor = $script:cPanel2
        $b.ForeColor = $script:cText
        $b.FlatAppearance.BorderColor = $script:cLine
        $b.FlatAppearance.MouseOverBackColor = C '#2A313C'
    }
    return $b
}

function Set-Toggle($b, [bool]$on) {
    $b.Tag = $on
    if ($on) {
        $b.Text = $b.AccessibleName + ':  ON'
        $b.BackColor = $script:cAccent
        $b.ForeColor = C '#17120A'
        $b.FlatAppearance.BorderColor = $script:cAccent
        $b.FlatAppearance.MouseOverBackColor = $script:cAccentH
    } else {
        $b.Text = $b.AccessibleName + ':  OFF'
        $b.BackColor = $script:cPanel2
        $b.ForeColor = $script:cText
        $b.FlatAppearance.BorderColor = $script:cLine
        $b.FlatAppearance.MouseOverBackColor = C '#2A313C'
    }
}

function New-Toggle([string]$text, [int]$x, [int]$y, [int]$w, [int]$h, [bool]$on) {
    $b = New-Button $text $x $y $w $h
    $b.AccessibleName = $text
    Set-Toggle $b $on
    $b.Add_Click({ Set-Toggle $this (-not [bool]$this.Tag) })
    return $b
}

function New-Text([int]$x, [int]$y, [int]$w) {
    $t = New-Object System.Windows.Forms.TextBox
    $t.Location = New-Object System.Drawing.Point($x, $y)
    $t.Size = New-Object System.Drawing.Size($w, 26)
    $t.BackColor = $script:cPanel2
    $t.ForeColor = $script:cText
    $t.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $t.Font = New-Object System.Drawing.Font('Segoe UI', [single]10)
    return $t
}

function New-Combo([int]$x, [int]$y, [int]$w) {
    $c = New-Object System.Windows.Forms.ComboBox
    $c.Location = New-Object System.Drawing.Point($x, $y)
    $c.Size = New-Object System.Drawing.Size($w, 26)
    $c.BackColor = $script:cPanel2
    $c.ForeColor = $script:cText
    $c.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $c.Font = New-Object System.Drawing.Font('Segoe UI', [single]10)
    return $c
}

function New-List([int]$x, [int]$y, [int]$w, [int]$h) {
    $l = New-Object System.Windows.Forms.ListBox
    $l.Location = New-Object System.Drawing.Point($x, $y)
    $l.Size = New-Object System.Drawing.Size($w, $h)
    $l.BackColor = $script:cPanel2
    $l.ForeColor = $script:cText
    $l.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $l.Font = New-Object System.Drawing.Font('Consolas', [single]10)
    return $l
}

function New-Page {
    $p = New-Object System.Windows.Forms.Panel
    $p.Location = New-Object System.Drawing.Point(200, 0)
    $p.Size = New-Object System.Drawing.Size(740, 620)
    $p.BackColor = $script:cBg
    $p.Visible = $false
    return $p
}

# ---------- helpers ----------
function Write-Log([string]$msg, $color = $null) {
    if (-not $script:LogBox) { return }
    if (-not $color) { $color = $script:cText }
    $script:LogBox.SelectionStart = $script:LogBox.TextLength
    $script:LogBox.SelectionLength = 0
    $script:LogBox.SelectionColor = $color
    $script:LogBox.AppendText(('[{0}] {1}{2}' -f (Get-Date -Format 'HH:mm:ss'), $msg, "`r`n"))
    $script:LogBox.ScrollToCaret()
}

function Show-Msg([string]$text, [string]$icon = 'Information') {
    [void][System.Windows.Forms.MessageBox]::Show($text, 'SC Offline Launcher', 'OK', $icon)
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Open-File([string]$path) {
    if (Test-Path $path) {
        Start-Process -FilePath 'notepad.exe' -ArgumentList ('"{0}"' -f $path)
    } else {
        Show-Msg ("Not there yet:`n{0}`n`nIt is created the first time the game runs with the mod." -f $path) 'Information'
    }
}

function Open-Folder([string]$path) {
    if (Test-Path $path) {
        Start-Process -FilePath 'explorer.exe' -ArgumentList ('"{0}"' -f $path)
    } else {
        Show-Msg ("Folder not found:`n{0}" -f $path) 'Warning'
    }
}

function Get-GameExe { Join-Path $script:Cfg.GameBin 'StarCitizen.exe' }
function Get-GameDll { Join-Path $script:Cfg.GameBin 'dinput8.dll' }
function Test-GameRunning { return [bool](Get-Process -Name 'StarCitizen' -ErrorAction SilentlyContinue) }

function Get-Ships([bool]$hideNpc) {
    $out = New-Object System.Collections.ArrayList
    if (Test-Path $script:ShipsPath) {
        foreach ($line in [System.IO.File]::ReadAllLines($script:ShipsPath)) {
            $s = $line.Trim()
            if ($s -eq '' -or $s.StartsWith('#')) { continue }
            if ($hideNpc -and ($s -match $script:NpcRx)) { continue }
            [void]$out.Add($s)
        }
    }
    return , $out
}

function Get-Slots {
    $d = Join-Path $script:Data 'spawn_slots'
    $out = @()
    if (Test-Path $d) {
        foreach ($f in (Get-ChildItem -Path $d -Filter '*.txt' | Sort-Object Name)) { $out += $f.BaseName }
    }
    return , $out
}

function Get-LocKey([string]$disp) {
    if ($disp -eq 'Over Daymar') { return 'daymar' }
    if ($disp.StartsWith('Slot: ')) { return 'slot:' + $disp.Substring(6) }
    return 'saved'
}

function Refresh-LocCombo {
    $script:LocBusy = $true
    $c = $script:ComboLoc
    $c.Items.Clear()
    [void]$c.Items.Add('Saved spot (F7)')
    [void]$c.Items.Add('Over Daymar')
    foreach ($n in (Get-Slots)) { [void]$c.Items.Add('Slot: ' + $n) }
    $want = [string]$script:Cfg.StartLoc
    $idx = 0
    for ($i = 0; $i -lt $c.Items.Count; $i++) {
        if ((Get-LocKey ([string]$c.Items[$i])) -eq $want) { $idx = $i }
    }
    $c.SelectedIndex = $idx
    $script:Cfg.StartLoc = Get-LocKey ([string]$c.Items[$idx])
    Save-Cfg
    $script:LocBusy = $false
}

# ---------- main window ----------
$script:State = 'idle'     # idle | starting | running | cleanup
$script:StartTime = Get-Date
$script:DelTries = 0

$form = New-Object System.Windows.Forms.Form
$form.Text = 'SC Offline Launcher'
$form.ClientSize = New-Object System.Drawing.Size(940, 620)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.MaximizeBox = $false
$form.BackColor = $script:cBg
$form.ForeColor = $script:cText
$script:Form = $form

# sidebar
$side = New-Object System.Windows.Forms.Panel
$side.Location = New-Object System.Drawing.Point(0, 0)
$side.Size = New-Object System.Drawing.Size(200, 620)
$side.BackColor = $script:cPanel
$script:Side = $side
$form.Controls.Add($side)

$side.Controls.Add((New-Label 'SC OFFLINE' 24 28 170 34 17 $true $script:cAccent))
$side.Controls.Add((New-Label 'L A U N C H E R' 26 62 170 20 8.5 $false $script:cMuted))

$script:NavButtons = @{}
$script:Pages = @{}

function Show-Page([string]$name) {
    foreach ($k in @($script:Pages.Keys)) {
        $script:Pages[$k].Visible = ($k -eq $name)
        $nb = $script:NavButtons[$k]
        if ($k -eq $name) {
            $nb.BackColor = $script:cPanel2
            $nb.ForeColor = $script:cAccent
        } else {
            $nb.BackColor = $script:cPanel
            $nb.ForeColor = $script:cText
        }
    }
}

function Add-Nav([string]$name, [string]$text, [int]$y) {
    $b = New-Button $text 0 $y 200 46
    $b.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $b.Padding = New-Object System.Windows.Forms.Padding(24, 0, 0, 0)
    $b.FlatAppearance.BorderSize = 0
    $b.BackColor = $script:cPanel
    $b.Font = New-Object System.Drawing.Font('Segoe UI', [single]11)
    $b.Tag = $name
    $b.Add_Click({ Show-Page $this.Tag })
    $script:Side.Controls.Add($b)
    $script:NavButtons[$name] = $b
}

Add-Nav 'home'     'Launch'    120
Add-Nav 'fleet'    'Fleet'     168
Add-Nav 'places'   'Places'    216
Add-Nav 'files'    'Files'     264
Add-Nav 'settings' 'Settings'  312

$script:VerLabel = New-Label 'Offline mod launcher' 24 580 170 20 8 $false $script:cMuted
$side.Controls.Add($script:VerLabel)

# ======================= HOME PAGE =======================
$home_ = New-Page
$script:Pages['home'] = $home_
$form.Controls.Add($home_)

$home_.Controls.Add((New-Label 'Ready to launch' 30 22 500 40 21 $true))
$home_.Controls.Add((New-Label 'Starts Star Citizen with the offline mod loaded.' 32 64 600 22 10 $false $script:cMuted))

$statusPanel = New-Object System.Windows.Forms.Panel
$statusPanel.Location = New-Object System.Drawing.Point(30, 100)
$statusPanel.Size = New-Object System.Drawing.Size(680, 56)
$statusPanel.BackColor = $script:cPanel
$home_.Controls.Add($statusPanel)

$script:LblGame  = New-Label '' 18 16 220 24 10
$script:LblDll   = New-Label '' 250 16 200 24 10
$script:LblState = New-Label '' 460 16 210 24 10
$statusPanel.Controls.Add($script:LblGame)
$statusPanel.Controls.Add($script:LblDll)
$statusPanel.Controls.Add($script:LblState)

$optPanel = New-Object System.Windows.Forms.Panel
$optPanel.Location = New-Object System.Drawing.Point(30, 172)
$optPanel.Size = New-Object System.Drawing.Size(680, 112)
$optPanel.BackColor = $script:cPanel
$home_.Controls.Add($optPanel)

$optPanel.Controls.Add((New-Label 'BOOT MAP' 18 14 200 18 8.5 $true $script:cMuted))
$script:ComboBoot = New-Combo 18 36 170
$script:ComboBoot.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
[void]$script:ComboBoot.Items.Add('PU_All')
[void]$script:ComboBoot.Items.Add('PU')
$script:ComboBoot.SelectedItem = [string]$script:Cfg.BootMap
if ($script:ComboBoot.SelectedIndex -lt 0) { $script:ComboBoot.SelectedIndex = 0 }
$script:ComboBoot.Add_SelectedIndexChanged({
    $script:Cfg.BootMap = [string]$script:ComboBoot.SelectedItem
    Save-Cfg
})
$optPanel.Controls.Add($script:ComboBoot)
$optPanel.Controls.Add((New-Label 'Try PU if you keep starting in Pyro.' 18 70 180 34 8.5 $false $script:cMuted))

$optPanel.Controls.Add((New-Label 'START SHIP' 208 14 200 18 8.5 $true $script:cMuted))
$script:ComboShip = New-Combo 208 36 230
$script:ComboShip.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
foreach ($s in (Get-Ships $true)) { [void]$script:ComboShip.Items.Add($s) }
$script:ComboShip.Text = [string]$script:Cfg.StartShip
$script:ComboShip.Add_TextChanged({
    $script:Cfg.StartShip = $script:ComboShip.Text.Trim()
    Save-Cfg
})
$optPanel.Controls.Add($script:ComboShip)

$optPanel.Controls.Add((New-Label 'START LOCATION' 458 14 200 18 8.5 $true $script:cMuted))
$script:ComboLoc = New-Combo 458 36 204
$script:ComboLoc.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$script:LocBusy = $false
$script:ComboLoc.Add_SelectedIndexChanged({
    if (-not $script:LocBusy) {
        $script:Cfg.StartLoc = Get-LocKey ([string]$script:ComboLoc.SelectedItem)
        Save-Cfg
    }
})
$optPanel.Controls.Add($script:ComboLoc)
$optPanel.Controls.Add((New-Label 'Add your own on the Places page.' 458 70 204 34 8.5 $false $script:cMuted))

$script:BtnLaunch = New-Button 'LAUNCH OFFLINE' 30 300 680 58 $true
$script:BtnLaunch.Font = New-Object System.Drawing.Font('Segoe UI Semibold', [single]14)
$home_.Controls.Add($script:BtnLaunch)

$script:LogBox = New-Object System.Windows.Forms.RichTextBox
$script:LogBox.Location = New-Object System.Drawing.Point(30, 374)
$script:LogBox.Size = New-Object System.Drawing.Size(680, 220)
$script:LogBox.BackColor = $script:cPanel
$script:LogBox.ForeColor = $script:cText
$script:LogBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$script:LogBox.ReadOnly = $true
$script:LogBox.Font = New-Object System.Drawing.Font('Consolas', [single]9.5)
$home_.Controls.Add($script:LogBox)

# ======================= FLEET PAGE =======================
$fleetPage = New-Page
$script:Pages['fleet'] = $fleetPage
$form.Controls.Add($fleetPage)

$fleetPage.Controls.Add((New-Label 'Fleet' 30 22 500 40 21 $true))
$fleetPage.Controls.Add((New-Label 'Ships listed here show up in the ASOP / fleet terminal on your next launch.' 32 64 680 22 10 $false $script:cMuted))

$fleetPage.Controls.Add((New-Label 'YOUR FLEET' 30 104 300 18 8.5 $true $script:cMuted))
$script:FleetBox = New-List 30 128 300 330
$script:FleetBox.SelectionMode = [System.Windows.Forms.SelectionMode]::MultiExtended
$fleetPage.Controls.Add($script:FleetBox)

$btnRemove = New-Button 'Remove selected' 30 468 140 36
$btnSave   = New-Button 'Save changes' 190 468 140 36 $true
$btnSave.Font = New-Object System.Drawing.Font('Segoe UI Semibold', [single]10)
$fleetPage.Controls.Add($btnRemove)
$fleetPage.Controls.Add($btnSave)
$script:LblDirty = New-Label '' 30 512 300 22 9 $false $script:cWarn
$fleetPage.Controls.Add($script:LblDirty)

$fleetPage.Controls.Add((New-Label 'ALL SHIPS' 370 104 120 18 8.5 $true $script:cMuted))
$script:TxtSearch = New-Text 370 128 180
$fleetPage.Controls.Add($script:TxtSearch)
$script:ChkNpc = New-Toggle 'Hide AI ships' 558 124 152 30 $true
$fleetPage.Controls.Add($script:ChkNpc)

$script:AllBox = New-List 370 160 340 298
$script:AllBox.SelectionMode = [System.Windows.Forms.SelectionMode]::MultiExtended
$fleetPage.Controls.Add($script:AllBox)
$btnAdd = New-Button 'Add selected  >' 370 468 340 36
$fleetPage.Controls.Add($btnAdd)
$fleetPage.Controls.Add((New-Label 'Tip: double-click a ship to add it. Changes apply the next time you launch.' 370 512 350 36 8.5 $false $script:cMuted))

function Set-Dirty([bool]$d) {
    if ($d) { $script:LblDirty.Text = 'Unsaved changes' } else { $script:LblDirty.Text = '' }
}

function Load-Fleet {
    $script:FleetBox.Items.Clear()
    if (Test-Path $script:ProfilePath) {
        try {
            $doc = New-Object System.Xml.XmlDocument
            $doc.Load($script:ProfilePath)
            foreach ($n in $doc.SelectNodes('/DB/Item')) {
                [void]$script:FleetBox.Items.Add($n.GetAttribute('class'))
            }
        } catch {
            Show-Msg ("Could not read default_1.xml:`n{0}" -f $_.Exception.Message) 'Warning'
        }
    }
    Set-Dirty $false
}

function Refresh-AllShips {
    $filter = $script:TxtSearch.Text.Trim()
    $script:AllBox.BeginUpdate()
    $script:AllBox.Items.Clear()
    foreach ($s in (Get-Ships ([bool]$script:ChkNpc.Tag))) {
        if ($filter -eq '' -or $s.IndexOf($filter, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            [void]$script:AllBox.Items.Add($s)
        }
    }
    $script:AllBox.EndUpdate()
}

function Add-Selected {
    $added = 0
    foreach ($s in @($script:AllBox.SelectedItems)) {
        if (-not $script:FleetBox.Items.Contains($s)) {
            [void]$script:FleetBox.Items.Add($s)
            $added++
        }
    }
    if ($added -gt 0) { Set-Dirty $true }
}

function Remove-Selected {
    $sel = @($script:FleetBox.SelectedItems)
    foreach ($s in $sel) { $script:FleetBox.Items.Remove($s) }
    if ($sel.Count -gt 0) { Set-Dirty $true }
}

function Save-Fleet {
    try {
        $doc = New-Object System.Xml.XmlDocument
        if (Test-Path $script:ProfilePath) {
            $doc.Load($script:ProfilePath)
        } else {
            New-Item -ItemType Directory -Force -Path (Split-Path $script:ProfilePath -Parent) | Out-Null
            $doc.LoadXml('<DB><aUEC amount="100000000"/><OfflineItems value="1"/></DB>')
        }
        $root = $doc.SelectSingleNode('/DB')
        foreach ($n in @($root.SelectNodes('Item'))) { [void]$root.RemoveChild($n) }
        foreach ($name in $script:FleetBox.Items) {
            $e = $doc.CreateElement('Item')
            $e.SetAttribute('class', [string]$name)
            [void]$root.AppendChild($e)
        }
        if (Test-Path $script:ProfilePath) { Copy-Item $script:ProfilePath ($script:ProfilePath + '.bak') -Force }
        $ws = New-Object System.Xml.XmlWriterSettings
        $ws.Indent = $true
        $ws.IndentChars = '  '
        $ws.OmitXmlDeclaration = $true
        $ws.Encoding = New-Object System.Text.UTF8Encoding($false)
        $w = [System.Xml.XmlWriter]::Create($script:ProfilePath, $ws)
        try { $doc.Save($w) } finally { $w.Close() }
        Set-Dirty $false
        Write-Log ('Fleet saved ({0} ships). A backup is in default_1.xml.bak' -f $script:FleetBox.Items.Count) $script:cGood
        Show-Msg 'Fleet saved. It will appear in the ASOP terminal the next time you launch.'
    } catch {
        Show-Msg ("Could not save the fleet:`n{0}" -f $_.Exception.Message) 'Error'
    }
}

$btnAdd.Add_Click({ Add-Selected })
$btnRemove.Add_Click({ Remove-Selected })
$btnSave.Add_Click({ Save-Fleet })
$script:AllBox.Add_DoubleClick({ Add-Selected })
$script:TxtSearch.Add_TextChanged({ Refresh-AllShips })
$script:ChkNpc.Add_Click({ Refresh-AllShips })

# ======================= PLACES PAGE =======================
$placesPage = New-Page
$script:Pages['places'] = $placesPage
$form.Controls.Add($placesPage)

$placesPage.Controls.Add((New-Label 'Places' 30 22 500 40 21 $true))
$placesPage.Controls.Add((New-Label 'Keep named start spots and pick where you load in.' 32 64 680 22 10 $false $script:cMuted))

$howPanel = New-Object System.Windows.Forms.Panel
$howPanel.Location = New-Object System.Drawing.Point(30, 100)
$howPanel.Size = New-Object System.Drawing.Size(680, 112)
$howPanel.BackColor = $script:cPanel
$placesPage.Controls.Add($howPanel)
$howPanel.Controls.Add((New-Label 'HOW TO ADD A START SPOT' 18 12 400 18 8.5 $true $script:cAccent))
$howPanel.Controls.Add((New-Label ("1.  Launch the game and go to where you want to start.`r`n2.  Press F7 in game to save the spot, then quit the game.`r`n3.  Come back here and click 'Save current spot as...'.") 18 34 650 60 10))
$howPanel.Controls.Add((New-Label 'Spots only work in the system the game starts in. If one is ignored, press F7 again in that system.' 18 90 650 18 8.5 $false $script:cMuted))

$placesPage.Controls.Add((New-Label 'YOUR SPOTS' 30 228 300 18 8.5 $true $script:cMuted))
$script:SlotBox = New-List 30 252 320 300
$placesPage.Controls.Add($script:SlotBox)

$btnSlotSave = New-Button 'Save current spot as...' 370 252 340 42 $true
$btnSlotSave.Font = New-Object System.Drawing.Font('Segoe UI Semibold', [single]10.5)
$btnSlotUse  = New-Button 'Use selected on next launch' 370 304 340 38
$btnSlotDel  = New-Button 'Delete selected' 370 352 340 38
$btnSpawnTxt = New-Button 'Open spawn.txt (your F7 spot)' 370 400 340 38
$placesPage.Controls.Add($btnSlotSave)
$placesPage.Controls.Add($btnSlotUse)
$placesPage.Controls.Add($btnSlotDel)
$placesPage.Controls.Add($btnSpawnTxt)
$script:LblSpotInfo = New-Label '' 370 448 340 60 9 $false $script:cMuted
$placesPage.Controls.Add($script:LblSpotInfo)

function Refresh-Places {
    $script:SlotBox.Items.Clear()
    foreach ($n in (Get-Slots)) { [void]$script:SlotBox.Items.Add($n) }
    $sp = Join-Path $script:Data 'spawn.txt'
    if (Test-Path $sp) {
        $script:LblSpotInfo.Text = ('Current F7 spot saved ' + (Get-Item $sp).LastWriteTime.ToString('g') + '.')
    } else {
        $script:LblSpotInfo.Text = 'No F7 spot saved yet.'
    }
    Refresh-LocCombo
}

function Save-Slot {
    $src = Join-Path $script:Data 'spawn.txt'
    if (-not (Test-Path $src)) {
        Show-Msg 'No spot saved yet. In the game press F7 where you want to start, quit the game, then try again.'
        return
    }
    Add-Type -AssemblyName Microsoft.VisualBasic
    $name = [Microsoft.VisualBasic.Interaction]::InputBox('Name for this spot (letters, numbers and spaces):', 'Save spot', '')
    $name = ($name -replace '[^A-Za-z0-9 _-]', '').Trim()
    if ($name -eq '') { return }
    $d = Join-Path $script:Data 'spawn_slots'
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    Copy-Item -Path $src -Destination (Join-Path $d ($name + '.txt')) -Force
    $script:Cfg.StartLoc = 'slot:' + $name
    Refresh-Places
    Write-Log ("Spot '{0}' saved and selected as your start location." -f $name) $script:cGood
}

$btnSlotSave.Add_Click({ Save-Slot })
$btnSlotUse.Add_Click({
    if ($script:SlotBox.SelectedItem) {
        $script:Cfg.StartLoc = 'slot:' + [string]$script:SlotBox.SelectedItem
        Refresh-LocCombo
        Show-Msg ("'{0}' will be your start location on the next launch." -f [string]$script:SlotBox.SelectedItem)
    } else { Show-Msg 'Select a spot in the list first.' }
})
$btnSlotDel.Add_Click({
    if ($script:SlotBox.SelectedItem) {
        $n = [string]$script:SlotBox.SelectedItem
        $f = Join-Path (Join-Path $script:Data 'spawn_slots') ($n + '.txt')
        if (Test-Path $f) { Remove-Item $f -Force }
        Refresh-Places
    } else { Show-Msg 'Select a spot in the list first.' }
})
$btnSpawnTxt.Add_Click({ Open-File (Join-Path $script:Data 'spawn.txt') })

# ======================= FILES PAGE =======================
$filesPage = New-Page
$script:Pages['files'] = $filesPage
$form.Controls.Add($filesPage)

$filesPage.Controls.Add((New-Label 'Files' 30 22 500 40 21 $true))
$filesPage.Controls.Add((New-Label 'Quick access to everything the mod reads and writes.' 32 64 680 22 10 $false $script:cMuted))

function Add-FileButton([string]$text, [string]$hint, [int]$col, [int]$row, [scriptblock]$action) {
    $x = 30 + ($col * 345)
    $y = 108 + ($row * 76)
    $b = New-Button $text $x $y 335 40
    $b.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $b.Padding = New-Object System.Windows.Forms.Padding(14, 0, 0, 0)
    $b.Add_Click($action)
    $script:FilesPageRef.Controls.Add($b)
    $script:FilesPageRef.Controls.Add((New-Label $hint ($x + 2) ($y + 42) 335 18 8.5 $false $script:cMuted))
}
$script:FilesPageRef = $filesPage

Add-FileButton 'Open mod folder'      'Where the launcher and DLL live'          0 0 { Open-Folder $script:Root }
Add-FileButton 'Open data folder'     'ships.txt, items.txt, logs, saves'        1 0 { Open-Folder $script:Data }
Add-FileButton 'mod.log'              'What the mod did last session'            0 1 { Open-File (Join-Path $script:Data 'mod.log') }
Add-FileButton 'Game.log'             'The game''s own log (in the LIVE folder)' 1 1 { Open-File (Join-Path (Split-Path $script:Cfg.GameBin -Parent) 'Game.log') }
Add-FileButton 'default_1.xml'        'Raw profile: ships and starting money'    0 2 { Open-File $script:ProfilePath }
Add-FileButton 'wallet.txt'           'Your saved aUEC balance'                  1 2 { Open-File (Join-Path $script:Data 'wallet.txt') }
Add-FileButton 'ships.txt'            'Every ship the spawn menu knows'          0 3 { Open-File $script:ShipsPath }
Add-FileButton 'items.txt'            'Gear and armor for the gear menu'         1 3 { Open-File (Join-Path $script:Data 'items.txt') }
Add-FileButton 'spawn.txt'            'Your F7 saved teleport spot'              0 4 { Open-File (Join-Path $script:Data 'spawn.txt') }
Add-FileButton 'Game user folder'     'Where the game reads your profile copy'   1 4 { Open-Folder ([System.IO.Path]::GetFullPath((Join-Path $script:Cfg.GameBin '..\user\client\0'))) }

# ======================= SETTINGS PAGE =======================
$setPage = New-Page
$script:Pages['settings'] = $setPage
$form.Controls.Add($setPage)

$setPage.Controls.Add((New-Label 'Settings' 30 22 500 40 21 $true))
$setPage.Controls.Add((New-Label 'Point the launcher at your Star Citizen install.' 32 64 680 22 10 $false $script:cMuted))

$setPage.Controls.Add((New-Label 'GAME FOLDER  (the Bin64 folder that holds StarCitizen.exe)' 30 112 600 18 8.5 $true $script:cMuted))
$script:TxtBin = New-Text 30 136 540
$script:TxtBin.Text = [string]$script:Cfg.GameBin
$setPage.Controls.Add($script:TxtBin)
$btnBrowse = New-Button 'Browse...' 580 134 130 30
$setPage.Controls.Add($btnBrowse)
$script:LblBinCheck = New-Label '' 30 170 680 22 9.5
$setPage.Controls.Add($script:LblBinCheck)

$setPage.Controls.Add((New-Label 'CLEAN UP' 30 226 300 18 8.5 $true $script:cMuted))
$btnRemoveDll = New-Button 'Remove mod DLL from game folder' 30 250 280 38
$setPage.Controls.Add($btnRemoveDll)
$setPage.Controls.Add((New-Label 'Use this if the launcher was closed while the game was running. The DLL must be removed before using the RSI launcher.' 30 292 680 40 9 $false $script:cMuted))

$setPage.Controls.Add((New-Label 'ADMINISTRATOR' 30 352 300 18 8.5 $true $script:cMuted))
$btnAdmin = New-Button 'Restart launcher as administrator' 30 376 280 38
$setPage.Controls.Add($btnAdmin)
$setPage.Controls.Add((New-Label 'Only needed if the launcher says it cannot copy the DLL into the game folder.' 30 418 680 22 9 $false $script:cMuted))

function Refresh-Status {
    $exeOk = Test-Path (Get-GameExe)
    $dllOk = Test-Path $script:Dll
    if ($exeOk) { $script:LblGame.Text = [string]([char]0x25CF) + '  Game found'; $script:LblGame.ForeColor = $script:cGood }
    else        { $script:LblGame.Text = [string]([char]0x25CF) + '  Game not found'; $script:LblGame.ForeColor = $script:cBad }
    if ($dllOk) { $script:LblDll.Text = [string]([char]0x25CF) + '  Mod DLL ready'; $script:LblDll.ForeColor = $script:cGood }
    else        { $script:LblDll.Text = [string]([char]0x25CF) + '  Mod DLL missing'; $script:LblDll.ForeColor = $script:cBad }

    switch ($script:State) {
        'idle'     { $script:LblState.Text = [string]([char]0x25CF) + '  Idle'; $script:LblState.ForeColor = $script:cMuted
                     $script:BtnLaunch.Text = 'LAUNCH OFFLINE'; $script:BtnLaunch.Enabled = $true }
        'starting' { $script:LblState.Text = [string]([char]0x25CF) + '  Starting...'; $script:LblState.ForeColor = $script:cWarn
                     $script:BtnLaunch.Text = 'STARTING...'; $script:BtnLaunch.Enabled = $false }
        'running'  { $script:LblState.Text = [string]([char]0x25CF) + '  Game running'; $script:LblState.ForeColor = $script:cGood
                     $script:BtnLaunch.Text = 'GAME RUNNING'; $script:BtnLaunch.Enabled = $false }
        'cleanup'  { $script:LblState.Text = [string]([char]0x25CF) + '  Cleaning up...'; $script:LblState.ForeColor = $script:cWarn
                     $script:BtnLaunch.Text = 'CLEANING UP...'; $script:BtnLaunch.Enabled = $false }
    }
    if ($exeOk) {
        $script:LblBinCheck.Text = 'StarCitizen.exe found.'
        $script:LblBinCheck.ForeColor = $script:cGood
    } else {
        $script:LblBinCheck.Text = 'StarCitizen.exe was not found in that folder.'
        $script:LblBinCheck.ForeColor = $script:cBad
    }
}

$script:TxtBin.Add_TextChanged({
    $script:Cfg.GameBin = $script:TxtBin.Text.Trim()
    Save-Cfg
    Refresh-Status
})
$btnBrowse.Add_Click({
    $fb = New-Object System.Windows.Forms.FolderBrowserDialog
    $fb.Description = 'Select the Bin64 folder that contains StarCitizen.exe'
    if (Test-Path $script:Cfg.GameBin) { $fb.SelectedPath = $script:Cfg.GameBin }
    if ($fb.ShowDialog() -eq 'OK') { $script:TxtBin.Text = $fb.SelectedPath }
})

# ---------- launch / cleanup ----------
function Start-Game {
    if ($script:State -ne 'idle') { return }
    try {
        $bin = $script:Cfg.GameBin
        $exe = Get-GameExe
        if (-not (Test-Path $exe)) {
            Show-Msg ("StarCitizen.exe was not found at:`n{0}`n`nFix the game folder under Settings." -f $bin) 'Warning'
            Show-Page 'settings'
            return
        }
        if (-not (Test-Path $script:Dll)) {
            Show-Msg ("dinput8.dll is missing:`n{0}`n`nKeep the launcher in the same folder as the mod's files." -f $script:Dll) 'Warning'
            return
        }
        if (Test-GameRunning) {
            Show-Msg 'StarCitizen.exe is already running. Close it first.' 'Warning'
            return
        }

        Write-Log 'Loading offline mod...'
        try {
            Copy-Item -Path $script:Dll -Destination (Get-GameDll) -Force -ErrorAction Stop
        } catch {
            Write-Log ('Could not copy dinput8.dll: ' + $_.Exception.Message) $script:cBad
            if (-not (Test-Admin)) {
                $ans = [System.Windows.Forms.MessageBox]::Show("Could not copy the mod DLL into the game folder.`n`nRestart the launcher as administrator?", 'SC Offline Launcher', 'YesNo', 'Question')
                if ($ans -eq 'Yes') { Restart-Elevated }
            }
            return
        }

        $userDir = [System.IO.Path]::GetFullPath((Join-Path $bin '..\user\client\0'))
        New-Item -ItemType Directory -Force -Path $userDir | Out-Null
        if (Test-Path $script:ProfilePath) {
            Copy-Item -Path $script:ProfilePath -Destination (Join-Path $userDir 'default_1.xml') -Force
            Write-Log 'Profile copied (default_1.xml).'
        } else {
            Write-Log 'data\OfflineDB\default_1.xml not found - you will start with no ships.' $script:cWarn
        }

        $env:SC_OFFLINE_BOOT_MAP   = [string]$script:Cfg.BootMap
        $env:SC_OFFLINE_MOD_LOG    = Join-Path $script:Data 'mod.log'
        $env:SC_OFFLINE_SPAWN_FILE = Join-Path $script:Data 'spawn.txt'
        $env:SC_OFFLINE_SHIPS_FILE = Join-Path $script:Data 'ships.txt'
        $env:SC_OFFLINE_START_SHIP = [string]$script:Cfg.StartShip
        $env:SC_USER               = $userDir
        $loc = [string]$script:Cfg.StartLoc
        if ($loc -eq 'daymar') {
            $env:SC_OFFLINE_START = 'Daymar'
        } else {
            Remove-Item Env:SC_OFFLINE_START -ErrorAction SilentlyContinue
        }
        if ($loc.StartsWith('slot:')) {
            $slotName = $loc.Substring(5)
            $slotFile = Join-Path (Join-Path $script:Data 'spawn_slots') ($slotName + '.txt')
            $spawnFile = Join-Path $script:Data 'spawn.txt'
            if (Test-Path $slotFile) {
                if (Test-Path $spawnFile) { Copy-Item $spawnFile ($spawnFile + '.bak') -Force }
                Copy-Item $slotFile $spawnFile -Force
                Write-Log ("Start location: '{0}'" -f $slotName)
            } else {
                Write-Log ("Spot '{0}' was not found - using your last F7 spot." -f $slotName) $script:cWarn
            }
        } elseif ($loc -eq 'daymar') {
            Write-Log 'Start location: over Daymar'
        } else {
            Write-Log 'Start location: your last F7 spot'
        }

        Write-Log ('Boot map: {0}   Start ship: {1}' -f $script:Cfg.BootMap, $script:Cfg.StartShip)
        Start-Process -FilePath $exe -WorkingDirectory $bin
        $script:StartTime = Get-Date
        $script:State = 'starting'
        Write-Log 'Star Citizen is starting. Leave this window open while you play.' $script:cAccent
        Refresh-Status
    } catch {
        Write-Log ('Launch failed: ' + $_.Exception.Message) $script:cBad
        $script:State = 'idle'
        Refresh-Status
    }
}

function Restart-Elevated {
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-WindowStyle', 'Hidden', '-File', ('"{0}"' -f $PSCommandPath))
        $script:Form.Close()
    } catch {
        Show-Msg 'Elevation was cancelled.' 'Information'
    }
}

function Begin-Cleanup {
    $script:State = 'cleanup'
    $script:DelTries = 0
    Write-Log 'Removing mod DLL from the game folder...'
    Refresh-Status
}

function Step-Cleanup {
    $dll = Get-GameDll
    if (-not (Test-Path $dll)) {
        $script:State = 'idle'
        Write-Log 'Mod DLL removed. Safe to use the RSI launcher.' $script:cGood
        Refresh-Status
        return
    }
    try {
        Remove-Item -Path $dll -Force -ErrorAction Stop
        $script:State = 'idle'
        Write-Log 'Mod DLL removed. Safe to use the RSI launcher.' $script:cGood
        Refresh-Status
    } catch {
        $script:DelTries++
        if ($script:DelTries -ge 30) {
            $script:State = 'idle'
            Write-Log ('Could not remove ' + $dll) $script:cBad
            Show-Msg ("Could not remove:`n{0}`n`nDelete it manually before using the RSI launcher." -f $dll) 'Warning'
            Refresh-Status
        }
    }
}

$btnRemoveDll.Add_Click({
    if ($script:State -ne 'idle') { Show-Msg 'Wait until the current session has finished.' 'Information'; return }
    if (Test-GameRunning) { Show-Msg 'Close Star Citizen first.' 'Warning'; return }
    $dll = Get-GameDll
    if (-not (Test-Path $dll)) { Show-Msg 'No mod DLL in the game folder. Nothing to remove.'; return }
    try {
        Remove-Item -Path $dll -Force -ErrorAction Stop
        Write-Log 'Mod DLL removed from the game folder.' $script:cGood
        Show-Msg 'Removed.'
    } catch {
        Show-Msg ("Could not remove it:`n{0}" -f $_.Exception.Message) 'Warning'
    }
})
$btnAdmin.Add_Click({ Restart-Elevated })
$script:BtnLaunch.Add_Click({ Start-Game })

# ---------- session watcher ----------
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1500
$timer.Add_Tick({
    try {
        $running = Test-GameRunning
        switch ($script:State) {
            'starting' {
                if ($running) {
                    $script:State = 'running'
                    Write-Log 'Game is running.' $script:cGood
                    Refresh-Status
                } elseif (((Get-Date) - $script:StartTime).TotalSeconds -gt 90) {
                    Write-Log 'The game did not start within 90 seconds.' $script:cBad
                    Begin-Cleanup
                }
            }
            'running' {
                if (-not $running) {
                    Write-Log 'Game closed.'
                    Begin-Cleanup
                }
            }
            'cleanup' { Step-Cleanup }
        }
    } catch { }
})
$timer.Start()

$form.Add_FormClosing({
    param($sender, $e)
    if ($script:State -ne 'idle') {
        $e.Cancel = $true
        Show-Msg "The game is running (or being cleaned up).`nClose Star Citizen first, so the mod DLL can be removed from the game folder." 'Warning'
    }
})

# ---------- startup ----------
Load-Fleet
Refresh-AllShips
Refresh-Places
Show-Page 'home'
Refresh-Status
Write-Log 'Launcher ready.'
if (Test-Path (Get-GameDll)) {
    if (-not (Test-GameRunning)) {
        Write-Log 'A mod DLL is still in the game folder from an earlier session. Use Settings > Remove mod DLL before using the RSI launcher.' $script:cWarn
    }
}
if (-not (Test-Path $script:Data)) {
    Write-Log 'Warning: the data folder was not found next to the launcher.' $script:cWarn
}

try {
    [void][System.Windows.Forms.Application]::Run($form)
} catch {
    [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'SC Offline Launcher - error', 'OK', 'Error')
}
