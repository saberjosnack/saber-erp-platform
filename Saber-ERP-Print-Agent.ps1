# ============================================================
#  Saber ERP Print Agent — وكيل الطباعة
#  يستقبل الفواتير من البرنامج ويرسلها للطابعة الحرارية عبر الشبكة
#  شغّله عبر Saber-ERP-Print-Agent.bat (لا تشغّل هذا الملف مباشرة)
# ============================================================

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:9123/")
try { $listener.Start() } catch {
    Write-Host "!! المنفذ 9123 مشغول — أغلق النسخة القديمة من الوكيل وأعد التشغيل" -ForegroundColor Red
    Read-Host "اضغط Enter للخروج"
    exit
}
Write-Host ""
Write-Host "  =========================================" -ForegroundColor Green
Write-Host "   Saber ERP Print Agent شغال ✓" -ForegroundColor Green
Write-Host "   لا تغلق هذه النافذة أثناء العمل" -ForegroundColor Yellow
Write-Host "  =========================================" -ForegroundColor Green
Write-Host ""

while ($listener.IsListening) {
    try {
        $context  = $listener.GetContext()
        $request  = $context.Request
        $response = $context.Response

        # CORS — السماح للبرنامج بالاتصال
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")

        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 204
            $response.Close()
            continue
        }

        if ($request.HttpMethod -eq "POST" -and $request.Url.AbsolutePath -eq "/print") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body   = $reader.ReadToEnd()
            $reader.Close()
            $json   = $body | ConvertFrom-Json
            $bytes  = [System.Convert]::FromBase64String($json.data)
            $ip     = $json.ip
            $port   = if ($json.port) { [int]$json.port } else { 9100 }

            try {
                $client = New-Object System.Net.Sockets.TcpClient
                $client.SendTimeout = 5000
                $client.Connect($ip, $port)
                $stream = $client.GetStream()
                $stream.Write($bytes, 0, $bytes.Length)
                $stream.Flush()
                Start-Sleep -Milliseconds 300
                $stream.Close(); $client.Close()

                Write-Host ("  [{0}] فاتورة انطبعت -> {1}:{2} ({3} بايت)" -f (Get-Date -Format "HH:mm:ss"), $ip, $port, $bytes.Length) -ForegroundColor Cyan
                $out = [System.Text.Encoding]::UTF8.GetBytes('{"ok":true}')
                $response.StatusCode = 200
            } catch {
                Write-Host ("  [{0}] فشل الاتصال بالطابعة {1}:{2} — تأكد من الـIP وأن الطابعة شغالة" -f (Get-Date -Format "HH:mm:ss"), $ip, $port) -ForegroundColor Red
                $out = [System.Text.Encoding]::UTF8.GetBytes('{"ok":false}')
                $response.StatusCode = 502
            }
            $response.ContentType = "application/json"
            $response.OutputStream.Write($out, 0, $out.Length)
            $response.Close()
            continue
        }

        # فحص الحالة
        $out = [System.Text.Encoding]::UTF8.GetBytes('{"agent":"saber-erp","ok":true}')
        $response.StatusCode = 200
        $response.ContentType = "application/json"
        $response.OutputStream.Write($out, 0, $out.Length)
        $response.Close()
    } catch {
        Write-Host ("  خطأ: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}
