module Hubspot
    # HubSpot ticket OBJECT

  class Ticket
    TICKET_PATH='https://api.hubapi.com/crm/v3/objects/tickets'

    def self.create_update_ticket(job_id,job_type)

      query = { 
        "columns"     => "ID,Type,Site,SiteContact,Customer,CustomerContact,OrderNo,Name,Description,Notes,DateIssued,DueDate,Tags,Salesperson,ProjectManager,Technician,Stage,ConvertedFrom,Status,CompletedDate,Total,Totals",
        "pageSize"      => 1,
      }

      job = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/jobs/#{job_id}",:query=> query, :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
      })

      custom_field = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/jobs/#{job_id}/customFields/9", :headers => {
        "Content-Type" => "application/json",
         "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
      })

      deal_id = custom_field["Value"]

      if job.present?

        job_name = job["Name"] + " - " + job["Site"]["Name"] rescue job["ID"]
        existing_ticket = Hubspot::Ticket.find_ticket(job_name)
        hs_pipeline_stage = job["Status"]["Name"] == "Job : Completed" ? '258349370' : '258349369'
        body_json = {
          "properties": {
          "hs_pipeline":  '153157723',
          "subject": job_name,
          "simpro_job_id": job["ID"],
          "hs_pipeline_stage": hs_pipeline_stage,
          "simpro_status": job["Status"]["Name"]
           }
         }

          if existing_ticket["results"].blank?
            if job_type!="simpro"
          	 response = HTTParty.post("#{TICKET_PATH}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
            end
          else
          	ticket_id = existing_ticket["results"].first["id"]
           	response = HTTParty.patch("#{TICKET_PATH}/#{ticket_id}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
          end

          if response.present? && response.success?
            deals_ticket_response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/deals/#{deal_id}/associations/tickets/#{response["id"].to_i}/#{{ENV['DEAL_TICKET_ASSOCIATION_ID']}}?paginateAssociations=false",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
          end
        end
        return response
    end

    def self.find_ticket(ticket_name)
      sleep(1)
       body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "subject",
                "operator": "EQ",
                "value": "#{ticket_name}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{TICKET_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      return response
    end

  end
end