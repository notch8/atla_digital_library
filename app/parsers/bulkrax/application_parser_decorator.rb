# OVERRIDE Bulkrax 4.4.1 to get a patch for create_objects

module Bulkrax
  class ApplicationParser
    class ApplicationParserDecorator
      # override create_objects to get the patch from https://github.com/samvera-labs/bulkrax/pull/663
      def create_objects(types = [])
        types.each do |object_type|
          send("create_#{object_type.pluralize}")
        end

      end
    end
  end
end

Bulkrax::ApplicationParser.prepend(Bulkrax::ApplicationParser::ApplicationParserDecorator)