# ============================================================
# dugduy.ps1 - PEDPRO STORE - COMPLETE FIXED VERSION
# ============================================================

# 1. การตั้งค่าความปลอดภัยและการเชื่อมต่อ (FIX: Connection Error)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

# 2. ข้อมูล API จาก KeyAuth Dashboard
$OwnerID   = "vGgzXjkfQj" 
$AppName   = "GetX"
$AppSecret = "c394cd53bf649b6c32ba7c7b37685554e7d44638323fc0858e87cc2f0088910d" 
$Version   = "1.0"

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       WELCOME TO PEDPRO STORE          " -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

# 3. ระบบ KeyAuth Login (ใช้ .cc เพื่อความเสถียร)
$userKey = Read-Host "[?] Please enter your License Key"
Write-Host "[*] Connecting to PEDPRO Server..." -ForegroundColor Gray

$authUrl = "https://keyauth.cc/api/1.1/?type=init&name=$AppName&ownerid=$OwnerID&ver=$Version"

try {
    # เชื่อมต่อเพื่อขอ Session ID
    $initReq = Invoke-RestMethod -Uri $authUrl -Method Get -TimeoutSec 15 -UserAgent "Mozilla/5.0"
    
    if ($initReq.success -eq "true") {
        $sessionid = $initReq.sessionid
        $loginUrl = "https://keyauth.cc/api/1.1/?type=license&key=$userKey&sessionid=$sessionid&name=$AppName&ownerid=$OwnerID"
        $loginReq = Invoke-RestMethod -Uri $loginUrl -Method Get -UserAgent "Mozilla/5.0"

        if ($loginReq.success -ne "true") {
            Write-Host "[-] ACCESS DENIED: $($loginReq.message)" -ForegroundColor Red
            Write-Host "[!] Press any key to exit..." -ForegroundColor Yellow
            $null = [Console]::ReadKey(); exit
        }
        Write-Host "[+] Login Successful! Welcome to PEDPRO STORE." -ForegroundColor Green
    } else {
        Write-Host "[-] INIT ERROR: $($initReq.message)" -ForegroundColor Red
        Write-Host "[!] Check your App Status on Dashboard." -ForegroundColor Yellow
        $null = [Console]::ReadKey(); exit
    }
} catch {
    Write-Host "[-] CONNECTION ERROR: Server unreachable." -ForegroundColor Red
    Write-Host "[!] Details: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "[*] Try turning off Windows Defender/Antivirus." -ForegroundColor Gray
    Write-Host "[*] Press any key to close..." -ForegroundColor Gray
    $null = [Console]::ReadKey(); exit
}

# 4. ตรวจสอบสิทธิ์ Administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[*] Escalating to Admin..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"iex ((iwr 'https://raw.githubusercontent.com/getx796-Harem/cmdFreefire/main/dugduy.ps1' -UseBasicParsing).Content)`"" -Verb RunAs
    exit
}

# 5. การเตรียมไฟล์และการพรางตัว (Stealth Mode)
$url = "https://github.com/getx796-Harem/cmdFreefire/releases/download/v1.0/AimbotFemaleFix.dll"
$fakeName = "mscories.dll"
$workDir = "$env:LOCALAPPDATA\Microsoft\CLR_v4.0"
$dllPath = Join-Path $workDir $fakeName
$targetProcess = "HD-Player"

if (Test-Path $workDir) { Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $workDir -Force | Out-Null
attrib +h +s $workDir

# 6. ดาวน์โหลดไฟล์ DLL แบบเงียบ
Write-Host "[*] Fetching internal components..." -ForegroundColor Gray
try {
    Invoke-WebRequest -Uri $url -OutFile $dllPath -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Host "[-] DOWNLOAD ERROR: Could not get DLL file." -ForegroundColor Red
    Pause; exit
}

# 7. โค้ด Injection (รันใน RAM)
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

# 8. เริ่มการ Inject เข้า Bluestacks
$proc = Get-Process -Name $targetProcess -ErrorAction SilentlyContinue
if (!$proc) {
    Write-Host "[!] $targetProcess not found. Launching..." -ForegroundColor Yellow
    if (Test-Path "C:\Program Files\BlueStacks_nxt\HD-Player.exe") {
        Start-Process "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Start-Sleep -Seconds 10
        $proc = Get-Process -Name $targetProcess -ErrorAction SilentlyContinue
    }
}

if ($proc) {
    Write-Host "[+] Injecting to $targetProcess (PID: $($proc.Id))..." -ForegroundColor Cyan
    try {
        Add-Type -TypeDefinition $Source -ErrorAction SilentlyContinue
        [Injector]::Inject($proc.Id, $dllPath)
        Write-Host "****************************************" -ForegroundColor Green
        Write-Host "    INJECTION SUCCESSFUL - ENJOY!       " -ForegroundColor Green
        Write-Host "****************************************" -ForegroundColor Green
    } catch {
        Write-Host "[-] INJECTION FAILED." -ForegroundColor Red
    }
} else {
    Write-Host "[-] ERROR: Cannot find or start $targetProcess." -ForegroundColor Red
}

# 9. การลบร่องรอย (Clean Up)
Write-Host "[*] Finalizing and cleaning up..." -ForegroundColor Gray
Start-Sleep -Seconds 5
Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue
Clear-History -ErrorAction SilentlyContinue

Write-Host "[*] Done. Closing in 3 seconds..." -ForegroundColor DarkGray
Start-Sleep -Seconds 3
exit
