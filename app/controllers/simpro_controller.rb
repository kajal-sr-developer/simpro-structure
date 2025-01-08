class SimproController < ApplicationController
	skip_before_action :verify_authenticity_token

	def individual_customer
		customer_id = params[:reference]["individualCustomerID"]
		if customer_id.present?
			# ProcessContactJob.delay(run_at: 1.seconds.from_now).perform(customer_id)
			Simpro::Customer.webhook_individual_customer(customer_id)
		end	
	end

	def company_contact
		customer_id = params[:reference]["customerID"]
		if customer_id.present?
			# ProcessCompanyContactJob.delay(run_at: 1.seconds.from_now).perform(customer_id)
    end
			
	end

	def company_customer
		customer_id = params[:reference]["customerID"]
		if customer_id.present?
			 Simpro::Company.webhook_customer(customer_id)

			# ProcessCompanyJob.delay(run_at: 1.seconds.from_now).perform(customer_id)
		end
	end




	def site
		site_id = params[:reference]["siteID"]
		if site_id.present?
			Simpro::Site.create_update_site_webhook(site_id)

			# ProcessSiteJob.delay(run_at: 1.seconds.from_now).perform(site_id)
    end	
	end

	def quote
		quote_id =  params[:reference]["quoteID"]
		if quote_id.present?
      ProcessQuoteJob.delay(run_at: 2.seconds.from_now).perform(quote_id)
      # Simpro::Quote.webhook_quote(quote_id)
		end
	end


	def job
		job_id =  params[:reference]["jobID"]
		if job_id.present?
			Simpro::Job.webhook_job(job_id)
			# ProcessTicketJob.delay(run_at: 1.seconds.from_now).perform(job_id)
		end
	end

end
