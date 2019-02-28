all: build/libnng.a client server

build/libnng.a:
	mkdir -p build
	cd build && cmake ../nng && make nng

server: server.zig build/libnng.a
	zig build-exe $< --library build/libnng.a --library c --library pthread -isystem ./nng/include

client: client.zig build/libnng.a
	zig build-exe $< --library build/libnng.a --library c --library pthread -isystem ./nng/include

clean:
	rm -rf build server client

.PHONY: clean
