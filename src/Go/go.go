package main

import (
	"flag"
	"fmt"
	"sync"
	"time"
)

func createChan() chan int {
	return make(chan int)
}

func syncSingleBenchmark(count int, iteration int, wg *sync.WaitGroup) {
	defer func() {
		wg.Done()
	}()

	start := time.Now()

	var output, input chan int = nil, createChan()

	go func(in chan int) {
		in <- 0
	}(input)

	for i := 0; i < count; i++ {
		output = createChan()

		go func(pong, ping chan int) {
			pong <- 1 + <-ping
		}(output, input)

		input = output
	}

	fmt.Printf("%dth iteration finished: took %s, final value: %d\n", iteration, time.Since(start), <-input)
}

var maxIterationCount = flag.Int("iters", 100, "how many iterations")
var pingpongCountPerIteration = flag.Int("n", 1000_0000, "how many pingpong in single iteration")

func main() {
	flag.Parse()

	iterationCount := *maxIterationCount
	pingpongCount := *pingpongCountPerIteration

	fmt.Printf("Started, will Run %d(iterations) * %d(ppc./iter.) of benchmark.\n", iterationCount, pingpongCount)

	start := time.Now()
	wg := &sync.WaitGroup{}
	for i := 0; i < iterationCount; i++ {
		wg.Add(1)
		go syncSingleBenchmark(pingpongCount, i, wg)
	}
	wg.Wait()

	fmt.Printf("Finished totally, took %s.\n", time.Since(start))
}
