# Setup the Freedom build script environment
include scripts/Freedom.mk

# Include version identifiers to build up the full version string
include Version.mk
PACKAGE_HEADING := riscv64-unknown-elf-binutils
PACKAGE_VERSION := $(RISCV_BINUTILS_VERSION)-$(FREEDOM_BINUTILS_METAL_ID)$(EXTRA_SUFFIX)

# Source code directory references
SRCNAME_BINUTILS := riscv-binutils
SRCPATH_BINUTILS := $(SRCDIR)/$(SRCNAME_BINUTILS)
BARE_METAL_TUPLE := riscv64-unknown-elf
BARE_METAL_CC_FOR_TARGET ?= $(BARE_METAL_TUPLE)-gcc
BARE_METAL_CXX_FOR_TARGET ?= $(BARE_METAL_TUPLE)-g++
BARE_METAL_BINUTILS = riscv-binutils

# Some special package configure flags for specific targets
$(WIN64)-binutils-host          := --host=$(WIN64)
$(WIN64)-binutils-configure     := --with-included-gettext
$(UBUNTU64)-binutils-host       := --host=x86_64-linux-gnu
$(UBUNTU64)-binutils-configure  := --with-included-gettext
$(DARWIN)-binutils-configure    := --with-included-gettext
$(REDHAT)-binutils-configure    := --with-included-gettext

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
	$(WIN64)-gcc -print-search-dirs | grep ^libraries | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libwinpthread*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	$(WIN64)-gcc -print-search-dirs | grep ^libraries | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libgcc_s_seh*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	$(WIN64)-gcc -print-search-dirs | grep ^libraries | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libstdc*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	$(WIN64)-gcc -print-search-dirs | grep ^libraries | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libssp*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
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

# Reusing binutils build script across binutils-metal, gcc-metal and trace-decoder
include scripts/Support.mk

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-binutils/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-binutils/support.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-binutils/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/build-binutils/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/build-binutils/build.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	$(MAKE) -C $(dir $@) -j1 install install-pdf install-html &>$($@_REC)/build-binutils-make-install.log
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-addr2line
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-ar
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-as
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-c++filt
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-elfedit
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-gprof
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-ld
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-ld.bfd
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-nm
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-objcopy
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-objdump
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-ranlib
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-readelf
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-size
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-strings
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/riscv64-unknown-elf-strip
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
