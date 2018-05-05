module RailsEventStore
  module RSpec
    class HavePublished
      def initialize(mandatory_expected, *optional_expected, differ:, formatter:)
        @expected  = [mandatory_expected, *optional_expected]
        @matcher   = ::RSpec::Matchers::BuiltIn::Include.new(*expected)
        @differ    = differ
        @formatter = formatter
      end

      def matches?(event_store)
        @events = stream_name ? event_store.read_events_backward(stream_name)
                              : event_store.read_all_streams_backward
        @matcher.matches?(events) && matches_count?
      end

      def exactly(count)
        @count = count
        self
      end

      def in_stream(stream_name)
        @stream_name = stream_name
        self
      end

      def times
        self
      end
      alias :time :times

      def once
        exactly(1)
      end

      def failure_message
        differ.diff_as_string(expected.to_s, events.to_s)
      end

      def description
        "have published [%s]" % expected
          .map { |e| formatter.(e) }
          .join(', ')
      end

      private

      def matches_count?
        return true unless count
        raise NotSupported if expected.size > 1

        expected.all? do |event_or_matcher|
          events.select { |e| event_or_matcher === e }.size.equal?(count)
        end
      end

      attr_reader :formatter, :differ, :stream_name, :expected, :count, :events
    end
  end
end
