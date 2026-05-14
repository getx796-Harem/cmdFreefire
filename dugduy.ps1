# ============================================================
# dugduy.ps1 - PEDPRO STORE (FULL VERSION: BRIDGE + HWID LOCK)
# ============================================================

# 1. ตั้งค่า Environment และ Network
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
netsh winhttp reset proxy | Out-Null
$ProgressPreference = 'SilentlyContinue'

# 2. ข้อมูล API จาก KeyAuth (อ้างอิงจาก image_ea4c79.png)
$OwnerID   = "vGgzXjkfQj" 
$AppName   = "GetX"
$Version   = "1.0"

# 3. URL ของ Cloudflare Worker (สะพานเชื่อมจาก image_e9679a.jpg)
$BridgeUrl = "https://getx.getx796.workers.dev"

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       WELCOME TO PEDPRO STORE          " -ForegroundColor White
Write-Host "    (      DEV PEDPRO      )     " -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan

# 4. ดึงค่า HWID ประจำเครื่อง
# ระบบจะใช้ค่านี้ไปตรวจสอบกับที่ตั้งไว้ใน image_e8fde5.png
$hwid = (Get-CimInstance Win32_ComputerSystemProduct).UUID

# 5. ระบบ Login
$userKey = Read-Host "[?] Please enter your License Key"
Write-Host "[*] Checking license for HWID: $hwid" -ForegroundColor Gray

# ขั้นตอน Init ผ่านสะพาน Cloudflare
$authUrl = "$BridgeUrl/api/1.3/?type=init&name=$AppName&ownerid=$OwnerID&ver=$Version"

try {
    $initReq = Invoke-RestMethod -Uri $authUrl -Method Get -TimeoutSec 15 -UserAgent "Mozilla/5.0"
    
    if ($initReq.success -eq "true") {
        $sessionid = $initReq.sessionid
        
        # ส่งค่า Key และ HWID ไปตรวจสอบพร้อมกัน
        $loginUrl = "$BridgeUrl/api/1.3/?type=license&key=$userKey&sessionid=$sessionid&name=$AppName&ownerid=$OwnerID&hwid=$hwid"
        $loginReq = Invoke-RestMethod -Uri $loginUrl -Method Get -UserAgent "Mozilla/5.0"

        if ($loginReq.success -ne "true") {
            Write-Host "[-] ACCESS DENIED: $($loginReq.message)" -ForegroundColor Red
            if ($loginReq.message -like "*HWID*") {
                Write-Host "[!] ติดล็อคเครื่อง! กรุณารีเซ็ต HWID ใน Dashboard (ดูภาพ image_e8fed9.png)" -ForegroundColor Yellow
            }
            Write-Host "[!] Press any key to exit..." -ForegroundColor Yellow
            $null = [Console]::ReadKey(); exit
        }
        Write-Host "[+] Login Successful! Welcome to GetX." -ForegroundColor Green
    } else {
        Write-Host "[-] INIT ERROR: $($initReq.message)" -ForegroundColor Red
        $null = [Console]::ReadKey(); exit
    }
} catch {
    Write-Host "[-] CONNECTION FAILED: ไม่สามารถติดต่อเซิร์ฟเวอร์ได้" -ForegroundColor Red
    Write-Host "[*] ตรวจสอบเน็ต หรือเช็คว่า Worker ใน Cloudflare ยังทำงานอยู่" -ForegroundColor Gray
    $null = [Console]::ReadKey(); exit
}

# 6. ตรวจสอบสิทธิ์ Administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[*] Escalating to Admin..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"iex ((iwr 'https://raw.githubusercontent.com/getx796-Harem/cmdFreefire/main/dugduy.ps1' -UseBasicParsing).Content)`"" -Verb RunAs
    exit
}

# 7. เตรียมโฟลเดอร์และดาวน์โหลดไฟล์ DLL
$url = "https://github.com/getx796-Harem/cmdFreefire/releases/download/v1.0/AimbotFemaleFix.dll"
$fakeName = "mscories.dll"
$workDir = "$env:LOCALAPPDATA\Microsoft\CLR_v4.0"
$dllPath = Join-Path $workDir $fakeName
$targetProcess = "HD-Player"

if (Test-Path $workDir) { Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $workDir -Force | Out-Null
attrib +h +s $workDir

Write-Host "[*] Downloading components..." -ForegroundColor Gray
try {
    Invoke-WebRequest -Uri $url -OutFile $dllPath -UseBasicParsing
} catch {
    Write-Host "[-] DOWNLOAD ERROR: ไม่สามารถโหลดไฟล์จาก GitHub ได้" -ForegroundColor Red
    Pause; exit
}

# 8. C# Injector Code
$Source = @"
using System;
using System.Runtime.InteropServices;
using System.Diagnostics;
using System.Text;

public class Injector {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);
    [DllImport("kernel32.dll")] public static extern IntPtr GetModuleHandle(string lpModuleName);
    [DllImport("kernel32.dll")] public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
    [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out IntPtr lpNumberOfBytesWritten);
    [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);

    public static void Inject(int pid, string dllPath) {
        IntPtr hProcess = OpenProcess(0x001F0FFF, false, pid);
        IntPtr addr = VirtualAllocEx(hProcess, IntPtr.Zero, (uint)((dllPath.Length + 1) * Marshal.SizeOf(typeof(char))), 0x3000, 0x40);
        IntPtr outSize;
        WriteProcessMemory(hProcess, addr, Encoding.Default.GetBytes(dllPath), (uint)((dllPath.Length + 1) * Marshal.SizeOf(typeof(char))), out outSize);
        IntPtr loadLib = GetProcAddress(GetModuleHandle("kernel32.dll"), "LoadLibraryA");
        CreateRemoteThread(hProcess, IntPtr.Zero, 0, loadLib, addr, 0, IntPtr.Zero);
    }
}
"@

# 9. ค้นหาโปรเซสและทำการ Inject
$proc = Get-Process -Name $targetProcess -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "[+] Found $targetProcess (PID: $($proc.Id))" -ForegroundColor Cyan
    Write-Host "[*] Injecting..." -ForegroundColor Yellow
    try {
        Add-Type -TypeDefinition $Source -ErrorAction SilentlyContinue
        [Injector]::Inject($proc.Id, $dllPath)
        Write-Host "[+] SUCCESS: DLL Injected Successfully!" -ForegroundColor Green
    } catch {
        Write-Host "[-] INJECTION FAILED: เกิดข้อผิดพลาดขณะ Inject" -ForegroundColor Red
    }
} else {
    Write-Host "[-] ERROR: ไม่พบโปรแกรม BlueStacks (HD-Player) กรุณาเปิดเกมก่อน" -ForegroundColor Red
}

# 10. ทำความสะอาด
Write-Host "[*] Finished. Cleaning up in 5s..." -ForegroundColor Gray
Start-Sleep -Seconds 5
Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue
exit
