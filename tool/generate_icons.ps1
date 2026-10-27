Add-Type -AssemblyName System.Drawing

$sourcePath = "e:\PROGRAMMATION\Projet_Mobile\angela_dress\assets\images\logo_mark.png"
if (-not (Test-Path $sourcePath)) {
    Write-Error "Source image not found: $sourcePath"
    exit 1
}

$sourceImg = [System.Drawing.Image]::FromFile($sourcePath)

function Create-AppIcon {
    param(
        [int]$size,
        [string]$destPath,
        [bool]$withBackground = $true
    )

    $parentDir = Split-Path $destPath
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    if ($withBackground) {
        # Draw white circular pastille with subtle cobalt border matching app design
        $pad = [math]::Round($size * 0.04)
        $circleSize = $size - (2 * $pad)
        $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
        $g.FillEllipse($brush, $pad, $pad, $circleSize, $circleSize)
        $brush.Dispose()

        $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(40, 23, 71, 184)), ([math]::Max(1, [math]::Round($size * 0.02)))
        $g.DrawEllipse($pen, $pad, $pad, $circleSize, $circleSize)
        $pen.Dispose()

        # Logo centered inside circle (taking ~65% of the circle)
        $logoWidth = [math]::Round($circleSize * 0.68)
        $logoHeight = [math]::Round($logoWidth * ($sourceImg.Height / $sourceImg.Width))
        $logoX = [math]::Round(($size - $logoWidth) / 2)
        $logoY = [math]::Round(($size - $logoHeight) / 2)
        $g.DrawImage($sourceImg, $logoX, $logoY, $logoWidth, $logoHeight)
    } else {
        # Transparent background, logo fitted with padding
        $pad = [math]::Round($size * 0.10)
        $avail = $size - (2 * $pad)
        $ratio = [math]::Min($avail / $sourceImg.Width, $avail / $sourceImg.Height)
        $logoWidth = [math]::Round($sourceImg.Width * $ratio)
        $logoHeight = [math]::Round($sourceImg.Height * $ratio)
        $logoX = [math]::Round(($size - $logoWidth) / 2)
        $logoY = [math]::Round(($size - $logoHeight) / 2)
        $g.DrawImage($sourceImg, $logoX, $logoY, $logoWidth, $logoHeight)
    }

    $g.Dispose()

    # Save PNG
    if (Test-Path $destPath) {
        Remove-Item $destPath -Force
    }
    $bmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "Generated: $destPath ($size x $size)"
}

# Android mipmap launcher icons
Create-AppIcon 48  "e:\PROGRAMMATION\Projet_Mobile\angela_dress\android\app\src\main\res\mipmap-mdpi\ic_launcher.png"
Create-AppIcon 72  "e:\PROGRAMMATION\Projet_Mobile\angela_dress\android\app\src\main\res\mipmap-hdpi\ic_launcher.png"
Create-AppIcon 96  "e:\PROGRAMMATION\Projet_Mobile\angela_dress\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png"
Create-AppIcon 144 "e:\PROGRAMMATION\Projet_Mobile\angela_dress\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png"
Create-AppIcon 192 "e:\PROGRAMMATION\Projet_Mobile\angela_dress\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"

# Android splash logo icon (for launch_background.xml)
Create-AppIcon 192 "e:\PROGRAMMATION\Projet_Mobile\angela_dress\android\app\src\main\res\drawable\splash_logo.png"
Create-AppIcon 192 "e:\PROGRAMMATION\Projet_Mobile\angela_dress\android\app\src\main\res\drawable-v21\splash_logo.png"

# Web icons
Create-AppIcon 32  "e:\PROGRAMMATION\Projet_Mobile\angela_dress\web\favicon.png"
Create-AppIcon 192 "e:\PROGRAMMATION\Projet_Mobile\angela_dress\web\icons\Icon-192.png"
Create-AppIcon 512 "e:\PROGRAMMATION\Projet_Mobile\angela_dress\web\icons\Icon-512.png"
Create-AppIcon 192 "e:\PROGRAMMATION\Projet_Mobile\angela_dress\web\icons\Icon-maskable-192.png"
Create-AppIcon 512 "e:\PROGRAMMATION\Projet_Mobile\angela_dress\web\icons\Icon-maskable-512.png"

# iOS icons
Create-AppIcon 1024 "e:\PROGRAMMATION\Projet_Mobile\angela_dress\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-1024x1024@1x.png"
Create-AppIcon 20   "e:\PROGRAMMATION\Projet_Mobile\angela_dress\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@1x.png"
Create-AppIcon 40   "e:\PROGRAMMATION\Projet_Mobile\angela_dress\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@2x.png"
Create-AppIcon 60   "e:\PROGRAMMATION\Projet_Mobile\angela_dress\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@3x.png"
Create-AppIcon 29   "e:\PROGRAMMATION\Projet_Mobile\angela_dress\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@1x.png"
Create-AppIcon 58   "e:\PROGRAMMATION\Projet_Mobile\angela_dress\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@2x.png"
Create-AppIcon 87   "e:\PROGRAMMATION\Projet_Mobile\angela_dress\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@3x.png"
Create-AppIcon 40   "e:\PROGRAMMATION\Projet_Mobile\angela_dress\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@1x.png"
Create-AppIcon 80   "e:\PROGRAMMATION\Projet_Mobile\angela_dress\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@2x.png"
Create-AppIcon 120  "e:\PROGRAMMATION\Projet_Mobile\angela_dress\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@3x.png"
Create-AppIcon 120  "e:\PROGRAMMATION\Projet_Mobile\angela_dress\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@2x.png"
Create-AppIcon 180  "e:\PROGRAMMATION\Projet_Mobile\angela_dress\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@3x.png"
Create-AppIcon 76   "e:\PROGRAMMATION\Projet_Mobile\angela_dress\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@1x.png"
Create-AppIcon 152  "e:\PROGRAMMATION\Projet_Mobile\angela_dress\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@2x.png"
Create-AppIcon 167  "e:\PROGRAMMATION\Projet_Mobile\angela_dress\ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-83.5x83.5@2x.png"

$sourceImg.Dispose()
Write-Output "All icons successfully created!"
