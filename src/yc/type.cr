require "./type_kind"

module Yc
  class Type
    getter kind : TypeKind
    getter name : String?

    def initialize(@kind : TypeKind, @name : String? = nil)
    end
  end
end

require "./types/*"