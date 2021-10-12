package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	for {
		fmt.Printf("Hello world from pod %s!\n", os.Getenv("POD_NAME"))
		time.Sleep(time.Second * 1)
	}
}
