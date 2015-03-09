#
# makefile
#
# Copyright 2000, 2001, 2002, 2003, 2004 Dean Ferreyra
#
# $Id: Makefile,v 1.3 2008-09-04 01:10:00 dean Exp $
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

default:
	cd src; $(MAKE)

docs:
	cd doc; $(MAKE) final

install:
	cd src; $(MAKE) install

clean:
	cd src; $(MAKE) clean
	cd doc; $(MAKE) clean

distclean:
	cd src; $(MAKE) distclean
	cd doc; $(MAKE) distclean
