Write-Host "building go version..."
go build -o .\src\go\main.exe .\src\go\main.go

Write-Host "building c#/USE_AWAIT version..."
dotnet publish -c Release -r win-x64 -p:DefineConstants=USE_AWAIT -o .\src\csharp\bin\use_await .\src\csharp\csharp.csproj

Write-Host "building c#/NO_USE_AWAIT version..."
dotnet publish -c Release -r win-x64 -p:DefineConstants=NO_USE_AWAIT -o .\src\csharp\bin\no_use_await .\src\csharp\csharp.csproj

$goExePath = ".\src\go\main.exe"
$csExeNoUseAwaitPath = ".\src\csharp\bin\no_use_await\csharp.exe"
$csExeUseAwaitPath = ".\src\csharp\bin\use_await\csharp.exe"

function Runbenchmark {
  param(
    $iters,
    $ppc,
    $debug,
    $output,
    $csv = $false,
    $appendCsvSepeator = $false
  )

  if ($csv) {
    Write-Output "lang,feature,iters,ppc,iters*ppc,elapsed time" > $output

    if ($appendCsvSepeator) {
      Write-Output "-,-,-,-,-,-" >> $output
    }
  }

  Write-Host "running $iters*$ppc test(go)..."
  &$goExePath -iters $iters -ppc $ppc $(if ($debug) { "-debug" }) >> $output

  $csharpDebugValue = if ($debug) { "true" } else { "false" }

  Write-Host "running $iters*$ppc test(C# noNewTask;no_use_wait)..."
  &$csExeNoUseAwaitPath -iters $iters -ppc $ppc -debug $csharpDebugValue -newTask false >> $output

  Write-Host "running $iters*$ppc test(C# newTask;no_use_wait)..."
  &$csExeNoUseAwaitPath -iters $iters -ppc $ppc -debug $csharpDebugValue -newTask true >> $output

  Write-Host "running $iters*$ppc test(C# noNewTask;use_wait)..."
  &$csExeUseAwaitPath -iters $iters -ppc $ppc -debug $csharpDebugValue -newTask false >> $output

  Write-Host "running $iters*$ppc test(C# newTask;use_wait)..."
  &$csExeUseAwaitPath -iters $iters -ppc $ppc -debug $csharpDebugValue -newTask true >> $output
}

Function GetTimeStamp() {
  return (Get-Date).ToString("yyMMddHHmmss_fff")
}

$resultPathRoot = ".\test_results"
$debugResultPath = Join-Path $resultPathRoot ("debug" + (GetTimeStamp) + ".txt")
$resultPath = Join-Path $resultPathRoot ("result" + (GetTimeStamp) + ".csv")

if (!(Test-Path $resultPathRoot)) { mkdir $resultPathRoot}

Write-Host "--------------------------------------debug mode--------------------------------------"
Runbenchmark 10 1000000 $true $debugResultPath

Write-Host "--------------------------------------benchmark mode--------------------------------------"
Runbenchmark 1 10000000 $false $resultPath $true
Runbenchmark 10 1000000 $false $resultPath $false $true
Runbenchmark 100 100000 $false $resultPath $false $true
Runbenchmark 1000 10000 $false $resultPath $false $true
Runbenchmark 10000 1000 $false $resultPath $false $true
Runbenchmark 100000 100 $false $resultPath $false $true
Runbenchmark 1000000 10 $false $resultPath $false $true
Runbenchmark 10000000 1 $false $resultPath $false $true