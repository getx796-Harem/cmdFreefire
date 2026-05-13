# ============================================================
# dugduy.ps1 - Ultimate Injector with KeyAuth (No Restart)
# ============================================================

# --- [ ส่วนการตั้งค่า KeyAuth ] ---
$OwnerID   = "vGgzXjkfQj"      # <--- แก้ไขตรงนี้
$AppName   = "Getx796's Application"      # <--- แก้ไขตรงนี้
$AppSecret = "c394cd15b9a4f86c126e7c7b17681114a7d44638323fcf0010c67cc3789ee756"    # <--- แก้ไขตรงนี้
$Version   = "1.0"

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       WELCOME TO PEDPROSTORE           " -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

# รับ Key จากผู้ใช้
$userKey = Read-Host "[?]  Key freefire "

# เริ่มการตรวจสอบ KeyAuth
$authUrl = "https://keyauth.win/api/1.1/?type=init&name=$AppName&ownerid=$OwnerID&ver=$Version"
try {
    $initReq = Invoke-RestMethod -Uri $authUrl -Method Get
    if ($initReq.success -eq "true") {
        $sessionid = $initReq.sessionid
        $loginUrl = "https://keyauth.win/api/1.1/?type=license&key=$userKey&sessionid=$sessionid&name=$AppName&ownerid=$OwnerID"
        $loginReq = Invoke-RestMethod -Uri $loginUrl -Method Get

        if ($loginReq.success -ne "true") {
            Write-Host "[-] Key outtime! (Error: $($loginReq.message))" -ForegroundColor Red
            Start-Sleep -Seconds 3
            exit
        }
        Write-Host "[+] Login สำเร็จ! PEDPROSTORE." -ForegroundColor Green
    } else {
        Write-Host "[-] ไม่สามารถเชื่อมต่อ API ได้: $($initReq.message)" -ForegroundColor Red
        exit
    }
} catch {
    Write-Host "[-] เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์" -ForegroundColor Red
    exit
}

# --- [ ส่วนการขอสิทธิ์ Administrator ] ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[*] กำลังขอสิทธิ์ Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"iex ((iwr 'https://raw.githubusercontent.com/getx796-Harem/cmdFreefire/main/dugduy.ps1' -UseBasicParsing).Content)`"" -Verb RunAs
    exit
}

# --- [ ส่วนการตั้งค่าไฟล์และการพรางตัว ] ---
$url = "https://github.com/getx796-Harem/cmdFreefire/releases/download/v1.0/AimbotFemaleFix.dll"
$fakeName = "mscories.dll"
$workDir = "$env:LOCALAPPDATA\Microsoft\CLR_v4.0"
$dllPath = Join-Path $workDir $fakeName
$targetProcess = "HD-Player"

# เตรียมโฟลเดอร์พรางตัว
if (Test-Path $workDir) { Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $workDir -Force | Out-Null
attrib +h +s $workDir

# ดาวน์โหลด DLL
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $url -OutFile $dllPath -UseBasicParsing -ErrorAction SilentlyContinue

# --- [ ฟังก์ชัน C# สำหรับ Inject DLL ] ---
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

# --- [ เริ่มรันโปรแกรมและ Inject ] ---
if (Test-Path $dllPath) {
    $proc = Get-Process -Name $targetProcess -ErrorAction SilentlyContinue
    if (!$proc) {
        Write-Host "[*] กำลังเปิด BlueStacks..." -ForegroundColor Yellow
        if (Test-Path "C:\Program Files\BlueStacks_nxt\HD-Player.exe") {
            Start-Process "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
            Start-Sleep -Seconds 8
            $proc = Get-Process -Name $targetProcess -ErrorAction SilentlyContinue
        } else {
            Write-Host "[-] ไม่พบ Path ของ BlueStacks" -ForegroundColor Red
        }
    }

    if ($proc) {
        Write-Host "[+] กำลัง Inject เข้าไปยัง $($targetProcess)..." -ForegroundColor Cyan
        Add-Type -TypeDefinition $Source -ErrorAction SilentlyContinue
        [Injector]::Inject($proc.Id, $dllPath)
        Write-Host "[+] สำเร็จ! ขอให้สนุกกับเกม" -ForegroundColor Green
    }
}

# --- [ การลบร่องรอย (The Ghost Clean) ] ---
Start-Sleep -Seconds 5
Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue
Clear-History -ErrorAction SilentlyContinue

# ล้าง MuiCache Registry
$muiPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
Get-Item -Path $muiPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Property | Where-Object { $_ -like "*$fakeName*" } | ForEach-Object {
    Remove-ItemProperty -Path $muiPath -Name $_ -Force -ErrorAction SilentlyContinue
}

Write-Host "[*] ระบบปิดการทำงานโดยสมบูรณ์" -ForegroundColor DarkGray
Start-Sleep -Seconds 2
exit
