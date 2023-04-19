desc 'reindex items missing ancestors'
task :reindex_ancestors do
  progress = ProgressBar.create(total: ActiveFedora::Base.where("-ancestor_collection_ids_tesim: [\"\" TO *] AND has_model_ssim: Work").count, format: "%t %c of %C %a %B %p%%")
  ActiveFedora::Base.where("-ancestor_collection_ids_tesim: [\"\" TO *] AND has_model_ssim: Work").find_each do |w|
    next unless w.is_a?(Work)
    w.reindex_extent = Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX
    w.update_index
    progress.increment
  end
end

desc 'Strip spaces from subjects'
task remove_subject_spaces: [:environment] do
  progress = ProgressBar.create(total: Work.count, format: "%t %c of %C %a %B %p%%")
  Work.find_each do |w|
    original_subject = []
    work.subject = work.subject.map do |subject|
      original_subject << subject
      subject.strip
    end
    work.save if work.subject.to_a != original_subject
    progress.increment
  end
end

desc 'Fixes mp3 facet duplications and properly set to MPEG'
task repair_format_digital: [:environment] do
  progress = ProgressBar.create(total: Work.count, format: "%t %c of %C %a %B %p%%")
  Work.find_each do |w|
    first = w.format_digital&.first
    if first && first&.downcase&.match?('mp3')
      w.format_digital = ['MPEG']
      w.save!
    end
    progress.increment
  end
end

desc 'reindex collections shallowly'
task collection_index_only: [:environment] do
  progress = ProgressBar.create(total: Collection.count, format: "%t %c of %C %a %B %p%%")

  Collection.find_each do |collection|
    collection.reindex_extent = Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX
    collection.update_index
    progress.increment
  end
end

desc 'Move location on collection to contributing institution'
task location_to_contributing: [:environment] do
  puts "Assigning all Collection's :contributing_institution attributes"
  puts "~~to :based_near (Location) values, then clear :based_near values:"

  collections_missing_location = []
  progress = ProgressBar.create(total: Collection.count, format: "%t %c of %C %a %B %p%%")
  Collection.find_each do |c|
    if c.contributing_institution.present?
      puts ">>> Skipping #{c.id} :contributing_institution already exists => [#{c.contributing_institution.first}]"
      next
    end

    if c.based_near.present?
      puts ">>> #{c.id} :contributing_institution value changed from [#{c.contributing_institution.first}] => [#{c.based_near.first}]"
      c.contributing_institution = c.based_near
      c.reindex_extent = Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX
      c.save!
    else
      collections_missing_location << c
    end
    progress.increment
  end

  if collections_missing_location.any?
    puts "\n"
    puts "!!!WARNING!!! Some Collections were missing :based_near (Location) values! This"
    puts "~~means that they didn't have a Contributing Institution set. Their id's follow:"
    collections_missing_location.each do |cml|
      puts "<<< #{cml.id} (current value: :contributing_institution => [#{cml.contributing_institution.first}])"
    end
  end
end

desc 'find works missing from fedora but still in search index'
task find_missing_in_fedora: [:environment] do
  progress = ProgressBar.create(total: Work.count, format: "%t %c of %C %a %B %p%%")
  Work.find_each do |w|
    begin
      progress.increment
    rescue ActiveFedora::ActiveFedoraError => e
      puts e.message
    end
  end
end

desc 'Update Bulkrax::OaiSetEntry.identifier and Collection system identifier'
task update_oai_set_entry_and_collection_identifiers: [:environment] do
  puts "Updating Bulkrax::OaiSetEntry.identifier and Collection.#{work_identifier}"

  progress = ProgressBar.create(total: Bulkrax::OaiSetEntry.count, format: "%t %c of %C %a %B %p%%")
  Bulkrax::OaiSetEntry.find_each do |entry|
    next if entry.identifier.include?(entry.importer.parser_fields['base_url'].split('/')[2])
    new_identifier = entry.importer.unique_collection_identifier(entry.identifier)
    contributing_institution = entry.parsed_metadata['contributing_institution']
    collection = nil
    Collection.where(work_identifier => entry.identifier).each do | c |
      if contributing_institution.present?
        collection = c if contributing_institution.first == c.contributing_institution&.first
      else
        collection = c
      end
    end
    metadata = entry.parsed_metadata
    metadata[work_identifier] = [new_identifier]
    if collection
      collection.send("#{work_identifier}=", [new_identifier])
      collection.save
      entry.identifier = new_identifier
      entry.parsed_metadata = metadata
      entry.save
    end
    progress.increment
  end
