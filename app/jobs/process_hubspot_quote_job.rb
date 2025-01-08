# app/jobs/process_hubspot_quote_job.rb
class ProcessHubspotQuoteJob < ApplicationJob
  queue_as :default

  def self.perform(params)
    # Your asynchronous task code here
    puts  "---------create quote from hubspot---------------------" + "no of jobs now " + Delayed::Job.count.to_s + "------------------------------"
    Simpro::Quote.create_quote(params)
  end
end
