# Compila Nivel para Android (arm64) y lo instala en el teléfono conectado por USB.
# Uso:  powershell -File build-android.ps1
# Por qué existe: Tauri crea un enlace simbólico que Windows bloquea sin modo de desarrollador.
# Aquí compilamos la librería Rust con Tauri (el error final se ignora), la copiamos a mano y
# dejamos que Gradle arme el APK saltándose la tarea de Rust.
# ponytail: si activas el modo de desarrollador, basta `npm run tauri android build -- --apk --debug --target aarch64`.
$ErrorActionPreference = 'Stop'
$dev = 'C:\Users\cesar\Documents\3_Progamacion\app_learn\dev'
$env:ANDROID_HOME = "$dev\android-sdk"; $env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:NDK_HOME = "$dev\android-sdk\ndk\27.2.12479018"
$env:JAVA_HOME = "$dev\jdk-21.0.12.1+1"
$env:PATH = "$env:JAVA_HOME\bin;$env:ANDROID_HOME\platform-tools;$env:PATH"
$root = $PSScriptRoot
$android = "$root\src-tauri\gen\android"

Set-Location $root
$ErrorActionPreference = 'Continue'   # tauri termina con error en el enlace; lo esperamos
npm run tauri android build -- --apk --debug --target aarch64 *> $null
$ErrorActionPreference = 'Stop'

$lib = "$root\src-tauri\target\aarch64-linux-android\debug\libnivel_lib.so"
if (-not (Test-Path $lib)) { throw "No se compiló la librería Rust: revisa el error de cargo." }
$jni = "$android\app\src\main\jniLibs\arm64-v8a"
New-Item -ItemType Directory -Force $jni | Out-Null
Copy-Item $lib "$jni\libnivel_lib.so" -Force

Set-Location $android
.\gradlew.bat assembleArm64Debug -x rustBuildArm64Debug --console=plain
if ($LASTEXITCODE -ne 0) { throw "Gradle falló." }

$apk = "$android\app\build\outputs\apk\arm64\debug\app-arm64-debug.apk"
adb install -r $apk
adb shell monkey -p com.nivel.app -c android.intent.category.LAUNCHER 1 | Out-Null
Write-Host "Listo: Nivel instalada y abierta en el teléfono."
