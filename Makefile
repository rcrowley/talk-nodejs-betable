all:
	showoff static
	cp -RT static ~/work/rcrowley/public/talks/nodejs-2013-02-19

clean:
	rm -rf static

.PHONY: all clean
