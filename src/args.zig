const std = @import("std");

pub const ParseArgsError = error{
    WrongArgumentsNumber,
};

pub const Args = struct {
    mode: Mode,
    content: Content,
    src: []const u8,
    dst: []const u8,
    password: []const u8,

    pub fn init(allocator: std.mem.Allocator, mode: Mode, content: Content, src: []const u8, dst: []const u8, password: []const u8) !Args {
        const arg_mode = mode;
        const arg_content = content;
        const arg_src = try allocator.dupe(u8, src);
        const arg_dst = try allocator.dupe(u8, dst);
        const arg_password = try allocator.dupe(u8, password);

        const args = Args{
            .mode = arg_mode,
            .content = arg_content,
            .src = arg_src,
            .dst = arg_dst,
            .password = arg_password,
        };
        return args;
    }

    pub fn deinit(self: Args, allocator: std.mem.Allocator) void {
        allocator.free(self.src);
        allocator.free(self.dst);
        allocator.free(self.password);
    }
};

pub const Mode = enum {
    encryption,
    decryption,
};

const default_mode = Mode.encryption;
const mode_encryption_flag = "-e";
const mode_decryption_flag = "-d";

pub const Content = enum {
    directory,
    file,
};

const default_content = Content.file;
const content_directory_flag = "-r";
const content_file_flag = "-f";

const password_request = "Password: ";
const password_max_len = 1024;

pub fn parseArgs(allocator: std.mem.Allocator) !Args {
    const raw_arguments = try std.process.argsAlloc(allocator);
    errdefer std.process.argsFree(allocator, raw_arguments);

    if (raw_arguments.len < 3) {
        return ParseArgsError.WrongArgumentsNumber;
    }

    var mode = default_mode;
    var content = default_content;

    const arguments = raw_arguments[1 .. raw_arguments.len - 2];
    for (0..arguments.len) |i| {
        if (std.mem.eql(u8, arguments[i], mode_encryption_flag)) {
            mode = Mode.encryption;
        }
        if (std.mem.eql(u8, arguments[i], mode_decryption_flag)) {
            mode = Mode.decryption;
        }
        if (std.mem.eql(u8, arguments[i], content_directory_flag)) {
            content = Content.directory;
        }
        if (std.mem.eql(u8, arguments[i], content_file_flag)) {
            content = Content.file;
        }
    }

    const src = raw_arguments[raw_arguments.len - 2];
    const dst = raw_arguments[raw_arguments.len - 1];

    const std_out = std.io.getStdOut().writer();
    const std_in = std.io.getStdIn().reader();

    _ = try std_out.write(password_request);

    const password = try std_in.readUntilDelimiterAlloc(allocator, '\n', password_max_len);
    errdefer allocator.free(password);

    const trimmed_password = std.mem.trimRight(u8, password, "\r");

    const args = try Args.init(allocator, mode, content, src, dst, trimmed_password);

    allocator.free(password);
    std.process.argsFree(allocator, raw_arguments);

    return args;
}
