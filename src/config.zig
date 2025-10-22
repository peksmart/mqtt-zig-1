pub const kernel_backlog = 16;
pub const io_entries = 128;
pub const queue_size = 256;

pub const max_clients = 1024;
pub const max_messages = max_clients;

pub const maximum_message_size = 256 * 1024 + 2;

pub const threads = 1;

pub const maximum_topic_number = 1024;
pub const maximum_topic_subscribers = 100_000;
pub const topic_name_pool_size = threads * 2;
pub const maximum_topic_name_length = 256;

// 调试：是否启用原始请求十六进制转储（默认关闭，避免性能影响）
pub const enable_hex_dump = true; // 设为 true 可输出每个请求的原始十六进制
// 十六进制转储最大字节数（超出部分截断显示）
pub const hex_dump_max = 256; // 根据需要可调大，但注意日志输出量
// 每行分组字节数，用于易读性
pub const hex_dump_group = 16;
