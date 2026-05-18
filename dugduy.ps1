# ============================================================
# dugduy.ps1 - PEDPRO STORE (ORIGINAL STABLE VERSION)
# ============================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
netsh winhttp reset proxy | Out-Null
$ProgressPreference = 'SilentlyContinue'

$OwnerID   = "vGgzXjkfQj" 
$AppName   = "GetX"
$Version   = "1.0"
$BridgeUrl = "https://naheeeeeeee.getx796.workers.dev"

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "        WELCOME TO PEDPRO STORE         " -ForegroundColor White
Write-Host "             ( DEV PEDPRO )             " -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan

$hwid = (Get-CimInstance Win32_ComputerSystemProduct).UUID
$userKey = Read-Host "[?] Please enter your License Key"
Write-Host "[*] Checking license for HWID: $hwid" -ForegroundColor Gray

$authUrl = "$BridgeUrl/api/1.3/?type=init&name=$AppName&ownerid=$OwnerID&ver=$Version"

try {
    $initReq = Invoke-RestMethod -Uri $authUrl -Method Get -TimeoutSec 15 -UserAgent "Mozilla/5.0"
    
    if ($initReq.success -eq "true") {
        $sessionid = $initReq.sessionid
        $loginUrl = "$BridgeUrl/api/1.3/?type=license&key=$userKey&sessionid=$sessionid&name=$AppName&ownerid=$OwnerID&hwid=$hwid"
        $loginReq = Invoke-RestMethod -Uri $loginUrl -Method Get -UserAgent "Mozilla/5.0"

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
    Write-Host "[-] CONNECTION FAILED: ไม่สามารถติดต่อเซิร์ฟเวอร์ได้" -ForegroundColor Red
    $null = [Console]::ReadKey(); exit
}

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[*] Requesting Admin Privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"iex ((iwr 'https://raw.githubusercontent.com/getx796-Harem/cmdFreefire/main/dugduy.ps1' -UseBasicParsing).Content)`"" -Verb RunAs
    exit
}

# ลิงก์ดาวน์โหลด DLL ตัวใหม่ล่าสุดตามที่ระบุ
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
    Write-Host "[-] DOWNLOAD ERROR: ไม่สามารถโหลดไฟล์โมดูลได้" -ForegroundColor Red
    Pause; exit
}

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

$proc = Get-Process -Name $targetProcess -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "[+] Found $targetProcess (PID: $($proc.Id))" -ForegroundColor Cyan
    try {
        Add-Type -TypeDefinition $Source -ErrorAction SilentlyContinue
        [Injector]::Inject($proc.Id, $dllPath)
        Write-Host "[+] SUCCESS: DLL Injected Successfully!" -ForegroundColor Green
    } catch {
        Write-Host "[-] INJECTION FAILED" -ForegroundColor Red
    }
} else {
    Write-Host "[-] ERROR: ไม่พบโปรแกรม BlueStacks ($targetProcess) กรุณาเปิดเกมก่อน" -ForegroundColor Red
}

Write-Host "[*] Cleaning up in 5s..." -ForegroundColor Gray
Start-Sleep -Seconds 5
Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue
exit
