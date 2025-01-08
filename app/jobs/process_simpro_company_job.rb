# app/jobs/process_quote_job.rb
class ProcessSimproCompanyJob < ApplicationJob
  queue_as :default

  def self.perform(props,company_id)
    # Your asynchronous task code here
    puts  "------------------------------" + "no of jobs now " + Delayed::Job.count.to_s + "------------------------------"
    Simpro::Company.find_hubspot_company(props,company_id)
  end
end
