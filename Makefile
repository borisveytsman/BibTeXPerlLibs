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

distclean:

install:
	for dir in ${DIRS}; do (cd $$dir && ${MAKE} -f Makefile.TDS install); done

archive:
	COPYFILE_DISABLE=1 tar -czvf $(PACKAGE).tgz -C .. --exclude '*~' --exclude '*.tgz' --exclude CVS $(PACKAGE)
