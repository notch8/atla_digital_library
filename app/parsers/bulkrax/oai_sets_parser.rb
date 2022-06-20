module Bulkrax
  # Parser for standard oai_dc OAI-PMH endpoints, with manual addition of sets
  class OaiSetsParser < OaiDcParser
    def entry_class
      OaiDcEntry
    end

    # One set only; no 'all' option
    def create_collections
      metadata = {
        visibility: 'open',
        collection_type_gid: Hyrax::CollectionType.find_or_create_default_collection_type.gid
      }

      set = parser_fields['set']
      unique_collection_identifier = importerexporter.unique_collection_identifier(set)

      metadata[:title] = [parser_fields['collection_title']]
      metadata[Bulkrax.system_identifier_field] = [unique_collection_identifier]

      new_entry = collection_entry_class.where(importerexporter: importerexporter,
                                               identifier: unique_collection_identifier,
                                               raw_metadata: metadata)
                                        .first_or_create!
      ImportWorkCollectionJob.perform_later(new_entry.id, importerexporter.current_importer_run.id)
    end
  end
end
