const std = @import("std");
const MemoryPool = std.heap.MemoryPool;

const Allocator = std.mem.Allocator;

pub fn SinglyLinkedList(comptime T: type) type {
    return struct {
        first: ?*Node = null,
        len: usize = 0,
        pool: MemoryPool(Node),
        allocator: Allocator,

        pub const Node = struct {
            next: ?*Node = null,
            data: T,
        };

        pub const CompareFn = *const fn (*T, *T) isize;

        const Self = @This();

        pub fn init(allocator: Allocator) Self {
            return .{
                .first = null,
                .pool = MemoryPool(Node).init(allocator),
                .allocator = allocator,
                .len = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            var cur = self.first;
            while (cur) |current_node| {
                cur = current_node.next;
                self.pool.destroy(current_node);
            }

            self.pool.deinit();

            self.len = 0;
        }

        pub fn remove(self: *Self, node_data: T, cmp: *const fn (T, T) isize) void {
            var prev: ?*Node = null;
            var it = self.first;
            while (it) |n| {
                if (cmp(n.data, node_data) == 0) {
                    if (prev) |p| {
                        p.next = n.next;
                    } else {
                        self.first = n.next;
                    }
                    self.pool.destroy(n);
                    self.len -= 1;
                    return;
                }

                prev = n;
                it = n.next;
            }
        }

        // Push at front of list
        pub fn push(self: *Self, data: T) !*Node {
            const node = try self.pool.create();
            node.* = .{ .data = data, .next = self.first };

            self.first = node;

            self.len += 1;

            return node;
        }

        pub fn sortInstert(self: *Self, data: T, cmp_fn: CompareFn) !void {
            const node = try self.pool.create();
            node.* = .{ .data = data, .next = null };

            if (self.first == null or cmp_fn(&self.first.?.data, &node.data) > 0) {
                node.next = self.first;
                self.first = node;
            } else {
                var cur = self.first.?;

                while (cur.next != null and cmp_fn(&cur.next.?.data, &node.data) < 0) {
                    cur = cur.next.?;
                }

                if (cur.next == null) {
                    cur.next = node;
                } else {
                    node.next = cur.next;
                    cur.next = node;
                }
            }

            self.len += 1;
        }

        //Returns a pointer to a node near the middle of the list
        pub fn bisect(self: *Self) Self {
            var fast: ?*Node = self.first;
            var slow: ?*Node = self.first;
            var prev: ?*Node = null;

            while (fast != null and fast.?.next != null) {
                fast = fast.?.next.?.next;
                prev = slow;
                slow = slow.?.next;
            }

            var result: Self = .{
                .first = slow,
                .pool = MemoryPool(Node).init(self.allocator),
                .allocator = self.allocator,
                .len = 0,
            };

            if (prev != null) {
                prev.?.next = null;
            } else {
                self.first = null;
            }

            result.recalculateLen();
            self.recalculateLen();

            return result;
        }

        fn recalculateLen(self: *Self) void {
            var cur = self.first;
            var len: usize = 0;

            while (cur) |current_node| {
                len += 1;
                cur = current_node.next;
            }

            self.len = len;
        }
    };
}

test "Push" {
    var l = SinglyLinkedList(usize).init(std.testing.allocator);
    defer l.deinit();

    const data = [_]usize{ 5, 15, 25, 35, 45, 55, 65 };
    for (data) |d| {
        _ = try l.push(d);
    }

    var cur = l.first;
    var i = data.len - 1;
    while (cur) |current| {
        try std.testing.expectEqual(data[i], current.data);

        cur = current.next;
        if (i == 0) {
            try std.testing.expect(cur == null);
            break;
        }
        i -= 1;
    }
}

test "Bisect" {
    var l = SinglyLinkedList(usize).init(std.testing.allocator);
    defer l.deinit();

    var data = [_]usize{ 5, 15, 25, 35, 45, 55, 65 };
    for (data) |d| {
        _ = try l.push(d);
    }

    std.mem.reverse(usize, &data);

    var bisected = l.bisect();
    defer bisected.deinit();

    try std.testing.expectEqual(l.len, 3);
    try std.testing.expectEqual(bisected.len, 4);

    var cur = l.first;
    var i: usize = 0;
    while (cur) |current| {
        try std.testing.expectEqual(data[i], current.data);

        cur = current.next;
        i += 1;
    }

    cur = bisected.first;
    while (cur) |current| {
        try std.testing.expectEqual(data[i], current.data);

        cur = current.next;
        i += 1;
    }
}
