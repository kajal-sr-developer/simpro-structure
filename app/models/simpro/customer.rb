module Simpro
  # Simpro customer OBJECT

  class Customer
   

    def self.find_hubspot_customer(contact,contact_id)
      email =  contact["email"]["value"] rescue nil
      firstname = contact["firstname"]["value"] rescue nil
      lastname = contact["lastname"]["value"] rescue nil
      if email.present?
        customer = Simpro::Customer.find_customer(email)
        if customer.blank?
          # customer =  Simpro::Customer.find_customer_name(firstname,lastname)
          if customer.blank?
            response = Simpro::Customer.create_update_customer(contact,contact_id,nil)
          else
            Simpro::Customer.create_update_customer(contact,contact_id,customer.first["ID"])
          end
        else
          if customer.present? && customer.success?
            Simpro::Customer.create_update_customer(contact,contact_id,customer.first["ID"])
            response = Simpro::Customer.find_customer(email)
          end
        end
        return response
      elsif contact["simpro_customer_id"].present? && contact["simpro_customer_id"]["value"].present?  && email.blank?
        response = Simpro::Customer.create_update_customer(contact,contact_id,contact["simpro_customer_id"]["value"])
      elsif contact["simpro_customer_id"].blank? && email.blank?
        response = Simpro::Customer.create_update_customer(contact,contact_id,nil)
      end
    end


    def self.create_update_customer(contact,contact_id,customer_id)
      # employee_name =["firstName"] + " " + owner['lastName'] rescue '------'
    title = contact["salutation"].present? && contact["salutation"]["value"].present? ? contact["salutation"]["value"] : contact["salutation"].presence || "-"
    phone = contact["phone"].present? && contact["phone"]["value"].present? ? contact["phone"]["value"] : contact["phone"].presence || "-"
    address = contact["address"].present? && contact["address"]["value"].present? ? contact["address"]["value"] : contact["address"].presence || "-"
    city = contact["city"].present? && contact["city"]["value"].present? ? contact["city"]["value"] : contact["city"].presence || "-"
    state = contact["state"].present? && contact["state"]["value"].present? ? contact["state"]["value"] : contact["state"].presence || "-"
    zip = contact["zip"].present? && contact["zip"]["value"].present? ? contact["zip"]["value"] : contact["zip"].presence || "-"
    country = contact["country"].present? && contact["country"]["value"].present? ? contact["country"]["value"] : contact["country"].presence || "-"
    email = contact["email"].present? && contact["email"]["value"].present? ? contact["email"]["value"] : contact["email"].presence || "-"
    alt_phone = contact["alt_phone"].present? && contact["alt_phone"]["value"].present? ? contact["alt_phone"]["value"] : contact["alt_phone"].presence || "-"
    firstname = contact["firstname"].present? && contact["firstname"]["value"].present? ? contact["firstname"]["value"] : contact["firstname"].presence || "-"
    lastname = contact["lastname"].present? && contact["lastname"]["value"].present? ? contact["lastname"]["value"] : contact["lastname"].presence || "-"
    mobile = contact["mobilephone"].present? && contact["mobilephone"]["value"].present? ? contact["mobilephone"]["value"] : contact["mobilephone"].presence || "-"

      customer_group = nil
      body_json = {
        "Title": title,
        "GivenName": firstname,
       "FamilyName": lastname,
        "Phone": phone,
        "AltPhone": alt_phone,
        "Address": {
         "Address": address,
         "City": city,
         "State": state,
         "PostalCode": zip,
         "Country": country
        },"Profile": {
          "CustomerGroup": customer_group,
         },
        "CustomerType": "Customer",
        "Email": email,
        "CellPhone": mobile,
      }

      postal_address = contact["postal_street_address"].present? && contact["postal_street_address"]["value"].present? ? contact["postal_street_address"]["value"] : address
      city = contact["city"].present? && contact["city"]["value"].present? ? contact["city"]["value"] : city
      postal_state = contact["postal_suburb"].present? && contact["postal_suburb"]["value"].present? ? contact["postal_suburb"]["value"] : state
      postal_zip = contact["postal_postcode"].present? && contact["postal_postcode"]["value"].present? ? contact["postal_postcode"]["value"] : zip
      postal_country = contact["postal_country"].present? && contact["postal_country"]["value"].present? ? contact["postal_country"]["value"] : country
      
      body_json.merge! "BillingAddress": {
         "Address": postal_address,
         "City": city,
         "State": postal_state,
         "PostalCode": postal_zip,
         "Country": postal_country
        }

      if customer_id.present?
       response = HTTParty.patch("#{ENV['SIMPRO_LIVE_URL']}/customers/individuals/#{customer_id}",:body=> body_json.to_json, :headers => {
      "Content-Type" => "application/json",
       "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
        }) 
      else
        response = HTTParty.post("#{ENV['SIMPRO_LIVE_URL']}/customers/individuals/",:body=> body_json.to_json, :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
        }) 
        if response.present? && response.success?
          Hubspot::Contact.update_simpro_id(response["ID"],contact_id)
        end 
      end
      return response
    end

    def self.create_quote_contact(body_json)
      response = HTTParty.post("#{ENV['SIMPRO_LIVE_URL']}/customers/individuals/",:body=> body_json.to_json, :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
      })

      if response.present? && response.success?
        return response["ID"]
      end 
    end

    def self.webhook_individual_customer(customer_id)
      #/api/v1.0/companies/{companyID}/contacts/
       
      query = { 
        "columns"     => "ID,GivenName,Title,FamilyName,Phone,DoNotCall,AltPhone,Address,Banking,Sites,BillingAddress,CustomerType,Email,PreferredTechs,Profile,DateCreated,CellPhone",
        "pageSize"      => 1 
       }

      response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/customers/individuals/#{customer_id}",:query=> query, :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
      })
      unless response.blank?
        Hubspot::Contact.create_update_individual(response) 
      end
    end


    def self.find_customer(email)
    	query = { 
        "columns"     => "ID,Email",
        "search" => "any"
       }
       response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/customers/individuals/?Email=#{email}",:query=> query, :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
         })
      return response
    end


    def self.find_customer_name(firstname,lastname)
      response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/customers/individuals/?FamilyName=#{lastname}&GivenName=#{firstname}", :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
       })
      return response
    end

    def self.find_notes(customer_id)
      response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/customers/#{customer_id}/notes/", :headers => {
          "Content-Type" => "application/json",
           "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
        })
    end
  end

end