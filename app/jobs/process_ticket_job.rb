# app/jobs/process_quote_job.rb
class ProcessTicketJob < ApplicationJob
  queue_as :default

  def self.perform(job_id)
    # Your asynchronous task code here
    puts  "---simpro job update---------------------------" + "no of jobs now " + Delayed::Job.count.to_s + "------------------------------"
    Simpro::Job.webhook_job(job_id)
  end
end