end

desc 'List Works with different contributing institution to Collection'
task list_works_with_mismatched_contributing_institution: [:environment] do
  puts "Listing Works with differnt contributing institution to Collection"
  puts "  use this list to check for items in the wrong collection"
  progress = ProgressBar.create(total: Bulkrax::OaiSetEntry.count, format: "%t %c of %C %a %B %p%%")
  Bulkrax::OaiSetEntry.find_each do |entry|
    collection = Collection.where(work_identifier => entry.identifier).first
    puts "Listing collection: #{collection.id} (#{collection.send(work_identifier).first})"
    Work.where(member_of_collection_ids_ssim: collection.id).each do | work |
      puts "#{work.id}\n" if work.contributing_institution.first != collection.contributing_institution.first
    end
    puts "------\n"
    progress.increment
  end
end

desc 'Transfer source to identifier'
task source_to_identifier: [:environment] do
  progress = ProgressBar.create(total: Bulkrax::Entry.count, format: "%t %c of %C %a %B %p%%")
  Bulkrax::Entry.find_each do |entry|
    progress.increment
    next unless entry.is_a?(Bulkrax::OaiEntry)
    work = Work.where(source: entry.identifier).first
    if work
      puts "Updating: #{work.id}"
      work.identifier += [entry.identifier] unless work.identifier.include?(entry.identifier)
      src = work.source.to_a
      src.delete(entry.identifier)
      work.source = src
      work.save
    end
  end
end

desc 'Update entries with multiple collection_ids'
task multiple_collection_ids: [:environment] do
  puts "Update entries with multiple collection_ids"
  progress = ProgressBar.create(total: Bulkrax::Entry.count, format: "%t %c of %C %a %B %p%%")
  Bulkrax::Entry.find_each do |entry|
    progress.increment
    next unless entry.is_a?(Bulkrax::OaiEntry)
    next if entry.collections_created?
    puts "Updating #{entry.id}"
    entry.collection_ids = []
    entry.find_or_create_collection_ids
    entry.save
  end
end


desc 'Remove duplicate entries on an importer'
task remove_duplicate_entries: [:environment] do
  puts "Remove duplicate entries on an importer"
  progress = ProgressBar.create(total: Bulkrax::Importer.count, format: "%t %c of %C %a %B %p%%")
  Bulkrax::Importer.find_each do |importer|
    puts "Processing #{importer.id}"
    total = importer.entries.count
    unique = importer.entries.map {|e| e.identifier }.uniq.count

    if total > unique
      puts "Total: #{total}; Unique #{unique}; cleaning up"

      done = []
      destroy = []

      importer.entries.each do |e|
        if done.include?(e.identifier)
          destroy << e.id
        else
          done << e.identifier
        end
      end
      puts "Removing #{destroy.size} entries"
      destroy.each {|d| Bulkrax::Entry.find(d).destroy}
      importer.reload
      total = importer.entries.count
      unique = importer.entries.map {|e| e.identifier }.uniq.count
      puts "Total: #{total}; Unique #{unique}; after clean up"
    end
    progress.increment
  end
end

