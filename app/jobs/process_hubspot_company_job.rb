   # app/jobs/process_hubspot_contact_job.rb
class ProcessHubspotCompanyJob < ApplicationJob
  queue_as :default

  def self.perform(params,company_id)
    # Your asynchronous task code here
    puts  "---------create company from hubspot---------------------" + "no of jobs now " + Delayed::Job.count.to_s + "------------------------------"
    
    Simpro::Company.find_hubspot_company(params,company_id)
  end
end
