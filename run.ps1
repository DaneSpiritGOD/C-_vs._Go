Write-Host "building go version..."
go build .\src\go\go.go

Write-Host "building c# version..."
dotnet build -c Release .\src\csharp\csharp.csproj > $null

Write-Host "running debug mode test..."

Write-Output $null > debug.txt
.\src\go\go.exe -iters 10 -ppc 1000000 -debug >> debug.txt
.\src\csharp\bin\Release\net5.0\csharp.exe -iters 10 -ppc 1000000 -debug true >> debug.txt

Write-Host "running test..."

Write-Output "lang,iters,ppc,iters*ppc,elapsed time" > result.csv
.\src\go\go.exe -iters 10 -ppc 1000000 >> result.csv
.\src\csharp\bin\Release\net5.0\csharp.exe -iters 10 -ppc 1000000 -debug false >> result.csv