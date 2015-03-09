#
# Makefile
#
# Copyright 2000, 2001, 2002, 2003, 2004 Dean Ferreyra
#
# $Id: Makefile,v 1.4 2008-09-04 01:10:00 dean Exp $
# Dean Ferreyra

# This file is part of AVR-THREADS.
# 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this library; see the file COPYING.LIB.  If not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite
# 330, Boston, MA 02111-1307  USA
# 
# Contact information:
# 
# Dean Ferreyra
# 12902 Malena Drive
# Santa Ana, CA 92705-1102  USA
# 
# dean@octw.com

%.preview: %.pdf
	AcroRd32 `cygpath -aw $*.pdf` &

%.pdf: %.ps
	gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -r600 -sOutputFile=$*.pdf $*.ps

%.ps: %.dvi
	dvips -t letter -Ppdf $*

%.prn.ps: %.dvi
	dvips -t letter -D 600 -o $*.prn.ps $*

%.html: %.ltx
	tex2page $*.ltx

%.dvi: %.ltx
	latex $*.ltx
	makeindex $*.idx

.SECONDARY:

.PHONY: all
all: threads.pdf web-pages/threads.html

web-pages:
	mkdir $@

web-pages/threads.html: web-pages
	tex2page threads.ltx

.PHONY: final
final: clean
	$(MAKE) -W threads.ltx all
	$(MAKE) -W threads.ltx all
	rm -f web-pages/*.tex web-pages/*.scm web-pages/*.idx web-pages/*.ilg web-pages/*.ind web-pages/*.hlog

threads.preview: threads.pdf

threads.pdf: threads.ps

threads.prn.ps: threads.dvi

threads.dvi: threads.ltx

spell:
	aspell --mode=tex -l < threads.ltx |sort |uniq

spelli:
	aspell --mode=tex -c threads.ltx

.PHONY: clean
clean:
	rm -f *.dvi *.log *.aux *.toc *.ilg *.idx *.ind
	rm -f *.ps *.pdf
	rm -f *.bak
	rm -rf web-pages

.PHONY: distclean
distclean: clean
	rm -f *.tex *.scm *.css *~
	rm -rf web-pages

.PHONY: install
install: all
