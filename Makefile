default: all

SRC = $(shell find src -name "*.coffee" -type f | sort)
LIB = $(SRC:src/%.coffee=lib/coffee2ls/%.js) lib/coffee2ls/parser.js
LIBMIN = $(LIB:lib/coffee2ls/%.js=lib/coffee2ls/%.min.js)
TESTS = $(shell find test -name "*.coffee" -type f | sort)
ROOT = $(shell pwd)

COFFEE = node_modules/CoffeeScriptRedux/bin/coffee --js --bare
PEGJS = node_modules/.bin/pegjs --track-line-and-column --cache
MOCHA = node_modules/.bin/mocha --compilers coffee:. -u tdd
MINIFIER = node_modules/.bin/uglifyjs --no-copyright --mangle-toplevel --reserved-names require,module,exports,global,window

all: $(LIB)
build: all
parser: lib/coffee2ls/parser.js

lib:
	mkdir lib/

lib/coffee2ls: lib
	mkdir -p lib/coffee2ls/

lib/coffee2ls/parser.js: src/grammar.pegjs lib/coffee2ls
	$(PEGJS) < "$<" > "$@"

lib/coffee2ls/%.min.js: lib/coffee2ls/%.js lib/coffee2ls
	$(MINIFIER) < "$<" >"$@"

lib/coffee2ls/%.js: src/%.coffee lib/coffee2ls
	$(COFFEE) < "$<" > "$@"


.PHONY: test coverage install loc clean

test: $(LIB) $(TESTS)
	$(MOCHA) -R dot

xtest: $(TESTS)
	$(MOCHA) -R dot

coverage: $(LIB)
	@which jscoverage || (echo "install node-jscoverage"; exit 1)
	rm -rf instrumented
	jscoverage -v lib instrumented
	$(MOCHA) -R dot
	$(MOCHA) -r instrumented/coffee-script/compiler -R html-cov > coverage.html
	@xdg-open coverage.html &> /dev/null

install: $(LIB)
	npm install -g .

loc:
	wc -l src/*

clean:
	rm -rf instrumented
	rm -f coverage.html
	rm -rf lib
