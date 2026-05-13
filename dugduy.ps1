# ============================================================
# dugduy.ps1 - PEDPRO STORE (CLOUDFLARE BRIDGE VERSION)
# ============================================================

# 1. ตั้งค่าการเชื่อมต่อให้เสถียรที่สุด
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
netsh winhttp reset proxy | Out-Null
$ProgressPreference = 'SilentlyContinue'

# 2. ข้อมูล API จาก KeyAuth Dashboard (อ้างอิงจาก image_ea4c79.png)
$OwnerID   = "vGgzXjkfQj" 
$AppName   = "GetX"
$Version   = "1.0"

# 3. URL ของ Cloudflare Worker (สะพานเชื่อมที่คุณสร้างใน image_e9679a.jpg)
$BridgeUrl = "https://getx.getx796.workers.dev"

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       WELCOME TO PEDPRO STORE          " -ForegroundColor White
Write-Host "    (Connection via Cloudflare Bridge)  " -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan

# 4. ระบบ Login
$userKey = Read-Host "[?] Please enter your License Key"
Write-Host "[*] Requesting access via getx.getx796.workers.dev..." -ForegroundColor Gray

# เชื่อมต่อผ่านสะพาน Cloudflare (API 1.3)
$authUrl = "$BridgeUrl/api/1.3/?type=init&name=$AppName&ownerid=$OwnerID&ver=$Version"

try {
    # ใช้ User-Agent เพื่อปลอมตัวเป็น Browser ปกติ
    $initReq = Invoke-RestMethod -Uri $authUrl -Method Get -TimeoutSec 15 -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    
    if ($initReq.success -eq "true") {
        $sessionid = $initReq.sessionid
        $loginUrl = "$BridgeUrl/api/1.3/?type=license&key=$userKey&sessionid=$sessionid&name=$AppName&ownerid=$OwnerID"
        $loginReq = Invoke-RestMethod -Uri $loginUrl -Method Get -UserAgent "Mozilla/5.0"

        if ($loginReq.success -ne "true") {
            Write-Host "[-] ACCESS DENIED: $($loginReq.message)" -ForegroundColor Red
            Write-Host "[!] Press any key to exit..." -ForegroundColor Yellow
            $null = [Console]::ReadKey(); exit
        }
        Write-Host "[+] Login Successful! Welcome." -ForegroundColor Green
    } else {
        Write-Host "[-] INIT ERROR: $($initReq.message)" -ForegroundColor Red
        Write-Host "[!] ลองตรวจสอบโค้ดใน Cloudflare Worker อีกครั้ง" -ForegroundColor Yellow
        $null = [Console]::ReadKey(); exit
    }
} catch {
    Write-Host "[-] CONNECTION FAILED" -ForegroundColor Red
    Write-Host "[!] ไม่สามารถติดต่อ Cloudflare Worker ได้" -ForegroundColor Yellow
    Write-Host "[*] ตรวจสอบว่าได้กด Save and Deploy ใน Cloudflare แล้วหรือยัง" -ForegroundColor Gray
    $null = [Console]::ReadKey(); exit
}

# 5. ตรวจสอบสิทธิ์ Administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[*] Escalating to Admin..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"iex ((iwr 'https://raw.githubusercontent.com/getx796-Harem/cmdFreefire/main/dugduy.ps1' -UseBasicParsing).Content)`"" -Verb RunAs
    exit
}

# 6. ดาวน์โหลดไฟล์ DLL
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
    Write-Host "[-] DOWNLOAD ERROR: Cannot reach GitHub." -ForegroundColor Red
    Pause; exit
}

# 7. C# Injector
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

# 8. รันการ Inject เข้าสู่ Bluestacks
$proc = Get-Process -Name $targetProcess -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "[+] Injecting to $targetProcess..." -ForegroundColor Cyan
    try {
        Add-Type -TypeDefinition $Source -ErrorAction SilentlyContinue
        [Injector]::Inject($proc.Id, $dllPath)
        Write-Host "[+] SUCCESS: Inject Complete!" -ForegroundColor Green
    } catch {
        Write-Host "[-] INJECTION FAILED." -ForegroundColor Red
    }
} else {
    Write-Host "[-] ERROR: Please open BlueStacks (HD-Player) first!" -ForegroundColor Red
}

# 9. ล้างไฟล์ชั่วคราว
Write-Host "[*] Finished. Cleaning up..." -ForegroundColor Gray
Start-Sleep -Seconds 5
Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue
exit
