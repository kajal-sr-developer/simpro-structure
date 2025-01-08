# app/jobs/process_hubspot_contact_job.rb
class ProcessHubspotContactJob < ApplicationJob
  queue_as :default

  def self.perform(params,user_id)
    # Your asynchronous task code here
    puts  "---------create contact from hubspot---------------------" + "no of jobs now " + Delayed::Job.count.to_s + "------------------------------"
    
    Simpro::Customer.find_hubspot_customer(params,user_id)
  end
end
