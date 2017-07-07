BINDIR ?= ~/bin

# This can be overwritten but right now we only support ~/.local/dbenv or
# /usr/share/dbenv/ without having DBENV_ROOT set in the environment
DBENV_ROOT ?= ~/.local/dbenv

DRIVERDIR = $(DBENV_ROOT)/drivers
DRIVERS=pg redis

.PHONY: test

install:
	install -m 755 -d $(DBENV_ROOT)/bin
	install -m 755 dbenv $(DBENV_ROOT)/bin
	install -m 755 -d $(DRIVERDIR)
	install -m 755 -d $(BINDIR)
	for driver in $(DRIVERS); do \
		ln -snf $(DBENV_ROOT)/bin/dbenv $(BINDIR)/dbenv-$${driver}; \
		install -m 644 drivers/$${driver} $(DRIVERDIR)/; \
	done;

uninstall:
	rm $(DBENV_ROOT)/bin/dbenv
	for driver in $(DRIVERS); do \
		rm $(BINDIR)/dbenv-$${driver}; \
		rm $(DRIVERDIR)/$${driver}; \
	done;
	rmdir $(DRIVERDIR)

test:
	@for driver in $(DRIVERS); do \
		echo Testing $${driver}; \
		test/test-$${driver}; \
	done;
