PROJECT ?= rockchip-iqfiles
PREFIX ?= /usr
ETCDIR ?= /etc
BINDIR ?= $(PREFIX)/bin
LIBDIR ?= $(PREFIX)/lib
SHAREDIR ?= $(PREFIX)/share
MANDIR ?= $(SHAREDIR)/man

.PHONY: all
all: build

#
# Test
#
.PHONY: test
test:

#
# Build
#
.PHONY: build
build: build-man build-doc

SRC-MAN		:=	man
SRCS-MAN	:=	$(wildcard $(SRC-MAN)/*.md)
MANS		:=	$(SRCS-MAN:.md=)
.PHONY: build-man
build-man: $(MANS)

$(SRC-MAN)/%: $(SRC-MAN)/%.md
	pandoc "$<" -o "$@" --from markdown --to man -s

SRC-DOC		:=	.
DOCS		:=	$(SRC-DOC)/SOURCE
build-doc: $(DOCS)

$(SRC-DOC):
	mkdir -p $(SRC-DOC)

.PHONY: $(SRC-DOC)/SOURCE
$(SRC-DOC)/SOURCE: $(SRC-DOC)
	echo -e "git clone $(shell git remote get-url origin)\ngit checkout $(shell git rev-parse HEAD)" > "$@"

#
# Install
#
.PHONY: install
install: install-man
	install -d $(DESTDIR)$(SHAREDIR)/${PROJECT}
	install -m 644 usr/share/${PROJECT}/* $(DESTDIR)$(SHAREDIR)/${PROJECT}
	install -d $(DESTDIR)$(ETCDIR)/iqfiles
	ln -fs $(SHAREDIR)/${PROJECT}/imx219_rpi-camera-v2_default.xml $(DESTDIR)$(ETCDIR)/iqfiles/imx219_rpi-camera-v2_default.xml

.PHONY: install-man
install-man: build-man
	install -d $(DESTDIR)$(MANDIR)/man7
	install -m 644 $(SRC-MAN)/*.7 $(DESTDIR)$(MANDIR)/man7/

#
# Clean
#
.PHONY: distclean
distclean: clean

.PHONY: clean
clean: clean-man clean-doc clean-deb

.PHONY: clean-man
clean-man:
	rm -rf $(MANS)

.PHONY: clean-doc
clean-doc:
	rm -rf $(DOCS)

.PHONY: clean-deb
clean-deb:
	rm -rf debian/.debhelper debian/${PROJECT} debian/debhelper-build-stamp debian/files debian/*.debhelper.log debian/*.postrm.debhelper debian/*.substvars

#
# Release
#
.PHONY: dch
dch: debian/changelog
	gbp dch --debian-branch=main

.PHONY: deb
deb: debian
	debuild --no-sign
