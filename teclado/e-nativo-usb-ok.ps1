param(
  [ValidateSet('setup', 'start', 'hook', 'raw', 'stop')]
  [string]$Role = 'setup'
)

$ErrorActionPreference = 'Stop'
$runName = 'NativoSemE-UsbComE'

function Assert-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal $id
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
      '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", '-Role', $Role
    )
    exit
  }
}

$csHook = @'
using System;
using System.Runtime.InteropServices;

public static class NativeEHook {
  const int WH_KEYBOARD_LL = 13;
  const int WM_KEYDOWN = 0x0100;
  const int WM_KEYUP = 0x0101;
  const int WM_SYSKEYDOWN = 0x0104;
  const int WM_SYSKEYUP = 0x0105;
  const int VK_E = 0x45;
  const uint LLKHF_EXTENDED = 0x01;
  const uint LLKHF_INJECTED = 0x10;
  const uint LLKHF_LOWER_IL_INJECTED = 0x02;

  delegate IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam);
  static readonly HookProc Proc = Callback;
  static IntPtr _hook;

  [StructLayout(LayoutKind.Sequential)]
  struct KBDLLHOOKSTRUCT {
    public uint vkCode;
    public uint scanCode;
    public uint flags;
    public uint time;
    public IntPtr dwExtraInfo;
  }

  [StructLayout(LayoutKind.Sequential)]
  struct MSG {
    public IntPtr hwnd;
    public uint message;
    public IntPtr wParam;
    public IntPtr lParam;
    public uint time;
    public int ptX;
    public int ptY;
  }

  [DllImport("user32.dll", SetLastError = true)]
  static extern IntPtr SetWindowsHookEx(int idHook, HookProc lpfn, IntPtr hMod, uint dwThreadId);

  [DllImport("user32.dll")]
  static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

  [DllImport("user32.dll")]
  static extern bool UnhookWindowsHookEx(IntPtr hhk);

  [DllImport("user32.dll")]
  static extern int GetMessage(out MSG lpMsg, IntPtr hWnd, uint wMsgFilterMin, uint wMsgFilterMax);

  [DllImport("user32.dll")]
  static extern bool TranslateMessage(ref MSG lpMsg);

  [DllImport("user32.dll")]
  static extern IntPtr DispatchMessage(ref MSG lpMsg);

  [DllImport("kernel32.dll")]
  static extern IntPtr GetModuleHandle(IntPtr lpModuleName);

  static IntPtr Callback(int nCode, IntPtr wParam, IntPtr lParam) {
    if (nCode >= 0) {
      int msg = (int)wParam.ToInt64();
      if (msg == WM_KEYDOWN || msg == WM_KEYUP || msg == WM_SYSKEYDOWN || msg == WM_SYSKEYUP) {
        KBDLLHOOKSTRUCT k = (KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(KBDLLHOOKSTRUCT));
        bool injected = (k.flags & LLKHF_INJECTED) != 0 || (k.flags & LLKHF_LOWER_IL_INJECTED) != 0;
        bool isE = k.vkCode == VK_E || (k.scanCode == 0x12 && (k.flags & LLKHF_EXTENDED) == 0);
        if (isE && !injected) return (IntPtr)1;
      }
    }
    return CallNextHookEx(_hook, nCode, wParam, lParam);
  }

  public static void Run() {
    _hook = SetWindowsHookEx(WH_KEYBOARD_LL, Proc, GetModuleHandle(IntPtr.Zero), 0);
    if (_hook == IntPtr.Zero) throw new System.ComponentModel.Win32Exception();
    MSG m;
    while (GetMessage(out m, IntPtr.Zero, 0, 0) > 0) {
      TranslateMessage(ref m);
      DispatchMessage(ref m);
    }
    UnhookWindowsHookEx(_hook);
  }
}
'@

$csRaw = @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

