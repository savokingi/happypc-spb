$ErrorActionPreference = 'Stop'
$assetDir = Join-Path $PSScriptRoot '..\public\images'
New-Item -ItemType Directory -Force -Path $assetDir | Out-Null
$posts = @()
foreach ($suffix in @('', '?before=905', '?before=880', '?before=850')) {
  $html = (Invoke-WebRequest -Uri "https://t.me/s/HappyPC_Piter$suffix").Content
  foreach ($chunk in [regex]::Split($html, '<div class="tgme_widget_message_wrap')) {
    $postId = [regex]::Match($chunk, 'data-post="HappyPC_Piter/(\d+)"').Groups[1].Value
    if (!$postId) { continue }
    $raw = [regex]::Match($chunk, '(?s)<div class="tgme_widget_message_text[^>]*>(.*?)</div>').Groups[1].Value
    $body = [System.Net.WebUtility]::HtmlDecode(([regex]::Replace($raw, '<br\s*/?>', "`n") -replace '<[^>]+>', ''))
    $imgs = @([regex]::Matches($chunk, "background-image:url\('([^']+)'\)") | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -match 'telesco.pe' })
    $posts += [PSCustomObject]@{id=$postId; text=$body; images=$imgs; date=[regex]::Match($chunk, 'datetime="([^"]+)"').Groups[1].Value}
  }
}
$posts | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'asset-sources.json') -Encoding utf8
$downloads = foreach ($post in $posts) { for ($i=0; $i -lt [Math]::Min($post.images.Count, 4); $i++) { [PSCustomObject]@{url=$post.images[$i]; path=(Join-Path $assetDir "$($post.id)-$i.jpg")} } }
$downloads | ForEach-Object -Parallel { try { Invoke-WebRequest -Uri $_.url -OutFile $_.path -TimeoutSec 30 } catch { Write-Warning $_ } } -ThrottleLimit 6
$posts | Select-Object id,@{n='text';e={$_.text.Substring(0,[Math]::Min(180,$_.text.Length))}},@{n='images';e={$_.images.Count}} | Format-Table -Wrap
