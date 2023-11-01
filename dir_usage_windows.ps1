# Input the directory path
$directoryPath = Read-Host "Enter the directory path to check (if you want to check all Disk (Ex> C:\ and D:\ etc) Enter the 'all')): "

# Set the depth for directory usage check
$maxDepth = Read-Host "Enter the depth (please enter as a number): "
Write-Host "Selected Depth: $maxDepth"

# Define a function to calculate folder size and cache the result
$folderSizeCache = @{}
function Get-FolderSize {
    param (
        [string] $folderPath
    )

    if ($folderSizeCache.ContainsKey($folderPath)) {
        return $folderSizeCache[$folderPath]
    }

    $folderSize = (Get-ChildItem -Path $folderPath -File -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1GB  # Size in GB
    $folderSizeCache[$folderPath] = $folderSize
    return $folderSize
}

# Define a function to show progress for each folder
function Show-Progress {
    param (
        [string] $folderName,
        [int] $currentIndex,
        [int] $totalFolders
    )
    $percentComplete = [math]::Round(($currentIndex / $totalFolders * 100), 0)
    Write-Progress -Activity "Processing Folder $folderName" -Status "Progress: $percentComplete%" -PercentComplete $percentComplete
}

# Available Volume Check & All Disk Directory Usage
if ($directoryPath -eq "all") {
    $volume_list = @()
    $volume_info = Get-Volume
    $driveLetters = $volume_info.DriveLetter

    # driveLetters save the array
    $driveLetters | ForEach-Object {
        $driveLetter = $_
        $volume_list += "$driveLetter" + ":\"
    }

    Write-Host "Drives you have: $($volume_list -join ', ')" 

    # foreach ($volume in $volumes) {
    #     $sizeGB = "{0:F2}" -f ($volume.Size / 1GB)
    #     $usedSpaceGB = "{0:F2}" -f ($volume.SizeRemaining / 1GB)
    #     $freeSpaceGB = "{0:F2}" -f ($volume.SizeUsed / 1GB)
    
    #     Write-Host "Volume Label: $($volume.FileSystemLabel)"
    #     Write-Host "Drive Letter: $($volume.DriveLetter)"
    #     Write-Host "File System: $($volume.FileSystemType)"
    #     Write-Host "Drive Type: $($volume.DriveType)"
    # }

    foreach ($driveLetter in $volume_list) {        
        # directory check under the drive
        $folders = Get-ChildItem -Path $driveLetter -Directory -Recurse -Depth $maxDepth -ErrorAction SilentlyContinue

        $folderDetails = @()
        # Process each folder and calculate size and file count
        $totalSpace = (Get-ChildItem -Path $driveLetter -File -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1GB
        $totalSpace = [math]::Round($totalSpace, 2)
        Write-Host "This Drive is $driveLetter. Let me Check."
        Write-Host "($driveLetter) total used space is: $totalSpace GB"

        for ($i = 0; $i -lt $folders.Count; $i++) {
            $folderPath = $folders[$i].FullName
            Show-Progress -folderName $folderPath -currentIndex $i -totalFolders $folders.Count
            $folderSize = Get-FolderSize -folderPath $folderPath
            $volume = Get-Volume | Where-Object { $_.DriveLetter -eq $folderPath.Substring(0,1) }
            $volumesizeGB = "{0:F2}" -f ($volume.Size / 1GB)
            $volumeusedSpaceGB = "{0:F2}" -f ($volume.SizeRemaining / 1GB)
            $volumeName = $volume.DriveLetter
        
            # disk usage check
            $UsagePercentage = ($folderSize / $volumesizeGB) * 100
        
            $result = [PSCustomObject]@{
                DiskSize_GB = $volumesizeGB
                Used_GB = [math]::Round($folderSize, 2)
                Used_Percent = [math]::Round($UsagePercentage, 2).Tostring() + "%"  
                VolumeName = "$volumeName Drive"
                Path = $folderPath
            }
            $folderDetails += $result
        }

    }

} else {
    $folders = Get-ChildItem -Path $directoryPath -Directory -Recurse -Depth $maxDepth -ErrorAction SilentlyContinue

    $folderDetails = @()
    
    # Process each folder and calculate size and file count
    $totalSpace = (Get-ChildItem -Path $directoryPath -File -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1GB
    $totalSpace = [math]::Round($totalSpace, 2)
    Write-Host "($directoryPath) total used space is: $totalSpace GB"
    
    for ($i = 0; $i -lt $folders.Count; $i++) {
        $folderPath = $folders[$i].FullName
        Show-Progress -folderName $folderPath -currentIndex $i -totalFolders $folders.Count
        $folderSize = Get-FolderSize -folderPath $folderPath
        $volume = Get-Volume | Where-Object { $_.DriveLetter -eq $folderPath.Substring(0,1) }
        $volumesizeGB = "{0:F2}" -f ($volume.Size / 1GB)
        $volumeusedSpaceGB = "{0:F2}" -f ($volume.SizeRemaining / 1GB)
        $volumeName = $volume.DriveLetter
    
        $UsagePercentage = ($folderSize / $volumesizeGB) * 100
    
        $result = [PSCustomObject]@{
            DiskSize_GB = $volumesizeGB
            Used_GB = [math]::Round($folderSize, 2)
            Used_Percent = [math]::Round($UsagePercentage, 2).Tostring() + "%"  # 소수점 2자리까지 반올림
            VolumeName = "$volumeName Drive"
            Path = $folderPath
        }
        $folderDetails += $result
    }
        
}

# Remove the progress display when processing is complete
Write-Progress -Activity "Processing Complete" -Completed

# Sort and display the top 15 folders by size
#$topFolders = $folderDetails | Sort-Object -Property UsedGB -Descending | Select-Object -First 15
#$topFolders | Format-Table -AutoSize

$topFolders = $folderDetails | Sort-Object -Property Used_GB -Descending | Select-Object -First 15
$topFolders | Format-Table -Property DiskSize_GB, Used_GB, Used_Percent, VolumeName, Path -AutoSize | Format-Table -AutoSize -Wrap