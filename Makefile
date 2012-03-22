all:
	coffee -co lib src

clean:
	rm -rf lib
	rm -rf cache

test: all
	mocha --reporter list --timeout 30000
