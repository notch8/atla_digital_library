# coding: utf-8
namespace :atla do
  def update_thumbnail_reference work
    solr_doc = SolrDocument.find(work.id)
    # the path should actually point to the "downloads" folder.
    return unless solr_doc['thumbnail_path_ss'].include? 'assets'

    work.thumbnail = ActiveFedora::Base.find work.thumbnail_id
    work.save
  end

  desc 'fix the thumbnail paths for all works in the database'
  task update_all_thumbnail_paths: [:environment] do
    Hyrax.config.curation_concerns.each do |cc|
      cc.all.each do |work|
        begin
          update_thumbnail_reference(work)
        rescue => e
          puts "******** update_all_thumbnail_paths error: #{e} ********"
        end
      end

      puts "******************************"
      puts "THUMBNAIL UPDATES COMPLETE."
      puts "******************************"
    end
  end

  desc 'fix the thumbnail paths for the given bulkrax importer id'
  # rake atla:update_thumbnail_paths_per_bulkrax_importer[bulkrax_id]
  task :update_thumbnail_paths_per_bulkrax_importer, [:bulkrax_id] => [:environment, ] do |t, args|
    begin
      Bulkrax::Importer.find(args[:bulkrax_id]).entries.each do |entry|
        puts "entry.id:: #{entry.id}"
        # find the related works for those entries
        work = Work.where(identifier: entry.identifier).first
        next if work.nil?
        # next unless SolrDocument.find(work.id)['thumbnail_path_ss'].include? 'assets'

        # puts "***** updating the thumbnail for #{cc}.id: #{work.id}"
        update_thumbnail_reference(work)
      end
    rescue => e
      puts "******** update_thumbnail_paths_per_bulkrax_importer error: #{e} ********"
    end

    puts "******************************"
    puts "THUMBNAIL UPDATES COMPLETE."
    puts "******************************"
  end
end