desc 'Remove duplicate identifiers from works where ActiveFedora/Solr has returned on an inexact match'
task remove_duplicate_identifiers: [:environment] do
  puts "Remove duplicate identifiers"
  progress = ProgressBar.create(total: Bulkrax::Entry.count, format: "%t %c of %C %a %B %p%%")
  num = 0
  Bulkrax::Entry.find_each do |entry|
    progress.increment
    next unless entry.is_a?(Bulkrax::OaiEntry)
    next if entry.is_a?(Bulkrax::OaiSetEntry)
    works = Work.where(identifier: entry.identifier).select {|work| work.identifier.include?(entry.identifier)}
    works.each do |work|
      identifiers = work.identifier.select {|i| i.include?(entry.identifier)}
      if identifiers.size > 1
        longest = identifiers.max_by(&:size)
        shortest = identifiers.min_by(&:size)
        # use URL to ensure we are matching the correct work
        # so far all examples have been PTC where there is a unique URL
        # if this means we miss some others, that's better than removing the
        # wrong identifier
        url = entry.parsed_metadata['identifier'].map { |i| i if i.include?('http')}.first
        if entry.identifier == shortest && work.identifier.include?(url)
          puts "Entry identifier #{entry.identifier}"
          puts "The shortest is #{shortest}"
          puts "Deleting #{longest} from #{work.id}"
          new_identifier = work.identifier.delete(longest)
          work.identifier.clear
          work.identifier = new_identifier
          work.save
          num += 1
        end
      end
    end
  end
  puts "Deleted identifiers from #{num} works"
end

desc 'Remove duplicate identifiers from works where the longer of the two should be kept'
task remove_duplicate_identifiers_longer: [:environment] do
  puts "Remove duplicate identifiers"
  progress = ProgressBar.create(total: Work.count, format: "%t %c of %C %a %B %p%%")
  num = 0
  Work.find_each do |work|
    if work.identifier.size >= 3
      url = work.identifier.select { | i | i.include?('http') }.first
      if url.present?
        id = url.split('/').last
        real_identifiers = work.identifier.select { | i | i.end_with?(id) }
        deleted_identifier = work.identifier.reject { | i | i.end_with?(id) }
        puts "Deleting identifiers #{deleted_identifier.join(' & ')} from #{work.id}"
        work.identifier.clear
        work.identifier = real_identifiers
        work.save!
        num += 1
      end
    end
    progress.increment
  end
  puts "Deleted identifiers from #{num} works"
end

desc 'Remove duplicate works - this will only work after the two remove_duplicate_identifiers tasks have run'
task remove_duplicate_works: [:environment] do
  puts "Remove duplicate works"
  progress = ProgressBar.create(total: Bulkrax::Entry.count, format: "%t %c of %C %a %B %p%%")
  num = 0
  Bulkrax::Entry.find_each do |entry|
    progress.increment
    next unless entry.is_a?(Bulkrax::OaiEntry)
    next if entry.is_a?(Bulkrax::OaiSetEntry)
    # ensure exact matches
    works = Work.where(identifier: entry.identifier).select {|work| work.identifier.include?(entry.identifier)}
    if works.length > 1
      # ensure we have the latest metadata
      entry.build_metadata
      entry.save
      latest = nil
      # older than the first object in atla
      latest_date = DateTime.new(2001,2,3,4,5,6)
      works.each do | w |
        if w.date_uploaded > latest_date
          latest = w
          latest_date = w.date_uploaded
        end
      end
      works.each do | w |
        unless w.id == latest.id
          if latest.identifier.size == w.identifier.size
            puts "Destroying #{w.id} - duplicate of #{latest.id}"
            w.destroy.eradicate
            num += 1
          else
            puts "Mismatched identifiers for #{w.id} and #{latest.id}"
          end
        end
      end
    end
  end
  puts "Destroyed #{num} works"
end

desc 'Update the collection_identifiers where the OaiSet has not yet been created'
task update_collection_identifiers: [:environment] do
  puts "Update the collection_identifiers where the OaiSet has not yet been created"
  num = 0
  identifiers = {}
  Bulkrax::Importer.find_each { | i | identifiers[i.parser_fields['set']] = i.unique_collection_identifier(i.parser_fields['set']) if i.parser_fields['set'] }
  progress = ProgressBar.create(total: identifiers.size,  format: "%t %c of %C %a %B %p%%")
  identifiers.each do |key,value|
    collection = Collection.where(identifier: key).select {|c| c.identifier.include?(key)}
    if collection.size == 1
      collection.first.identifier = [value]
      collection.first.save
      num += 1
    elsif collection.size > 1
      puts "Check these for duplicates: #{collection.each {|c| c.id}.join(', ') }"
    end
    progress.increment
  end
  puts "Updated #{num} collections"
