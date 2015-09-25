PROJECT=gru

all: deps app protocols cljs

get-deps:
	rm -f mix.lock
	mix deps.get

deps: get-deps
	mix deps.compile

app:
	@mix compile

protocols:
	mix compile.protocols

clean-deps:
	mix deps.clean --all
	rm -rf deps

clean:
	@mix clean

clean-all: clean-deps clean clean-cljs

shell: app
	@iex --name ${PROJECT}@`hostname` -pa _build/dev/consolidated -S mix

escript:
	mix escript.build

tests:
	mix test --trace

cljs:
	@cd web; lein cljsbuild once

clean-cljs:
	@cd web; lein clean
