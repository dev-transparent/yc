module Yc
  module Codec
    record NodeLength,
      id : Id,
      length : UInt64

    abstract struct Node
      def self.from_reader(reader : Reader, id : Id)
        info = reader.read_byte.not_nil!

        first_5_bit = info & 0b011111

        case first_5_bit
        when 0
          length = reader.read_u64.not_nil!

          GCNode.new(NodeLength.new(id, length))
        when 10
          length = reader.read_u64.not_nil!

          SkipNode.new(NodeLength.new(id, length))
        else
          item = Item.from_reader(reader, id, info, first_5_bit)

          ItemNode.new(item)
        end
      end

      abstract def id : Id
      abstract def length
      abstract def split_at(offset)
      abstract def to_buffer(buffer : Buffer)

      def clock
        id.clock
      end

      def client
        id.client
      end
    end

    struct GCNode < Node
      property node_length : NodeLength

      def initialize(@node_length : NodeLength)
      end

      def id : Id
        node_length.id
      end

      def length
        node_length.length
      end

      def split_at(offset)
        raise "Item not splittable"
      end

      def to_buffer(buffer : Buffer)
        buffer.write_byte(0u8)
        buffer.write_u64(length)
      end
    end

    struct SkipNode < Node
      property node_length : NodeLength

      def initialize(@node_length : NodeLength)
      end

      def id : Id
        node_length.id
      end

      def length
        node_length.length
      end

      def split_at(offset)
        raise "Item not splittable"
      end

      def to_buffer(buffer : Buffer)
        buffer.write_byte(10u8)
        buffer.write_u64(length)
      end
    end

    struct ItemNode < Node
      property item : Item

      def initialize(@item : Item)
      end

      def id : Id
        item.id
      end

      def length
        item.length
      end

      def split_at(offset) : Tuple(ItemNode, ItemNode)
        id = item.id
        right_id = Id.new(id.client, id.clock + offset)

        left_content, right_content = item.content.split(offset)

        left_item = Item.new(
          id: id,
          origin_left_id: nil,
          origin_right_id: nil,
          left: nil,
          right: nil,
          parent: item.parent,
          parent_sub: item.parent_sub,
          content: left_content,
          flags: ItemFlag.new(0) # Or countable?
        )

        right_item = Item.new(
          id: right_id,
          origin_left_id: nil,
          origin_right_id: nil,
          left: nil,
          right: nil,
          parent: item.parent,
          parent_sub: item.parent_sub,
          content: right_content,
          flags: ItemFlag.new(0) # Or countable?
        )

        {ItemNode.new(left_item), ItemNode.new(right_item)}
      end

      def to_buffer(buffer : Buffer)
        item.to_buffer(buffer)
      end
    end
  end
end