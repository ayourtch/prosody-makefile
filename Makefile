# Edit the bext line to be your install directory
INSTALL_DIR_NO_TRAILER=/home/dalien/prosody/prosody-install

INSTALL_DIR=$(INSTALL_DIR_NO_TRAILER)/
INSTALL_DIR_ESCAPED=`(echo $(INSTALL_DIR) | sed -e 's/\\//\\\\\\//g')`
LUA_TARGET=linux
LUASEC_PLATFORM=linux
# Lua version number
# (according to Lua 5.1 definition:
# first version digit * 100 + second version digit
# e.g. Lua 5.0.2 => 500, Lua 5.1 => 501, Lua 5.1.1 => 501)
#
LUA_VERSION_NUM=501
LUA_TGZ=lua-5.1.4.tar.gz
PROSODY_TGZ=prosody-0.6.1.tar.gz
LUAEXPAT_TGZ=luaexpat-1.1.tar.gz
LUASEC_TGZ=luasec-0.3.3.tar.gz
LUASOCKET_TGZ=luasocket-2.0.2.tar.gz

LUAFILESYSTEM_URL=http://github.com/keplerproject/luafilesystem/tarball/v1.5.0
LUAFILESYSTEM_TGZ=keplerproject-luafilesystem-*.tar.gz

all: tarballs tmpdir build

tarballs: $(LUA_TGZ) $(PROSODY_TGZ) $(LUAEXPAT_TGZ) $(LUASEC_TGZ) $(LUASOCKET_TGZ) $(LUAFILESYSTEM_TGZ)

build: install-dir lua-build prosody-build luaexpat-build luasec-build luasocket-build luafilesystem-build

install-dir:
	install -d $(INSTALL_DIR)

lua-build: $(LUA_TGZ) tmpdir
	echo $(INSTALL_DIR_ESCAPED)
	# unpack        
	(cd tmp; tar xzvf ../$(LUA_TGZ))
	# fix the path in luaconf.h
	(cd tmp; REAL_ROOT=$(INSTALL_DIR_ESCAPED); EDIT_CMD="s#\(LUA_ROOT\s\"\)\/usr\/local\/\(\"\)#\1$$REAL_ROOT\2#g"; cd lua-*/src; sed -i.bak -e $$EDIT_CMD luaconf.h)
	# fix the install path in Makefile
	(cd tmp; REAL_ROOT=$(INSTALL_DIR_ESCAPED); EDIT_CMD="s#\(INSTALL_TOP=\s\)\/usr\/local#\1$$REAL_ROOT#g"; cd lua-*; sed -i.bak -e $$EDIT_CMD Makefile)
	# fix the cflags to add -fPIC in src/Makefile
	(cd tmp; EDIT_CMD="s#\(^CFLAGS=\)#\1-fPIC#g"; cd lua-*/src; sed -i.bak -e $$EDIT_CMD Makefile)
	# build and install
	(cd tmp; cd lua-*; make $(LUA_TARGET); make install)

prosody-build: $(PROSODY_TGZ) tmpdir
	(cd tmp; tar xzvf ../$(PROSODY_TGZ))
	(cd tmp; cd prosody-*; ./configure --prefix=$(INSTALL_DIR_NO_TRAILER) --with-lua=$(INSTALL_DIR_NO_TRAILER) --with-lua-lib=$(INSTALL_DIR_NO_TRAILER)/lib ;)
	(cd tmp; REAL_ROOT=$(INSTALL_DIR_ESCAPED); EDIT_CMD="s#\(LFLAGS=\)#\1-L$$REAL_ROOT\/lib\nLFLAGS+=#g"; cd prosody-*; sed -i.bak -e $$EDIT_CMD config.unix)
	(cd tmp; cd prosody-*; make install)

