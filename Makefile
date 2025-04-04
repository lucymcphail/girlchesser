.PHONY: build

EXE?=girlchesser

build:
ifeq ($(EXE),girlchesser)
	gleam build
	gleam run -m gleescript
else
	gleam build
	gleam run -m gleescript
	mv girlchesser $(EXE)
endif