public class NativeERaw : NativeWindow {
  const int WM_INPUT = 0x00FF;
  const int RID_INPUT = 0x10000003;
  const int RIDI_DEVICENAME = 0x20000007;
  const int RIM_TYPEKEYBOARD = 1;
  const int RIDEV_INPUTSINK = 0x00000100;
  const uint KEYEVENTF_KEYUP = 0x0002;
  const int VK_E = 0x45;
  const ushort RI_KEY_BREAK = 1;
  const ushort RI_KEY_E0 = 2;
  const uint MAGIC = 0x4E415445;

  static readonly Dictionary<long, bool> Cache = new Dictionary<long, bool>();

  [StructLayout(LayoutKind.Sequential)]
  struct RAWINPUTDEVICE {
    public ushort usUsagePage;
    public ushort usUsage;
    public uint dwFlags;
    public IntPtr hwndTarget;
  }

  [StructLayout(LayoutKind.Sequential)]
  struct RAWINPUTHEADER {
    public uint dwType;
    public uint dwSize;
    public IntPtr hDevice;
    public IntPtr wParam;
  }

  [StructLayout(LayoutKind.Sequential)]
  struct RAWKEYBOARD {
    public ushort MakeCode;
    public ushort Flags;
    public ushort Reserved;
    public ushort VKey;
    public uint Message;
    public uint ExtraInformation;
  }

  [StructLayout(LayoutKind.Sequential)]
  struct RAWINPUT {
    public RAWINPUTHEADER header;
    public RAWKEYBOARD keyboard;
  }

  [StructLayout(LayoutKind.Sequential)]
  struct MOUSEINPUT {
    public int dx;
    public int dy;
    public uint mouseData;
    public uint dwFlags;
    public uint time;
    public IntPtr dwExtraInfo;
  }

  [StructLayout(LayoutKind.Sequential)]
  struct KEYBDINPUT {
    public ushort wVk;
    public ushort wScan;
    public uint dwFlags;
    public uint time;
    public IntPtr dwExtraInfo;
  }

  [StructLayout(LayoutKind.Explicit)]
  struct InputUnion {
    [FieldOffset(0)] public MOUSEINPUT mi;
    [FieldOffset(0)] public KEYBDINPUT ki;
  }

  [StructLayout(LayoutKind.Sequential)]
  struct INPUT {
    public uint type;
    public InputUnion U;
  }

  [DllImport("user32.dll", SetLastError = true)]
  static extern bool RegisterRawInputDevices(RAWINPUTDEVICE[] pRawInputDevices, uint uiNumDevices, uint cbSize);

  [DllImport("user32.dll")]
  static extern uint GetRawInputData(IntPtr hRawInput, uint uiCommand, IntPtr pData, ref uint pcbSize, uint cbSizeHeader);

  [DllImport("user32.dll", CharSet = CharSet.Unicode)]
  static extern uint GetRawInputDeviceInfo(IntPtr hDevice, uint uiCommand, StringBuilder pData, ref uint pcbSize);

  [DllImport("user32.dll", CharSet = CharSet.Unicode)]
  static extern uint GetRawInputDeviceInfo(IntPtr hDevice, uint uiCommand, IntPtr pData, ref uint pcbSize);

  [DllImport("user32.dll", SetLastError = true)]
  static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

  [DllImport("cfgmgr32.dll", CharSet = CharSet.Unicode)]
  static extern int CM_Locate_DevNode(out uint pdnDevInst, string pDeviceID, uint ulFlags);

  [DllImport("cfgmgr32.dll")]
  static extern int CM_Get_Parent(out uint pdnDevInst, uint dnDevInst, uint ulFlags);

  [DllImport("cfgmgr32.dll", CharSet = CharSet.Unicode)]
  static extern int CM_Get_Device_ID(uint dnDevInst, StringBuilder buffer, uint bufferLen, uint ulFlags);

