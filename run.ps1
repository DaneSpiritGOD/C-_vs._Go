Write-Host "building go version..."
go build -o .\src\go\go.exe .\src\go\go.go

Write-Host "building c# version..."
dotnet build -c Release .\src\csharp\csharp.csproj

function Runbenchmark {
  param(
    $iters,
    $ppc,
    $debug,
    $goPath,
    $csharpPath,
    $output,
    $brandNewCsv = $false,
    $appendCsvSepeator = $false
  )

  if ($brandNewCsv) {
    Write-Output $(if($output.EndsWith(".csv")) { "lang,iters,ppc,iters*ppc,elapsed time" } else { $null }) > $output
  }

  if ($appendCsvSepeator) {
    Write-Output $(if($output.EndsWith(".csv")) { "-,-,-,-,-" } else { $null }) >> $output
  }

  Write-Host "running $iters*$ppc test(go)..."
  &$goPath -iters $iters -ppc $ppc $(if ($debug) { "-debug" }) >> $output

  $csharpDebugValue = if ($debug) { "true" } else { "false" }

  Write-Host "running $iters*$ppc test(C# noNewTask)..."
  &$csharpPath -iters $iters -ppc $ppc -debug $csharpDebugValue -newTask false >> $output

  Write-Host "running $iters*$ppc test(C# newTask)..."
  &$csharpPath -iters $iters -ppc $ppc -debug $csharpDebugValue -newTask true >> $output
}

Write-Host "--------------------------------------debug mode--------------------------------------"
Runbenchmark 10 1000000 $true ".\src\go\go.exe" ".\src\csharp\bin\Release\net5.0\csharp.exe" "debug_results.txt" $true

Write-Host "--------------------------------------benchmark mode--------------------------------------"
Runbenchmark 1 10000000 $false ".\src\go\go.exe" ".\src\csharp\bin\Release\net5.0\csharp.exe" "result.csv" $true
Runbenchmark 10 1000000 $false ".\src\go\go.exe" ".\src\csharp\bin\Release\net5.0\csharp.exe" "result.csv" $false $true
Runbenchmark 100 100000 $false ".\src\go\go.exe" ".\src\csharp\bin\Release\net5.0\csharp.exe" "result.csv" $false $true
Runbenchmark 1000 10000 $false ".\src\go\go.exe" ".\src\csharp\bin\Release\net5.0\csharp.exe" "result.csv" $false $true
Runbenchmark 10000 1000 $false ".\src\go\go.exe" ".\src\csharp\bin\Release\net5.0\csharp.exe" "result.csv" $false $true
Runbenchmark 100000 100 $false ".\src\go\go.exe" ".\src\csharp\bin\Release\net5.0\csharp.exe" "result.csv" $false $true
Runbenchmark 1000000 10 $false ".\src\go\go.exe" ".\src\csharp\bin\Release\net5.0\csharp.exe" "result.csv" $false $true
Runbenchmark 10000000 1 $false ".\src\go\go.exe" ".\src\csharp\bin\Release\net5.0\csharp.exe" "result.csv" $false $true