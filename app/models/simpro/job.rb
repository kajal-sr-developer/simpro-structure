module Simpro
  # Simpro job OBJECT
  class Job
  	def self.create_postmix_job(deal)
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
          site_name = deal["properties"]["new_site_name"]["value"]
          site_address = deal["properties"]["new_site_address"]["value"] rescue ""
          site_response = Simpro::Site.create_deal_site(site_name,site_address)
          if site_response.success?
            site_id = site_response["ID"]
          end
        end
        #company/contact code
        
        if site_id.present?
          puts "site found"
          created_date = Time.at(deal["properties"]["createdate"]["timestamp"]/1000).to_date.strftime('%Y-%m-%d')
          # notes = deal["notes"]["value"] rescue "--"
          owner_id = deal["properties"]["hubspot_owner_id"]["value"]
          if owner_id.present?
            owner = HTTParty.get("http://api.hubapi.com/owners/v2/owners/#{owner_id}?properties=",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
            salesperson = Simpro::Quote.find_sales_person(owner["firstName"] + " " + owner["lastName"])
          end

          description = deal["properties"]["description"]["value"] rescue "--"
          job_type = deal["properties"]["job_type"]["value"] rescue "Service"
          if salesperson.present?
            sales_id = salesperson.first["ID"]
             body_json = {
            "Customer": 631,
            "Site": site_id.to_i,
            "Description": description,
            "Type": job_type,
            "DateIssued": created_date,
            "Name": deal["properties"]["dealname"]["value"],
            "Stage": "Progress",
            "Salesperson": sales_id,
            "Status": 57,
            }
          else
             body_json = {
            "Customer": 631,
            "Site": site_id.to_i,
            "Description": description,
            "Type": job_type,
            "DateIssued": created_date,
            "Name": deal["properties"]["dealname"]["value"],
            "Stage": "Progress",
            "Status": 57,
            }
          end
            puts "coming here"


          #  get = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/setup/statusCodes/projects/", :headers => { "Content-Type" => "application/json",
          #    "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
          # }) 
          job_response = HTTParty.post("#{ENV['SIMPRO_LIVE_URL']}/jobs/",:body=> body_json.to_json, :headers => {
            "Content-Type" => "application/json",
             "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
          }) 

          puts "after quote"
          if job_response.success?
            job_id = job_response["ID"]
            puts "job created #{deal["properties"]["dealname"]["value"]}"
            Hubspot::Deal.update_simpro_job_id(job_id,deal_id,deal["properties"]["dealname"]["value"])
            Simpro::Job.update_deal_id(deal_id,job_id)
            Hubspot::Ticket.create_update_ticket(job_id,'hs')
            #cost center code

            hs_cost_center = HTTParty.get("https://api.hubapi.com/crm/v4/objects/deals/#{deal_id}/associations/p_costcenters",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
            hs_cost_center_id =  hs_cost_center["results"].first["toObjectId"] rescue nil

            if hs_cost_center_id.present?
              costcenter_detail = HTTParty.get("https://api.hubapi.com/crm/v4/objects/p_costcenters/#{hs_cost_center_id}?properties=name,simpro_id",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
            	cost_center_id = costcenter_detail["properties"]["simpro_id"]
            	cost_center_name = costcenter_detail["properties"]["name"]
            end
            if cost_center_id.present?
              section_response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/jobs/#{job_id}/sections/", :headers => {
              "Content-Type" => "application/json",
               "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
              })

              if section_response.blank?
                body_json = {
                  "DisplayOrder": 0,
                }
                section_response = HTTParty.post("#{ENV['SIMPRO_LIVE_URL']}/jobs/#{job_id}/sections/",:body=> body_json.to_json, :headers => {
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
              cost_center_response = HTTParty.post("#{ENV['SIMPRO_LIVE_URL']}/jobs/#{job_id}/sections/#{section_id}/costCenters/",:body=> cost_body_json.to_json, :headers => {
                  "Content-Type" => "application/json",
                   "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
              })
            end

          else
            puts job_response["message"]

          end
          # Hubspot::Deal.update_response(quote_response,deal_id)
        end
      end
  	end

  	def self.update_deal_id(deal_id,job_id)

      body_json = {
       "Value": deal_id
      }
      response =  HTTParty.patch("#{ENV['SIMPRO_LIVE_URL']}/jobs/#{job_id}/customFields/9",:body=> body_json.to_json, :headers => {
          "Content-Type" => "application/json",
           "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
        })
      
    end

     def self.webhook_job(job_id)
      initial_time = Time.now
      query = { 
        "columns"     => "ID,Type,Site,SiteContact,Customer,CustomerContact,OrderNo,Name,Description,Notes,DateIssued,DueDate,Tags,Salesperson,ProjectManager,Technician,Stage,ConvertedFrom,Status,CompletedDate,Total,Totals",
        "pageSize"      => 1,
       }

      response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/jobs/#{job_id}",:query=> query, :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
      })
      if response.present? && response.success?
        # timeline_data =  HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/jobs/#{job_id}/timelines/", :headers => {
        #     "Content-Type" => "application/json",
        #      "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
        #   })
        # if response["ConvertedFrom"].present?
        #   existing_deal = Hubspot::Deal.find_deal(response["ConvertedFrom"]["ID"])
        #   if existing_deal["results"].present? && existing_deal["results"].first["properties"]["pipeline"] == "114091282"
        #     Hubspot::Job.create_update_job(response,existing_deal["results"].first["id"],existing_deal["results"].first["properties"]["pipeline"],initial_time,timeline_data)
        #   end
        # end
         Hubspot::Ticket.create_update_ticket(job_id,'simpro')
      end
    end
  end
end