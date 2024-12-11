module Yc
  class Buffer
    private getter io : IO::Memory

    def initialize(@io : IO = IO::Memory.new)
    end

    delegate write_byte, to_slice, to: io

    def write_u64(n : UInt64)
      while n >= 0b10000000
        @io.write_byte(n.to_u8! & 0b0111_1111 | 0b10000000)
        n >>= 7
      end

      io.write_byte((n & 0b01111111).to_u8!)
    end

    def write_i32(n : Int32)
      n = n.to_i64
      is_negative = n < 0

      if is_negative
        n = -n
      end

      io.write_byte(((n > 0b00111111 ? 0b10000000 : 0) | (is_negative ? 0b0100_0000 : 0) | n).to_u8! & 0b0011_1111)

      while n > 0
        io.write_byte(((n > 0b01111111 ? 0b10000000 : 0) | n).to_u8! & 0b0111_1111)
        n >>= 7
      end
    end

    def write_buffer(buffer : Buffer)
      write_bytes(buffer.io.to_slice)
    end

    def write_bytes(bytes : Bytes)
      write_u64(bytes.size.to_u64)
      io.write(bytes)
    end

    def write_string(value : String)
      write_bytes(value.to_slice)
    end
  end
end