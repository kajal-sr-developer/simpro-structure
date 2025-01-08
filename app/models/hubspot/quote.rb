module Hubspot
	class Quote
    QUOTE_PATH = 'https://api.hubapi.com/crm/v3/objects/quotes'
		def self.update_quote(quote,timeline_data)
			existing_deal = Hubspot::Deal.find_deal(quote["ID"])
      section_response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote['ID']}/sections/", :headers => {
          "Content-Type" => "application/json",
           "Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"
        })
      query = { "columns"     => "ID,CostCenter,Name"}
      q_section_id = section_response.last["ID"] rescue nil
      q_quote_cost_center_response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote['ID']}/sections/#{q_section_id}/costCenters/",:query=> query, :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"})
      # q_name =  q_quote_cost_center_response.map{|i| i["Name"]} rescue nil
      # if q_name.include?('Service') || q_name.include?('COUNTER SALES')
      #   Hubspot::Deal.service_deal_create(quote,existing_deal["results"],"deal")
      # end
      sleep(1)
      existing_deal = Hubspot::Deal.find_deal(quote["ID"])
			if existing_deal["results"].present?
				deal_id = existing_deal["results"].first["id"]
        if quote["Customer"]["CompanyName"].present? && quote["Customer"]["GivenName"].blank?
          Hubspot::Deal.associate_company(deal_id,quote["Customer"]["ID"])
        else
          Hubspot::Deal.associate_contact(deal_id,quote["Customer"]["ID"])
        end
				quote_name = quote["ID"].to_s + " - " + quote["Name"] rescue "-"
				existing_quote = Hubspot::Quote.find_quote_by_name(quote_name) 
				duedate = (quote["DueDate"].to_time).to_i*1000  rescue ((Date.today + 1.year).to_time).to_i*1000
        comment = quote["Description"].gsub('&amp;','&') rescue ""
			  body_json = {
	        "properties": {
	        "hs_template_type": 'CUSTOMIZABLE_QUOTE_TEMPLATE',
	        "hs_title": quote_name,
	        "hs_sender_company_domain": 'baronsbeverageservices.com.au',
	        "hs_sender_lastname": 'Barons Beverage Services',
	        "hs_sender_company_address": '64 Mordaunt Circuit, Canning Vale, WA, 6155',
	        "hs_sender_company_name": 'Barons Beverage Services',
	        "hs_sender_email": 'sales@baronsbeverageservices.com.au',
	        "hs_sender_company_city": 'Canning Vale, WA, 6155',
	        "hs_status": 'DRAFT',
	        "hs_expiration_date": duedate,
	        "hs_comments": comment,
	        "hs_language": 'en'
	        }
	      }
        if existing_quote.present? && existing_quote.success? && existing_quote["total"] > 1
          for i in 0..(existing_quote["total"].to_i-2)
            if  existing_quote["results"][i]["properties"]["hs_status"] =="DRAFT" 
              id = existing_quote["results"][i]["id"]
              delete_response = HTTParty.delete("https://api.hubapi.com/crm/v3/objects/quotes/#{id}",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
            end
          end 
        end
	      if existing_quote["results"].blank?
	        response = HTTParty.post("#{QUOTE_PATH}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
	        association_response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/quotes/#{response['id']}/associations/deals/#{deal_id}/quote_to_deal",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
	      else 
	      	hs_quote_id = existing_quote["results"].first["id"]
	      	response = HTTParty.patch("#{QUOTE_PATH}/#{hs_quote_id}",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
	      end
	      
        # section_id = section_response.last["ID"] rescue nil

	      if response.present? && response.success?
          # Hubspot::Quote.get_file(quote["ID"])
	      	Hubspot::Quote.create_line_item(quote["ID"],response["id"],quote,section_response,deal_id,existing_deal)
          
	      	if timeline_data.present?
            deal_notes = HTTParty.get("https://api.hubapi.com/crm/v4/objects/deals/#{deal_id}/associations/notes",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
            if deal_notes["results"].present?
              delete_json = {
              "ids": deal_notes["results"].map{|i| i["toObjectId"]}
            }
              HTTParty.post("https://api.hubapi.com/crm-objects/v1/objects/notes/batch-delete",:body=> delete_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })          
            end
            Hubspot::Note.create_deal_note(timeline_data,deal_id)
          end
	      end
	    end
		end
   
		def self.create_line_item(quote_id,hubspot_quote_id,quote,section_response,deal_id,existing_deal)

      initial_time = Time.now
			query = { "columns"     => "ID,CostCenter,Name,Stage,OrderNo,Description,Notes,Total,Totals,Site,DisplayOrder,Billable"}
      line_items = HTTParty.get("https://api.hubapi.com/crm/v4/objects/quotes/#{hubspot_quote_id}/associations/line_items",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
      if line_items["results"].present?
        delete_json = {
            "ids": line_items["results"].map{|i| i["toObjectId"]}
          }
         HTTParty.post("https://api.hubapi.com/crm-objects/v1/objects/line_items/batch-delete",:body=> delete_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })          
      end


      puts "deleted lineitems"

      taxes = HTTParty.get("https://api.hubapi.com/crm/v4/objects/quotes/#{hubspot_quote_id}/associations/taxes",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
      if taxes["results"].present?
        taxes["results"].each do |taxe|
          delete_response = HTTParty.delete("https://api.hubapi.com/crm/v4/objects/quotes/#{hubspot_quote_id}/associations/taxes/#{taxe['toObjectId']}",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
        end
      end

      puts "deleted taxes"
      discounts = HTTParty.get("https://api.hubapi.com/crm/v4/objects/quotes/#{hubspot_quote_id}/associations/discounts",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
      if discounts["results"].present?
        discounts["results"].each do |discount|
          delete_response = HTTParty.delete("https://api.hubapi.com/crm/v4/objects/quotes/#{hubspot_quote_id}/associations/discounts/#{discount['toObjectId']}",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
        end
      end
      puts "deleted discounts"



      quote_sections = HTTParty.get("https://api.hubapi.com/crm/v4/objects/deals/#{deal_id}/associations/p_quote_sections",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
      if quote_sections["results"].present?
        quote_sections["results"].each do |taxe|
          delete_response = HTTParty.delete("https://api.hubapi.com/crm/v4/objects/deals/#{deal_id}/associations/p_quote_sections/#{taxe['toObjectId']}",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
        end
      end

      puts "section deleted"

      costcenters = HTTParty.get("https://api.hubapi.com/crm/v4/objects/deals/#{deal_id}/associations/p_costcenters",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
      if costcenters["results"].present?
        costcenters["results"].each do |taxe|
          delete_response = HTTParty.delete("https://api.hubapi.com/crm/v4/objects/deals/#{deal_id}/associations/p_costcenters/#{taxe['toObjectId']}",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
        end
      end
      puts "cost center deleted"


      if section_response.present?
        @product = []
        section_response.each do |section|
          section_id = section["ID"]
          existing_quote_section = Hubspot::QuoteSection.get_quote_section(section_id)
          if existing_quote_section["results"].blank?
            existing_quote_section = Hubspot::QuoteSection.get_quote_section_by_name(section["Name"])
          end
          if existing_quote_section["results"].blank?
            sec_response = Hubspot::QuoteSection.create_quote_section(section)
            if sec_response.present? && sec_response.success?
              hs_section_id = sec_response["id"]
            end 
          else
            hs_section_id = existing_quote_section["results"].first["id"]
          end



          quote_cost_center_response = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}/sections/#{section_id}/costCenters/",:query=> query, :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"})
          cs_names = quote_cost_center_response.map{|i| i["CostCenter"]["Name"]}
          if cs_names.include?("COUNTER SALES")
            Hubspot::Deal.service_deal_create(quote,existing_deal["results"],"cs")
          end
          if quote_cost_center_response.present?
            quote_cost_center_response.each do |cost_center|
              existing_cost_center = Hubspot::CostCenter.get_cost_center(cost_center["ID"])
              if existing_cost_center["results"].blank?
                existing_cost_center = Hubspot::CostCenter.get_cost_center_by_name(cost_center["Name"])
              end
              if existing_cost_center["results"].blank?
                description = Loofah.html5_fragment(cost_center["Description"]).to_text.strip.delete("\n")  rescue "--"

                body_json = {
                "properties": {
                  "simpro_id": cost_center["ID"],
                  "name": cost_center["Name"],
                  "description": cost_center["Description"]
                }
              }
                response = HTTParty.post("https://api.hubspot.com/crm/v3/objects/p_costcenters",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
                 hs_cost_center_id = response["id"]
              else
                hs_cost_center_id = existing_cost_center["results"].first["id"]
              end
            
              if cost_center["Billable"]== true
                catalogue_item = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}/sections/#{section_id}/costCenters/#{cost_center["ID"]}/catalogs/", :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"})
                if catalogue_item.present? && catalogue_item.success?
                  catalogue_item.each do |f|
                    product_name = f["Catalog"]["Name"]
                    sku_code = f["Catalog"]["PartNo"].to_s rescue nil
                    if f["Catalog"]["PartNo"].present?
                      part_no = f["Catalog"]["PartNo"]
                    else
                      part_no = f["ID"]
                    end
                    hs_product = Hubspot::Product.search_quoteline_item_product(product_name)
                    if hs_product.present? && hs_product["results"].present?
                      product = hs_product["results"].first["id"]
                    else
                      product_response = Hubspot::Product.create(f,"Catalog")
                      product = product_response["id"]
                    end
                    amount = f["SellPrice"]["ExTax"].round(2) rescue 0
                    quantity =  f["Total"]["Qty"].round(2) rescue 0
                     @product << [{
                          "name": "hs_product_id",
                          "value": product
                        },
                        {
                          "name": "quantity",
                          "value": quantity
                        },
                        {
                          "name": "name",
                          "value": product_name
                        },{
                          "name": "price",
                          "value": amount
                        },{
                          "name": "costcenter",
                          "value": cost_center["Name"]
                        },{
                          "name": "section",
                          "value": section["Name"]
                        },{
                          "name": "costcenter_description",
                          "value": cost_center["Description"]
                        }]
                  end
                end
                oneoff_item = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}/sections/#{section_id}/costCenters/#{cost_center["ID"]}/oneOffs/", :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"})
                if oneoff_item.present? && oneoff_item.success?
                  oneoff_item.each do |f|
                    product_name = f["Description"]
                    sku_code = f["PartNo"].to_s rescue nil
                    if f["PartNo"].present?
                      part_no = f["PartNo"]
                    else
                      part_no = f["ID"]
                    end 
                    hs_product = Hubspot::Product.search_quoteline_item_product(product_name)
                    if hs_product.present? && hs_product["results"].present?
                      product = hs_product["results"].first["id"]
                    else
                      product_response = Hubspot::Product.create(f,"One-Off")
                      product = product_response["id"]
                    end
                    amount = f["SellPrice"]["ExTax"].round(2) rescue 0
                    quantity =  f["Total"]["Qty"].round(2) rescue 0

                      @product << [{
                          "name": "hs_product_id",
                          "value": product
                        },
                        {
                          "name": "quantity",
                          "value": quantity
                        },
                        {
                          "name": "name",
                          "value": product_name
                        },{
                          "name": "price",
                          "value": amount
                        },{
                          "name": "costcenter",
                          "value": cost_center["Name"]
                        },{
                          "name": "section",
                          "value": section["Name"]
                        },{
                          "name": "costcenter_description",
                          "value": cost_center["Description"]
                        }]


                  end
                end
                prebuild_item = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}/sections/#{section_id}/costCenters/#{cost_center["ID"]}/prebuilds/", :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"})
                if prebuild_item.present?  && prebuild_item.success?
                  prebuild_item.each do |f|
                    product_name = f["Prebuild"]["Name"]
                     sku_code = f["Prebuild"]["PartNo"].to_s rescue nil
                     if f["Prebuild"]["PartNo"].present?
                      part_no = f["Prebuild"]["PartNo"]
                    else
                      part_no = f["ID"]
                    end 
                    hs_product = Hubspot::Product.search_quoteline_item_product(product_name)
                    if hs_product.present? && hs_product["results"].present?
                      product = hs_product["results"].first["id"]
                    else
                      product_response = Hubspot::Product.create(f,"Pre-Builds")
                      product = product_response["id"]
                    end
                    amount = f["SellPrice"]["ExTax"].round(2) rescue 0
                    quantity =  f["Total"]["Qty"].round(2) rescue 0

                    @product << [{
                          "name": "hs_product_id",
                          "value": product
                        },
                        {
                          "name": "quantity",
                          "value": quantity
                        },
                        {
                          "name": "name",
                          "value": product_name
                        },{
                          "name": "price",
                          "value": amount
                        },{
                          "name": "costcenter",
                          "value": cost_center["Name"]
                        },{
                          "name": "section",
                          "value": section["Name"]
                        },{
                          "name": "costcenter_description",
                          "value": cost_center["Description"]
                        }]

                  end
                end
                service_item = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}/sections/#{section_id}/costCenters/#{cost_center["ID"]}/serviceFees/", :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"})
                if service_item.present? && service_item.success?
                  service_item.each do |f|
                    product_name = f["ServiceFee"]["Name"] rescue nil
                    sku_code = f["ServiceFee"]["PartNo"].to_s rescue nil

                    if ["PartNo"].present?
                      part_no = ["PartNo"]
                    else
                      part_no = f["ID"]
                    end 

                    if product_name.present?
                      hs_product = Hubspot::Product.search_quoteline_item_product(product_name)
                      if hs_product.present? && hs_product["results"].present?
                        product = hs_product["results"].first["id"]
                      else
                        product_response = Hubspot::Product.create(f,"Service")
                        product = product_response["id"]
                      end
                      amount = f["SellPrice"]["ExTax"].round(2) rescue 0
                      quantity =  f["Total"]["Qty"].round(2) rescue 0

                      @product << [{
                          "name": "hs_product_id",
                          "value": product
                        },
                        {
                          "name": "quantity",
                          "value": quantity
                        },
                        {
                          "name": "name",
                          "value": product_name
                        },{
                          "name": "price",
                          "value": amount
                        },{
                          "name": "costcenter",
                          "value": cost_center["Name"]
                        },{
                          "name": "section",
                          "value": section["Name"]
                        },{
                          "name": "costcenter_description",
                          "value": cost_center["Description"]
                        }]
                      end
                  end
                end

                  labour_item = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}/sections/#{section_id}/costCenters/#{cost_center["ID"]}/labor/", :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"})
                if labour_item.present?  && labour_item.success?
                  labour_item.each do |f|
                    amount = f["SellPrice"]["ExTax"] rescue 0
                    quantity =  f["Total"]["Qty"] rescue 0
                    product_name = f["LaborType"]["Name"]
                    sku_code = f["LaborType"]["PartNo"].to_s rescue nil

                    if f["PartNo"].present?
                      part_no = f["PartNo"]
                    else
                      part_no = f["ID"]
                    end 


                    hs_product = Hubspot::Product.search_quoteline_item_product(product_name)
                    if hs_product.present? && hs_product["results"].present?
                      product = hs_product["results"].first["id"]
                    else
                      product_response = Hubspot::Product.create(f,"Labour")
                      product = product_response["id"]
                    end
                    amount = amount.round(2)

                    @product << [{
                          "name": "hs_product_id",
                          "value": product
                        },
                        {
                          "name": "quantity",
                          "value": quantity
                        },
                        {
                          "name": "name",
                          "value": product_name
                        },{
                          "name": "price",
                          "value": amount
                        },{
                          "name": "costcenter",
                          "value": cost_center["Name"]
                        },{
                          "name": "costcenter_description",
                          "value": cost_center["Description"]
                        }]

                  end
                end
              else
                catalogue_item = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}/sections/#{section_id}/costCenters/#{cost_center["ID"]}/catalogs/", :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"})
                if catalogue_item.present? && catalogue_item.success?
                  catalogue_item.each do |f|
                    product_name = f["Catalog"]["Name"]
                    sku_code = f["Catalog"]["PartNo"].to_s rescue nil

                    if f["Catalog"]["PartNo"].present?
                      part_no = f["Catalog"]["PartNo"]
                    else
                      part_no = f["ID"]
                    end 


                    hs_product = Hubspot::Product.search_quoteline_item_product(product_name)
                    if hs_product.present? && hs_product["results"].present?
                      product = hs_product["results"].first["id"]
                    else
                      product_response = Hubspot::Product.create(f,"Catalogue")
                      product = product_response["id"]
                    end
                    amount = f["SellPrice"]["ExTax"].round(2) rescue 0
                    quantity =  f["Total"]["Qty"].round(2) rescue 0


                    @product << [{
                          "name": "hs_product_id",
                          "value": product
                        },
                        {
                          "name": "quantity",
                          "value": quantity
                        },
                        {
                          "name": "name",
                          "value": product_name
                        },{
                          "name": "price",
                          "value": amount
                        },{
                          "name": "costcenter",
                          "value":  cost_center["Name"]
                        },{
                          "name": "section",
                          "value":  section["Name"]
                        },{
                          "name": "costcenter_description",
                          "value": cost_center["Description"]
                        }]

                  end
                end
                oneoff_item = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}/sections/#{section_id}/costCenters/#{cost_center["ID"]}/oneOffs/", :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"})
                if oneoff_item.present? && oneoff_item.success?
                  oneoff_item.each do |f|
                    product_name = f["Description"]
                    sku_code = f["PartNo"].to_s rescue nil
                    if f["PartNo"].present?
                      part_no = f["PartNo"]
                    else
                      part_no = f["ID"]
                    end 
                    hs_product = Hubspot::Product.search_quoteline_item_product(product_name)
                    if hs_product.present? && hs_product["results"].present?
                      product = hs_product["results"].first["id"]
                    else
                      product_response = Hubspot::Product.create(f,"One-Off")
                      product = product_response["id"]
                    end
                    amount = f["SellPrice"]["ExTax"].round(2) rescue 0
                    quantity =  f["Total"]["Qty"].round(2) rescue 0

                    @product << [{
                          "name": "hs_product_id",
                          "value": product
                        },
                        {
                          "name": "quantity",
                          "value": quantity
                        },
                        {
                          "name": "name",
                          "value": product_name
                        },{
                          "name": "price",
                          "value": amount
                        },{
                          "name": "costcenter",
                          "value":  cost_center["Name"]
                        },{
                          "name": "section",
                          "value":  section["Name"]
                        },{
                          "name": "costcenter_description",
                          "value": cost_center["Description"]
                        }]

                  end
                end
                prebuild_item = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}/sections/#{section_id}/costCenters/#{cost_center["ID"]}/prebuilds/", :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"})
                if prebuild_item.present?  && prebuild_item.success?
                  prebuild_item.each do |f|
                    product_name = f["Prebuild"]["Name"]
                    sku_code = f["Prebuild"]["PartNo"].to_s rescue nil
                    if f["Prebuild"]["PartNo"].present?
                      part_no = f["Prebuild"]["PartNo"]
                    else
                      part_no = f["ID"]
                    end 

                    hs_product = Hubspot::Product.search_quoteline_item_product(product_name)
                    if hs_product.present? && hs_product["results"].present?
                      product = hs_product["results"].first["id"]
                    else
                      product_response = Hubspot::Product.create(f,"Pre-Builds")
                      product = product_response["id"]
                    end
                    amount = f["SellPrice"]["ExTax"].round(2) rescue 0
                    quantity =  f["Total"]["Qty"].round(2) rescue 0

                    @product << [{
                          "name": "hs_product_id",
                          "value": product
                        },
                        {
                          "name": "quantity",
                          "value": quantity
                        },
                        {
                          "name": "name",
                          "value": product_name
                        },{
                          "name": "price",
                          "value": amount
                        },{
                          "name": "costcenter",
                          "value":  cost_center["Name"]
                        },{
                          "name": "section",
                          "value":  section["Name"]
                        },{
                          "name": "costcenter_description",
                          "value": cost_center["Description"]
                        }]
                  end
                end
                service_item = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}/sections/#{section_id}/costCenters/#{cost_center["ID"]}/serviceFees/", :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"})
                if service_item.present? && service_item.success?
                  service_item.each do |f|
                    product_name = f["ServiceFee"]["Name"] rescue nil
                    sku_code = f["ServiceFee"]["PartNo"].to_s rescue nil
                    if f["PartNo"].present?
                      part_no = f["PartNo"]
                    else
                      part_no = f["ID"]
                    end 

                    if product_name.present?
                      hs_product = Hubspot::Product.search_quoteline_item_product(product_name)
                      if hs_product.present? && hs_product["results"].present?
                        product = hs_product["results"].first["id"]
                      else
                        product_response = Hubspot::Product.create(f,"Service")
                        product = product_response["id"]
                      end
                      amount = f["SellPrice"]["ExTax"].round(2) rescue 0
                      quantity =  f["Total"]["Qty"].round(2) rescue 0

                      @product << [{
                          "name": "hs_product_id",
                          "value": product
                        },
                        {
                          "name": "quantity",
                          "value": quantity
                        },
                        {
                          "name": "name",
                          "value": product_name
                        },{
                          "name": "price",
                          "value": amount
                        },{
                          "name": "costcenter",
                          "value":  cost_center["Name"]
                        },{
                          "name": "section",
                          "value":  section["Name"]
                        },{
                          "name": "costcenter_description",
                          "value": cost_center["Description"]
                        }]
                      end
                  end
                end
                labour_item = HTTParty.get("#{ENV['SIMPRO_LIVE_URL']}/quotes/#{quote_id}/sections/#{section_id}/costCenters/#{cost_center["ID"]}/labor/", :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_KEY_ID']}"})
                if labour_item.present?  && labour_item.success?
                  labour_item.each do |f|
                    amount = f["SellPrice"]["ExTax"].round(2) rescue 0
                    quantity =  f["Total"]["Qty"].round(2) rescue 0
                    product_name = f["LaborType"]["Name"]
                    sku_code = f["LaborType"]["PartNo"].to_s rescue nil
                    if f["PartNo"].present?
                      part_no = f["PartNo"]
                    else
                      part_no = f["ID"]
                    end 


                    hs_product = Hubspot::Product.search_quoteline_item_product(product_name)
                    if hs_product.present? && hs_product["results"].present?
                      product = hs_product["results"].first["id"]
                    else
                      product_response = Hubspot::Product.create(f,"Labour")
                      product = product_response["id"]
                    end
                    @product << [{
                          "name": "hs_product_id",
                          "value": product
                        },
                        {
                          "name": "quantity",
                          "value": quantity
                        },
                        {
                          "name": "name",
                          "value": product_name
                        },{
                          "name": "price",
                          "value": amount
                        },{
                          "name": "costcenter",
                          "value":  cost_center["Name"]
                        },{
                          "name": "section",
                          "value":  section["Name"]
                        },{
                          "name": "costcenter_description",
                          "value": cost_center["Description"]
                        }]
                  end
                end

              end
               
              Hubspot::CostCenter.associate_quote_section(hs_section_id,hs_cost_center_id)
              if quote["Type"] == "Service"
                Hubspot::CostCenter.associate_deal(deal_id,hs_cost_center_id)
              end

            end
          end
          sub_total = quote_cost_center_response.map{|i| i["Total"]["ExTax"]}.sum rescue 0
          total = quote_cost_center_response.map{|i| i["Total"]["IncTax"]}.sum rescue 0
          tax = quote_cost_center_response.map{|i| i["Total"]["Tax"]}.sum rescue 0
          Hubspot::QuoteSection.update_price(hs_section_id,total,sub_total,tax)
          Hubspot::QuoteSection.associate_quote_section(deal_id,hs_section_id)
        end
        batch_create_response = HTTParty.post("https://api.hubapi.com/crm-objects/v1/objects/line_items/batch-create",:body=> @product.to_json, :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"})
        line_item_ids = batch_create_response.map{ |i| i["properties"]["hs_object_id"]}.map{|i| i["value"]}
        puts "batch create lineitems"

          from_id = hubspot_quote_id
          type = "quote_to_line_item"

          asso_body = {
            inputs: line_item_ids.map do |to_id|
              { "from" => { "id" => from_id }, "to" => { "id" => to_id }, "type" => type }
            end
          }

       acc_response = HTTParty.post("https://api.hubapi.com/crm/v3/associations/quote/line_item/batch/create",:body=> asso_body.to_json, :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"})
        puts "batch create line item and quote association"


        from_id = deal_id
          type = "deal_to_line_item"

          asso_body = {
            inputs: line_item_ids.map do |to_id|
              { "from" => { "id" => from_id }, "to" => { "id" => to_id }, "type" => type }
            end
          }
       deal_acc_response = HTTParty.post("https://api.hubapi.com/crm/v3/associations/deal/line_item/batch/create",:body=> asso_body.to_json, :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"})
        puts "batch create line item and deal association"
      

      end

      body_json = {
        "properties": {
          "hs_label": "GST",
          "hs_type": "FIXED",
          "hs_value":  quote["Total"]["Tax"]
        }     
      }
      tax_response = HTTParty.post("https://api.hubapi.com/crm/v3/objects/taxes",:body=> body_json.to_json, :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"})
      if tax_response["id"].present?
        if tax_response["id"].present?
          Hubspot::Quote.associate_tax(hubspot_quote_id,tax_response["id"])
        end
      end
      puts "tax addeds"
      last_time = Time.now
      total_time = last_time - initial_time
      Hubspot::Deal.update_properties(deal_id,quote,total_time)
		end
  def self.associate_tax(quote_id,tax_id)
      response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/quotes/#{quote_id}/associations/taxes/#{tax_id}/quote_to_tax",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
    end
    def self.associate_discount(quote_id,discount_id)
      response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/quotes/#{quote_id}/associations/discounts/#{discount_id}/quote_to_discount",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}" })
    end

		def self.find_quote_by_name(quote_name)
      sleep(2)
			body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "hs_title",
                "operator": "EQ",
                "value": "#{quote_name}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{QUOTE_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['SIMPRO_LIVE_TOKEN']}"
         })
      return response
		end
	end
end