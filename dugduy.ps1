# ============================================================
# dugduy.ps1 - PEDPRO STORE (ANTI-REVERSE ENGINEERING VERSION)
# ============================================================

# 1. ตั้งค่า Environment และ Network
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
netsh winhttp reset proxy | Out-Null
$ProgressPreference = 'SilentlyContinue'

# 2. ข้อมูล API จาก KeyAuth (อ้างอิงจากข้อมูลของคุณ)
$OwnerID   = "vGgzXjkfQj" 
$AppName   = "GetX"
$Version   = "1.0"

# 3. สะพานเชื่อม Cloudflare (ใส่พาร์ทหลอกตาไว้ ถ้าคนก๊อปไปเปิดใน Chrome จะถูกดีดหนี)
$BridgeUrl = "https://naheeeeeeee.getx796.workers.dev"

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "        WELCOME TO PEDPRO STORE         " -ForegroundColor White
Write-Host "             ( DEV PEDPRO )             " -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan

# 4. ดึงค่า HWID ประจำเครื่องเพื่อตรวจสอบสิทธิ์
$hwid = (Get-CimInstance Win32_ComputerSystemProduct).UUID

# 5. ระบบ Login
$userKey = Read-Host "[?] Please enter your License Key"
Write-Host "[*] Checking license for HWID: $hwid" -ForegroundColor Gray

# ส่ง Request ผ่านสะพาน Cloudflare โดยแนบพารามิเตอร์ของ KeyAuth ปกติ
$authUrl = "$BridgeUrl/api/1.3/?type=init&name=$AppName&ownerid=$OwnerID&ver=$Version"

try {
    # 🕵️‍♂️ ปลอมตัวเป็น Browser และส่งแอบแนบ Header พิเศษเพื่อบอก Worker ว่านี่คือสคริปต์จริง ไม่ใช่คนมาแฮก
    $initReq = Invoke-RestMethod -Uri $authUrl -Method Get -TimeoutSec 15 -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) PowerShell/7.0"
    
    if ($initReq.success -eq "true") {
        $sessionid = $initReq.sessionid
        
        $loginUrl = "$BridgeUrl/api/1.3/?type=license&key=$userKey&sessionid=$sessionid&name=$AppName&ownerid=$OwnerID&hwid=$hwid"
        $loginReq = Invoke-RestMethod -Uri $loginUrl -Method Get -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) PowerShell/7.0"

        if ($loginReq.success -ne "true") {
            Write-Host "[-] ACCESS DENIED: $($loginReq.message)" -ForegroundColor Red
            if ($loginReq.message -like "*HWID*") {
                Write-Host "[!] ติดล็อคเครื่อง! กรุณารีเซ็ต HWID ใน Dashboard" -ForegroundColor Yellow
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
    # 🎭 สับขาหลอก: ถ้าเกิดการ Block หรือหลุดไปหน้าเว็บอื่น ให้ขึ้นข้อความแสดงความผิดพลาดแบบเนียนๆ
    Write-Host "[-] CONNECTION FAILED: ไม่สามารถตั้งค่าความปลอดภัยได้" -ForegroundColor Red
    $null = [Console]::ReadKey(); exit
}

# 6. ตรวจสอบสิทธิ์ Administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[*] Escalating to Admin..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"iex ((iwr 'https://raw.githubusercontent.com/getx796-Harem/cmdFreefire/main/dugduy.ps1' -UseBasicParsing).Content)`"" -Verb RunAs
    exit
}

# 7. เตรียมโฟลเดอร์และดาวน์โหลดไฟล์ DLL ตัวใหม่ล่าสุด
$url = "https://github.com/getx796-Harem/cmdFreefire/releases/download/v1.0/dllfreefire.dll"
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
    Write-Host "[-] DOWNLOAD ERROR: ไม่สามารถดาวน์โหลดโมดูลความปลอดภัยได้" -ForegroundColor Red
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
        Write-Host "[-] INJECTION FAILED: เกิดข้อผิดพลาดขณะส่งข้อมูล" -ForegroundColor Red
    }
} else {
    Write-Host "[-] ERROR: ไม่พบโปรแกรม BlueStacks (HD-Player) กรุณาเปิดเกมก่อน" -ForegroundColor Red
}

# 10. ทำความสะอาด
Write-Host "[*] Finished. Cleaning up in 5s..." -ForegroundColor Gray
Start-Sleep -Seconds 5
Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue
exit
