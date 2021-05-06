Write-Host "building go version..."
go build -o .\src\go\go.exe .\src\go\go.go

Write-Host "building c# version..."
dotnet build -c Release .\src\csharp\csharp.csproj

Write-Output "debug mode info" > debug.txt

Write-Host "running debug mode test(go)..."
.\src\go\go.exe -iters 10 -ppc 1000000 -debug >> debug.txt

Write-Host "running debug mode test(C# noNewTask)..."
.\src\csharp\bin\Release\net5.0\csharp.exe -iters 10 -ppc 1000000 -debug true -newTask false >> debug.txt

Write-Host "running debug mode test(C# newTask)..."
.\src\csharp\bin\Release\net5.0\csharp.exe -iters 10 -ppc 1000000 -debug true -newTask true >> debug.txt

Write-Output "lang,iters,ppc,iters*ppc,elapsed time" > result.csv

Write-Host "running 10*1000000 test(go)..."
.\src\go\go.exe -iters 10 -ppc 1000000 >> result.csv
Write-Host "running 10*1000000 test(C# noNewTask)..."
.\src\csharp\bin\Release\net5.0\csharp.exe -iters 10 -ppc 1000000 -debug false -newTask false >> result.csv
Write-Host "running 10*1000000 test(C# newTask)..."
.\src\csharp\bin\Release\net5.0\csharp.exe -iters 10 -ppc 1000000 -debug false -newTask true >> result.csv

Write-Host "running 10*10000000 test(go)..."
.\src\go\go.exe -iters 10 -ppc 10000000 >> result.csv
Write-Host "running 10*10000000 test(C# noNewTask)..."
.\src\csharp\bin\Release\net5.0\csharp.exe -iters 10 -ppc 10000000 -debug false -newTask false >> result.csv
Write-Host "running 10*10000000 test(C# newTask)..."
.\src\csharp\bin\Release\net5.0\csharp.exe -iters 10 -ppc 10000000 -debug false -newTask true >> result.csv