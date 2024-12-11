module Yc
  module Codec
    # @[Flags]
    # enum ItemFlag
    #   Keep # 1
    #   Countable # 2
    #   Deleted # 4
    #   Marked# 8
    #   Unused # 64
    #   HasParentSub # 16
    #   HasRightId # 32
    #   HasLeftId # 64
    #   HasSibling # 4
    # end
    #
    struct ItemFlag
      Keep = 0b0000_0001u8
      Countable = 0b0000_0010u8
      Deleted = 0b0000_0100u8
      Marked = 0b0000_1000u8
      HasParentSub = 0b0010_0000u8
      HasRightId = 0b0100_0000u8
      HasLeftId = 0b1000_0000u8
      HasSibling = 0b1100_0000u8

      getter value : UInt8

      def initialize(@value : UInt8)
      end

      def check(flag : UInt8)
        value & flag == flag
      end

      def not(flag : UInt8)
        value & flag == 0u8
      end

      def to_u8
        value
      end
    end


    # enum ItemFlag
    #   Keep = 1
    #   Countable = 2
    #   Deleted = 4
    #   Marked = 8
    #   HasParentSub = 32
    #   HasRightId = 64
    #   HasLeftId = 128
    #   HasSibling = 192

    #   def ==(other)
    #     puts "got other #{other}"
    #     false
    #   end
    # end
  end
end