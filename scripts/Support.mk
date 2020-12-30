# Reused binutils build script across binutils-metal, gcc-metal and trace-decoder
$(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-binutils/support.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/build-binutils/support.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/build-binutils/support.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_BUILD := $(patsubst %/build/$(PACKAGE_HEADING)/build-binutils/support.stamp,%/build/$(PACKAGE_HEADING),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/build-binutils/support.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	# Workaround for CentOS random build fail issue
	#
	# Corresponding bugzilla entry on upstream:
	# https://sourceware.org/bugzilla/show_bug.cgi?id=22941
	touch $(abspath $($@_BUILD))/$(BARE_METAL_BINUTILS)/intl/plural.c
# CC_FOR_TARGET is required for the ld testsuite.
	cd $(dir $@) && CC_FOR_TARGET=$(BARE_METAL_CC_FOR_TARGET) $(abspath $($@_BUILD))/$(BARE_METAL_BINUTILS)/configure \
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
		--with-expat=no \
		--with-mpc=no \
		--with-mpfr=no \
		--with-gmp=no \
		$($($@_TARGET)-binutils-configure) \
		CFLAGS="-O2" \
		CXXFLAGS="-O2" &>$($@_REC)/build-binutils-make-configure.log
	$(MAKE) -C $(dir $@) &>$($@_REC)/build-binutils-make-build.log
	date > $@
