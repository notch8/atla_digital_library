module Bulkrax
  class ScheduleImportersJob < ApplicationJob
    queue_as :default

    def perform
      importers = Bulkrax::Importer.where('frequency <> ?', 'PT0S')
      importers.each do |importer|
        if importer.schedulable? && !job_exists_for_importer?(importer)
          Bulkrax::ImporterJob.set(wait_until: importer.next_import_at).perform_later(importer.id, true)
        end
      end
      puts "************************* HIT def perform *************************"
    end

    private

    def job_exists_for_importer?(importer)
      enqueued_jobs.any? do |job|
        job_class_name = case Rails.application.config.active_job.queue_adapter
                         when :delayed_job
                           job.handler.match(/job_class: ([\w:]+)/)[1]
                         when :sidekiq
                           job['class']
                         when :good_job
                           job[:job_class]
                         end

        job_class_name == "Bulkrax::ImporterJob" && job_arguments_include?(job, importer.to_gid.to_s)
      end
    end

    def enqueued_jobs
      case Rails.application.config.active_job.queue_adapter
      when :delayed_job
        Delayed::Job.where("handler LIKE ?", "%job_class: Bulkrax::ImporterJob%")
      when :sidekiq
        Sidekiq::Queue.new.map(&:item)
      when :good_job
        GoodJob::ActiveJobExtensions::Concurrency.executing.where("serialized_params LIKE ?", "%Bulkrax::ImporterJob%")
      else
        raise RuntimeError, "The current queue_as adapter in your application, is currently not supported. Supported adapters are: Delayed Job, Sidekiq, and GoodJob."
      end
    end

    def job_arguments_include?(job, importer_gid)
      case Rails.application.config.active_job.queue_adapter
      when :delayed_job
        job.handler.include?(importer_gid)
      when :sidekiq
        job['args'].include?(importer_gid)
      when :good_job
        job[:serialized_params].include?(importer_gid)
      else
        false
      end
    end
  end
end