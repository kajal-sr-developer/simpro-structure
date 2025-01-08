class HubspotController < ApplicationController
	skip_before_action :verify_authenticity_token
	def contact_webhook
    user_id = params["properties"]["hs_object_id"]["value"]
    Simpro::Customer.find_hubspot_customer(params["properties"],user_id)
    #ProcessHubspotContactJob.delay(run_at: 1.seconds.from_now).perform(params["properties"],user_id)
  end



  def company_webhook
    company_id = params["properties"]["hs_object_id"]["value"]
    if company_id.present?
      Simpro::Company.find_hubspot_company(params["properties"],company_id)
      #ProcessHubspotCompanyJob.delay(run_at: 1.seconds.from_now).perform(params["properties"],company_id)
    end
  end

  def deal_notes_webhook
    deal_id = params["properties"]["hs_object_id"]["value"]
    quote_id = params["properties"]["simpro_quote_id"]["value"] rescue nil
    notes = Simpro::Note.get_quote_notes(quote_id)
    emails = Simpro::Note.get_quote_emails(quote_id)
    if quote_id.present?
      Simpro::Note.create_quote_notes(emails,notes,quote_id,deal_id)
    end
  end


  def change_to_newjob
    quote_id = params["properties"]["simpro_quote_id"]["value"] rescue nil
    if quote_id.present?
      Simpro::Quote.change_to_newjob(quote_id,params)
    end
  end

  def resync
    quote_id = params["properties"]["simpro_quote_id"]["value"] rescue nil
    if quote_id
      # Simpro::Quote.webhook_quote(quote_id)
      ProcessQuoteJob.delay(run_at: 1.seconds.from_now).perform(quote_id)

      # ProcessQuoteJob.delay(run_at: 1.seconds.from_now).perform(quote_id)
    end
  end

  def postmix_job_webhook
     Simpro::Job.create_postmix_job(params)
  end

  def resync_button
    # Simpro::Quote.webhook_quote(params["quote_id"])
    ProcessQuoteJob.delay(run_at: 1.seconds.from_now).perform(params["quote_id"])
  end

  def change_to_lost
    quote_id = params["properties"]["simpro_quote_id"]["value"] rescue nil
    if quote_id.present?
      reason = params["properties"]["closed_lost_reason___select"]["value"] rescue ""
      Simpro::Quote.change_to_lost(quote_id,reason)
    end
  end

  def site_webhook
     Simpro::Site.create_find_site(params)
    # ProcessHubspotSiteJob.delay(run_at: 1.seconds.from_now).perform(params)
  end

  def quote_webhook
    # ProcessHubspotQuoteJob.delay(run_at: 1.seconds.from_now).perform(params)
    puts  "---------create quote from hubspot---------------------"
    Simpro::Quote.create_quote(params)
  end
end