luaexpat-build: $(LUAEXPAT_TGZ) tmpdir
	(cd tmp; tar xzvf ../$(LUAEXPAT_TGZ))
	# patch the config
	(cd tmp; REAL_ROOT=$(INSTALL_DIR_ESCAPED); EDIT_CMD1="s#\(LUA_LIBDIR=\s\)#\1$${REAL_ROOT}lib\/lua\/5.1\n\##g"; EDIT_CMD2="s#\(LUA_DIR=\s\)#\1$${REAL_ROOT}share\/lua\/5.1\n\##g";  EDIT_CMD3="s#\(LUA_INC=\s\)#\1$${REAL_ROOT}include\n\##g"; EDIT_CMD4="s#\(LUA_VERSION_NUM=\s\)#\1$(LUA_VERSION_NUM)\n\##g"; EDIT_CMD5="s#\(CFLAGS\s=\)#\1-fPIC#g"; cd luaexpat-*; sed -i.bak -e $$EDIT_CMD1 -e $$EDIT_CMD2 -e $$EDIT_CMD3 -e $$EDIT_CMD4 -e $$EDIT_CMD5 config)
	# compile
	(cd tmp; cd luaexpat-*; make; make install)

luasec-build: $(LUASEC_TGZ) tmpdir
	(cd tmp; tar xzvf ../$(LUASEC_TGZ))
	# patch the config
	(cd tmp; REAL_ROOT=$(INSTALL_DIR_ESCAPED); EDIT_CMD1="s#\(^LUAPATH=\)#\1$${REAL_ROOT}share\/lua\/5.1\n\##g"; EDIT_CMD2="s#\(^CPATH=\)#\1$${REAL_ROOT}lib\/lua\/5.1\n\##g";  EDIT_CMD3="s#\(^LUAPATH=\)#INCDIR=-I$${REAL_ROOT}include\n\1#g"; cd luasec-*; sed -i.bak -e $$EDIT_CMD1 -e $$EDIT_CMD2 -e $$EDIT_CMD3 Makefile)
	(cd tmp; cd luasec-*; make $(LUASEC_PLATFORM) && make install)

luasocket-build: $(LUASOCKET_TGZ) tmpdir
	(cd tmp; tar xzvf ../$(LUASOCKET_TGZ))
	# patch the config
	(cd tmp; REAL_ROOT=$(INSTALL_DIR_ESCAPED); EDIT_CMD1="s#\(INSTALL_TOP_LIB=\)#\1$${REAL_ROOT}lib\/lua\/5.1\n\##g"; EDIT_CMD2="s#\(INSTALL_TOP_SHARE=\)#\1$${REAL_ROOT}share\/lua\/5.1\n\##g";  EDIT_CMD3="s#LUAINC=-Ilua#\nLUAINC=-I$${REAL_ROOT}include\n\##g"; cd luasocket-*; sed -i.bak -e $$EDIT_CMD1 -e $$EDIT_CMD2 -e $$EDIT_CMD3 config)
	# compile
	(cd tmp; cd luasocket-*; make && make install)
luafilesystem-build: $(LUAFILESYSTEM_TGZ) tmpdir
	(cd tmp; tar xzvf ../$(LUAFILESYSTEM_TGZ))
	# patch the config
	(cd tmp; REAL_ROOT=$(INSTALL_DIR_ESCAPED); EDIT_CMD1="s#\(PREFIX=\)#\1$${REAL_ROOT}\n\##g"; EDIT_CMD2="s#\(INSTALL_TOP_SHARE=\)#\1$${REAL_ROOT}share\/lua\/5.1\n\##g";  EDIT_CMD3="s#LUAINC=-Ilua#\nLUAINC=-I$${REAL_ROOT}include\n\##g"; cd keplerproject-luafilesystem-*; sed -i.bak -e $$EDIT_CMD1 -e $$EDIT_CMD2 -e $$EDIT_CMD3 config)
	# compile
	(cd tmp; cd keplerproject-luafilesystem-*; make && make install)
$(PROSODY_TGZ):
	wget -c http://prosody.im/downloads/source/$(PROSODY_TGZ)

$(LUA_TGZ):
	wget -c http://www.lua.org/ftp/$(LUA_TGZ)

$(LUAEXPAT_TGZ):
	wget -c http://luaforge.net/frs/download.php/2469/luaexpat-1.1.tar.gz

$(LUASEC_TGZ):
	wget -c http://luaforge.net/frs/download.php/3920/$(LUASEC_TGZ)

$(LUASOCKET_TGZ):
	wget -c http://luaforge.net/frs/download.php/2664/luasocket-2.0.2.tar.gz
$(LUAFILESYSTEM_TGZ):
	wget -c $(LUAFILESYSTEM_URL)

tmpdir:
	install -d tmp
