package main

import (
	"flag"
	"fmt"
	"sync"
	"time"
)

func syncSingleBenchmark(count int, iteration int, wg *sync.WaitGroup, debugMode bool) {
	defer func() {
		wg.Done()
	}()

	start := time.Now()

	input := createChan()

	go func(in chan int) {
		in <- 0
	}(input)

	for i := 0; i < count; i++ {
		output := createChan()

		go func(pong, ping chan int) {
			pong <- 1 + <-ping
		}(output, input)

		input = output
	}

	finalValue := <-input
	if debugMode {
		fmt.Printf("%dth iteration finished: took %s, final value: %d\n", iteration, time.Since(start), finalValue)
	}
}

func createChan() chan int {
	return make(chan int, 1)
}

var maxIterationCount = flag.Int("iters", 10, "how many iterations")
var pingpongCountPerIteration = flag.Int("ppc", 100_0000, "how many pingpong in single iteration")
var debugMode = flag.Bool("debug", false, "is debug modeto judge whether to print intermediate information")

func main() {
	flag.Parse()

	iterationCount := *maxIterationCount
	pingpongCount := *pingpongCountPerIteration
	debugMode2 := *debugMode

	if debugMode2 {
		fmt.Printf("Started, will run %d(iterations) * %d(ppc./iter.) of benchmark.\n", iterationCount, pingpongCount)
	}

	start := time.Now()
	wg := &sync.WaitGroup{}
	for i := 0; i < iterationCount; i++ {
		wg.Add(1)
		go syncSingleBenchmark(pingpongCount, i, wg, debugMode2)
	}
	wg.Wait()

	if debugMode2 {
		fmt.Printf("Finished totally, took %s.\n", time.Since(start))
	} else {
		fmt.Printf("%s,%d,%d,%d,%s", "go", iterationCount, pingpongCount, iterationCount*pingpongCount, time.Since(start))
	}
}
