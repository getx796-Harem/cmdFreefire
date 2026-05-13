# ============================================================
# dugduy.ps1 - PEDPRO STORE (API 1.3 FIXED VERSION)
# ============================================================

# 1. บังคับใช้โปรโตคอลความปลอดภัยและจัดการ Proxy (แก้ปัญหา Connection Closed)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
netsh winhttp reset proxy | Out-Null
$ProgressPreference = 'SilentlyContinue'

# 2. ข้อมูล API จาก KeyAuth Dashboard (อ้างอิงจาก image_ea4c79.png)
$OwnerID   = "vGgzXjkfQj" 
$AppName   = "GetX"
$Version   = "1.0"
# หมายเหตุ: API 1.3 ไม่ต้องใช้ AppSecret ในการ Init (ตามประกาศในหน้า Dashboard ของคุณ)

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       WELCOME TO PEDPRO STORE          " -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

# 3. ระบบ KeyAuth Login (API 1.3)
$userKey = Read-Host "[?] Please enter your License Key"
Write-Host "[*] Connecting to PEDPRO Server (API 1.3)..." -ForegroundColor Gray

# ลองเชื่อมต่อผ่าน Domain สำรอง (.uk) หาก .win โดนบล็อก
$authUrl = "https://keyauth.uk/api/1.3/?type=init&name=$AppName&ownerid=$OwnerID&ver=$Version"

try {
    # ใช้ User-Agent ของ Browser เพื่อเลี่ยงการโดน ISP ตัดสาย
    $initReq = Invoke-RestMethod -Uri $authUrl -Method Get -TimeoutSec 15 -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    
    if ($initReq.success -eq "true") {
        $sessionid = $initReq.sessionid
        $loginUrl = "https://keyauth.uk/api/1.3/?type=license&key=$userKey&sessionid=$sessionid&name=$AppName&ownerid=$OwnerID"
        $loginReq = Invoke-RestMethod -Uri $loginUrl -Method Get -UserAgent "Mozilla/5.0"

        if ($loginReq.success -ne "true") {
            Write-Host "[-] ACCESS DENIED: $($loginReq.message)" -ForegroundColor Red
            Write-Host "[!] Press any key to exit..." -ForegroundColor Yellow
            $null = [Console]::ReadKey(); exit
        }
        Write-Host "[+] Login Successful! Welcome." -ForegroundColor Green
    } else {
        Write-Host "[-] INIT ERROR: $($initReq.message)" -ForegroundColor Red
        $null = [Console]::ReadKey(); exit
    }
} catch {
    Write-Host "[-] CRITICAL CONNECTION ERROR" -ForegroundColor Red
    Write-Host "[!] ปัญหา: เน็ตบ้าน/Firewall บล็อกการเชื่อมต่อ" -ForegroundColor Yellow
    Write-Host "[*] วิธีแก้: ให้ลองเปิด Cloudflare WARP (1.1.1.1) หรือใช้เน็ตมือถือรัน" -ForegroundColor Gray
    Write-Host "[*] กดปุ่มใดก็ได้เพื่อปิด..." -ForegroundColor Gray
    $null = [Console]::ReadKey(); exit
}

# 4. ตรวจสอบสิทธิ์ Administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[*] Escalating to Admin..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"iex ((iwr 'https://raw.githubusercontent.com/getx796-Harem/cmdFreefire/main/dugduy.ps1' -UseBasicParsing).Content)`"" -Verb RunAs
    exit
}

# 5. การดาวน์โหลดไฟล์ DLL (Aimbot)
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

# 6. C# Injector Source (ตัวเดิมที่ใช้งานได้)
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

# 7. เริ่มการ Inject
$proc = Get-Process -Name $targetProcess -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "[+] Injecting to $targetProcess..." -ForegroundColor Cyan
    Add-Type -TypeDefinition $Source -ErrorAction SilentlyContinue
    [Injector]::Inject($proc.Id, $dllPath)
    Write-Host "[+] SUCCESS: Inject Complete!" -ForegroundColor Green
} else {
    Write-Host "[-] ERROR: Please open BlueStacks (HD-Player) first!" -ForegroundColor Red
}

# 8. ทำความสะอาด
Write-Host "[*] Cleaning up..." -ForegroundColor Gray
Start-Sleep -Seconds 5
Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue
exit
