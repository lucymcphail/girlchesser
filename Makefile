.PHONY: build

EXE?=./girlchesser

build:
	gleam build
	gleam run -m gleescript
	cp ./girlchesser $(EXE)
