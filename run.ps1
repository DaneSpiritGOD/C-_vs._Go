Write-Output "lang,iters,ppc,iters*ppc,elapsed time" > result.csv

go build .\src\go\go.go
.\go.exe -iters 10 -ppc 1000000 >> result.csv