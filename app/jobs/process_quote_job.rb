# app/jobs/process_quote_job.rb
class ProcessQuoteJob < ApplicationJob
  queue_as :default

  def self.perform(quote_id)
    # Your asynchronous task code here
    puts  "---simpro quote update---------------------------" + "no of jobs now " + Delayed::Job.count.to_s + "------------------------------"
    Simpro::Quote.webhook_quote(quote_id)
  end
end
