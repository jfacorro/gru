PROJECT=grog

all: deps compile

deps:
	mix deps.get

compile:
	mix compile; mix compile.protocols

clean-deps:
	mix deps.clean --all

clean: clean-deps
	mix clean

shell:
	iex --name ${PROJECT}@`hostname` -pa _build/dev/consolidated -S mix
