 module Simpro
  # Simpro customer OBJECT

  class Quote
    def self.create_quote(deal)

      deal_id = deal["properties"]["hs_object_id"]["value"]
      quote_id = deal["properties"]["simpro_quote_id"]["value"] rescue nil
      pipeline = deal["properties"]["pipeline"]["value"] rescue nil

       unless quote_id.present?
        hs_site = HTTParty.get("https://api.hubapi.com/crm/v4/objects/deals/#{deal_id}/associations/p_sites",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
        #site code
        if hs_site["results"].present?
        hs_site_id =  hs_site["results"].first["toObjectId"] rescue nil
          if hs_site_id.present?
            site_detail = HTTParty.get("https://api.hubapi.com/crm/v4/objects/p_sites/#{hs_site_id}?properties=site_name,simpro_site_id",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
          end
          if site_detail["properties"].present? && site_detail["properties"]["simpro_site_id"].present?
            site_id = site_detail["properties"]["simpro_site_id"]  
          end
        else
          site_name = deal["properties"]["new_site_name"]["value"]  rescue ""
          site_address = deal["properties"]["new_site_address"]["value"] rescue ""
          site_response = Simpro::Site.create_deal_site(site_name,site_address)
          if site_response.success?
            site_id = site_response["ID"]
          end
        end


        contact_dropdown = deal["properties"]["is_this_a_new_or_existing_contact_record_within_hubspot_"]["value"]

        if contact_dropdown == "New Contact to be created within HubSpot"
             first_name = deal["properties"]["first_name_of_new_hubspot_contact"]["value"]  rescue ""
             last_name = deal["properties"]["last_name_of_new_hubspot_contact"]["value"]  rescue ""
             job_title = deal["properties"]["job_title_of_new_hubspot_contact"]["value"]  rescue ""
             contact_mobile = deal["properties"]["mobile_number_of_new_hubspot_contact"]["value"]  rescue ""
             contact_email = deal["properties"]["create_new_contact__email"]["value"]  rescue ""

            body_json = {
            "properties": {
              "email": contact_email,
              "mobilephone": contact_mobile,
              "firstname": first_name,
              "lastname": last_name,
              "jobtitle":  job_title
            }
          }
        user_id = Hubspot::Contact.create_quote_contact(body_json,contact_email)
        if contact_email.present? 
          simpro_contact = Simpro::Customer.find_customer(contact_email)
          if simpro_contact.present? && simpro_contact.success?
            simpro_contact_id = simpro_contact.first["ID"]
          else
            simpro_json = {
            "Title": job_title,
            "GivenName": first_name,
            "FamilyName": last_name,
            "CustomerType": "Customer",
            "Email": contact_email,
            "CellPhone": contact_mobile,
          }
           simpro_contact_id = Simpro::Customer.create_quote_contact(simpro_json)
          end
          Hubspot::Contact.update_simpro_id(simpro_contact_id,user_id)
          Hubspot::Deal.associate_contact(deal_id,simpro_contact_id)
          sleep(1)
        end

        end
        user_id = Hubspot::Deal.get_deal_associated_contact(deal_id) rescue nil
       
        company_dropdown = deal["properties"]["is_this_a_new_or_existing_company_record_within_hubspot_"]["value"]

        if company_dropdown == "New Company to be created within HubSpot"
          company_name = deal["properties"]["name_of_new_hubspot_company"]["value"] rescue ""
          domain = deal["properties"]["domain_name_of_new_hubspot_company"]["value"] rescue ""
          company_id = Hubspot::Company.create_quote_company(deal_id,company_name,domain)
          if company_name.present? 
            simpro_company = Simpro::Company.find_company(company_name)
            if simpro_company.present? && simpro_company.success?
              simpro_company_id = simpro_company.first["ID"]
            else
             simpro_company_id = Simpro::Company.create_quote_company(company_name)
            end
            Hubspot::Company.update_simpro_id(simpro_company_id,company_id)
            Hubspot::Deal.associate_company(deal_id,simpro_company_id)
            sleep(1)
          end
        end
          company_id = Hubspot::Deal.get_deal_associated_company(deal_id) rescue nil

        site_ownership = deal["properties"]["company_customer_site_ownership_type"]["value"] rescue nil
        if site_ownership == "New Owner"
          body_json =   [
              {
               "associationCategory": "USER_DEFINED",
               "associationTypeId": 85
              }
            ]
            owner_response = HTTParty.put("https://api.hubapi.com/crm/v4/objects/p_sites/#{hs_site_id.to_i}/associations/company/#{company_id.to_i}",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
        else
         body_json =   [
              {
               "associationCategory": "USER_DEFINED",
               "associationTypeId": 83
              }
            ]
            owner_response = HTTParty.put("https://api.hubapi.com/crm/v4/objects/p_sites/#{hs_site_id.to_i}/associations/company/#{company_id.to_i}",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
        end


        #company/contact code
        
        
        if user_id.last == "Individual Customer"
           contact = HTTParty.get("https://api.hubapi.com/crm/v3/objects/contacts/#{user_id.first}/?properties=email,firstname,lastname,salutation,phone,address,city,suburb,country,postal_country,customer_group,postal_postcode,postal_state,postal_street_address,postal_suburb,phone,zip,mobilephone,simpro_customer_id",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
          if contact["properties"].present? && contact["properties"]["simpro_customer_id"].present?
            customer_id = contact["properties"]["simpro_customer_id"]
          else
            response = Simpro::Customer.create_update_customer(contact["properties"],user_id.first,nil)
            customer_id = response["ID"]
          end
           if customer_id.present?
            puts "contact attached" 
          end
        elsif company_id.present?
          company = HTTParty.get("https://api.hubapi.com/crm/v3/objects/companies/#{company_id}/?properties=simpro_customer_id,name,address,city,suburb,country,abn,simpro_postal_country,simpro_postal_postcode,simpro_postal_state,simpro_postal_address,simpro_postal_suburb,phone,zip",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
          if company["properties"].present? && company["properties"]["simpro_customer_id"].present?
            customer_id = company["properties"]["simpro_customer_id"]
          else
            response = Simpro::Company.create_update_company(company["properties"],company_id,nil)
            sleep(2)
            if response.success?
              customer_id = response["ID"]
            else
              puts response["message"]
            end
          end
          if customer_id.present?
            sleep(1)
            puts "company attached" 
            contact = HTTParty.get("https://api.hubapi.com/crm/v3/objects/contacts/#{user_id.first}/?properties=email,firstname,salutation,phone,address,city,suburb,country,postal_country,customer_group,postal_postcode,postal_state,postal_street_address,postal_suburb,phone,zip,mobilephone,simpro_customer_id,lastname,jobtitle",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
            Simpro::Company.attach_contact(contact,customer_id)
          end
        else
          contact = HTTParty.get("https://api.hubapi.com/crm/v3/objects/contacts/#{user_id.first}/?properties=email,firstname,salutation,phone,address,city,suburb,country,postal_country,customer_group,postal_postcode,postal_state,postal_street_address,postal_suburb,phone,zip,mobilephone,simpro_customer_id",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
          if contact["properties"].present? && contact["properties"]["simpro_customer_id"].present?
            customer_id = contact["properties"]["simpro_customer_id"]
          else
            response = Simpro::Customer.create_update_customer(contact["properties"],user_id.first,nil)
            customer_id = response["ID"]
          end
           if customer_id.present?
            puts "contact attached" 
          end
        end
        if site_id.present? && customer_id.present?
          puts "site found"
          created_date = Time.at(deal["properties"]["createdate"]["timestamp"]/1000).to_date.strftime('%Y-%m-%d')
          # notes = deal["notes"]["value"] rescue "--"
          owner_id = deal["properties"]["hubspot_owner_id"]["value"]
          if owner_id.present?
            owner = HTTParty.get("http://api.hubapi.com/owners/v2/owners/#{owner_id}?properties=",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
            salesperson = self.find_sales_person(owner["firstName"] + " " + owner["lastName"])
          end
          description = deal["properties"]["description"]["value"] rescue "--"
         #quote_type = pipeline == "default" ? "Project" : "Service" rescue "Service"
         quote_type = deal["properties"]["quote_type"]["value"] rescue "Service"
          if salesperson.present?
            sales_id = salesperson.first["ID"]
             body_json = {
            "Customer": customer_id.to_i,
            "Site": site_id.to_i,
            "Description": description,
            "Type": quote_type,
            "DateIssued": created_date,
            "Name": deal["properties"]["dealname"]["value"],
            "Stage": "InProgress",
            "Salesperson": sales_id,
            "Status": 50,
            }
          else
             body_json = {
            "Customer": customer_id.to_i,
            "Site": site_id.to_i,
            "Description": description,
            "Type": quote_type,
            "DateIssued": created_date,
            "Name": deal["properties"]["dealname"]["value"],
            "Stage": "InProgress",
            "Status": 50,
            }
          end
            puts "coming here"


           get = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/setup/statusCodes/projects/", :headers => { "Content-Type" => "application/json",
             "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
          }) 
          quote_response = HTTParty.post("#{ENV['SIMPRO_LIVE_URL']}/quotes/",:body=> body_json.to_json, :headers => {
            "Content-Type" => "application/json",
             "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
          }) 
          puts "after quote"
          if quote_response.success?
            quote_id = quote_response["ID"]
            puts "deal created #{deal["properties"]["dealname"]["value"]}"
            Hubspot::Deal.attach_site(site_id,deal_id)
            Hubspot::Deal.update_simpro_id(quote_response["ID"],deal_id,deal["properties"]["dealname"]["value"])
            Simpro::Quote.update_deal_id(deal_id,quote_id)

            #cost center code

            hs_cost_center = HTTParty.get("https://api.hubapi.com/crm/v4/objects/deals/#{deal_id}/associations/p_costcenters",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
            hs_cost_center_id =  hs_cost_center["results"].first["toObjectId"] rescue nil

            if hs_cost_center_id.present?
              costcenter_detail = HTTParty.get("https://api.hubapi.com/crm/v4/objects/p_costcenters/#{hs_cost_center_id}?properties=name,simpro_id",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
              cost_center_id = costcenter_detail["properties"]["simpro_id"]
              cost_center_name = costcenter_detail["properties"]["name"]
            end
            if cost_center_id.present?
              section_response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}/sections/", :headers => {
              "Content-Type" => "application/json",
               "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
              })

              if section_response.blank?
                body_json = {
                  "DisplayOrder": 0,
                }
                section_response = HTTParty.post("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}/sections/",:body=> body_json.to_json, :headers => {
                    "Content-Type" => "application/json",
                     "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
                  })
                section_id = section_response["ID"] rescue nil
              else
               section_id =  section_response.first["ID"] rescue nil
              end

              cost_body_json = {
                "Name": cost_center_name,
                "CostCenter": cost_center_id.to_i

              }
              cost_center_response = HTTParty.post("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}/sections/#{section_id}/costCenters/",:body=> cost_body_json.to_json, :headers => {
                  "Content-Type" => "application/json",
                   "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
              })
            end

          else
            puts quote_response["message"]

          end
          Hubspot::Deal.update_response(quote_response,deal_id)
        end
      end
    end


    def self.change_to_newjob(quote_id,params)
      body_json = {
       "Status": 173
      }
      response =  HTTParty.patch("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}",:body=> body_json.to_json, :headers => {
          "Content-Type" => "application/json",
           "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
        })
      # if response.present? && response.success?
      #   Hubspot::Job.create_update(params)
      # end
    end

    def self.change_to_lost(quote_id,reason)
      reason_id = reason.to_i rescue nil
      body_json = {
       "Status": 294,
       "ArchiveReason": reason_id,
       "IsClosed": true 
      }
      response =  HTTParty.patch("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}",:body=> body_json.to_json, :headers => {
          "Content-Type" => "application/json",
           "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
        })
    end



     def self.update_deal_id(deal_id,quote_id)

      body_json = {
       "Value": deal_id
      }
      response =  HTTParty.patch("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}/customFields/9",:body=> body_json.to_json, :headers => {
          "Content-Type" => "application/json",
           "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
        })
      
    end


    def self.webhook_quote(quote_id)
      query = { 
        "columns"     => "ID,Customer,Site,SiteContact,Description,Salesperson,ProjectManager,CustomerContact,Technician,DateIssued,DueDate,DateApproved,OrderNo,Name,Stage,Total,Totals,Status,Tags,Notes,Type,STC,LinkedJobID,ArchiveReason",
         "pageSize"      => 1 
       }

      response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}",:query=> query, :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
      })

      timeline_data =  HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}/timelines/", :headers => {
            "Content-Type" => "application/json",
             "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
          })
      if response.present? && response.success?
        Hubspot::Quote.update_quote(response,timeline_data)
      end
    end


    def self.find_sales_person(salesperson_name)
      query = { 
        "columns"     => "ID,Name",
        "search" => "any"
      }
     response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/staff/?Name=#{salesperson_name}",:query=> query, :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
      })
   end



    def self.sync_cost_center
     query = { 
         "columns"     => "ID,Name",
          "pageSize"      => 250,
          "page" => 1
       }
      cost_response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/setup/accounts/costCenters/?display=all",:query=> query, :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
      })
      cost_response.each_with_index do |cost_center_item,index|
            body_json = {
                "properties": {
                  "simpro_id": cost_center_item["ID"],
                  "name": cost_center_item["Name"]
                }
              }
            response = HTTParty.post("https://api.hubspot.com/crm/v3/objects/p_costcenters",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
 
      end
       
    end

  end
end