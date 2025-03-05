# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script requires administrator privileges. Please run PowerShell as Administrator." -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit
}

# Add the required type for device management
$setupapi = @"
using System;
using System.Runtime.InteropServices;

public class SetupApi {
    [DllImport("setupapi.dll", SetLastError = true)]
    public static extern IntPtr SetupDiGetClassDevs(ref Guid ClassGuid, IntPtr Enumerator, IntPtr hwndParent, uint Flags);
    
    [DllImport("setupapi.dll", SetLastError = true)]
    public static extern bool SetupDiEnumDeviceInfo(IntPtr DeviceInfoSet, uint MemberIndex, ref SP_DEVINFO_DATA DeviceInfoData);
    
    [DllImport("setupapi.dll", SetLastError = true)]
    public static extern bool SetupDiDestroyDeviceInfoList(IntPtr DeviceInfoSet);
    
    [DllImport("setupapi.dll", SetLastError = true)]
    public static extern bool SetupDiGetDeviceRegistryProperty(IntPtr DeviceInfoSet, ref SP_DEVINFO_DATA DeviceInfoData, 
        uint Property, out uint PropertyRegDataType, IntPtr PropertyBuffer, uint PropertyBufferSize, out uint RequiredSize);
    
    [DllImport("setupapi.dll", SetLastError = true)]
    public static extern bool SetupDiSetClassInstallParams(IntPtr DeviceInfoSet, ref SP_DEVINFO_DATA DeviceInfoData, 
        ref SP_PROPCHANGE_PARAMS ClassInstallParams, uint ClassInstallParamsSize);
    
    [DllImport("setupapi.dll", SetLastError = true)]
    public static extern bool SetupDiCallClassInstaller(uint InstallFunction, IntPtr DeviceInfoSet, ref SP_DEVINFO_DATA DeviceInfoData);
    
    [StructLayout(LayoutKind.Sequential)]
    public struct SP_DEVINFO_DATA {
        public uint cbSize;
        public Guid ClassGuid;
        public uint DevInst;
        public IntPtr Reserved;
    }
    
    [StructLayout(LayoutKind.Sequential)]
    public struct SP_PROPCHANGE_PARAMS {
        public SP_CLASSINSTALL_HEADER ClassInstallHeader;
        public uint StateChange;
        public uint Scope;
        public uint HwProfile;
    }
    
    [StructLayout(LayoutKind.Sequential)]
    public struct SP_CLASSINSTALL_HEADER {
        public uint cbSize;
        public uint InstallFunction;
    }
    
    public const int DIGCF_PRESENT = 0x02;
    public const uint DICS_FLAG_GLOBAL = 0x00000001;
    public const uint DIREG_DEV = 0x00000001;
    public const uint DICS_ENABLE = 0x00000001;
    public const uint DICS_DISABLE = 0x00000002;
    public const uint DIF_PROPERTYCHANGE = 0x00000012;
    public const uint SPDRP_DEVICEDESC = 0x00000000;
}
"@

try {
    Add-Type -TypeDefinition $setupapi -ErrorAction Stop

    Write-Host "Resetting USB devices..." -ForegroundColor Yellow
    
    # USB device class GUID
    $USBClassGuid = [Guid]::new("36FC9E60-C465-11CF-8056-444553540000")
    
    # Get device info set
    $deviceInfoSet = [SetupApi]::SetupDiGetClassDevs([ref]$USBClassGuid, [IntPtr]::Zero, [IntPtr]::Zero, [SetupApi]::DIGCF_PRESENT)
    if ($deviceInfoSet -eq [IntPtr]::Zero) {
        throw "Failed to get device info set"
    }
    
    try {
        $devIndex = 0
        $devInfo = New-Object SetupApi+SP_DEVINFO_DATA
        $devInfo.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($devInfo)
        $successCount = 0
        $totalDevices = 0
        
        while ([SetupApi]::SetupDiEnumDeviceInfo($deviceInfoSet, $devIndex, [ref]$devInfo)) {
            $totalDevices++
            $devIndex++
            
            # Get device description
            $propertyType = 0
            $requiredSize = 0
            [SetupApi]::SetupDiGetDeviceRegistryProperty($deviceInfoSet, [ref]$devInfo, [SetupApi]::SPDRP_DEVICEDESC, 
                [ref]$propertyType, [IntPtr]::Zero, 0, [ref]$requiredSize)
            
            $propertyBuffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($requiredSize)
            try {
                if ([SetupApi]::SetupDiGetDeviceRegistryProperty($deviceInfoSet, [ref]$devInfo, [SetupApi]::SPDRP_DEVICEDESC,
                    [ref]$propertyType, $propertyBuffer, $requiredSize, [ref]$requiredSize)) {
                    $deviceName = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($propertyBuffer)
                    Write-Host "Processing device: $deviceName" -ForegroundColor Cyan
                    
                    try {
                        # Prepare disable parameters
                        $propChangeParams = New-Object SetupApi+SP_PROPCHANGE_PARAMS
                        $propChangeParams.ClassInstallHeader.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf([SetupApi+SP_CLASSINSTALL_HEADER])
                        $propChangeParams.ClassInstallHeader.InstallFunction = [SetupApi]::DIF_PROPERTYCHANGE
                        $propChangeParams.StateChange = [SetupApi]::DICS_DISABLE
                        $propChangeParams.Scope = [SetupApi]::DICS_FLAG_GLOBAL
                        $propChangeParams.HwProfile = 0
                        
                        Write-Host "  Disabling..." -ForegroundColor Gray
                        if (![SetupApi]::SetupDiSetClassInstallParams($deviceInfoSet, [ref]$devInfo, [ref]$propChangeParams, 
                            [System.Runtime.InteropServices.Marshal]::SizeOf($propChangeParams))) {
                            throw "Failed to set disable parameters"
                        }
                        
                        if (![SetupApi]::SetupDiCallClassInstaller([SetupApi]::DIF_PROPERTYCHANGE, $deviceInfoSet, [ref]$devInfo)) {
                            throw "Failed to disable device"
                        }
                        
                        Start-Sleep -Seconds 2
                        
                        # Prepare enable parameters
                        $propChangeParams.StateChange = [SetupApi]::DICS_ENABLE
                        
                        Write-Host "  Enabling..." -ForegroundColor Gray
                        if (![SetupApi]::SetupDiSetClassInstallParams($deviceInfoSet, [ref]$devInfo, [ref]$propChangeParams,
                            [System.Runtime.InteropServices.Marshal]::SizeOf($propChangeParams))) {
                            throw "Failed to set enable parameters"
                        }
                        
                        if (![SetupApi]::SetupDiCallClassInstaller([SetupApi]::DIF_PROPERTYCHANGE, $deviceInfoSet, [ref]$devInfo)) {
                            throw "Failed to enable device"
                        }
                        
                        Start-Sleep -Seconds 2
                        Write-Host "  Successfully reset" -ForegroundColor Green
                        $successCount++
                    }
                    catch {
                        Write-Host "  Failed to reset device: $_" -ForegroundColor Red
                    }
                }
            }
            finally {
                [System.Runtime.InteropServices.Marshal]::FreeHGlobal($propertyBuffer)
            }
        }
        
        Write-Host "`nReset complete! Successfully reset $successCount out of $totalDevices devices." -ForegroundColor Green
    }
    finally {
        # Clean up
        [SetupApi]::SetupDiDestroyDeviceInfoList($deviceInfoSet)
    }
} catch {
    Write-Host "`nAn error occurred while processing devices: $_" -ForegroundColor Red
}

# Keep window open
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
