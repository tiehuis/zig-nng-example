const std = @import("std");
const c = @cImport({
    @cInclude("nng/nng.h");
    @cInclude("nng/protocol/reqrep0/req.h");
    @cInclude("nng/supplemental/util/platform.h");
});

fn fatal(msg: []const u8, code: c_int) void {
    // TODO: std.fmt should accept [*c]const u8 for {s} format specific, should not require {s}
    // in this case?
    std.debug.warn("{}: {s}\n", msg, @ptrCast([*]const u8, c.nng_strerror(code)));
    std.os.exit(1);
}

pub fn request(address: [*]const u8, msec: u32) void {
    var sock: c.nng_socket = undefined;
    var r: c_int = undefined;

    r = c.nng_req0_open(&sock);
    if (r != 0) {
        fatal("nng_req0_open", r);
    }
    defer _ = c.nng_close(sock);

    r = c.nng_dial(sock, address, 0, 0);
    if (r != 0) {
        fatal("nng_dial", r);
    }

    const start = c.nng_clock();

    var msg: ?*c.nng_msg = undefined;
    r = c.nng_msg_alloc(&msg, 0);
    if (r != 0) {
        fatal("nng_msg_alloc", r);
    }
    defer c.nng_msg_free(msg);

    r = c.nng_msg_append_u32(msg, msec);
    if (r != 0) {
        fatal("nng_msg_append_u32", r);
    }

    r = c.nng_sendmsg(sock, msg, 0);
    if (r != 0) {
        fatal("nng_sendmsg", r);
    }

    r = c.nng_recvmsg(sock, &msg, 0);
    if (r != 0) {
        fatal("nng_recvmsg", r);
    }

    const end = c.nng_clock();

    std.debug.warn("Request took {} milliseconds.\n", end - start);
}

pub fn main() !void {
    var allocator = std.heap.c_allocator;
    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len <= 2) {
        std.debug.warn("usage: {} <url> <msec>\n", args[0]);
        std.os.exit(1);
    }

    const address = try std.cstr.addNullByte(allocator, args[1]);
    defer allocator.free(address);

    const msec = try std.fmt.parseUnsigned(u32, args[2], 10);

    request(address.ptr, msec);
}
