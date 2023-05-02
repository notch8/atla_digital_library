module Bulkrax
  class OaiDcEntry < OaiEntry
    include Bulkrax::Concerns::HasLocalProcessing
    def self.matcher_class
      Bulkrax::AtlaOaiMatcher
    end

    # OVERRIDE: v4.4.2 Bulkrax::ImportBehavior#add_collections
    def add_collections
      return if self.find_collection_ids.blank?

      # we need this mapping to exist so that Bulkrax::ImportBehavior#build_for_importer calls #parent_jobs
      self.parsed_metadata[related_parents_parsed_mapping] = self.find_collection_ids
    end
  end
end
