# OVERRIDE: Bulkrax 4.4.1 to add collection title, noted below.
# OVERRIDE: Bulkrax 4.4.1 to get a patch from Bulkrax 5.x.x for create_objects, noted below.
# TODO: remove create_objects method when upgrading to Bulkrax 5.x.x
module Bulkrax
  # Parser for the Internet Archive OAI-PMH Endpoint
  class OaiIaParser < OaiDcParser
    def entry_class
      OaiIaEntry
    end

    def create_collections
      metadata = {
        visibility: 'open',
        collection_type_gid: Hyrax::CollectionType.find_or_create_default_collection_type.gid
      }

      collections.each_with_index do |set, index|
        next unless collection_name == 'all' || collection_name == set.spec
        unique_collection_identifier = importerexporter.unique_collection_identifier(set.spec)

        # add collection title
        metadata[:title] = [parser_fields['collection_title'] || set.name]
        metadata[work_identifier] = [unique_collection_identifier]

        new_entry = collection_entry_class.where(importerexporter: importerexporter,
                                                 identifier: unique_collection_identifier,
                                                 raw_metadata: metadata)
                                          .first_or_create!
        # perform now to ensure this gets created before work imports start
        ImportCollectionJob.perform_now(new_entry.id, importerexporter.current_run.id)
        increment_counters(index, collection: true)
      end
    end
  end
end
