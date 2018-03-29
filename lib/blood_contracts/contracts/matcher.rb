module BloodContracts
  module Contracts
    class Matcher
      extend Dry::Initializer

      param :contract_hash, ->(v) { Hashie::Mash.new(v) }

      def call(input, output, meta, error = nil, statistics:)
        round = Round.new(
          input: input, output: output, error: wrap_error(error), meta: meta
        )
        rule_names = select_matched_rules!(round).keys
        if rule_names.empty?
          rule_names = if error.present?
                         [Storage::EXCEPTION_CAUGHT]
                       else
                         [Storage::UNDEFINED_RULE]
                       end
        end
        Array(rule_names).each(&statistics.method(:store))

        yield rule_names, round if block_given?

        !statistics.found_unexpected_behavior?
      end

      private

      def wrap_error(exception)
        return {} if exception.to_s.empty?
        return exception.to_h if exception.respond_to?(:to_hash)
        {
          exception.class.to_s => {
            message: exception.message,
            backtrace: exception.backtrace
          }
        }
      end

      def select_matched_rules!(round)
        contract_hash.select do |_name, rule|
          rule.check.call(round)
        end
      end
    end
  end
end
