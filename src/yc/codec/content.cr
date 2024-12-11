module Yc
  module Codec
    abstract struct Content
      abstract def clock_length : UInt64
      abstract def split(offset) : Tuple(Content, Content)

      def self.from_reader(reader : Reader, tag_type : UInt8)
        case tag_type
        when 1
          DeletedContent.new(reader.read_u64.not_nil!)
        when 2
          length = reader.read_u64.not_nil!
          strings = length.times.to_a.map do
            content = reader.read_string.not_nil!
            content == "undefined" ? nil : content
          end

          JSONContent.new(strings)
        when 3
          BinaryContent.new(reader.read_bytes.not_nil!)
        when 4
          StringContent.new(reader.read_string.not_nil!)
        when 5
          raise "Unsupported type"
        when 6
          raise "Unsupported type"
        when 7
          raise "Unsupported type"
        when 8
          raise "Unsupported type"
        when 9
          raise "Unsupported type"
        else
          raise "Unsupported type"
        end
      end
    end

    struct DeletedContent < Content
      def initialize(@length : UInt64)
      end

      def clock_length : UInt64
        @length
      end

      def split(offset) : Tuple(Content, Content)
        {DeletedContent.new(offset), DeletedContent.new(@length - offset)}
      end
    end

    struct JSONContent < Content
      def initialize(@strings : Array(String?))
      end

      def clock_length : UInt64
        @strings.size.to_u64
      end

      def split(offset) : Tuple(Content, Content)
        left = @strings[0, offset]
        right = @strings[offset, @strings.size - offset]

        {JSONContent.new(left), JSONContent.new(right)}
      end
    end

    struct BinaryContent < Content
      def initialize(@bytes : Bytes)
      end

      def clock_length : UInt64
        1u64
      end

      def split(offset) : Tuple(Content, Content)
        raise "Unsupported split on binary"
      end
    end

    struct StringContent < Content
      def initialize(@string : String)
      end

      def clock_length : UInt64
        @string.to_utf16.sum(0u64) { |byte| byte & 0xFFFF == byte ? 1u64 : 2u64 }
      end

      def split(offset) : Tuple(Content, Content)
        slice = @string.to_utf16

        left = String.from_utf16(slice[0, offset])
        right = String.from_utf16(slice[offset, slice.size - offset])

        {StringContent.new(left), StringContent.new(right)}
      end
    end

    struct EmbedContent < Content
      def clock_length : UInt64
        1u64
      end

      def split(offset) : Tuple(Content, Content)
        raise "Unsupported split on embed"
      end
    end

    struct FormatContent < Content
      def initialize(@key : String, @value : String)
      end

      def clock_length : UInt64
        1u64
      end

      def split(offset) : Tuple(Content, Content)
        raise "Unsupported split on format"
      end
    end

    struct TypeContent < Content
      def initialize(@type_ref : String) # TODO: Fix
      end

      def clock_length : UInt64
        1u64
      end

      def split(offset) : Tuple(Content, Content)
        raise "Unsupported split on type"
      end
    end

    struct AnyContent < Content
      def initialize(@value : Array(String)) # TODO: Fix
      end

      def clock_length : UInt64
        @value.size.to_u64
      end

      def split(offset) : Tuple(Content, Content)
        left = @value[0, offset]
        right = @value[offset, @value.size - offset]

        {AnyContent.new(left), AnyContent.new(right)}
      end
    end

    struct DocContent < Content
      def initialize(@guid : String, @opts : String) # Fix any
      end

      def clock_length : UInt64
        1u64
      end

      def split(offset) : Tuple(Content, Content)
        raise "Unsupported split on doc"
      end
    end
  end
end