


all clean:
	for m in */Makefile ; do \
		dir=`dirname $$m`; \
		$(MAKE) -C $$dir $@ ; \
                if [ $$? -ne 0 ]; then \
                  echo "make failed!"; \
                  exit 2; \
                fi \
	done 
