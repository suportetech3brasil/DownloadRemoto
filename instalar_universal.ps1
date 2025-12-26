if ($instalarPrint) {
    Write-Host "`n[$etapaAtual/$totalEtapas] DRIVER DE IMPRESSAO" -ForegroundColor Yellow
    $novoNome = Read-Host "  -> Nome desejado para a impressora"
    $ip = Read-Host "  -> Endereco IP"
    
    $nomeArquivo = "driver_print_" + ($modelo -replace '\s+','_') + ".exe"
    $filePrint = Obter-Arquivo -url $urlPrint -nomeDestino $nomeArquivo
    
    Write-Host "  -> Extraindo e registrando driver no Windows..." -ForegroundColor Gray
    Start-Process $filePrint -ArgumentList "/S" -Wait
    
    # --- NOVO: Aguarda e verifica se o driver apareceu no sistema ---
    Write-Host "  -> Aguardando registro do driver..." -ForegroundColor Gray
    $tentativas = 0
    $driverEncontrado = $false
    while ($tentativas -lt 15) {
        if (Get-PrinterDriver -Name "*$filtroDriverWindows*" -ErrorAction SilentlyContinue) {
            $driverEncontrado = $true
            $nomeRealDriver = (Get-PrinterDriver -Name "*$filtroDriverWindows*").Name
            break
        }
        Start-Sleep -Seconds 2
        $tentativas++
    }

    if (-not $driverEncontrado) {
        Write-Host "  -> ERRO: O driver '$filtroDriverWindows' nao foi encontrado no Windows apos a instalacao." -ForegroundColor Red
        Write-Host "  -> Verifique se o nome no CSV esta correto." -ForegroundColor Yellow
        Pause
        return
    }

    # Gerenciamento da Porta
    if (-not (Get-PrinterPort $ip -ErrorAction SilentlyContinue)) { 
        Add-PrinterPort -Name $ip -PrinterHostAddress $ip 
    }

    try {
        # Tenta capturar a impressora que o instalador da Samsung costuma criar automaticamente
        $impGenerica = Get-Printer | Where-Object {$_.DriverName -like "*Samsung Universal*" -or $_.Name -like "*Samsung Universal*"} | Select-Object -First 1
        
        if ($impGenerica) {
            Set-Printer -Name $impGenerica.Name -DriverName $nomeRealDriver -PortName $ip
            Rename-Printer -Name $impGenerica.Name -NewName $novoNome
            Write-Host "  -> OK: Impressora vinculada e renomeada!" -ForegroundColor Green
        } else {
            Add-Printer -Name $novoNome -DriverName $nomeRealDriver -PortName $ip
            Write-Host "  -> OK: Fila criada do zero com o driver correto!" -ForegroundColor Green
        }
    } catch {
        Write-Host "  -> Erro ao criar fila: $($_.Exception.Message)" -ForegroundColor Red
    }
    $etapaAtual++
}
