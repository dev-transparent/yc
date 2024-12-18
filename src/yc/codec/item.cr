require "./id"
require "./item_flag"

module Yc
  module Codec
    class Item
      property id : Id
      property origin_left_id : Id?
      property origin_right_id : Id?
      property left : Item?
      property right : Item?
      property parent : String | Id | Nil # TODO: Type ref?
      property parent_sub : String?
      property content : Content
      property flags : ItemFlag

      def initialize(@id : Id, @origin_left_id : Id?, @origin_right_id : Id?, @left : Item?, @right : Item?, @parent : String | Id | Nil, @parent_sub : String?, @content : Content, @flags : ItemFlag)
      end

      def self.from_reader(reader : Reader, id : Id, info : UInt8, first_5_bit : UInt8)
        flags = ItemFlag.new(info)

        origin_left_id = if flags.check(ItemFlag::HasLeftId)
          Id.from_reader(reader)
        end

        origin_right_id = if flags.check(ItemFlag::HasRightId)
          Id.from_reader(reader)
        end

        parent = if flags.not(ItemFlag::HasSibling)
          has_parent = reader.read_u64 == 1

          if has_parent
            reader.read_string.not_nil!
          else
            Id.from_reader(reader)
          end
        else
          nil
        end

        parent_sub = if flags.not(ItemFlag::HasSibling) && flags.check(ItemFlag::HasParentSub)
          reader.read_string.not_nil!
        end

        item = Item.new(
          id: id,
          origin_left_id: origin_left_id,
          origin_right_id: origin_right_id,
          left: nil,
          right: nil,
          parent: parent,
          parent_sub: parent_sub,
          content: Content.from_reader(reader, first_5_bit),
          flags: ItemFlag.new(0)
        )

        if item.content.countable?
          item.flags.set(ItemFlag::Countable)
        end

        if item.content == DeletedContent
          item.flags.set(ItemFlag::Deleted)
        end

        item
      end

      def to_buffer(buffer : Buffer)
        buffer.write_byte(flags.to_u8)
      end

      def length
        content.clock_length
      end

      def last_id : Id
        Id.new(id.client, id.clock + length - 1)
      end
    end
  end
end