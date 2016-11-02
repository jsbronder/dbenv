NO_SYMLINK ?= false
pwd=`pwd`

install:
	@install -m 755 -d ~/bin
	@install -m 755 -d ~/.local/dbenv
	@if $(NO_SYMLINK); then \
		install -m 644 base.sh ~/.local/dbenv/;  \
		install -m 755 dbenv-pg ~/bin/; \
		install -m 755 dbenv-redis ~/bin/; \
	else \
		ln -snf $(pwd)/base.sh ~/.local/dbenv/base.sh; \
		ln -snf $(pwd)/dbenv-pg  ~/bin/; \
		ln -snf $(pwd)/dbenv-redis  ~/bin/; \
	fi

uninstall:
	rm ~/bin/dbenv-pg
	rm ~/bin/dbenv-redis
	rm ~/.local/dbenv/base.sh
	rmdir ~/.local/dbenv

