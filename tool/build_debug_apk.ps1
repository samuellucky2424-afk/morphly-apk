$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $repoRoot '.env'

if (-not (Test-Path $envFile)) {
  throw "Missing .env file at $envFile"
}

$localJdk = 'C:\Users\HP\devtools\jdk'
if (-not $env:JAVA_HOME -and (Test-Path $localJdk)) {
  $env:JAVA_HOME = $localJdk
}
if ($env:JAVA_HOME) {
  $env:Path = "$env:JAVA_HOME\bin;$env:Path"
}

$localFlutter = 'C:\Users\HP\devtools\flutter\bin\flutter.bat'
$flutter = if (Test-Path $localFlutter) { $localFlutter } else { 'flutter' }

Push-Location $repoRoot
try {
  & $flutter build apk --debug "--dart-define-from-file=$envFile"
} finally {
  Pop-Location
}
