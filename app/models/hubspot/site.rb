module Hubspot  
  class Site
    SITE_PATH = 'https://api.hubapi.com/crm/v3/objects/p_sites'
    def self.update_simpro_id(simpro_site_id,site_id)
      body_json = {
        "properties": {
         "simpro_site_id":  simpro_site_id
        }
      }
      response = HTTParty.patch("#{SITE_PATH}/#{site_id}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
    end


    def self.associate_sites_customer(sites,contact_type,contact_id)
      sites.each do |simpro_site|
        site = Hubspot::Site.search_site_by_name(simpro_site["Name"])
        if site["results"].present? && contact_id.present?
          site_id = site["results"].first["id"]
          if contact_type == "individual"
            ass_response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/p_sites/#{site_id}/associations/contacts/#{contact_id.to_i}/#{ENV['SITE_CONTACT_ASSOCIATION_ID']}?paginateAssociations=false",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
          else
            ass_response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/p_sites/#{site_id}/associations/companies/#{contact_id.to_i}/#{ENV['SITE_COMPANY_ASSOCIATION_ID']}?paginateAssociations=false",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
          end
        end
      end
    end



    def self.create_site(site)
      site_name = site["Name"].present? ? site["Name"].strip : "No Site Name"
      existing_site = Hubspot::Site.search_site(site["ID"]) 
      street_address = site["Address"]["Address"] rescue nil
      body_json = {
        "properties": {
          "site_name": site_name,
          "site_address": site["Address"]["Address"],
          "suburb": site["Address"]["City"],
          "state": site["Address"]["State"],
          "postcode": site["Address"]["PostalCode"],
          "postal_address": site["BillingAddress"]["Address"],
          "postal_suburb": site["BillingAddress"]["City"],
          "postal_state": site["BillingAddress"]["State"],
          "postal_postcode": site["BillingAddress"]["PostalCode"],
          "simpro_site_id": site["ID"],
          "country": site["Address"]["Country"],
        }
      }
      if existing_site["results"].blank?
        response = HTTParty.post("#{SITE_PATH}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
      else
        site_id = existing_site["results"].first["id"]
        response = HTTParty.patch("#{SITE_PATH}/#{site_id}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
      end
       
      if response.present? && response.success? && site["Customers"].present?
        puts "site created #{site_name}"
        Hubspot::Site.associate_compnay_contact(site["Customers"],response["id"])
      end
    end

    def self.search_site(site_id)
       sleep(1)
        body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "simpro_site_id",
                "operator": "EQ",
                "value": "#{site_id}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{SITE_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })

      return response
    end


    def self.search_site_by_name(site_name)
       sleep(1)
        body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "site_name",
                "operator": "EQ",
                "value": "#{site_name}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{SITE_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })

      return response
    end


    def self.associate_compnay_contact(customers,site_id)
      #response = HTTParty.get("https://api.hubapi.com/crm/v4/associations/line_items/quotes/labels",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
      customers.each do |f|
        if f["GivenName"].blank?
          hs_company_id = Hubspot::Company.find_company(f["ID"])
          if hs_company_id.present? && hs_company_id["results"].present?
             hs_company_id = hs_company_id["results"].first["id"]
            response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/p_sites/#{site_id}/associations/companies/#{hs_company_id.to_i}/#{ENV['SITE_COMPANY_ASSOCIATION_ID']}?paginateAssociations=false",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
          end
        else
          hs_contact_id = Hubspot::Contact.find_user(f["ID"])
          if hs_contact_id.present? && hs_contact_id["results"].present?
            hs_contact_id = hs_contact_id["results"].first["id"]
            response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/p_sites/#{site_id}/associations/contacts/#{hs_contact_id.to_i}/#{ENV['SITE_CONTACT_ASSOCIATION_ID']}?paginateAssociations=false",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
          end
        end
      end

    end

  end
end