<#
.SYNOPSIS
    Oyunun web surumunu derleyip GitHub Pages'e (gh-pages dali) yayinlar.

.DESCRIPTION
    main dali SADECE kaynak kod olarak kalir; bu script calisma agacina
    ve gercek index'e HIC dokunmaz.

    Nasil: gecici bir index dosyasi kullanilir (GIT_INDEX_FILE).
      1. read-tree --empty          -> bos index
      2. --work-tree=build/web add  -> yalnizca web dosyalari index'e girer
      3. write-tree + commit-tree   -> ebeveynsiz (orphan) tek commit
      4. update-ref + push -f       -> gh-pages guncellenir

    Neden boyle:
      - build/ klasoru index'e hic girmez; 100 MB'lik .exe'nin yanlislikla
        commit'lenmesi (GitHub bunu reddeder) mumkun degildir.
      - Ana depo kullanildigi icin kimlik dogrulama ve safe.directory
        ayarlari zaten calisir.
      - Her yayinda tek commit kalir (force push) -> 38 MB'lik cikti
        repoyu sismez.

.PARAMETER GodotPath
    Godot calistirilabilir dosyasinin tam yolu. Verilmezse bilinen
    konumlar ve PATH denenir.

.PARAMETER SkipExport
    Derlemeyi atla, mevcut build/web icerigini yayinla.

.PARAMETER NoPush
    Commit'i olustur ama push etme (deneme icin).

.EXAMPLE
    powershell -File tools\deploy_web.ps1
    powershell -File tools\deploy_web.ps1 -SkipExport -NoPush
#>
param(
    [string]$GodotPath = "",
    [switch]$SkipExport,
    [switch]$NoPush
)

$ErrorActionPreference = "Stop"
$repo    = Split-Path $PSScriptRoot -Parent
$WEB_DIR = Join-Path $repo "build\web"
$URL     = "https://oktaycosar.github.io/kelime-eslestirme/"
$LIMIT   = 95MB

function Adim($n, $m) { Write-Host ("[{0}] {1}" -f $n, $m) }

function Bul-Godot {
    if ($GodotPath -and (Test-Path $GodotPath)) { return $GodotPath }
    $aday = @(
        "C:\Users\OktayC\Desktop\Godot_v4.7.1-stable_win64.exe",
        "C:\Program Files\Godot\Godot.exe"
    ) | Where-Object { Test-Path $_ }
    if ($aday) { return $aday[0] }
    $cmd = Get-Command godot -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "Godot bulunamadi. -GodotPath ile tam yolu verin."
}

Set-Location $repo

# ------------------------------------------------------------- 1) Derleme
if (-not $SkipExport) {
    $godot = Bul-Godot
    Adim 1 "Godot: $godot"
    New-Item -ItemType Directory -Force -Path $WEB_DIR | Out-Null
    Adim 1 "Web export ediliyor..."
    & $godot --headless --path $repo --export-release "Web" (Join-Path $WEB_DIR "index.html")
    if ($LASTEXITCODE -ne 0) { throw "Export basarisiz (cikis kodu $LASTEXITCODE)" }
} else {
    Adim 1 "Derleme atlandi (-SkipExport)"
}

$html = Join-Path $WEB_DIR "index.html"
if (-not (Test-Path $html)) { throw "build/web/index.html yok - once derleme yapin." }
$dosyalar = Get-ChildItem $WEB_DIR -Recurse -File
Adim 1 ("Web ciktisi: {0} dosya, {1:N1} MB" -f $dosyalar.Count, (($dosyalar | Measure-Object Length -Sum).Sum / 1MB))

