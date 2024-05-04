SUBDIRS = src tests

include buildsys.mk

.PHONY: check

tests: src

check: tests
	${MAKE} -C tests -s run
