# An ordinary service. Nothing special about it.
module Greeting
  module Send
    class Service < Servus::Base
      def initialize(name:)
        @name = name
      end

      def call
        success(greeting: "Hello, #{@name}")
      end
    end
  end
end
