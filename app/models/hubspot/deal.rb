
module Hubspot
  # Simpro company OBJECT

  class Deal
    DEAL_PATH='https://api.hubapi.com/crm/v3/objects/deals'

  	def self.create_update_booking_deal(booking,company_id,customer_id)
  		existing_deal = Hubspot::Deal.find_booking_deal(booking["id"])
      created_at = Time.strptime(booking["created_at"].to_datetime.strftime("%m/%d/%Y %I:%M %p"), "%m/%d/%Y %I:%M %p").to_i * 1000 rescue ""
  		updated_at = Time.strptime(booking["updated_at"].to_datetime.strftime("%m/%d/%Y %I:%M %p"), "%m/%d/%Y %I:%M %p").to_i * 1000 rescue ""

      start_time = Time.strptime(booking["starts_at"].to_datetime.strftime("%m/%d/%Y %I:%M %p"), "%m/%d/%Y %I:%M %p").to_i * 1000 rescue ""
      end_time = Time.strptime(booking["stops_at"].to_datetime.strftime("%m/%d/%Y %I:%M %p"), "%m/%d/%Y %I:%M %p").to_i * 1000 rescue ""
      deal_name =  booking["number"] + " - " + booking["customer"]["name"] rescue booking["id"]
      if booking["status"] == 'reserved'
        stage = '241790136'
      elsif booking["status"] == 'canceled'
        stage = '241790211'
      else
        stage = '241790212'
      end
      booqable_url = 'https://barons-beverage-services.booqable.com/orders/' + booking["id"].to_s rescue "N/A"
      delivery_contact = booking["customer"]["properties_attributes"]["delivery_contact"] rescue ""    
      delivery_info = booking["properties_attributes"]["delivery_information"] rescue "" 
      event_name = booking["properties_attributes"]["event_name"] rescue "" 
       body_json = {
        "properties": {
        "pipeline":  '141419081',
        "booking_created_at": created_at,
        "booking_end":   end_time,
        "dealname": deal_name,
        "booking_start":  start_time,
        "booking_updated_at": updated_at,
        "booqable_event_name": event_name,
        "booqable_id": booking["id"],
        "booqable_item_count": booking["item_count"],
        "booking_number": booking["number"],
        "dealstage": stage,
        "booqable_payment_status": booking["payment_status"],
        "booqable_status": booking["status"],
        "delivery_contact": delivery_contact,
        "delivery_information": delivery_info,
        "deposit_type": booking["deposit_type"],
        "deposit_value": booking["deposit_value"],
        "discount": booking["discount"],
         "discount_type": booking["discount_type"],
         "entirely_started": booking["entirely_started"],
         "entirely_stopped": booking["entirely_stopped"],
         "amount": booking["price_with_tax"],
         "tax": booking["tax"],
         "service_category": 'Rental',
         "booqable_url": booqable_url
         }
      }

        if existing_deal["results"].blank?
          response = HTTParty.post("#{DEAL_PATH}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
        else 
          deal_id = existing_deal["results"].first["id"]
          response = HTTParty.patch("#{DEAL_PATH}/#{deal_id}",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
        end

        if response.present? && response.success?
          puts "deal created/updated #{deal_name}"
            if customer_id.present?
              response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/deals/#{response["id"]}/associations/contacts/#{customer_id}/deal_to_contact",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
            end
            if company_id.present?
              response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/deals/#{response["id"]}/associations/companies/#{company_id}/deal_to_company",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })

            end
              
        end
  end

  def self.get_deal_associated_contact(deal_id)
      body_json = 
     {"inputs":[{"id": "#{deal_id}"}]}
    
      response = HTTParty.get("https://api.hubapi.com/crm/v4/objects/deals/#{deal_id}/associations/contacts", :headers => {
           "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      
      contact_id = response["results"].first["toObjectId"].to_s rescue nil
      association_label = response["results"].first["associationTypes"].map{|i| i["label"]}.compact.join rescue nil
      return contact_id,association_label
    end

    def self.get_deal_associated_company(deal_id)
      body_json = 
     {"inputs":[{"id": "#{deal_id}"}]}
    
      response = HTTParty.post("https://api.hubapi.com/crm/v3/associations/deal/company/batch/read",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      contact_id = response["results"].first["to"].first["id"] rescue nil
      return contact_id
    end

    def self.associate_company(deal_id,company_id)
      existing_company =  Hubspot::Company.find_company(company_id)
      if existing_company["results"].blank?
        Simpro::Company.webhook_customer(company_id)
        existing_company =  Hubspot::Company.find_company(company_id)
      end
      user_id = existing_company["results"].first["id"]
      response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/deals/#{deal_id}/associations/companies/#{user_id}/deal_to_company",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
    end

    def self.associate_contact(deal_id,company_id)
      existing_user = Hubspot::Contact.find_simpro_user(company_id)
      if existing_user["results"].blank?
        Simpro::Customer.webhook_individual_customer(company_id)
        existing_user = Hubspot::Contact.find_simpro_user(company_id)
      end
      user_id = existing_user["results"].first["id"]
      response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/deals/#{deal_id}/associations/contacts/#{user_id}/deal_to_contact",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })

    end


    def self.update_simpro_id(simpro_id,deal_id,dealname)
      deal_name = simpro_id.to_s + " - " + dealname
      body_json = {
        "properties": {
         "simpro_quote_id":  simpro_id,
         "dealname": deal_name,
          "initial_sync": Time.strptime(Time.now.to_datetime.strftime("%m/%d/%Y %I:%M %p"), "%m/%d/%Y %I:%M %p").to_i * 1000

        }
      }
      response = HTTParty.patch("#{DEAL_PATH}/#{deal_id}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
    end

    def self.update_simpro_job_id(simpro_id,deal_id,dealname)
      deal_name = simpro_id.to_s + " - " + dealname
      body_json = {
        "properties": {
         "simpro_job_id":  simpro_id,
         "dealname": deal_name,
          "initial_sync": Time.strptime(Time.now.to_datetime.strftime("%m/%d/%Y %I:%M %p"), "%m/%d/%Y %I:%M %p").to_i * 1000

        }
      }
      response = HTTParty.patch("#{DEAL_PATH}/#{deal_id}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
    end

 def self.update_response(quote_response,deal_id)
      if quote_response["message"].present?
        message =  quote_response["message"]
      else
         message =  "Quote synced successfully Quote id #{ quote_response["ID"]}"
      end
       body_json = {
        "properties": {
          "last_sync_notes": message
        }
      }
      response = HTTParty.patch("#{DEAL_PATH}/#{deal_id}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
    end


    def self.update_properties(deal_id,quote,time)
      deal_name = quote["ID"].to_s + " - " + quote["Name"] rescue "-"
      sync_time = (time.round(2)).to_s + " seconds"
       body_json = {
        "properties": {
         "amount":  quote["Total"]["ExTax"],
         "simpro_status": quote["Status"]["Name"],
         "dealname": deal_name,
         "last_synced": Time.strptime(Time.now.to_datetime.strftime("%m/%d/%Y %I:%M %p"), "%m/%d/%Y %I:%M %p").to_i * 1000,
         "sync_time": sync_time
        }
      }
      response = HTTParty.patch("#{DEAL_PATH}/#{deal_id}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
    end


    # def self.service_deal_create(quote,deal,deal_quote_type)
    #   lost_reason = quote["ArchiveReason"]["ArchiveReason"] rescue ""
    #   createdate = quote["DateIssued"].to_date.midnight.to_time.to_i*1000  rescue ""
    #   duedate = (quote["DueDate"].to_date.midnight.to_time).to_i*1000  rescue ""
    #   deal_name = quote["ID"].to_s + " - " + quote["Name"] rescue quote["ID"].to_s
    #   existing_deal = Hubspot::Deal.find_deal(quote["ID"])

    #   if deal_quote_type == "cs"
    #      body_json = {
    #     "properties": {
    #     "pipeline":  '99064497',
    #     "dealname": deal_name,
    #     "amount":  quote["Total"]["ExTax"],
    #     "simpro_quote_id": quote["ID"],
    #     "createdate": createdate,
    #     "dealstage": 181249911,
    #     "description": quote["Description"],
    #     "quote_type": 'Service',
    #     "simpro_status": quote["Status"]["Name"],
    #     "closed_lost_reason": lost_reason,
    #      }
    #   }
    #   else
    #      body_json = {
    #     "properties": {
    #     "pipeline":  '99064497',
    #     "dealname": deal_name,
    #     "amount":  quote["Total"]["ExTax"],
    #     "simpro_quote_id": quote["ID"],
    #     "createdate": createdate,
    #     "dealstage": 181249906,
    #     "description": quote["Description"],
    #     "quote_type": 'Service',
    #     "simpro_status": quote["Status"]["Name"],
    #     "closed_lost_reason": lost_reason,
    #      }
    #   }
    #   end



    #   if existing_deal["results"].blank?
    #     response = HTTParty.post("#{DEAL_PATH}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
     
    #   else
    #     deal_id = existing_deal.first["id"]
    #     response = HTTParty.patch("#{DEAL_PATH}/#{deal_id}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
    #   end
    # end

    def self.attach_site(site_id,deal_id)
      site = Hubspot::Site.search_site(site_id)
      sm_site_id = site["results"].first["id"] rescue nil
      if sm_site_id.present?
        response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/deals/#{deal_id}/associations/p_sites/#{sm_site_id.to_i}/54?paginateAssociations=false",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
      end
    end

    def self.find_deal(simpro_id)
      sleep(1)
       body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "simpro_quote_id",
                "operator": "EQ",
                "value": "#{simpro_id}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{DEAL_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      return response
    end


  	def self.find_booking_deal(booking_id)
  		sleep(1)
       body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "booqable_id",
                "operator": "EQ",
                "value": "#{booking_id}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{DEAL_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      return response
  	end
  end
end