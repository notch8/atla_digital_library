module Bulkrax
  # Parser for the Internet Archive OAI-PMH Endpoint
  class OaiIaParser < OaiDcParser
    def entry_class
      OaiIaEntry
    end

    # def collection_entry_class
    #   # OaiSetEntry # default from application_parser.rb
    # end

    # @abstract Subclass and override {#create_file_sets} to implement behavior for the parser.
    def create_file_sets
      # create_objects(['file_set'])
    end

    # @abstract Subclass and override {#create_relationships} to implement behavior for the parser.
    def create_relationships
      # create_objects(['relationship'])
    end

    def file_set_entry_class; end

    def create_collections
      metadata = {
        visibility: 'open',
        collection_type_gid: Hyrax::CollectionType.find_or_create_default_collection_type.gid
      }

      # OVERRIDE Bulkrax 4.4.1 to add collection title
      collections.each_with_index do |set, index|
        next unless collection_name == 'all' || collection_name == set.spec
        unique_collection_identifier = importerexporter.unique_collection_identifier(set.spec)

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

    def create_objects(types = [])
      types_array ||= Bulkrax::Importer::DEFAULT_OBJECT_TYPES
      types.each do |object_type|
        send("create_#{object_type.pluralize}")
      end
    end
  end
end
