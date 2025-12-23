# PowerShell script to comment out all print statements in Dart files

$dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse
$packagesFiles = Get-ChildItem -Path "packages" -Filter "*.dart" -Recurse -ErrorAction SilentlyContinue

$allFiles = $dartFiles + $packagesFiles
$totalFiles = 0
$totalPrints = 0

foreach ($file in $allFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    
    # Replace print statements with commented versions
    # Match: optional whitespace + print( ... )
    $pattern = '(?m)^(\s*)(print\()'
    $replacement = '$1// $2'
    
    $content = $content -replace $pattern, $replacement
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        $changedLines = ([regex]::Matches($originalContent, $pattern)).Count
        $totalPrints += $changedLines
        $totalFiles++
        Write-Host "✓ $($file.FullName): $changedLines print(s) commented"
    }
}

Write-Host "`n========================================="
Write-Host "完成! 共处理 $totalFiles 个文件，注释了 $totalPrints 个 print 语句"
Write-Host "========================================="
