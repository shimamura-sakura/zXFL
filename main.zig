const std = @import("std");
const mem = std.heap.page_allocator;
const xfl = @import("xfl.zig");

pub fn entryLT(context: ?void, lhs: xfl.Entry, rhs: xfl.Entry) bool {
    _ = context;
    return lhs.offset < rhs.offset;
}

pub fn main() !void {
    const argv = try std.process.argsAlloc(mem);
    defer std.process.argsFree(mem, argv);
    if (argv.len < 3)
        return error.NotEnoughArgs;
    const infile = try std.fs.cwd().openFileZ(argv[1], .{});
    defer infile.close();
    const reader = infile.reader();
    const outfdr = argv[2][0..];
    const out_fn = try mem.alloc(u8, outfdr.len + 34);
    defer mem.free(out_fn);
    std.mem.set(u8, out_fn, 0);
    std.mem.copy(u8, out_fn, outfdr);
    var copy_dst = out_fn[outfdr.len..][0..32];
    if (outfdr.len > 0 and out_fn[outfdr.len - 1] != '/') {
        out_fn[outfdr.len] = '/';
        copy_dst = out_fn[outfdr.len + 1 ..][0..32];
    }
    const outfnz = @ptrCast([:0]u8, out_fn);
    const count = try xfl.readHeader(reader);
    const entries = try mem.alloc(xfl.Entry, count);
    defer mem.free(entries);
    for (entries) |*ent|
        ent.* = try xfl.Entry.read(reader);
    std.sort.sort(xfl.Entry, entries, @as(?void, null), entryLT);
    const baseoff: u64 = try infile.getPos();
    for (entries) |ent| {
        std.mem.copy(u8, copy_dst, &ent.name_buf);
        const outfile = try std.fs.cwd().createFileZ(outfnz, .{});
        defer outfile.close();
        const copycnt = try infile.copyRangeAll(baseoff +% ent.offset, outfile, 0, ent.length);
        if (copycnt != ent.length)
            return error.EndOfFile;
        std.debug.print("{s}\n", .{ent.name()});
    }
}