end

desc 'Transfer source to identifier - stray ptsem'
task source_to_identifier_ptsem: [:environment] do
  puts 'Transfer source to identifier - stray ptsem'
  works = Work.where(source: 'oai:digital.library.ptsem.edu')
  puts "Updating #{works.size} works"
  num = 0
  progress = ProgressBar.create(total: works.size, format: "%t %c of %C %a %B %p%%")
  works.each do | work |
    puts "Updating: #{work.id}"
    work.identifier += [work.source.first]
    work.source = []
    work.save
    num += 1
    progress.increment
  end
  puts "Updated #{num} works"
end

desc 'Restore missing identifiers ptsem'
task missing_identifier_pstem: [:environment] do
  puts 'Restore missing identifiers ptsem'
  num = 0
  pstem = Collection.where(member_of_collection_ids_ssim: "4q77fs785")
  progress = ProgressBar.create(total: pstem.count, format: "%t %c of %C %a %B %p%%")
  pstem.each do | collection |
    puts "Processing #{collection.title.join}\n "
    progress.increment
    works = Work.where(member_of_collection_ids_ssim: collection.id)
    works.each do |work|
      url = work.identifier.select {|i| i.starts_with?('http://commons.ptsem.edu/id/')}
      next if url.blank?
      oai = "oai:digital.library.ptsem.edu:#{url.first.split('/').last}"
      unless work.identifier.include?(oai)
        work.identifier = [oai, url.first]
        work.source = []
        work.save
        num += 1
      end
    end
  end
  puts "Updated #{num} works"
end

desc 'Remove duplicate works - stray ptsem'
task remove_duplicate_works_pstem: [:environment] do
  puts 'Remove duplicate works - stray ptsem'
  works = Work.where(identifier: 'oai:digital.library.ptsem.edu')
  duplicates = {}
  # build a hash of identifiers
  works.each { | w | duplicates[w.identifier.reject {|i| i.include?('http')}.first] = [] }
  # populate the hash
  works.each { | w | duplicates[w.identifier.reject {|i| i.include?('http')}.first] << w }
  num = 0
  progress = ProgressBar.create(total: works.size, format: "%t %c of %C %a %B %p%%")
  duplicates.each do | key, value |
    progress.increment
    next if value.length <= 1
    latest = nil
    # older than the first object in atla
    latest_date = DateTime.new(2001,2,3,4,5,6)
    value.each do | w |
      if w.date_uploaded > latest_date
        latest = w
        latest_date = w.date_uploaded
      end
    end
    value.each do | w |
      unless w.id == latest.id
        puts "Destroying #{w.id} - duplicate of #{latest.id}"
        #w.destroy.eradicate
        num += 1
      end
    end
  end
  puts "Deleted #{num} works"
end

desc 'format_original_and_subject makes sure subject and format original rules match current bulkrax convention for new records'
task format_original_and_subjects: [:environment] do
  progress = ProgressBar.create(total: Work.count, format: "%t %c of %C %a %B %p%%")
  Work.find_each do |work|
    dirty = false
    if work.format_original.present?
      formats = []
      work.format_original.each_with_index do |format, i|
        string = format.downcase
        fixed = string.slice(0,1).capitalize + string.slice(1..-1)
        if fixed != format
          formats << fixed
          dirty = true
        else
          formats << format
        end
      end
      work.format_original = formats if dirty
    end
    if work.subject.present?
      subjects = []
      work.subject.each_with_index do |subject, i|
        fixed = subject.gsub(/\.$/, '')
        if fixed != subject
          subjects << fixed
          dirty = true
        else
          subjects << subject
        end
      end
      work.subject = subjects if dirty
    end
    work.save! if dirty
    progress.increment
  end
end
