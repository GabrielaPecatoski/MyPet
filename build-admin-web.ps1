param(
    [string]$Action = "help"
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$mypetAppPath = Join-Path $projectRoot "mypet_app"
$buildWebPath = Join-Path $mypetAppPath "build" "web"
$nginxHtmlPath = Join-Path $projectRoot "docker" "nginx" "html"

function Show-Help {
    Write-Host "Flutter Web Admin - Build & Deployment Script`n" -ForegroundColor Cyan
    Write-Host "Usage: .\build-admin-web.ps1 [action]`n" -ForegroundColor Gray
    Write-Host "Actions:" -ForegroundColor Yellow
    Write-Host "  build     - Build Flutter web application"
    Write-Host "  copy      - Copy build output to nginx html directory"
    Write-Host "  clean     - Clean build artifacts"
    Write-Host "  serve     - Serve web locally (requires http-server)"
    Write-Host "  full      - Build, copy, and prepare for deployment"
    Write-Host "  help      - Show this help message"
}

function Build-Web {
    Write-Host "`nBuilding Flutter web application..." -ForegroundColor Cyan
    Set-Location $mypetAppPath
    
    if (!(Test-Path $mypetAppPath)) {
        Write-Host "Error: mypet_app directory not found" -ForegroundColor Red
        return $false
    }

    flutter pub get
    flutter build web --base-href "/" --release

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Build successful!" -ForegroundColor Green
        Write-Host "Output location: $buildWebPath`n" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Build failed!" -ForegroundColor Red
        return $false
    }
}

function Copy-ToNginx {
    Write-Host "Copying build to nginx..." -ForegroundColor Cyan
    
    if (!(Test-Path $buildWebPath)) {
        Write-Host "Error: Build directory not found. Run 'build' action first." -ForegroundColor Red
        return $false
    }

    if (!(Test-Path $nginxHtmlPath)) {
        New-Item -ItemType Directory -Path $nginxHtmlPath -Force | Out-Null
        Write-Host "Created nginx html directory" -ForegroundColor Gray
    }

    Copy-Item -Path "$buildWebPath\*" -Destination $nginxHtmlPath -Recurse -Force
    Write-Host "Files copied successfully to: $nginxHtmlPath" -ForegroundColor Green
    return $true
}

function Clean-Build {
    Write-Host "Cleaning build artifacts..." -ForegroundColor Cyan
    
    if (Test-Path $buildWebPath) {
        Remove-Item -Path $buildWebPath -Recurse -Force
        Write-Host "Build directory removed" -ForegroundColor Green
    }

    if (Test-Path $nginxHtmlPath) {
        Remove-Item -Path $nginxHtmlPath -Recurse -Force
        Write-Host "Nginx html directory cleaned" -ForegroundColor Green
    }
}

function Serve-Local {
    Write-Host "Starting local development server..." -ForegroundColor Cyan
    
    if (!(Test-Path $buildWebPath)) {
        Write-Host "Error: Build directory not found. Run 'build' action first." -ForegroundColor Red
        return
    }

    Set-Location $buildWebPath
    npx http-server --port 8080
}

function Full-Build {
    if (Build-Web) {
        Copy-ToNginx
    }
}

switch ($Action) {
    "build" { Build-Web }
    "copy" { Copy-ToNginx }
    "clean" { Clean-Build }
    "serve" { Serve-Local }
    "full" { Full-Build }
    default { Show-Help }
}

Set-Location $projectRoot
