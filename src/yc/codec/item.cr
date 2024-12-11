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

        pp flags
        # puts flags == ItemFlag::HasLeftId
        # puts flags == ItemFlag::HasRightId
        # puts flags == ItemFlag::HasParentSub
        # puts flags == ItemFlag::HasSibling
        # puts flags != ItemFlag::HasSibling
        # puts flags == ItemFlag::Deleted

        origin_left_id = if flags.check(ItemFlag::HasLeftId)
          Id.from_reader(reader)
        end

        origin_right_id = if flags.check(ItemFlag::HasRightId)
          Id.from_reader(reader)
        end

        parent = if flags.not(ItemFlag::HasSibling)
          puts "reading parent"
          has_parent = reader.read_u64 == 1

          puts "has_parent #{has_parent}"

          if has_parent
            puts reader.read_u64
            # puts reader.read_string.not_nil!
          else
            Id.from_reader(reader)
          end
        else
          nil
        end

        parent_sub = if flags.not(ItemFlag::HasSibling) && flags.check(ItemFlag::HasParentSub)
          reader.read_string.not_nil!
        end

        Item.new(
          id: id,
          origin_left_id: origin_left_id,
          origin_right_id: origin_right_id,
          left: nil,
          right: nil,
          parent: nil,
          parent_sub: parent_sub,
          content: Content.from_reader(reader, first_5_bit),
          flags: flags
        )
      end

      def to_buffer(buffer : Buffer)
        buffer.write_byte(flags.to_u8)
      end

      def length
        content.clock_length
      end
    end
  end
end

# pub id: Id,
#     pub origin_left_id: Option<Id>,
#     pub origin_right_id: Option<Id>,
#     #[cfg_attr(all(test, not(loom)), proptest(value = "Somr::none()"))]
#     pub left: ItemRef,
#     #[cfg_attr(all(test, not(loom)), proptest(value = "Somr::none()"))]
#     pub right: ItemRef,
#     pub parent: Option<Parent>,
#     #[cfg_attr(all(test, not(loom)), proptest(value = "Option::<SmolStr>::None"))]
#     pub parent_sub: Option<SmolStr>,
#     pub content: Content,
#     #[cfg_attr(all(test, not(loom)), proptest(value = "ItemFlag::default()"))]
#     pub flags: ItemFlag,