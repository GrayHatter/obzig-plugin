const std = @import("std");
const Allocator = std.mem.Allocator;

pub const SwayMessages = @import("sway-messages.zig");

pub const Payload = enum(u32) {
    RUN_COMMAND = 0, // Runs the payload as sway commands
    GET_WORKSPACES = 1, // Get the list of current workspaces
    SUBSCRIBE = 2, // Subscribe the IPC connection to the events listed in the payload
    GET_OUTPUTS = 3, // Get the list of current outputs
    GET_TREE = 4, // Get the node layout tree
    GET_MARKS = 5, // Get the names of all athe marks currently set
    GET_BAR_CONFIG = 6, // Get the specified bar config or a list of bar config names
    GET_VERSION = 7, // Get the version of sway that owns the IPC socket
    GET_BINDING_MODES = 8, // Get the list of binding mode names
    GET_CONFIG = 9, // Returns the config that was last loaded
    SEND_TICK = 10, // Sends a tick event with the specified payload
    SYNC = 11, // Replies failure object for i3 compatibility
    GET_BINDING_STATE = 12, // Request the current binding state, e.g. the currently active binding mode name.
    GET_INPUTS = 100, // Get the list of input devices
    GET_SEATS = 101, // Get the list of seats
    //
    pub fn fromInt(i: u32) Payload {
        _ = i;
        return .RUN_COMMAND;
    }
};

const Subscribe = Message{
    .header = .{
        .length = 10,
        .payload_type = .SUBSCRIBE,
    },
    .data = "[\"window\"]",
};

pub const Message = struct {
    pub const Header = struct {
        magic: []const u8 = "i3-ipc",
        length: u32 = 0,
        payload_type: Payload = undefined,
    };
    header: Header = .{},
    data: []const u8,

    pub fn raze(m: Message, a: Allocator) void {
        a.free(m.data);
    }

    pub fn read(a: Allocator, r: *std.net.Stream.Reader) !Message {
        var m = Message{ .data = undefined };
        try r.skipBytes(6, .{});
        m.header = .{
            .length = try r.readInt(u32, .little),
            .payload_type = Payload.fromInt(try r.readInt(u32, .little)),
        };
        // TODO specify a better max size
        if (m.header.length == 0 or m.header.length > 0x2ffff) unreachable;
        m.data = try a.alloc(u8, m.header.length);
        const rlen = try r.read(@constCast(m.data));
        std.debug.assert(rlen == m.data.len);
        return m;
    }

    pub fn send(m: Message, w: *std.net.Stream.Writer) !void {
        std.debug.assert(m.header.length == m.data.len);
        try w.writeAll(m.header.magic);
        try w.writeInt(u32, m.header.length, .little);
        try w.writeInt(u32, @intFromEnum(m.header.payload_type), .little);
        try w.writeAll(m.data);
    }

    /// Leaks if you don't use an gc'd allocator
    pub fn toStruct(m: Message, a: Allocator) !SwayMessages.MsgKind {
        const thing = try std.json.parseFromSlice(SwayMessages.WindowChange, a, m.data, .{ .ignore_unknown_fields = true });
        return .{
            .window = thing.value,
        };
    }
};

pub fn getSockPath(a: Allocator) ![]const u8 {
    var child = std.ChildProcess.init(&[_][]const u8{ "sway", "--get-socketpath" }, a);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    var stdout = std.ArrayList(u8).init(a);
    var stderr = std.ArrayList(u8).init(a);
    defer stdout.clearAndFree();

    try child.spawn();
    try child.collectOutput(&stdout, &stderr, 0xff);
    _ = try child.wait();

    _ = stdout.pop();
    return try stdout.toOwnedSlice();
}

pub const Connection = struct {
    alloc: Allocator,
    socket_path: ?[]const u8 = null,
    sock: ?std.net.Stream = null,

    pub fn init(a: Allocator) !Connection {
        var c = Connection{ .alloc = a };
        c.socket_path = try getSockPath(c.alloc);
        c.sock = try std.net.connectUnixSocket(c.socket_path.?);
        return c;
    }

    pub fn raze(c: *Connection) void {
        if (c.socket_path) |path| c.alloc.free(path);
        c.socket_path = null;
        if (c.sock) |sock| sock.close();
    }

    pub fn subscribe(c: *Connection) !void {
        var sock = c.sock orelse unreachable;
        var w = sock.writer();
        try Subscribe.send(&w);
    }

    pub fn loop(c: *Connection) !Message {
        var sock = c.sock orelse unreachable;

        var r = sock.reader();
        return try Message.read(c.alloc, &r);
    }
};

test "sway get socketpath" {
    const a = std.testing.allocator;
    var child = std.ChildProcess.init(&[_][]const u8{ "sway", "--get-socketpath" }, a);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    var stdout = std.ArrayList(u8).init(a);
    defer stdout.clearAndFree();
    var stderr = std.ArrayList(u8).init(a);
    defer stdout.clearAndFree();

    try child.spawn();
    try child.collectOutput(&stdout, &stderr, 0xff);
    const out = try child.wait();
    _ = out;
    std.debug.print("sway socket path {s}\n", .{stdout.items});
}

test "sending" {
    var buf: [0xff]u8 = undefined;

    var fbs = std.io.fixedBufferStream(&buf);
    var w = fbs.writer();

    const m = Subscribe;

    try w.writeAll(m.header.magic);
    try w.writeInt(u32, m.header.length, .little);
    try w.writeInt(u32, @intFromEnum(m.header.payload_type), .little);
    try w.writeAll(m.data);
}

test "waiting" {
    const a = std.testing.allocator;

    var sway = try Connection.init(a);
    defer sway.raze();
    try sway.subscribe();
    std.time.sleep(1_000_000_000);
    for (0..10) |_| {
        const msg = try sway.loop();
        defer msg.raze(a);
        std.time.sleep(10_000_000);
        const thing = std.json.parseFromSlice(
            SwayMessages.WindowChange,
            a,
            msg.data,
            .{ .ignore_unknown_fields = true },
        ) catch |err| {
            std.debug.print("error {}\n", .{err});
            std.debug.print("msg {s}\n", .{msg.data});
            continue;
        };
        //std.debug.print("value {}\n", .{thing.value});
        //std.debug.print("marks {s}\n", .{thing.value.container.marks});
        if (thing.value.container.marks.len > 0) {
            try std.testing.expectEqualStrings("test", thing.value.container.marks[0]);
        }
        defer thing.deinit();
    }
}
