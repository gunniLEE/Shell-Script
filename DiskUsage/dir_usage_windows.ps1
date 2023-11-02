# Input the directory path
$validPath = $false
while (-not $validPath) {
    $directoryPath = Read-Host "Enter the directory path to check (if you want to check all Disk (Ex> C:\ and D:\ etc) Enter the 'all')): "

    if (Test-Path -Path $directoryPath -PathType Container) {
        $validPath = $true
    } else {
        Write-Host "Invalid directory path. Please enter a valid directory path."
    }
}

#$directoryPath = Read-Host "Enter the directory path to check (if you want to check all Disk (Ex> C:\ and D:\ etc) Enter the 'all')): "

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

    $volume_list_length = $volume_list.Count

    Write-Host "Drives you have: $($volume_list -join ', ')" 

    for ($i = 0; $i -lt $volume_list.Length; $i++) {
    # foreach ($driveLetter in $volume_list) {        
        # directory check under the drive
        $folders = Get-ChildItem -Path $volume_list[$i] -Directory -Recurse -Depth $maxDepth -ErrorAction SilentlyContinue
        $folderDetails = @()
        # Process each folder and calculate size and file count
        $totalSpace = "{0:F2}" -f ($volume_info[$i].Size / 1GB)
        $usedSpace = "{0:F2}" -f ($volume_info[$i].SizeRemaining / 1GB)
        $remainSpace = $totalSpace - $usedSpace 

        Write-Host "This Drive is $($volume_list[$i]). Let me Check."
        Write-Host "$($volume_list[$i].ToString()) total space is : $totalSpace. total used space is: $remainSpace GB"


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
    if ($volume_list -contains $directoryPath) {
        $directoryLetter = $directoryPath.Substring(0, 1)

        $DriveInfo = $volume_info | Where-Object { $_.DriveLetter -eq $directoryLetter}
        $totalSpace = "{0:F2}" -f ($DriveInfo.Size / 1GB)
        $usedSpace = "{0:F2}" -f ($DriveInfo.SizeRemaining / 1GB)
        $remainSpace = $totalSpace - $usedSpace

        Write-Host "($directoryPath) total space is: $totalSpace GB. total used space is: $remainSpace GB"
    }
    else {
        $totalSpace = (Get-ChildItem -Path $directoryPath -File -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1GB
        $totalSpace = [math]::Round($totalSpace, 2)

        Write-Host "($directoryPath) total used space is: $totalSpace GB"
    }
    
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
            Used_Percent = [math]::Round($UsagePercentage, 2).Tostring() + "%"
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