require "./any"

module Yc
  module Codec
    abstract struct Content
      enum ContentType
        Deleted = 1
        JSON = 2
        Binary = 3
        String = 4
        Embed = 5
        Format = 6
        Type = 7
        Any = 8
        Doc = 9
      end

      abstract def clock_length : UInt64
      abstract def split(offset) : Tuple(Content, Content)
      abstract def countable? : Bool

      def self.from_reader(reader : Reader, tag_type : UInt8)
      case ContentType.from_value(tag_type)
        in .deleted?
          DeletedContent.new(reader.read_u64.not_nil!)
        in .json?
          length = reader.read_u64.not_nil!
          strings = Array(String?).new(length)

          length.times do
            content = reader.read_string.not_nil!
            content = content == "undefined" ? nil : content
            strings << content
          end

          JSONContent.new(strings)
        in .binary?
          BinaryContent.new(reader.read_bytes.not_nil!)
        in .string?
          StringContent.new(reader.read_string.not_nil!)
        in .embed?
          raise "Unsupported type"
        in .format?
          raise "Unsupported type"
        in .type?
          kind = TypeKind.from_value(reader.read_u64.not_nil!)
          name = case kind
          when TypeKind::XMLElement, TypeKind::XMLHook
            reader.read_string.not_nil!
          else
            nil
          end

          TypeContent.new(Type.new(kind, name))
        in .any?
          length = reader.read_u64.not_nil!
          values = Array(Any).new(length)

          length.times do
            values << Any.from_reader(reader)
          end

          AnyContent.new(values)
        in .doc?
          guid = reader.read_string.not_nil!
          # options =
          DocContent.new(guid, "")
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

      def countable? : Bool
        false
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

      def countable? : Bool
        true
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

      def countable? : Bool
        true
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

      def countable? : Bool
        true
      end
    end

    struct EmbedContent < Content
      def clock_length : UInt64
        1u64
      end

      def split(offset) : Tuple(Content, Content)
        raise "Unsupported split on embed"
      end

      def countable? : Bool
        true
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

      def countable? : Bool
        false
      end
    end

    struct TypeContent < Content
      def initialize(@type : Type) # TODO: Fix
      end

      def clock_length : UInt64
        1u64
      end

      def split(offset) : Tuple(Content, Content)
        raise "Unsupported split on type"
      end

      def countable? : Bool
        true
      end
    end

    struct AnyContent < Content
      def initialize(@value : Array(Any))
      end

      def clock_length : UInt64
        @value.size.to_u64
      end

      def split(offset) : Tuple(Content, Content)
        left = @value[0, offset]
        right = @value[offset, @value.size - offset]

        {AnyContent.new(left), AnyContent.new(right)}
      end

      def countable? : Bool
        true
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

      def countable? : Bool
        true
      end
    end
  end
end