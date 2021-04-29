``` bash
wget https://golang.org/dl/go1.16.3.linux-amd64.tar.gz

rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.16.3.linux-amd64.tar.gz

go build go.go
```