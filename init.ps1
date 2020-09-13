$installFolder          = (Split-Path -Parent $MyInvocation.MyCommand.Definition) + "\"
$downloadFolder         = $installFolder + "update\"
##############################################################################

# vc60-toolset configuration
$vc60ToolsetUri         = "https://github.com/kirino17/vc60/releases/download/6.02/vc60env.zip"
$vc60Folder             = $installFolder + "vc60\"
$vc60DownloadFile       = $downloadFolder + "vc60.zip"
$vc60ExecutableFolder   = $vc60Folder + "Common\MSDev98\Bin\"
$vc60VC98Folder         = $vc60Folder + "VC98\Bin\"
$vc60IncludeFolder      = $vc60Folder + "VC98\atl\include;" + $vc60Folder + "VC98\mfc\include;" + $vc60Folder + "VC98\include"
$vc60LibFolder          = $vc60Folder + "VC98\mfc\lib;" + $vc60Folder + "VC98\lib"

#############################################################################
# cmake configuration
$cmakeUri               = "https://github.com/Kitware/CMake/releases/download/v3.0.2/cmake-3.0.2-win32-x86.zip"  #version 3.0.2
$cmakeFolder            = $installFolder + "cmake\"
$cmakeDownloadFile      = $downloadFolder + "cmake302.zip"
$camkeExecutableFolder  = $cmakeFolder

#############################################################################
#############################################################################

function fetch {
    param (
        $Uri,
        $WriteToLocation
    )
    Write-Host ("fetching archive the " + $Uri + " ...")
    Invoke-WebRequest -Uri $Uri -OutFile $WriteToLocation
    Write-Host ("saved to " + $WriteToLocation)
    Write-Host "fetch finished!"

}
function installVC60 {

    # 设置环境变量
    $Env:MSDevDir = $vc60ExecutableFolder
    $Env:include = $vc60IncludeFolder
    $Env:lib = $vc60LibFolder
    $pathValue = $vc60VC98Folder+";"+$vc60ExecutableFolder+";"

    if($Env:Path.IndexOf($pathValue) -eq -1){
        $Env:Path = ($pathValue+$Env:Path)
    }

    do {
        # 编译环境完整性检查
        if(!((Test-Path $vc60ExecutableFolder) -and (Test-Path ($vc60ExecutableFolder + "MSDEV.EXE")))) {
            break
        }

        if(!((Test-Path $vc60VC98Folder) -and (Test-Path ($vc60VC98Folder + "CL.EXE")) -and (Test-Path ($vc60VC98Folder + "LINK.EXE")))){
            break
        }

        return

    } while (0)

    if(!(Test-Path $vc60Folder)){
        New-Item -ItemType Directory -Force -Path $vc60Folder
    }
    else {
        Remove-Item ($vc60Folder + "*") -Recurse
    }

    Write-Host ("installing vc60 toolset: " + $vc60DownloadFile + " ...")
    if(!(Test-Path $vc60DownloadFile)){
        New-Item -ItemType Directory -Force -Path $downloadFolder
        fetch -Uri $vc60ToolsetUri -WriteToLocation $vc60DownloadFile
    }
    Write-Host "expand archive ..."
    Expand-Archive -Path $vc60DownloadFile -DestinationPath $vc60Folder
    Write-Host "install finished!"
}

function installCmake {
    $camkeBinFolder = $cmakeFolder

    if(!(Test-Path $cmakeFolder)){
        New-Item -ItemType Directory -Force -Path $cmakeFolder
    }

    Get-ChildItem $cmakeFolder | ForEach-Object -Process {
        if(($_.Attributes -eq "Directory")){
            $camkeBinFolder += $_.Name
        }
    }
    $camkeBinFolder += "\bin\"

    if($Env:Path.IndexOf($camkeBinFolder) -eq -1){
        $Env:Path = ($camkeBinFolder+";"+$Env:Path)
    }

    $Script:camkeExecutableFolder = $camkeBinFolder

    do{

        if(!(Test-Path ($camkeBinFolder + "cmake.exe"))){
            break
        }

        return

    }while(0)


    if(!(Test-Path $cmakeFolder)){
        New-Item -ItemType Directory -Force -Path $cmakeFolder
    }
    else {
        Remove-Item ($cmakeFolder + "*") -Recurse
    }

    Write-Host ("installing cmake 3.0.2 : " + $cmakeDownloadFile + " ...")
    if(!(Test-Path $cmakeDownloadFile)){
        New-Item -ItemType Directory -Force -Path $downloadFolder
        fetch -Uri $cmakeUri -WriteToLocation $cmakeDownloadFile
        Write-Host "expand archive ..."
    }
    Expand-Archive -Path $cmakeDownloadFile -DestinationPath $cmakeFolder

    $camkeBinFolder = $cmakeFolder
    Get-ChildItem $cmakeFolder | ForEach-Object -Process {
        if(($_.Attributes -eq "Directory")){
            $camkeBinFolder += $_.Name
        }
    }
    $camkeBinFolder += "\bin\"
    if($Env:Path.IndexOf($camkeBinFolder) -eq -1){
        $Env:Path = ($camkeBinFolder+";"+$Env:Path)
    }

    $Script:camkeExecutableFolder = $cmakeFolder

    Write-Host "install finished!"
}

############################################################################
############################################################################
############################################################################

installVC60
installCmake

function make {
    param (
        $Project,
        $Target,
        $SourceDir,
        $OutputDir
    )
    $cmakeOptions = @(
        ('"'+$SourceDir+'"'),
        "-G",
        '"Visual Studio 6"'
    )
    $compileOptions = @(
        ($Project + ".dsw"),
        "/make",
        ('"'+ $Project + " - Win32 " + $Target + '"')
    )
    Start-Process -FilePath "cmake" -WorkingDirectory $OutputDir -ArgumentList $cmakeOptions -NoNewWindow -Wait
    Start-Process -FilePath "msdev" -WorkingDirectory $OutputDir -ArgumentList $compileOptions -NoNewWindow -Wait
}

if($args.Count -ge 4){
    make -Project $args[0] -Target $args[1] -SourceDir $args[2] -OutputDir $args[3]
}




