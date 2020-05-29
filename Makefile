# Setup the Freedom build script environment
include scripts/Freedom.mk

# Include version identifiers to build up the full version string
include Version.mk
PACKAGE_HEADING := freedom-binutils-metal
PACKAGE_VERSION := $(RISCV_BINUTILS_VERSION)-$(FREEDOM_BINUTILS_METAL_CODELINE)$(FREEDOM_BINUTILS_METAL_GENERATION)b$(FREEDOM_BINUTILS_METAL_BUILD)

# Source code directory references
SRCNAME_BINUTILS := riscv-binutils
SRCPATH_BINUTILS := $(SRCDIR)/$(SRCNAME_BINUTILS)
BARE_METAL_TUPLE := riscv64-unknown-elf
BARE_METAL_CC_FOR_TARGET ?= $(BARE_METAL_TUPLE)-gcc
BARE_METAL_CXX_FOR_TARGET ?= $(BARE_METAL_TUPLE)-g++

# Some special package configure flags for specific targets
$(WIN64)-binutils-host          := --host=$(WIN64)
$(UBUNTU64)-binutils-host       := --host=x86_64-linux-gnu

# Setup the package targets and switch into secondary makefile targets
# Targets $(PACKAGE_HEADING)/install.stamp and $(PACKAGE_HEADING)/libs.stamp
include scripts/Package.mk

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/install.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_BINUTILS)/build.stamp
	mkdir -p $(dir $@)
	date > $@

# We might need some extra target libraries for this package
$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/libs.stamp: \
		$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/install.stamp
	date > $@

$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/libs.stamp: \
		$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/install.stamp
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp:
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/source.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	rm -rf $($@_INSTALL)
	mkdir -p $($@_INSTALL)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cp -a $(SRCPATH_BINUTILS) $(dir $@)
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_BINUTILS)/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_BINUTILS)/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/$(SRCNAME_BINUTILS)/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
# CC_FOR_TARGET is required for the ld testsuite.
	cd $(dir $@) && CC_FOR_TARGET=$(BARE_METAL_CC_FOR_TARGET) ./configure \
		--target=$(BARE_METAL_TUPLE) \
		$($($@_TARGET)-binutils-host) \
		--prefix=$(abspath $($@_INSTALL)) \
		--with-pkgversion="SiFive Binutils $(PACKAGE_VERSION)" \
		--with-bugurl="https://github.com/sifive/freedom-tools/issues" \
		--disable-werror \
		--disable-gdb \
		--disable-sim \
		--disable-libdecnumber \
		--disable-libreadline \
		--with-included-gettext \
		--with-mpc=no \
		--with-mpfr=no \
		--with-gmp=no \
		CFLAGS="-O2" \
		CXXFLAGS="-O2" &>make-configure.log
	$(MAKE) -C $(dir $@) &>$(dir $@)/make-build.log
	$(MAKE) -C $(dir $@) -j1 install install-pdf install-html &>$(dir $@)/make-install.log
	date > $@
