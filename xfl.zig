pub fn readHeader(reader: anytype) !u32 {
    if ((try reader.readIntLittle(u32)) != 0x00_01_42_4c)
        return error.InvalidMagic;
    const len = try reader.readIntLittle(u32);
    const cnt = try reader.readIntLittle(u32);
    if (len % 40 != 0)
        return error.InvalidEntriesLen;
    if (len / 40 != cnt)
        return error.InvalidCount;
    return cnt;
}

pub const Entry = struct {
    name_buf: [32]u8,
    offset: u32,
    length: u32,
    pub fn read(reader: anytype) !Entry {
        var ent: Entry = undefined;
        try reader.readNoEof(&ent.name_buf);
        ent.offset = try reader.readIntLittle(u32);
        ent.length = try reader.readIntLittle(u32);
        return ent;
    }
    pub fn name(self: @This()) []const u8 {
        for (self.name_buf) |ch, i|
            if (ch == 0)
                return self.name_buf[0..i];
        return &self.name_buf;
    }
};
