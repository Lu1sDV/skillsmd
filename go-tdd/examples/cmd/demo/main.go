package main

import (
	"errors"
	"fmt"
	"log"

	budget "example.com/go-tdd"
)

func main() {
	b, err := budget.NewBudget(10)
	if err != nil {
		log.Fatal(err)
	}
	if err := b.Take(11); !errors.Is(err, budget.ErrInsufficient) {
		log.Fatalf("Take(11) = %v; want insufficient budget", err)
	}
	if _, err := fmt.Printf("after rejected request: %d\n", b.Remaining()); err != nil {
		log.Fatal(err)
	}
	if err := b.Take(10); err != nil {
		log.Fatal(err)
	}
	if _, err := fmt.Printf("after exact request: %d\n", b.Remaining()); err != nil {
		log.Fatal(err)
	}
}
