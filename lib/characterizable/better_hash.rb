module Characterizable
  class BetterHash < ::Hash
    # In Ruby 1.9, running select/reject/etc. gives you back a hash
    # if RUBY_VERSION < '1.9'
      def to_hash
        Hash.new.replace self
      end
      def as_json(*)
        to_hash
      end
      def reject(&block)
        inject(Characterizable::BetterHash.new) do |memo, ary|
          unless block.call(*ary)
            memo[ary[0]] = ary[1]
          end
          memo
        end
      end
      def select(&block)
        inject(Characterizable::BetterHash.new) do |memo, ary|
          if block.call(*ary)
            memo[ary[0]] = ary[1]
          end
          memo
        end
      end
      # I need this because otherwise it will try to do self.class.new on subclasses
      # which would get "0 for 1" arguments error with Snapshot, among other things
      def slice(*keep)
        inject(Characterizable::BetterHash.new) do |memo, ary|
          if keep.include?(ary[0])
            memo[ary[0]] = ary[1]
          end
          memo
        end
      end
    # end
  end
end
