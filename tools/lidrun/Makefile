CC ?= cc
CFLAGS ?= -O2 -Wall -Wextra -Werror -std=c11

all: build/lidrun

build/lidrun: lidrun.c
	mkdir -p build
	$(CC) $(CFLAGS) $< -o $@ -framework IOKit -framework CoreFoundation

build/lidrun-test: lidrun.c
	mkdir -p build
	$(CC) $(CFLAGS) -DLIDRUN_TEST $< -o $@

test: build/lidrun-test
	python3 -m unittest discover -s tests -v

clean:
	rm -rf build

.PHONY: all test clean