  public void Start() {
    CreateHandle(new CreateParams {
      Caption = "NativeERaw",
      Parent = new IntPtr(-3)
    });
    RAWINPUTDEVICE[] rid = new RAWINPUTDEVICE[1];
    rid[0].usUsagePage = 1;
    rid[0].usUsage = 6;
    rid[0].dwFlags = RIDEV_INPUTSINK;
    rid[0].hwndTarget = Handle;
    if (!RegisterRawInputDevices(rid, 1, (uint)Marshal.SizeOf(typeof(RAWINPUTDEVICE))))
      throw new System.ComponentModel.Win32Exception();
  }

  protected override void WndProc(ref Message m) {
    if (m.Msg == WM_INPUT) HandleInput(m.LParam);
    base.WndProc(ref m);
  }

  void HandleInput(IntPtr hRawInput) {
    uint size = 0;
    uint header = (uint)Marshal.SizeOf(typeof(RAWINPUTHEADER));
    GetRawInputData(hRawInput, RID_INPUT, IntPtr.Zero, ref size, header);
    if (size == 0) return;
    IntPtr buf = Marshal.AllocHGlobal((int)size);
    try {
      if (GetRawInputData(hRawInput, RID_INPUT, buf, ref size, header) != size) return;
      RAWINPUT raw = (RAWINPUT)Marshal.PtrToStructure(buf, typeof(RAWINPUT));
      if (raw.header.dwType != RIM_TYPEKEYBOARD) return;
      if (raw.keyboard.ExtraInformation == MAGIC) return;
      bool isE = raw.keyboard.VKey == VK_E || (raw.keyboard.MakeCode == 0x12 && (raw.keyboard.Flags & RI_KEY_E0) == 0);
      if (!isE) return;
      if (!IsExternal(raw.header.hDevice)) return;
      InjectE((raw.keyboard.Flags & RI_KEY_BREAK) != 0);
    } finally {
      Marshal.FreeHGlobal(buf);
    }
  }

  static void InjectE(bool keyUp) {
    INPUT input = new INPUT();
    input.type = 1;
    input.U.ki.wVk = VK_E;
    input.U.ki.wScan = 0x12;
    input.U.ki.dwFlags = keyUp ? KEYEVENTF_KEYUP : 0;
    input.U.ki.dwExtraInfo = (IntPtr)MAGIC;
    INPUT[] arr = new INPUT[] { input };
    SendInput(1, arr, Marshal.SizeOf(typeof(INPUT)));
  }

  static bool IsExternal(IntPtr hDevice) {
    long key = hDevice.ToInt64();
    bool cached;
    if (Cache.TryGetValue(key, out cached)) return cached;
    bool ext = DeviceNameIsExternal(GetDeviceName(hDevice));
    Cache[key] = ext;
    return ext;
  }

  static string GetDeviceName(IntPtr hDevice) {
    uint size = 0;
    GetRawInputDeviceInfo(hDevice, RIDI_DEVICENAME, IntPtr.Zero, ref size);
    if (size == 0) return "";
    StringBuilder sb = new StringBuilder((int)size);
    if (GetRawInputDeviceInfo(hDevice, RIDI_DEVICENAME, sb, ref size) == 0) return "";
    return sb.ToString();
  }

