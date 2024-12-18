require "./node"
require "./update_iterator"

module Yc
  module Codec
    class Update
      property structs : Hash(UInt64, Array(Node))
      property delete_set : DeleteSet
      property pending_structs : Hash(UInt64, Array(Node))
      property missing_state : StateVector
      property pending_delete_set : DeleteSet

      def initialize(@structs, @delete_set, @pending_structs = {} of UInt64 => Array(Node), @missing_state = StateVector.new, @pending_delete_set = DeleteSet.new)
      end

      def self.from_reader(reader : Reader)
        number_of_clients = reader.read_u64.not_nil!

        map = {} of UInt64 => Array(Node)
        number_of_clients.times do
          number_of_structs = reader.read_u64.not_nil!

          client = reader.read_u64.not_nil!
          clock = reader.read_u64.not_nil!

          structs = Array(Node).new
          number_of_structs.times do
            node = Node.from_reader(reader, Id.new(client, clock))
            clock += node.length
            structs << node
          end

          map[client] = structs
        end

        delete_set = DeleteSet.from_reader(reader)

        new(map, delete_set)
      end

      def to_buffer(buffer : Buffer)
        buffer.write_u64(structs.size.to_u64)
        structs.each do |client, items|
          buffer.write_u64(items.size.to_u64)

          buffer.write_u64(client)
          buffer.write_u64(items.first?.try &.clock || 0u64)

          items.each do |item|
            item.to_buffer(buffer)
          end
        end

        delete_set.to_buffer(buffer)
      end
    end
  end
end
