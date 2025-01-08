# app/jobs/process_company_job.rb
class ProcessCompanyJob < ApplicationJob
  queue_as :default

  def self.perform(customer_id)
    # Your asynchronous task code here
    puts  "------------------------------" + "no of jobs now " + Delayed::Job.count.to_s + "------------------------------"
    Simpro::Company.webhook_customer(customer_id)
  end
end
