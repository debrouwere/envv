all:
	coffee -co lib src

clean:
	rm -rf lib
	rm -rf cache

test: all
	./node_modules/.bin/mocha --reporter list
