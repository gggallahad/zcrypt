const std = @import("std");
const file = @import("file.zig");

const aes = std.crypto.core.aes.Aes256;
const aes_decrypt_ctx = std.crypto.core.aes.AesDecryptCtx(aes);
const aes_block_len = aes.block.block_length;

const sha = std.crypto.hash.sha3.Sha3_256;

pub const Decryptor = struct {
    decrypt_ctx: aes_decrypt_ctx,

    pub fn init(password: []const u8) Decryptor {
        var aes_key: [aes.key_bits / 8]u8 = undefined;
        sha.hash(password, &aes_key, .{});
        const decrypt_ctx = aes.initDec(aes_key);

        const decryptor = Decryptor{
            .decrypt_ctx = decrypt_ctx,
        };
        return decryptor;
    }

    pub fn decryptFile(self: *Decryptor, allocator: std.mem.Allocator, src: []const u8, dst: []const u8) !void {
        var new_file = try file.File.init(allocator, src, dst);
        errdefer new_file.deinit(allocator);

        var file_data = try new_file.read(allocator);

        file_data = self.decryptFileData(file_data);

        file_data = try self.removePadding(allocator, file_data);

        try new_file.write(file_data);

        allocator.free(file_data);

        new_file.deinit(allocator);
    }

    fn decryptFileData(self: *Decryptor, file_data: []u8) []u8 {
        var new_file_data = file_data;

        var decrypt_buffer: [aes_block_len]u8 = undefined;
        var file_data_chunk_buffer: [aes_block_len]u8 = undefined;
        const blocks_count = new_file_data.len / aes_block_len;
        for (0..blocks_count) |i| {
            const file_data_chunk = new_file_data[i * aes_block_len .. i * aes_block_len + aes_block_len];
            @memcpy(&file_data_chunk_buffer, file_data_chunk);

            self.decrypt_ctx.decrypt(&decrypt_buffer, &file_data_chunk_buffer);
            @memcpy(new_file_data[i * aes_block_len .. i * aes_block_len + aes_block_len], &decrypt_buffer);
        }

        return new_file_data;
    }

    fn removePadding(_: *Decryptor, allocator: std.mem.Allocator, file_data: []u8) ![]u8 {
        var new_file_data = file_data;
        const last_byte = new_file_data[new_file_data.len - 1];

        new_file_data = try allocator.realloc(new_file_data, new_file_data.len - last_byte);

        return new_file_data;
    }
};
