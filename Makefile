# Setup the Freedom build script environment
include scripts/Freedom.mk

# Include version identifiers to build up the full version string
include Version.mk
PACKAGE_HEADING := freedom-binutils-metal
PACKAGE_VERSION := $(RISCV_BINUTILS_VERSION)-$(FREEDOM_BINUTILS_METAL_ID)$(EXTRA_SUFFIX)

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
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-binutils/build.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/install.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/install.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	mkdir -p $(dir $@)
	git log > $(abspath $($@_INSTALL))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).commitlog
	cp README.md $(abspath $($@_INSTALL))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).readme.md
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
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/source.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	rm -rf $($@_INSTALL)
	mkdir -p $($@_INSTALL)
	rm -rf $($@_REC)
	mkdir -p $($@_REC)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cp -a $(SRCPATH_BINUTILS) $(dir $@)
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-binutils/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-binutils/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/build-binutils/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_BUILD := $(patsubst %/build/$(PACKAGE_HEADING)/build-binutils/build.stamp,%/build/$(PACKAGE_HEADING),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/build-binutils/build.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
# CC_FOR_TARGET is required for the ld testsuite.
	cd $(dir $@) && CC_FOR_TARGET=$(BARE_METAL_CC_FOR_TARGET) $(abspath $($@_BUILD))/$(SRCNAME_BINUTILS)/configure \
		--target=$(BARE_METAL_TUPLE) \
		$($($@_TARGET)-binutils-host) \
		--prefix=$(abspath $($@_INSTALL)) \
		--with-pkgversion="SiFive Binutils-Metal $(PACKAGE_VERSION)" \
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
		CXXFLAGS="-O2" &>$($@_REC)/build-binutils-make-configure.log
	$(MAKE) -C $(dir $@) &>$($@_REC)/build-binutils-make-build.log
	$(MAKE) -C $(dir $@) -j1 install install-pdf install-html &>$($@_REC)/build-binutils-make-install.log
	date > $@

$(OBJDIR)/$(NATIVE)/test/$(PACKAGE_HEADING)/test.stamp: \
		$(OBJDIR)/$(NATIVE)/test/$(PACKAGE_HEADING)/launch.stamp
	mkdir -p $(dir $@)
	PATH=$(abspath $(OBJDIR)/$(NATIVE)/launch/$(PACKAGE_TARNAME)/bin):$(PATH) riscv64-unknown-elf-ld -v
	PATH=$(abspath $(OBJDIR)/$(NATIVE)/launch/$(PACKAGE_TARNAME)/bin):$(PATH) riscv64-unknown-elf-objdump -v
	PATH=$(abspath $(OBJDIR)/$(NATIVE)/launch/$(PACKAGE_TARNAME)/bin):$(PATH) riscv64-unknown-elf-readelf -v
	PATH=$(abspath $(OBJDIR)/$(NATIVE)/launch/$(PACKAGE_TARNAME)/bin):$(PATH) riscv64-unknown-elf-size -v
	@echo "Finished testing $(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(NATIVE).tar.gz tarball"
	date > $@
