#
# This is Makefile for TDS-compliant TeX distributions
# Written by Boris Veytsman, boris@varphi.com
#
# This file is in public domain
#

PACKAGE = bibtexperllibs

DIRS = BibTeX-Parser LaTeX-ToUnicode

all:

clean:
	for dir in ${DIRS}; do (cd $$dir && ${MAKE} -f Makefile.TDS clean); done


distclean: clean
	for dir in ${DIRS}; do (cd $$dir && ${MAKE} -f Makefile.TDS distclean); done

install:
	for dir in ${DIRS}; do (cd $$dir && ${MAKE} -f Makefile.TDS install); done

archive: 
	for dir in ${DIRS}; do (cd $$dir && ${MAKE} -f Makefile.TDS docs); done
	for dir in ${DIRS}; do (cd $$dir && ${MAKE} -f Makefile.TDS clean); done
	COPYFILE_DISABLE=1 tar -czvf $(PACKAGE).tgz -C .. --exclude '*~' --exclude '*.tgz' --exclude CVS  --exclude .git --exclude .gitignore --exclude blib  --exclude "*.tar.gz" --exclude pm_to_blib  $(PACKAGE)
