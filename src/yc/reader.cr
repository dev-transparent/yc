module Yc
  class Reader
    private getter io : IO

    def initialize(@io)
    end

    def initialize(bytes : Bytes)
      @io = IO::Memory.new(bytes)
    end

    delegate read_byte, to: io

    def read_u64
      shift = 7
      curr_byte = io.read_byte.not_nil!

      num = (curr_byte & 0b0111_1111).to_u64!

      while (curr_byte >> 7) & 0b1 != 0
        curr_byte = io.read_byte.not_nil!
        num |= ((curr_byte & 0b0111_1111).to_u64!) << shift
        shift += 7
      end

      num
    end

    def read_i32
      shift = 6
      curr_byte = io.read_byte.not_nil!

      sign_bit = (curr_byte >> 6) & 0b1
      num = (curr_byte & 0b0011_1111).to_i64

      while (curr_byte >> 7) & 0b1 != 0
        curr_byte = io.read_byte.not_nil!
        num |= ((curr_byte & 0b0111_1111).to_i64) << shift
        shift += 7
      end

      if sign_bit == 1
        num = -num
      end

      num.to_i
    end

    def read_string
      bytes = read_bytes
      return nil if bytes.nil?
      String.new(bytes)
    end

    def read_bytes
      n = read_u64
      return nil if n.nil?
      read(n)
    end

    def read(n : UInt64)
      slice = Bytes.new(n)
      @io.read_fully(slice)
      slice
    end

    def new_from_length
      slice = read_bytes
      return nil if slice.nil?
      Reader.new(slice)
    end
  end
end