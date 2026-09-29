$ngrok = "C:\Program Files\WindowsApps\ngrok.ngrok_3.39.9.0_x64__1g87z0zv29zzc\ngrok.exe"
$backendAddress = "127.0.0.1"
$backendPort = 5000

$backendReady = Test-NetConnection `
	-ComputerName $backendAddress `
	-Port $backendPort `
	-InformationLevel Quiet

if (-not $backendReady) {
	Write-Error "Backend is not reachable at http://$backendAddress`:$backendPort. Start it first with: npm --prefix backend run dev"
	exit 1
}

Write-Host "Starting ngrok HTTPS tunnel..."
Write-Host "Backend: http://$backendAddress`:$backendPort"

& $ngrok http "$backendAddress`:$backendPort"