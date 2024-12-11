require "./order_range"

module Yc
  module Codec
    class DeleteSet
      property map : Hash(UInt64, OrderRange)

      def initialize(@map : Hash(UInt64, OrderRange) = {} of UInt64 => OrderRange)
      end

      def self.from_reader(reader : Reader)
        number_of_clients = reader.read_u64.not_nil!

        puts "number of clients #{number_of_clients}"

        map = {} of UInt64 => OrderRange
        number_of_clients.times do
          client = reader.read_u64.not_nil!

          map[client] = OrderRange.from_reader(reader)
        end

        new(map)
      end

      def to_buffer(buffer : Buffer)
        buffer.write_u64(map.size.to_u64)

        map.each do |client, order_range|
          buffer.write_u64(client)
          order_range.to_buffer(buffer)
        end
      end
    end
  end
end