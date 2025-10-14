
# SCCM Distribution Point Content Sync Tool


Interactive PowerShell tool for syncing all SCCM/ConfigMgr content from one Distribution Point to another. Perfect for adding new DPs to your environment!



##  Features

-  **Interactive Interface** - No parameters needed, just run and follow prompts
-  **Auto-Discovery** - Automatically lists all available Distribution Points
-  **Real-time Progress** - Colored output with live progress tracking
-  **Comprehensive Coverage** - Syncs all content types:
  - Packages (Legacy)
  - Applications
  - Boot Images
  - OS Images
  - Driver Packages
  - Software Update Packages
  - Task Sequences
-  **Detailed Statistics** - Success/failure counts with completion percentages
-  **Full Logging** - Timestamped logs for audit and troubleshooting
-  **Error Handling** - Continues on failures, reports all issues
-  **Production Ready** - Tested in enterprise environments

## Quick Demo

```
╔════════════════════════════════════════════════════════════╗
║     SCCM Distribution Point Content Sync Tool v3.0         ║
╚════════════════════════════════════════════════════════════╝

[Step 1/4] SCCM Site Configuration
─────────────────────────────────────────────────────────────
Enter SCCM Site Code: CMK
Enter SCCM Site Server FQDN: sccm-server.domain.com

[Step 3/4] Available Distribution Points
─────────────────────────────────────────────────────────────
  Found 3 Distribution Point(s):
    [1] dp01.domain.com
    [2] dp02.domain.com
    [3] dp03.domain.com

Select SOURCE Distribution Point: 1
Select TARGET Distribution Point: 3

┌─────────────────────────────────────────────────────────┐
│ Applications                                              │
└─────────────────────────────────────────────────────────┘
  [1/15] Microsoft Office 2021 ✓
  [2/15] Adobe Reader DC ✓
  [3/15] Google Chrome ✓
```

##  Requirements

- **SCCM Console** installed on the machine
- **PowerShell 5.1** or higher
- **Administrative privileges**
- **SCCM Site Access** with appropriate permissions
- Supported SCCM versions: 2012, 2016, 2019, 2022 (Current Branch)

##  Installation

### Option 1: Download Script Directly
```powershell
# Download the script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Kanlikilic/SCCM_DP_Content_Sync/main/SCCM-DP-Content-Sync.ps1" -OutFile "SCCM-DP-Content-Sync.ps1"
```

### Option 2: Clone Repository
```powershell
git clone https://github.com/Kanlikilic/SCCM DP-Content-Sync.git
cd sccm-dp-content-sync
```

##  Usage

### Basic Usage
Simply run the script - no parameters needed:
```powershell
.\SCCM-DP-Content-Sync.ps1
```

Then follow the interactive prompts:
1. Enter your SCCM Site Code
2. Enter your SCCM Site Server FQDN
3. Select Source Distribution Point from the list
4. Select Target Distribution Point from the list
5. Confirm and watch the magic happen! ✨

### Custom Log Path
```powershell
.\SCCM-DP-Content-Sync.ps1 -LogPath "D:\Logs\MyCustomLog.log"
```

### Getting Help
```powershell
Get-Help .\SCCM-DP-Content-Sync.ps1 -Detailed
```

## Output Example

```
╔════════════════════════════════════════════════════════════╗
║                    DISTRIBUTION SUMMARY                    ║
╚════════════════════════════════════════════════════════════╝

  Packages              : 45/45 (100.0%)
  Applications          : 120/122 (98.4%)
    └─ Failed: 2
  BootImages            : 2/2 (100.0%)
  OSImages              : 5/5 (100.0%)
  DriverPackages        : 8/8 (100.0%)
  SoftwareUpdates       : 12/12 (100.0%)
  TaskSequences         : 6/6 (100.0%)

  ─────────────────────────────────────────────────────────
  Total Items   : 198
  Successful    : 196
  Failed        : 2
  Success Rate  : 99.0%
  Duration      : 0h 15m 32s

╔════════════════════════════════════════════════════════════╗
║      ⚠ Content Distribution Completed with Errors          ║
╚════════════════════════════════════════════════════════════╝
```

##  Troubleshooting

### "SCCM module not found"
**Solution**: Install SCCM Console on the machine where you're running the script.

### "Cannot connect to SCCM site"
**Solution**: 
- Verify Site Code is correct
- Check network connectivity to Site Server
- Ensure you have appropriate SCCM permissions

### Distribution fails for specific content
**Solution**: 
- Check the log file for detailed error messages
- Verify content exists on source DP
- Ensure target DP has enough disk space
- Check distribution point health in SCCM console

### Log File Location
Default: `C:\Logs\SCCM-DP-Sync_YYYYMMDD-HHMMSS.log`

## Project Structure

```
sccm-dp-content-sync/
│
├── SCCM-DP-Content-Sync.ps1    # Main script
├── README.md                    # This file
├── LICENSE                      # MIT License
├── CHANGELOG.md                 # Version history
└── assets/                      # Screenshots and demos
    └── demo.gif
```

##  Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Ideas for Contributions
- Add support for additional content types
- Implement parallel distribution for faster sync
- Add scheduling capabilities
- Create a GUI version
- Add email notifications

##  Changelog

### Version 3.0 (Current)
-  Interactive user interface
-  Automatic DP discovery and listing
-  Enhanced visual feedback with colors
-  Detailed statistics and reporting
-  Improved error handling

### Version 2.0
- Added comprehensive logging
- Added support for Task Sequences
- Improved error handling

### Version 1.0
- Initial release
- Basic content distribution

## License

This project is licensed under the MIT License - see the LICENSE file for details.

##  Disclaimer

This script is provided as-is without any warranty. Always test in a non-production environment first. The authors are not responsible for any issues that may arise from using this script.

##  Author

Mert Efe Kanlikilic

- GitHub: @Kanlikilic (https://github.com/Kanlikilic)
- LinkedIn: https://www.linkedin.com/in/mertefekanlikilic/

## Show Your Support

Give a ⭐️ if this project helped you!

## Support

For issues, questions, or suggestions:
- Open an Issue (https://github.com/Kanlikilic/SCCM_DP_Content_Sync/issues)
- Start a  Discussion (https://github.com/Kanlikilic/SCCM_DP_Content_Sync/discussions)



**Made with ❤️ for the SCCM Community**