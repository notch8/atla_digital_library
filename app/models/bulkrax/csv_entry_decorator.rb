# frozen_string_literal: true
# OVERRIDE Bulkrax 4.4.2 to make sure the AtlaMatcher is being used for CSVs
module Bulkrax
  module CsvEntryClassDecorator
    def matcher_class
      Bulkrax::AtlaMatcher
    end
  end
end

::Bulkrax::CsvEntry.singleton_class.send(:prepend, Bulkrax::CsvEntryClassDecorator)
