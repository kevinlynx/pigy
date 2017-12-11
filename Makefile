.PHONY: all clean

PLAT ?= linux
SHARED := -fPIC --shared 
LUA_CLIB_PATH ?= luaclib

CFLAGS = -g -O2 -Wall -Iskynet/3rd/lua/

LUA_CLIB = protobuf log

all : \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

$(LUA_CLIB_PATH)/protobuf.so : | $(LUA_CLIB_PATH)
	cd lualib-src/pbc && $(MAKE) lib && cd binding/lua53 && $(MAKE) && cd ../../../.. && cp lualib-src/pbc/binding/lua53/protobuf.so $@

$(LUA_CLIB_PATH)/log.so : lualib-src/lua-log.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

clean :
	cd skynet && $(MAKE) clean
	
