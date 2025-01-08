module Hubspot
	class CostCenter
		COST_PATH='https://api.hubspot.com/crm/v3/objects/p_costcenters'
		def self.get_cost_center(cost_center_id)
			 body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "simpro_id",
                "operator": "EQ",
                "value": "#{cost_center_id}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{COST_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      return response
		end


		def self.get_cost_center_by_name(name)
			 body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "name",
                "operator": "EQ",
                "value": "#{name}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{COST_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      return response
		end


		def self.associate_quote_section(section_id,cost_center_id)
      response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/p_costcenters/#{cost_center_id}/associations/p_quote_sections/#{section_id.to_i}/#{ENV['QUOTE_SECTION_ASSOCIATION_ID']}?paginateAssociations=false",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
    end

    def self.associate_deal(deal_id,cost_center_id)
      response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/p_costcenters/#{cost_center_id}/associations/deals/#{deal_id.to_i}/#{ENV['COSTCENTER_DEAL_ASSOCIATION_ID']}?paginateAssociations=false",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
    end
	end
end