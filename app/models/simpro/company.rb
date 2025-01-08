module Simpro
  # Simpro company OBJECT

  class Company

    def self.webhook_customer(customer_id)
      query = { 
        "columns"     => "ID,CompanyName,Phone,DoNotCall,AltPhone,Banking,Address,BillingAddress,CustomerType,Email,Fax,PreferredTechs,EIN,Website,Contacts,Profile,Sites",
        "pageSize"      => 1
       }

      response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/customers/companies/#{customer_id}",:query=> query, :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
      })
        # @response = response
      unless response.blank?
        company_response = Hubspot::Company.create(response) 
      end    
    end


    def self.attach_contact(customer,company_id)
        query = { 
            "columns"     => "ID,Email,GivenName,FamilyName",
            "search" => "any"
           }

        company_contacts = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/customers/#{company_id}/contacts/",:query=> query, :headers => {
            "Content-Type" => "application/json",
             "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
          })
        emails = company_contacts.map{|i| i["Email"]} 
           body_json = {
            "Title" => customer["properties"] && customer["properties"]["salutation"] || "",
            "GivenName" => customer["properties"] && customer["properties"]["firstname"] || "",
            "FamilyName" => customer["properties"] && customer["properties"]["lastname"] || "",
            "Email" => customer["properties"] && customer["properties"]["email"] || "",
            "Position" => customer["properties"] && customer["properties"]["jobtitle"] || "",
            "WorkPhone" => customer["properties"] && customer["properties"]["phone"] || "",
            "Fax" => customer["properties"] && customer["properties"]["fax"] || "",
            "CellPhone" => customer["properties"] && customer["properties"]["mobilephone"] || "",
            "QuoteContact" => true,
            "PrimaryQuoteContact" => true
          }


        if emails.include?(customer["properties"]["email"])
          company_contact_id =  company_contacts.select{|i| i["Email"] == customer["properties"]["email"]}.first["ID"] rescue nil
          if company_contact_id.present?
            response = HTTParty.patch("#{ENV['SIMPRO_LIVE_URL']}/customers/#{company_id}/contacts/#{company_contact_id}",:body=> body_json.to_json, :headers => {
            "Content-Type" => "application/json",
             "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
          }) 
          end
        else
          
          response = HTTParty.post("#{ENV['SIMPRO_LIVE_URL']}/customers/#{company_id}/contacts/",:body=> body_json.to_json, :headers => {
            "Content-Type" => "application/json",
             "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
          }) 
        end
    end

    def self.find_hubspot_company(company,company_id)
      companyname = company["name"]["value"]

      if company["simpro_customer_id"].blank?
        companyname = companyname.gsub('&','%26') if companyname.include?('&')
        companyname = companyname.gsub('-','%2D') if companyname.include?('-')
        companyname = companyname.gsub('–','%96') if companyname.include?('–')
        companyname = companyname.gsub('—','%97') if companyname.include?('—')

        customer = Simpro::Company.find_company(companyname)
        if customer.present? && customer.success?
          response = Simpro::Company.create_update_company(company,company_id,customer.first["ID"])
        else
          response = Simpro::Company.create_update_company(company,company_id,nil)
        end
      else
        response = Simpro::Company.create_update_company(company,company_id,company["simpro_customer_id"])
      end

    end

    def self.create_update_company(company,company_id,simpro_company_id)

     phone = company['phone'].present? && company['phone'].is_a?(String) ? company['phone'] : company.dig('phone', 'value') || "-"
    address = company['address'].present? && company['address'].is_a?(String) ? company['address'] : company.dig('address', 'value') || "-"
    city = company['city'].present? && company['city'].is_a?(String) ? company['city'] : company.dig('city', 'value') || "-"
    state = company['state'].present? && company['state'].is_a?(String) ? company['state'] : company.dig('state', 'value') || "-"
    zip = company['zip'].present? && company['zip'].is_a?(String) ? company['zip'] : company.dig('zip', 'value') || "-"
    country = company['country'].present? && company['country'].is_a?(String) ? company['country'] : company.dig('country', 'value') || "-"
    company_name = company['name'].present? && company['name'].is_a?(String) ? company['name'] : company.dig('name', 'value') || "-"



       body_json = {
        "CompanyName": company_name,
        "Phone": phone,
       "CustomerType": 'Customer',
        "Address": {
         "Address": address,
         "City": city,
         "State": state,
         "PostalCode": zip,
         "Country": country
        }
        }
      if simpro_company_id.present? && simpro_company_id["value"].present?
        simpro_company_id = simpro_company_id["value"] || simpro_company_id
        response = HTTParty.patch("#{ENV['SIMPRO_LIVE_URL']}/customers/companies/#{simpro_company_id}",:body=> body_json.to_json, :headers => {
            "Content-Type" => "application/json",
             "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
            }) 

      else
        response = HTTParty.post("#{ENV['SIMPRO_LIVE_URL']}/customers/companies/",:body=> body_json.to_json, :headers => {
          "Content-Type" => "application/json",
           "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
          }) 
        if response.present? && response.success?
          Hubspot::Company.update_simpro_id(response["ID"],company_id)
        end 
      end 
      return response

    end



    def self.create_quote_company(companyname)
       body_json = {
        "CompanyName": companyname,
       "CustomerType": 'Customer'
        }
        response = HTTParty.post("#{ENV['SIMPRO_LIVE_URL']}/customers/companies/",:body=> body_json.to_json, :headers => {
          "Content-Type" => "application/json",
           "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
          }) 
        # if response.present? && response.success?
        #   Hubspot::Company.update_simpro_id(response["ID"],company_id)
        # end 
        if response.present? && response.success?
        return response["ID"]
      end

    end

    def self.find_company(companyname)
      companyname = CGI.escape(companyname)
       response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/customers/companies/?CompanyName=#{companyname}", :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
       })
    end
  end
end