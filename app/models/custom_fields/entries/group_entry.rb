module CustomFields
  module Entries
    # A set of Entrys corresponding to a GroupField in the Spec.
    class GroupEntry < Entry
      include ActiveModel::Validations

      attr_accessor :entries

      delegate :root?, to: :field

      validate :validate_children

      def initialize(field:, hash:, parent: nil)
        super(field: field, hash: hash, parent: parent)
        self.entries = field.fields.map do |f|
          klass = f.type == :group ? GroupEntry : BasicEntry
          klass.new(field: f, hash: root? ? hash : hash[key], parent: self)
        end
      end

      def value
        self
      end

      def keys
        entries_by_key.keys
      end

      def [](key)
        entries_by_key[key.to_sym].try(:value)
      end

      def []=(key, new_value)
        entries_by_key[key.to_sym].try(:update, new_value)
      end

      def method_missing(symbol, *args)
        key = symbol.to_s.chomp("=").to_sym
        if keys.include?(key)
          if symbol[-1] == "="
            self[key] = args.first
          else
            self[key]
          end
        else
          super
        end
      end

      def update(hash)
        check_hash(hash)
        hash = hash.with_indifferent_access
        entries.each do |entry|
          entry.update(hash[entry.key]) if hash.has_key?(entry.key)
        end
      end

      # Runs validations and sets error on parent GroupEntry if invalid
      def do_validation(parent)
        parent.errors.add(key, :invalid) unless valid?
      end

      # Returns an i18n_key of the given type (e.g. `errors`, `placeholders`).
      # If `suffix` is true, adds `._self` on the end,
      # for when the group itself needs a translation.
      def i18n_key(type, suffix: true)
        super << (suffix ? "._self" : "")
      end

      private

      def entries_by_key
        @entries_by_key ||= entries.map { |e| [e.key, e] }.to_h
      end

      # Runs the validations specified in the `validations` property of any children.
      def validate_children
        entries.each { |e| e.do_validation(self) }
      end
    end
  end
end