  static bool DeviceNameIsExternal(string rawName) {
    if (string.IsNullOrEmpty(rawName)) return false;
    string id = rawName;
    if (id.StartsWith(@"\\?\")) id = id.Substring(4);
    int brace = id.IndexOf('{');
    if (brace > 0) id = id.Substring(0, brace).TrimEnd('#', '\\');
    id = id.Replace('#', '\\');
    uint node;
    if (CM_Locate_DevNode(out node, id, 0) != 0) {
      return rawName.IndexOf("USB", StringComparison.OrdinalIgnoreCase) >= 0
          || rawName.IndexOf("BTHENUM", StringComparison.OrdinalIgnoreCase) >= 0;
    }
    for (int i = 0; i < 12; i++) {
      StringBuilder sb = new StringBuilder(512);
      if (CM_Get_Device_ID(node, sb, 512, 0) != 0) break;
      string cur = sb.ToString();
      if (cur.StartsWith(@"USB\", StringComparison.OrdinalIgnoreCase)) return true;
      if (cur.StartsWith(@"BTHENUM\", StringComparison.OrdinalIgnoreCase)) return true;
      if (cur.StartsWith(@"BTHLEDEVICE\", StringComparison.OrdinalIgnoreCase)) return true;
      if (cur.StartsWith(@"ACPI\", StringComparison.OrdinalIgnoreCase)) return false;
      if (cur.StartsWith(@"ROOT\", StringComparison.OrdinalIgnoreCase)) return false;
      uint parent;
      if (CM_Get_Parent(out parent, node, 0) != 0) break;
      if (parent == node) break;
      node = parent;
    }
    return false;
  }
}
'@

if ($Role -eq 'stop') {
  Assert-Admin
  Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $runName -ErrorAction SilentlyContinue
  Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object {
    $_.CommandLine -and $_.CommandLine -match 'e-nativo-usb-ok.ps1' -and $_.CommandLine -match '-Role (hook|raw)'
  } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  Write-Host 'Filtro parado. Tecla E do notebook volta a funcionar (se estiver presa, volta o eeee).'
  pause
  exit
}

if ($Role -eq 'setup') {
  Assert-Admin

  $layout = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
  $tinhaMapa = $null -ne (Get-ItemProperty -Path $layout -Name 'Scancode Map' -ErrorAction SilentlyContinue)
  if ($tinhaMapa) {
    Remove-ItemProperty -Path $layout -Name 'Scancode Map' -Force
    Write-Host 'Removido o mapa global da tecla E (ele matava o E no USB).'
  }

  Get-PnpDevice -Class Keyboard -ErrorAction SilentlyContinue | ForEach-Object {
    try { Enable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false -ErrorAction Stop } catch {}
  }
  Write-Host 'Teclado nativo religado.'

  $dir = Join-Path $env:LOCALAPPDATA 'NativoSemE'
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  $ps1 = Join-Path $dir 'e-nativo-usb-ok.ps1'
  Copy-Item -LiteralPath $PSCommandPath -Destination $ps1 -Force

  $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ps1`" -Role start"
  New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $runName -Value $cmd -PropertyType String -Force | Out-Null

  if ($tinhaMapa) {
    Write-Host 'Reiniciando para o USB voltar a enviar E. O filtro sobe depois do login.'
    shutdown.exe /r /t 5 /c "Reiniciando para o E do USB voltar. O filtro do E nativo sobe apos o login."
    exit
  }

  Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object {
    $_.CommandLine -and $_.CommandLine -match 'e-nativo-usb-ok.ps1' -and $_.CommandLine -match '-Role (hook|raw)' -and $_.ProcessId -ne $PID
  } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

  Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ps1, '-Role', 'hook'
  )
  Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ps1, '-Role', 'raw'
  )

  Write-Host ''
  Write-Host 'Filtro ativo (precisa ficar rodando em segundo plano):'
  Write-Host '  Notebook: teclado nativo ligado, so o E bloqueado'
  Write-Host '  USB: E funciona'
  Write-Host 'Sobe automaticamente no login. Para parar: desabilitar-filtro-e.bat'
  pause
  exit
}

if ($Role -eq 'start') {
  Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object {
    $_.CommandLine -and $_.CommandLine -match 'e-nativo-usb-ok.ps1' -and $_.CommandLine -match '-Role (hook|raw)' -and $_.ProcessId -ne $PID
  } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

  Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, '-Role', 'hook'
  )
  Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, '-Role', 'raw'
  )
  exit
}

if ($Role -eq 'hook') {
  Add-Type -TypeDefinition $csHook
  [NativeEHook]::Run()
  exit
}

if ($Role -eq 'raw') {
  Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition $csRaw
  $raw = New-Object NativeERaw
  $raw.Start()
  $ctx = New-Object System.Windows.Forms.ApplicationContext
  [System.Windows.Forms.Application]::Run($ctx)
  exit
}
