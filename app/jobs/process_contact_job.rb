# app/jobs/process_contact_job.rb
class ProcessContactJob < ApplicationJob
  queue_as :default

  def self.perform(customer_id)
    # Your asynchronous task code here
    puts  "------created simpro customer------------------------" + "no of jobs now " + Delayed::Job.count.to_s + "------------------------------"
    Simpro::Customer.webhook_individual_customer(customer_id)
  end
end