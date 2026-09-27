# A service that configures its job, as documented in
# https://zarpay.github.io/servus/features/async-execution#per-service-job-configuration
module Greeting
  module Archive
    class Service < Servus::Base
      async queue: :low

      def initialize(name:)
        @name = name
      end

      def call
        success(archived: @name)
      end
    end
  end
end
