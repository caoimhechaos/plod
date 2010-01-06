#Nothing to be done, file is a perl script
all: plod

plod: plod.1.gz plod.el

install: all 
	cp ./plod /usr/local/bin
	cp ./plod.1.gz /usr/local/man/man1
	cp ./plod.el /usr/local/share/emacs/site-lisp

clean:
	rm ./plod
	rm ./plod.1.gz
	rm ./plod.el
