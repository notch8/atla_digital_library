# frozen_string_literal: true
# OVERRIDE Bulkrax 4.4.2 to make sure the AtlaMatcher is being used for CSVs
Bulkrax::CsvEntry.class_eval do
  def self.matcher_class
    Bulkrax::AtlaMatcher
  end
end
