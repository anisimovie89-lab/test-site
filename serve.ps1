$root = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:8137/")
$listener.Start()
Write-Host "serving on 8137"
while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $path = [System.Uri]::UnescapeDataString($ctx.Request.Url.LocalPath).TrimStart('/')
    if ($path -eq "") { $path = "index.html" }
    $file = Join-Path $root ($path -replace '/', '\')
    if (-not [IO.Path]::GetFullPath($file).StartsWith([IO.Path]::GetFullPath($root))) {
      $ctx.Response.StatusCode = 403
      $ctx.Response.Close()
      continue
    }
    if (Test-Path $file -PathType Leaf) {
      $bytes = [IO.File]::ReadAllBytes($file)
      switch -Wildcard ($file) {
        "*.html" { $ctx.Response.ContentType = "text/html; charset=utf-8" }
        "*.jpg"  { $ctx.Response.ContentType = "image/jpeg" }
        "*.png"  { $ctx.Response.ContentType = "image/png" }
        "*.css"  { $ctx.Response.ContentType = "text/css" }
        "*.js"   { $ctx.Response.ContentType = "application/javascript" }
        "*.svg"  { $ctx.Response.ContentType = "image/svg+xml" }
        "*.woff2"{ $ctx.Response.ContentType = "font/woff2" }
      }
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
    }
  } catch {
    Write-Host $_
  }
  try { $ctx.Response.Close() } catch {}
}
