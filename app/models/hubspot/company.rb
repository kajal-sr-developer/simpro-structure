module Hubspot
  #
  # HubSpot COMPANY OBJECT

  class Company
    COMPANY_PATH='https://api.hubapi.com/crm/v3/objects/companies'
      def self.create_update_booking_company(company_name,contact_id)
        # Method : Post/Patch
      
        existing_company = Hubspot::Company.find_by_name(company_name)
         body_json = {
          "properties": {
            "name": company_name
          }}

        if existing_company["results"].blank?
          response = HTTParty.post("#{COMPANY_PATH}",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" }) 
        else
          company_id = existing_company["results"].first["id"]
          response = HTTParty.patch("#{COMPANY_PATH}/#{company_id}",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })  
        end
        if response.present? && response.success? && contact_id.present?
          Hubspot::Company.associate_contact_with_company(contact_id,response["id"])
        end
      end


      def self.create(company)
      # Method : Post/Patch
      # Create company if company doesn't exixt update if it does
     
      existing_company = Hubspot::Company.find_company(company["ID"])
      if existing_company["results"].blank?
        existing_company = Hubspot::Company.find_by_name(company["CompanyName"])
      end
      
       body_json = {
        "properties": {
        "city": company["Address"]["City"] || '',
        "name": company["CompanyName"],
        "phone": company["Phone"] || '',
        "state": company["Address"]["State"] || '',
        "zip": company["Address"]["PostalCode"] || '',
        "country": company["Address"]["Country"] || '',
        "simpro_customer_id": company["ID"],
        "abn": company["EIN"] || '',
        "address": company["Address"]["Address"],
        "city": company["Address"]["City"],
        "state": company["Address"]["State"],
        "zip": company["Address"]["PostalCode"],
        "country": company["Address"]["Country"],
        "simpro_postal_address": company["BillingAddress"]["Address"],
        "simpro_postal_suburb": company["BillingAddress"]["City"],
        "simpro_postal_state": company["BillingAddress"]["State"],
        "simpro_postal_postcode": company["BillingAddress"]["PostalCode"],
        "simpro_postal_country": company["BillingAddress"]["Country"],
        "on_stop":  company["Banking"]["OnStop"]
      }}

      if existing_company["results"].blank?
        response = HTTParty.post("#{COMPANY_PATH}",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" }) 
        puts "company added #{company["CompanyName"]}" 
      else
        company_id = existing_company["results"].first["id"]
        response = HTTParty.patch("#{COMPANY_PATH}/#{company_id}",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })  
        puts "company updated #{company["CompanyName"]}" 
      end
      if response.present? && response.success?
        Hubspot::CompanyContact.create_update_company_contact(company["Contacts"],response["id"])
      end
      if response.present? && response.success? && company["Sites"].present?
        Hubspot::Site.associate_sites_customer(company["Sites"],'company',response["id"])
      end
    end


    def self.create_quote_company(deal_id,company_name,domain)
      existing_company = Hubspot::Company.find_by_name(company_name)
      if existing_company["results"].blank?
        body_json = {
        "properties": {
        "name": company_name,
        "domain": domain
      }}
        response = HTTParty.post("#{COMPANY_PATH}",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" }) 
        puts "company added #{company_name}" 

        if response.present? && response.success?
          return response["id"]
        end
      else
        return existing_company["results"].first["id"]
      end 
    end

    def self.find_company(company_id)
      body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "simpro_customer_id",
                "operator": "EQ",
                "value": "#{company_id}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{COMPANY_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      return response
    end


      def self.find_by_name(company_name)
        body_json =
            {
          "filterGroups":[
            {
              "filters":[
                {
                  "propertyName": "name",
                  "operator": "EQ",
                  "value": "#{company_name}"
                }
              ]
            }
          ]
        }
        response = HTTParty.post("#{COMPANY_PATH}/search",:body=> body_json.to_json, :headers => {
             "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
           })
        return response
      end

      def self.associate_contact_with_company(contact_id,company_id)
        body_json =   [
              {
               "associationCategory": "USER_DEFINED",
               "associationTypeId": "#{ENV['CONTACT_ASSOCIATION_ID']}"
              }
          ]
          response = HTTParty.put("https://api.hubapi.com/crm/v4/objects/contact/#{contact_id.to_i}/associations/company/#{company_id.to_i}",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })

      end

      def self.update_simpro_id(simpro_id,company_id)
      
      body_json = {
        "properties": {
         "simpro_customer_id":  simpro_id,
        }
      }
      response = HTTParty.patch("#{COMPANY_PATH}/#{company_id}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
    end
  end
end