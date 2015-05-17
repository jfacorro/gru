PROJECT=grog

all: get-deps compile

get-deps:
	rm -f mix.lock
	mix deps.get

compile:
	mix deps.compile
	mix compile
	mix compile.protocols

clean-deps:
	mix deps.clean --all
	rm -rf deps

clean: clean-deps
	mix clean

shell:
	iex --name ${PROJECT}@`hostname` -pa _build/dev/consolidated -S mix