# ------------------------------------------------- 2) Gecici index ile tree
$idx = Join-Path $env:TEMP "kelime-pages.index"
if (Test-Path $idx) { Remove-Item $idx -Force }
$env:GIT_INDEX_FILE  = $idx
$env:GIT_DIR         = (Join-Path $repo ".git")
$env:GIT_WORK_TREE   = $WEB_DIR
$eskiKonum = Get-Location
try {
    # WEB_DIR'i calisma agacinin koku yapiyoruz; boylece index'e giren yollar
    # "index.html" gibi KOK seviyesinde olur (aksi halde "build/web/index.html"
    # olur ve site yanlis yerden yayinlanir).
    Set-Location $WEB_DIR
    git read-tree --empty
    if ($LASTEXITCODE -ne 0) { throw "read-tree basarisiz (bu depo degil mi?)" }

    git add -A
    if ($LASTEXITCODE -ne 0) { throw "add basarisiz" }

    # ONEMLI: git diff --cached KULLANMA. O, gecici index'i HEAD ile
    # karsilastirir ve "silinecek 86 dosya" diye sayar. Index'in GERCEK
    # icerigini git ls-files verir.
    $staged = @(git ls-files)
    Adim 2 ("Index'e giren dosya: {0}" -f $staged.Count)
    if ($staged.Count -eq 0)  { throw "Eklenecek dosya yok." }
    if ($staged.Count -gt 30) { throw "Beklenmedik cok dosya ($($staged.Count)). Durduruldu." }

    # --- GUVENLIK: 100 MB siniri ---
    foreach ($f in $staged) {
        $p = Join-Path $WEB_DIR $f
        if (Test-Path $p -PathType Leaf) {
            $s = (Get-Item $p).Length
            if ($s -gt $LIMIT) { throw "Cok buyuk dosya: $f ($([math]::Round($s/1MB,1)) MB)" }
        }
    }
    $toplam = (($staged | ForEach-Object { Join-Path $WEB_DIR $_ } | Where-Object { Test-Path $_ -PathType Leaf } |
                ForEach-Object { (Get-Item $_).Length }) | Measure-Object -Sum).Sum
    Adim 2 ("Yayinlanacak: {0} dosya, {1:N1} MB" -f $staged.Count, ($toplam/1MB))

    $tree = (git write-tree).Trim()
    if (-not $tree) { throw "write-tree basarisiz" }

    # --- GUVENLIK: tree gercekten yalnizca web dosyalarindan mi olusuyor? ---
    $agac = @(git ls-tree --name-only $tree)
    Adim 2 ("Tree icerigi: {0} kok oge" -f $agac.Count)
    foreach ($gerekli in @("index.html", "index.js", "index.wasm", "index.pck")) {
        if ($agac -notcontains $gerekli) { throw "Tree'de $gerekli yok! Yanlis icerik yayinlanacakti." }
    }
    foreach ($yasak in @("build", "scripts", "scenes", "tests", "tools", ".gitignore")) {
        if ($agac -contains $yasak) { throw "Tree'de olmamasi gereken oge var: $yasak" }
    }
    Adim 2 "Tree dogru: sadece web dosyalari"

    $commit = (git commit-tree $tree -m "web: oyunun tarayici surumu").Trim()
    if (-not $commit) { throw "commit-tree basarisiz" }
    Adim 2 "Commit: $($commit.Substring(0,10))"

    git update-ref refs/heads/gh-pages $commit
    Set-Location $eskiKonum
    Adim 2 "gh-pages yerlisi guncellendi"
}
finally {
    Remove-Item Env:\GIT_INDEX_FILE -ErrorAction SilentlyContinue
    Remove-Item Env:\GIT_DIR        -ErrorAction SilentlyContinue
    Remove-Item Env:\GIT_WORK_TREE  -ErrorAction SilentlyContinue
    Remove-Item $idx -Force -ErrorAction SilentlyContinue
}

# ----------------------------------------------------------------- 3) Push
if ($NoPush) {
    Adim 3 "Push atlandi (-NoPush)"
} else {
    Adim 3 "GitHub'a gonderiliyor (38 MB, birkac dakika surebilir)..."
    git push -f origin gh-pages
    if ($LASTEXITCODE -ne 0) { throw "push basarisiz (cikis kodu $LASTEXITCODE)" }
    Adim 3 "Push tamam."
}

Write-Host ""
Write-Host "Bitti. Birkac dakika icinde yayinda: $URL"