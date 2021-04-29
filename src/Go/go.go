package main

import (
	"flag"
	"fmt"
	"os"
	"sync"
	"time"
)

func measure(start time.Time, name string) {
	elapsed := time.Since(start)
	fmt.Printf("%s took %s", name, elapsed)
	fmt.Println()
}

var maxCount = flag.Int("n", 1000000, "how many")

func f(output, input chan int) {
	output <- 1 + <-input
}

func test() {
	fmt.Printf("Started, sending %d messages.", *maxCount)
	fmt.Println()
	flag.Parse()
	defer measure(time.Now(), fmt.Sprintf("Sending %d messages", *maxCount))
	finalOutput := make(chan int, 1)
	var left, right chan int = nil, finalOutput
	for i := 0; i < *maxCount; i++ {
		left, right = right, make(chan int)
		go f(left, right)
	}
	right <- 0
	x := <-finalOutput
	fmt.Println(x)
}

var wg sync.WaitGroup

func test1() {
	defer wg.Done()
	test()
}

func testPal() {
	var cout = os.Stdout
	var runs = 10
	fmt.Printf("Started, Running %d tests.", runs)
	fmt.Println()
	// var fakecout, _ = os.Open("/dev/null");
	var fakecout, _ = os.Open("NUL")
	os.Stdout = fakecout
	wg.Add(runs)
	defer measure(time.Now(), fmt.Sprintf("Running %d tests", runs))
	for i := 0; i < runs; i++ {
		go test1()
	}
	wg.Wait()
	os.Stdout = cout
}

func main() {
	test()
	test()
	fmt.Println()

	time.Sleep(1000 * time.Millisecond)
	testPal()
	fmt.Println()
}
