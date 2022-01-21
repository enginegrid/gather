# frozen_string_literal: true

module CustomFields
  module Fields
    class UrlField < TextualField
      def type
        :url
      end

      def normalize(value)
        value&.strip.presence
      end

      protected

      def set_implicit_validations
        super
        validation[:url] = {host: extra_params[:host], allow_blank: true}
      end
    end
  end
end
