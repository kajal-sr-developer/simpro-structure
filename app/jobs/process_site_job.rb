# app/jobs/process_quote_job.rb
class ProcessSiteJob < ApplicationJob
  queue_as :default

  def self.perform(site_id)
    # Your asynchronous task code here
    puts  "------------------------------" + "no of jobs now " + Delayed::Job.count.to_s + "------------------------------"
    Simpro::Site.create_update_site_webhook(site_id)
  end
end
