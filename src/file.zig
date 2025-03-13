const std = @import("std");

pub const File = struct {
    src: []const u8,
    dst: []const u8,

    pub fn init(allocator: std.mem.Allocator, src: []const u8, dst: []const u8) !File {
        const file_src = try allocator.dupe(u8, src);
        const file_dst = try allocator.dupe(u8, dst);

        const file = File{
            .src = file_src,
            .dst = file_dst,
        };
        return file;
    }

    pub fn deinit(self: *File, allocator: std.mem.Allocator) void {
        allocator.free(self.src);
        allocator.free(self.dst);
    }

    pub fn read(self: *File, allocator: std.mem.Allocator) ![]u8 {
        const fs_file = try std.fs.cwd().openFile(self.src, .{});
        errdefer fs_file.close();

        const file_size = try fs_file.getEndPos();

        const file_data = try allocator.alloc(u8, file_size);
        _ = try fs_file.readAll(file_data);

        fs_file.close();

        return file_data;
    }

    pub fn write(self: *File, file_data: []u8) !void {
        const fs_file = try std.fs.cwd().createFile(self.dst, .{});
        errdefer fs_file.close();

        try fs_file.writeAll(file_data);

        fs_file.close();
    }
};
