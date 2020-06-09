require 'rake'

Rake::Task.clear
AtlaDigitalLibrary::Application.load_tasks

class UpdateStatisticalDataJob < Hyrax::ApplicationJob
  queue_as :update_statistical_data

  def perform
    begin
      Rake::Task['atla:update_announcement_text'].invoke

      self.class.set(wait_until: 1.week.from_now.beginning_of_day).perform_later
    rescue
      return false
    end
  end
end
