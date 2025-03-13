const std = @import("std");
const encrypt = @import("encryptor.zig");
const decrypt = @import("decryptor.zig");
const util = @import("args.zig");

const aes = std.crypto.core.aes.Aes256;
const sha = std.crypto.hash.sha3.Sha3_256;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer {
        const gpa_status = gpa.deinit();
        if (gpa_status == .leak) {
            std.debug.print("leak found\n", .{});
        }
    }
    const allocator = gpa.allocator();

    // const allocator = std.heap.smp_allocator;

    const args = try util.parseArgs(allocator);
    errdefer args.deinit(allocator);

    switch (args.mode) {
        .encryption => {
            var encryptor = encrypt.Encryptor.init(args.password);
            switch (args.content) {
                .directory => {
                    try encryptor.encryptDirectory(allocator, args.src, args.dst);
                },

                .file => {
                    try encryptor.encryptFile(allocator, args.src, args.dst);
                },
            }
        },

        .decryption => {
            var decryptor = decrypt.Decryptor.init(args.password);
            switch (args.content) {
                .directory => {
                    try decryptor.decryptDirectory(allocator, args.src, args.dst);
                },

                .file => {
                    try decryptor.decryptFile(allocator, args.src, args.dst);
                },
            }
        },
    }

    args.deinit(allocator);
}
