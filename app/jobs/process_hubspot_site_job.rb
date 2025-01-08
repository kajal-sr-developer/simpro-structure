# app/jobs/process_hubspot_site_job.rb
class ProcessHubspotSiteJob < ApplicationJob
  queue_as :default

  def self.perform(params)
    # Your asynchronous task code here
    puts  "---------create site from hubspot---------------------" + "no of jobs now " + Delayed::Job.count.to_s + "------------------------------"
    Simpro::Site.create_find_site(params)
  end
end
