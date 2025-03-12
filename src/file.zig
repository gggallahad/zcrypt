const std = @import("std");

pub const File = struct {
    src: []const u8,
    dst: []const u8,
    data: []u8,

    pub fn init(allocator: std.mem.Allocator, src: []const u8, dst: []const u8) !File {
        const file_src = try allocator.dupe(u8, src);
        const file_dst = try allocator.dupe(u8, dst);
        const file_data = try allocator.alloc(u8, 0);

        const file = File{
            .src = file_src,
            .dst = file_dst,
            .data = file_data,
        };
        return file;
    }

    pub fn deinit(self: *File, allocator: std.mem.Allocator) void {
        allocator.free(self.src);
        allocator.free(self.dst);
        allocator.free(self.data);
    }

    pub fn read(self: *File, allocator: std.mem.Allocator) !void {
        const fs_file = try std.fs.cwd().openFile(self.src, .{});
        errdefer fs_file.close();

        const file_size = try fs_file.getEndPos();

        self.data = try allocator.realloc(self.data, file_size);
        _ = try fs_file.readAll(self.data);

        fs_file.close();
    }

    pub fn write(self: *File) !void {
        const fs_file = try std.fs.cwd().createFile(self.dst, .{});
        errdefer fs_file.close();

        try fs_file.writeAll(self.data);

        fs_file.close();
    }
};
