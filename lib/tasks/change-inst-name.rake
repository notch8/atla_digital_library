# coding: utf-8
namespace :cdri do
  desc 'postcards-of-unitarian-and-universalist-church-buildings fixes'
  task postcards_unitarian_and_church_buildings: [:environment] do
    col = Collection.where(slug: 'postcards-of-unitarian-and-universalist-church-buildings').first
    raise 'collection not found' unless col.present?

    progress = ProgressBar.create(format: "%t %c of %C %a %B %p%%", total: ActiveFedora::Base.where(member_of_collection_ids_ssim: col.id, has_model_ssim: ['Work']).count)
    errors = []
    ActiveFedora::Base.where(member_of_collection_ids_ssim: col.id, has_model_ssim: ['Work']).each do |work|
      begin
        ActiveFedora::Base.where(contributing_institution_sim: ['Andover-Harvard Theological Library']).each do |work|
          # Correct Contributing Institution field to be: Harvard Divinity School Library
          work.contributing_institution = ['Harvard Divinity School Library']
          work.save!
        rescue => e
          errors << [work, e]
        end
        progress.increment
      end
    end
    if errors.present?
      $stderr.puts "-- ERRORS REPORTED"
      $stderr.puts "#{work.id} - #{e.message}\n#{e.backtrace[0..6]}"
    end
  end
  if errors.present?
    $stderr.puts "-- ERRORS REPORTED"
    $stderr.puts "#{work.id} - #{e.message}\n#{e.backtrace[0..6]}"
  end
end
  
desc 'thanksgiving-day-sermons fixes'
task thanksgiving_day_sermons: [:environment] do
  col = Collection.where(slug: 'thanksgiving-day-sermons').first
  raise 'collection not found' unless col.present?
  
  progress = ProgressBar.create(format: "%t %c of %C %a %B %p%%", total: ActiveFedora::Base.where(member_of_collection_ids_ssim: col.id, has_model_ssim: ['Work']).count)
  errors = []
  ActiveFedora::Base.where(member_of_collection_ids_ssim: col.id, has_model_ssim: ['Work']).each do |work|
    begin
      ActiveFedora::Base.where(contributing_institution_sim: ['Andover-Harvard Theological Library']).each do |work|
        # Correct Contributing Institution field to be: Harvard Divinity School Library
        work.contributing_institution = ['Harvard Divinity School Library']
        work.save!
      rescue => e
        errors << [work, e]
      end
    end
    if errors.present?
      $stderr.puts "-- ERRORS REPORTED"
      $stderr.puts "#{work.id} - #{e.message}\n#{e.backtrace[0..6]}"
    end
  end
end
