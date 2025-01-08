  module Hubspot
  #
  # HubSpot CONTACT OBJECT
  #
  class Contact
    CONTACT_PATH='https://api.hubapi.com/crm/v3/objects/contacts'
    CRM_PATH = 'https://api.hubapi.com/crm/v3/objects/companies'

    def self.create_update_individual(customer)
      # Method : Post
      # Example URL to POST to:
      time = Time.now.strftime("%m/%d/%Y %I:%M %p")
      if customer["ID"].present?
        existing_user = Hubspot::Contact.find_user(customer["ID"])
        if existing_user["results"].blank?
          existing_user = Hubspot::Contact.find_by_email(customer["Email"])
        end
      end   
      # cost_center = customer["Profile"]["ServiceJobCostCenter"]["Name"]  rescue ""
      create_date = (customer["DateCreated"].to_date) rescue (Date.today)
      customer_group = customer["Profile"]["CustomerGroup"].present? ? customer["Profile"]["CustomerGroup"]["Name"] : ""
      body_json = {
        "properties": {
          "salutation": customer["Title"], 
           "phone": customer["Phone"].gsub(/[^0-9A-Za-z , : ]/, '') || '',
           "email": customer["Email"],
           "alt_company": customer["AltPhone"].gsub(/[^0-9A-Za-z , : ]/, '') || '',
           "mobilephone": customer["CellPhone"] || '',
           "website": customer["Website"] || "",
           "fax": customer["Fax"] || "",
          "firstname": customer["GivenName"],
          "lastname": customer["FamilyName"],
          "address": customer["Address"]["Address"].gsub(/[^0-9A-Za-z , : ]/, '') || '',
          "city": customer["Address"]["City"],
          "state": customer["Address"]["State"],
          "zip": customer["Address"]["PostalCode"],
          "country": customer["Address"]["Country"],
          "customer_group":  customer_group,
          "postal_street_address": customer["BillingAddress"]["Address"],
          "postal_suburb": customer["BillingAddress"]["City"],
          "postal_state": customer["BillingAddress"]["State"],
          "postal_post_code": customer["BillingAddress"]["PostalCode"],
          "postal_country": customer["BillingAddress"]["Country"],
          "simpro_date_created": create_date,
         "simpro_customer_id": customer["ID"],
         "on_stop":  customer["Banking"]["OnStop"]
        }
      }

      if existing_user["results"].blank?
        response = HTTParty.post("#{CONTACT_PATH}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
      else  
        contact_id = existing_user["results"].first["id"]
        response = HTTParty.patch("#{CONTACT_PATH}/#{contact_id}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
        if response.present? && response.success?
          note = Simpro::Customer.find_notes(customer["ID"])
          if response["id"].present?
           customer_notes = HTTParty.get("https://api.hubapi.com/crm/v4/objects/contacts/#{response["id"]}/associations/notes",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
            if customer_notes["results"].present?
              customer_notes["results"].each do |note|
                delete_response = HTTParty.delete("https://api.hubapi.com/crm/v4/objects/contacts/#{response["id"]}/associations/notes/#{note['toObjectId']}",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
              end
            end
            Hubspot::Note.create_user_note(note,response["id"])
          end
        elsif response["message"].include?("A contact with the email")
          body_json[:properties].delete(:email)
          response = HTTParty.patch("#{CONTACT_PATH}/#{contact_id}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
        end
        if response.present? && response.success? && customer["Sites"].present?
          Hubspot::Site.associate_sites_customer(customer["Sites"],'individual',response["id"])
          puts "conatct added/updated #{customer["Email"]}" 
        end
      end
    end


    def self.create_quote_contact(body_json,email)
      existing_user = Hubspot::Contact.find_by_email(email)
      if existing_user["results"].blank?
        response = HTTParty.post("#{CONTACT_PATH}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
        if response.present? && response.success?
          return response["id"]
        end
      else
        return existing_user["results"].first["id"]
      end
    end



   def self.create_update_booking_customer(customer)
      # Method : Post
      # Example URL to POST to:
      if customer.present?
        time = Time.now.strftime("%m/%d/%Y %I:%M %p")
        if customer["id"].present? 
          existing_user = Hubspot::Contact.find_user(customer["id"])
          if existing_user["results"].blank?
            existing_user = Hubspot::Contact.find_by_email(customer["email"])
          end
        end      
        # cost_center = customer["Profile"]["ServiceJobCostCenter"]["Name"]  rescue ""
        create_date = (customer["created_at"].to_date) rescue (Date.today)
        customer_name = customer["properties_attributes"]["main"]
        cus_name =  customer_name.split("\n") rescue nil
        firstname = cus_name.first rescue ""
        lastname = cus_name.last rescue ""
        address = (customer["address1"] + customer["address2"]).gsub(/[^0-9A-Za-z , : ]/, '') rescue customer["address1"] 
        phone = customer["properties_attributes"]["phone"].gsub(/[^0-9A-Za-z , : ]/, '') rescue ''
        body_json = {
          "properties": {
            "phone":  phone,
            "email": customer["email"],
            "firstname": firstname,
            "lastname": lastname,
            "address":  address,
            "city": customer["city"],
            "state": customer["region"],
            "zip": customer["zipcode"],
            "country": customer["country"],
            "booqable_create_date": create_date,
            "booqable_id": customer["id"],
            "booqable_notes": customer["properties_attributes"]["notes"]
          }
        }
        if customer["properties_attributes"]["main"].present? 
          if existing_user["results"].blank?
            response = HTTParty.post("#{CONTACT_PATH}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
          else  
            contact_id = existing_user["results"].first["id"]
            response = HTTParty.patch("#{CONTACT_PATH}/#{contact_id}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
          end
          if response.present? && response.success?
            if customer["properties_attributes"]["company"].present?
              Hubspot::Company.create_update_booking_company(customer["properties_attributes"]["company"],response["id"])
            end
          else
            if response["message"].include?("A contact with the email")
              body_json[:properties].delete(:email)
              response = HTTParty.patch("#{CONTACT_PATH}/#{contact_id}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
            end 
          end
        elsif customer["properties_attributes"]["company"].present?
          Hubspot::Company.create_update_booking_company(customer["properties_attributes"]["company"],nil)

        end
      end
    end


     def self.find_user(booqable_id)
      sleep(1)
       body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "booqable_id",
                "operator": "EQ",
                "value": "#{booqable_id}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{CONTACT_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      return response
    end

    def self.find_simpro_user(simpro_customer_id)
      sleep(1)
       body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "simpro_customer_id",
                "operator": "EQ",
                "value": "#{simpro_customer_id}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{CONTACT_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      return response
    end


    def self.find_by_email(email)
      sleep(1)
       body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "email",
                "operator": "EQ",
                "value": "#{email}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{CONTACT_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      return response
    end
    def self.find_contact_user(simpro_id)
      sleep(1)
       body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "simpro_contact_id",
                "operator": "EQ",
                "value": "#{simpro_id}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{CONTACT_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      return response
    end
    def self.update_simpro_id(simpro_id,contact_id)
      
      body_json = {
        "properties": {
         "simpro_customer_id":  simpro_id,
        }
      }
      response = HTTParty.patch("#{CONTACT_PATH}/#{contact_id}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
    end
	end
end