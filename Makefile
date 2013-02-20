all:
	showoff static
	cp -RT static ~/src/github.com/rcrowley/rcrowley/public/talks/nodejs-2013-02-19

clean:
	rm -rf static

.PHONY: all clean
