# Makefile for wasm-opt memory-related semantics and optimizations

# Default input/output (override via command line: make target INPUT=my.wasm)
INPUT ?= module.wasm
OUTPUT ?= module.opt.wasm

.PHONY: all help memory-packing limit-memory bulk-memory asyncify

help:
	@echo "wasm-opt memory-related targets:"
	@echo "  memory-packing : Packs memory segments to reduce initialization overhead."
	@echo "  limit-memory   : Enforces usage of memory limits."
	@echo "  bulk-memory    : Optimizes using bulk memory operations (memcpy/memset)."
	@echo "  asyncify       : Instruments code for stack switching (spills locals to memory)."
	@echo "  strip          : Removes debug info and unused module elements."

# --memory-packing
# Merges multiple small data segments into fewer, larger ones.
# This reduces the size of the data section and can speed up instantiation.
memory-packing:
	wasm-opt $(INPUT) -o $(OUTPUT) \
		--memory-packing \
		--print-stats

# --enable-bulk-memory
# Enables the bulk memory proposal (if not already enabled) and optimizes for it.
# This allows the optimizer to use bulk-memory instructions like memory.copy.
bulk-memory:
	wasm-opt $(INPUT) -o $(OUTPUT) \
		--enable-bulk-memory \
		-O3

# --asyncify
# Asyncify transforms the wasm to support suspending and resuming execution.
# It heavily relies on memory to save the stack state (locals and call stack) 
# into a linear memory buffer.
# Customize --pass-arg=asyncify-imports@... based on your imports.
asyncify:
	wasm-opt $(INPUT) -o $(OUTPUT) \
		--asyncify \
		--optimize-level=3

# General cleanup including removing unused memory elements
strip:
	wasm-opt $(INPUT) -o $(OUTPUT) \
		--remove-unused-module-elements \
		--strip-debug \
		--strip-producers \
		--vacuum

# Combination of memory optimizations
optimize-memory:
	wasm-opt $(INPUT) -o $(OUTPUT) \
		--memory-packing \
		--coalesce-locals \
		--simplify-locals \
		--reorder-locals \
		-Oz
