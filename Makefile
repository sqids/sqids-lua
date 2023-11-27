all: build

build:
	luarocks make

publish:
	luarocks pack sqids-lua
	luarocks upload --api-key=${LUAROCKS_API_KEY} sqids-lua-*.rockspec

clean:
	rm -rf sqids-lua-*.rock
